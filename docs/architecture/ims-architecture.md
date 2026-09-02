# IMS Architecture

## AWS target architecture (`infrastructure/environments/dev`)

```mermaid
flowchart TB
    Internet((Internet))

    subgraph VPC["VPC (module: networking)"]
        subgraph Public["Public subnets"]
            ALB["ALB (module: ecs-fargate-service)"]
        end
        subgraph Private["Private subnets"]
            ECS["ECS Fargate tasks: IMS API\n(module: ecs-fargate-service)"]
            RDS[("RDS Postgres\n(module: rds-postgres)")]
        end
        NAT["NAT Gateway"]
    end

    ECR["ECR repository\n(module: ecr)"]
    SM["Secrets Manager\nDB credentials"]
    IAM["IAM execution + task roles\n(module: iam-app-role)"]
    CW["CloudWatch Logs"]

    Internet -->|HTTP :80| ALB
    ALB -->|:3000, ALB-SG -> service-SG only| ECS
    ECS -->|:5432, service-SG -> db-SG only| RDS
    ECS -->|outbound via NAT| NAT
    NAT --> Internet
    ECS -.pulls image.-> ECR
    ECS -.assumes.-> IAM
    IAM -.reads.-> SM
    RDS -.generates & stores creds in.-> SM
    ECS -.ships logs to.-> CW
```

## Local demo architecture (`app/ims/docker-compose.yml`)

```mermaid
flowchart LR
    Dev["Developer / curl"] -->|:3000| API["api container\n(Node/Express, Dockerfile)"]
    API -->|:5432| DB[("db container\npostgres:16")]
```

The local demo intentionally mirrors the AWS shape at the application layer (same image, same environment
variable contract — `PGHOST`/`PGPORT`/`PGUSER`/`PGPASSWORD`/`PGDATABASE`) so behavior validated locally
transfers directly to the ECS deployment; only the *infrastructure* wrapping around the container differs.

## Data model

```mermaid
erDiagram
    ITEMS {
        int id PK
        text sku UK
        text name
        int quantity
        text warehouse_location
        int reorder_level
        timestamptz updated_at
    }
```
