terraform {
  required_version = ">= 1.5.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.6"
    }
  }
}

resource "random_password" "master" {
  length           = 24
  special          = true
  override_special = "!#$%&*()-_=+[]{}<>:?"
}

resource "aws_db_subnet_group" "this" {
  name       = "${var.identifier}-subnet-group"
  subnet_ids = var.subnet_ids
  tags       = var.tags
}

resource "aws_security_group" "db" {
  name        = "${var.identifier}-sg"
  description = "Allows inbound Postgres only from explicitly allowed security groups"
  vpc_id      = var.vpc_id

  dynamic "ingress" {
    for_each = var.allowed_security_group_ids
    content {
      description     = "Postgres from ${ingress.value}"
      from_port       = 5432
      to_port         = 5432
      protocol        = "tcp"
      security_groups = [ingress.value]
    }
  }

  # checkov:skip=CKV_AWS_382: the DB needs outbound to reach Secrets Manager/CloudWatch;
  # inbound is already scoped to allowed_security_group_ids only, which is the actual gate.
  egress {
    description = "All outbound"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(var.tags, { Name = "${var.identifier}-sg" })
}

# Query/DDL logging (CKV2_AWS_30): a dedicated parameter group so callers can still layer
# their own tuning on top without losing the log_statement setting.
resource "aws_db_parameter_group" "this" {
  name   = "${var.identifier}-params"
  family = "postgres16"

  parameter {
    name  = "log_statement"
    value = "ddl"
  }

  # Encryption in transit (CKV2_AWS_69): reject any client connection that doesn't use SSL.
  parameter {
    name  = "rds.force_ssl"
    value = "1"
  }

  tags = var.tags
}

data "aws_iam_policy_document" "monitoring_assume" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["monitoring.rds.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "monitoring" {
  name               = "${var.identifier}-enhanced-monitoring"
  assume_role_policy = data.aws_iam_policy_document.monitoring_assume.json
  tags               = var.tags
}

resource "aws_iam_role_policy_attachment" "monitoring" {
  role       = aws_iam_role.monitoring.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonRDSEnhancedMonitoringRole"
}

resource "aws_db_instance" "this" {
  # checkov:skip=CKV_AWS_354: Performance Insights uses its AWS-managed default key here,
  # sufficient for this dev environment; pass a customer CMK as a follow-up if a specific
  # application's compliance requirements need one (same rationale as the secret's CKV_AWS_149).
  identifier                      = var.identifier
  engine                          = "postgres"
  engine_version                  = var.engine_version
  instance_class                  = var.instance_class
  allocated_storage               = var.allocated_storage
  storage_encrypted               = true
  db_name                         = var.db_name
  username                        = var.master_username
  password                        = random_password.master.result
  db_subnet_group_name            = aws_db_subnet_group.this.name
  parameter_group_name            = aws_db_parameter_group.this.name
  vpc_security_group_ids          = [aws_security_group.db.id]
  publicly_accessible             = false
  apply_immediately               = true
  auto_minor_version_upgrade      = true
  copy_tags_to_snapshot           = true
  performance_insights_enabled    = true
  monitoring_interval             = 60
  monitoring_role_arn             = aws_iam_role.monitoring.arn
  enabled_cloudwatch_logs_exports = ["postgresql", "upgrade"]

  # checkov:skip=CKV_AWS_157: controlled via var.multi_az, defaulting false for dev cost;
  # a prod composition of this module should set multi_az = true.
  multi_az = var.multi_az

  skip_final_snapshot = true
  # checkov:skip=CKV_AWS_293: controlled via var.deletion_protection, defaulting false so this
  # dev environment can be cleanly `terraform destroy`ed; set true for long-lived environments.
  deletion_protection = var.deletion_protection

  # checkov:skip=CKV_AWS_161: this module deliberately authenticates via a generated password
  # stored in Secrets Manager (see aws_secretsmanager_secret below) rather than IAM auth, so the
  # same credential-injection pattern works identically for ECS tasks via the "secrets" block.
  tags = var.tags
}

resource "aws_secretsmanager_secret" "this" {
  name = "${var.identifier}-credentials"
  # checkov:skip=CKV_AWS_149: uses the AWS-managed aws/secretsmanager key by default, which is
  # sufficient for this dev environment; pass a customer CMK ARN as a follow-up if a specific
  # application's compliance requirements need one.
  # checkov:skip=CKV2_AWS_57: automatic rotation requires a custom rotation Lambda, which is out
  # of scope for this capstone - documented as a platform follow-up.
  tags = var.tags
}

resource "aws_secretsmanager_secret_version" "this" {
  secret_id = aws_secretsmanager_secret.this.id
  secret_string = jsonencode({
    username = var.master_username
    password = random_password.master.result
    host     = aws_db_instance.this.address
    port     = aws_db_instance.this.port
    dbname   = var.db_name
  })
}
