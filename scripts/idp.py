#!/usr/bin/env python3
"""idp - self-service CLI for the group1-advanced Internal Developer Platform.

One entry point for everything an application team needs to onboard and work on the platform,
running the same gates locally that CI runs. Standard library only - no install needed.

    python scripts/idp.py doctor                      # check required tooling
    python scripts/idp.py new-service billing-service # scaffold a repo from the template
    python scripts/idp.py bootstrap                   # venv + deps + .env for app/ims
    python scripts/idp.py lint | test                 # same as reusable-ci.yml
    python scripts/idp.py build                       # container image
    python scripts/idp.py up | down | status          # local Postgres + API stack
    python scripts/idp.py scan                        # Gitleaks + Trivy + Checkov
    python scripts/idp.py tf-validate                 # terraform fmt/init/validate

Run `python scripts/idp.py <command> -h` for per-command options.
"""
import argparse
import json
import os
import shutil
import subprocess
import sys
import time
import urllib.request
from pathlib import Path

REPO_ROOT = Path(__file__).resolve().parent.parent
TEMPLATE_DIR = REPO_ROOT / "templates" / "service-repo-template"
DEFAULT_APP = "app/ims"
PLACEHOLDER = "TODO-service-name"
TEXT_EXTENSIONS = {".json", ".tf", ".py", ".txt", ".yml", ".yaml", ".md", ".ini", ".example"}
TF_TARGETS = [
    "infrastructure/modules/networking",
    "infrastructure/modules/ecr",
    "infrastructure/modules/iam-app-role",
    "infrastructure/modules/rds-postgres",
    "infrastructure/modules/s3-bucket",
    "infrastructure/modules/ecs-fargate-service",
    "infrastructure/environments/dev",
]
NETWORK, DB_CTR = "ims-net", "ims-db"

USE_COLOR = sys.stdout.isatty() and os.getenv("NO_COLOR") is None


def _c(code, msg):
    return f"\033[{code}m{msg}\033[0m" if USE_COLOR else msg


def step(msg):
    print(_c("36", f"==> {msg}"))


def ok(msg):
    print(_c("32", msg))


def warn(msg):
    print(_c("33", f"WARNING: {msg}"))


def die(msg, code=1):
    print(_c("31", f"ERROR: {msg}"), file=sys.stderr)
    sys.exit(code)


def run(cmd, cwd=None, check=True, quiet=False):
    if not quiet:
        print("    $ " + " ".join(str(c) for c in cmd))
    proc = subprocess.run([str(c) for c in cmd], cwd=cwd, stdout=subprocess.DEVNULL if quiet else None)
    if check and proc.returncode != 0:
        die(f"command failed with exit code {proc.returncode}: {cmd[0]}", proc.returncode)
    return proc.returncode


def container_runtime():
    for candidate in ("podman", "docker"):
        if shutil.which(candidate):
            return candidate
    die("neither podman nor docker found on PATH")


def app_dir(arg):
    path = (REPO_ROOT / arg).resolve()
    if not (path / "requirements.txt").exists():
        die(f"{arg} is not a Python service (no requirements.txt)")
    return path


def venv_python(app):
    sub = "Scripts/python.exe" if os.name == "nt" else "bin/python"
    py = app / ".venv" / sub
    return py if py.exists() else Path(sys.executable)


# ---------------------------------------------------------------- commands


def cmd_doctor(_args):
    tools = [
        ("python", True, "run the CLI, app and tests"),
        ("git", True, "version control"),
        ("podman|docker", False, "build/run containers, local security scans"),
        ("terraform", False, "validate infrastructure modules"),
    ]
    missing_required = False
    step("Checking platform tooling")
    for names, required, why in tools:
        found = next((shutil.which(n) for n in names.split("|") if shutil.which(n)), None)
        if found:
            print(f"  [ok]      {names:<14} {found}")
        else:
            label = "MISSING" if required else "optional"
            print(f"  [{label}] {names:<14} needed to {why}")
            missing_required |= required
    if sys.version_info < (3, 10):
        warn(f"Python {sys.version.split()[0]} found; 3.10+ recommended")
    if missing_required:
        die("required tooling missing")
    ok("Environment looks good.")


def cmd_list_services(_args):
    step("Python services in this repo")
    for req in sorted(REPO_ROOT.glob("**/requirements.txt")):
        if ".venv" in req.parts or "node_modules" in req.parts:
            continue
        rel = req.parent.relative_to(REPO_ROOT).as_posix()
        kind = "template" if rel.startswith("templates/") else "service"
        print(f"  {kind:<9} {rel}")


def cmd_new_service(args):
    name = args.name
    if not name.replace("-", "").isalnum() or name != name.lower():
        die("service name must be lowercase kebab-case, e.g. billing-service")
    out = Path(args.output).resolve() if args.output else REPO_ROOT.parent / name
    if out.exists():
        die(f"target directory already exists, refusing to overwrite: {out}")
    if not TEMPLATE_DIR.exists():
        die(f"template directory not found: {TEMPLATE_DIR}")

    step(f"Copying template to {out}")
    shutil.copytree(TEMPLATE_DIR, out, ignore=shutil.ignore_patterns(".venv", "__pycache__", ".pytest_cache"))

    step(f"Substituting '{PLACEHOLDER}' -> '{name}'")
    for f in out.rglob("*"):
        if f.is_file() and f.suffix in TEXT_EXTENSIONS:
            text = f.read_text(encoding="utf-8")
            if PLACEHOLDER in text:
                f.write_text(text.replace(PLACEHOLDER, name), encoding="utf-8")
                print(f"    updated: {f.relative_to(out).as_posix()}")

    if args.git:
        step("Initialising git repository")
        run(["git", "init", "-q"], cwd=out)
        run(["git", "add", "-A"], cwd=out)
        run(["git", "commit", "-q", "-m", f"chore: scaffold {name} from platform template"], cwd=out, check=False)

    print()
    ok(f"Service '{name}' scaffolded at {out}")
    print("Remaining manual steps (marked TODO(new-service) / TODO(platform-owner)):")
    print("  1. Replace app/service/ with your real application code.")
    print("  2. Set the platform repo path/ref in infrastructure/main.tf and .github/workflows/*.yml.")
    print("  3. Fill in docs/ai-specifications/*.md for this service.")


def cmd_bootstrap(args):
    app = app_dir(args.app)
    venv = app / ".venv"
    if not venv.exists():
        step(f"Creating virtualenv {venv.relative_to(REPO_ROOT)}")
        run([sys.executable, "-m", "venv", venv])
    py = venv_python(app)
    reqs = app / "requirements-dev.txt"
    if not reqs.exists():
        reqs = app / "requirements.txt"
    step(f"Installing {reqs.relative_to(REPO_ROOT)}")
    run([py, "-m", "pip", "install", "-q", "--upgrade", "pip"])
    run([py, "-m", "pip", "install", "-q", "-r", reqs])

    env, example = app / ".env", app / ".env.example"
    if example.exists() and not env.exists():
        step("Seeding .env from .env.example")
        shutil.copy(example, env)
    ok("Bootstrap complete. Next: idp test, idp up, idp scan")


def cmd_lint(args):
    app = app_dir(args.app)
    step(f"ruff check {args.app}")
    run([venv_python(app), "-m", "ruff", "check", "."], cwd=app)
    ok("Lint passed.")


def cmd_test(args):
    app = app_dir(args.app)
    step(f"pytest {args.app}")
    run([venv_python(app), "-m", "pytest", "-q", *args.pytest_args], cwd=app)
    ok("Tests passed.")


def cmd_build(args):
    app = app_dir(args.app)
    rt = container_runtime()
    tag = args.tag or f"{app.name}:local"
    step(f"Building {tag} with {rt}")
    run([rt, "build", "-t", tag, "-f", app / "Dockerfile", app])
    ok(f"Built {tag}")


def _wait_healthy(url, timeout):
    deadline = time.time() + timeout
    while time.time() < deadline:
        try:
            with urllib.request.urlopen(url, timeout=3) as r:
                if r.status == 200:
                    return json.loads(r.read())
        except Exception:
            time.sleep(2)
    return None


def cmd_up(args):
    app = app_dir(args.app)
    rt = container_runtime()
    name, tag = app.name, f"{app.name}:local"
    step(f"Starting local stack for {args.app} with {rt}")
    if run([rt, "network", "inspect", NETWORK], check=False, quiet=True) != 0:
        run([rt, "network", "create", NETWORK])
    run([rt, "rm", "-f", DB_CTR, f"{name}-api"], check=False, quiet=True)
    run([rt, "run", "-d", "--name", DB_CTR, "--network", NETWORK,
         "-e", "POSTGRES_USER=ims", "-e", "POSTGRES_PASSWORD=ims", "-e", "POSTGRES_DB=ims",
         "postgres:16.4-bookworm"])
    run([rt, "build", "-t", tag, "-f", app / "Dockerfile", app])
    step("Waiting for Postgres")
    for _ in range(30):
        if run([rt, "exec", DB_CTR, "pg_isready", "-U", "ims"], check=False, quiet=True) == 0:
            break
        time.sleep(1)
    run([rt, "run", "-d", "--name", f"{name}-api", "--network", NETWORK, "-p", f"{args.port}:3000",
         "-e", f"PGHOST={DB_CTR}", "-e", "PGPORT=5432", "-e", "PGUSER=ims",
         "-e", "PGPASSWORD=ims", "-e", "PGDATABASE=ims", tag])
    url = f"http://localhost:{args.port}/health"
    step(f"Waiting for {url}")
    body = _wait_healthy(url, 60)
    if body is None:
        die(f"service did not become healthy; check `{rt} logs {name}-api`")
    ok(f"Up: {json.dumps(body)}")


def cmd_down(args):
    rt = container_runtime()
    name = Path(args.app).name
    step("Stopping local stack")
    run([rt, "rm", "-f", f"{name}-api", DB_CTR], check=False)
    run([rt, "network", "rm", NETWORK], check=False, quiet=True)
    ok("Down.")


def cmd_status(args):
    url = f"http://localhost:{args.port}/health"
    body = _wait_healthy(url, 3)
    if body is None:
        die(f"{url} is not responding")
    ok(json.dumps(body))


def cmd_scan(args):
    rt = container_runtime()
    reports = REPO_ROOT / "security-reports"
    reports.mkdir(exist_ok=True)
    mount = f"{REPO_ROOT}:/repo"
    failures = []

    step("Gitleaks: scanning repository for secrets")
    if run([rt, "run", "--rm", "-v", mount, "zricethezav/gitleaks:latest", "detect", "--source=/repo",
            "--report-path=/repo/security-reports/gitleaks-report.json", "--redact"], check=False):
        failures.append("gitleaks")

    step(f"Trivy: scanning {args.app} dependencies (CRITICAL,HIGH)")
    if run([rt, "run", "--rm", "-v", mount, "aquasec/trivy:latest", "fs", "--severity", "CRITICAL,HIGH",
            "--exit-code", "1", "--format", "table", f"/repo/{args.app}"], check=False):
        failures.append("trivy")

    if not args.skip_iac:
        step(f"Checkov: scanning {args.terraform_dir}")
        if run([rt, "run", "--rm", "-v", mount, "bridgecrew/checkov:latest", "-d", f"/repo/{args.terraform_dir}",
                "--compact", "--quiet"], check=False):
            failures.append("checkov")

    print()
    if failures:
        die(f"security gates reported findings: {', '.join(failures)} (reports in security-reports/)")
    ok("All local security gates passed.")


def cmd_tf_validate(_args):
    if not shutil.which("terraform"):
        die("terraform not found on PATH (https://developer.hashicorp.com/terraform/install)")
    step("terraform fmt -check -recursive")
    if run(["terraform", "fmt", "-check", "-recursive"], cwd=REPO_ROOT / "infrastructure", check=False):
        die("formatting issues; run `terraform fmt -recursive` inside infrastructure/")
    failed = []
    for target in TF_TARGETS:
        step(f"Validating {target}")
        d = REPO_ROOT / target
        if run(["terraform", "init", "-backend=false", "-input=false"], cwd=d, check=False, quiet=True):
            failed.append(f"{target} (init)")
        elif run(["terraform", "validate"], cwd=d, check=False):
            failed.append(f"{target} (validate)")
    if failed:
        die("terraform validate failed for: " + ", ".join(failed))
    ok("All modules and environments passed terraform validate.")


def cmd_ci(args):
    """Run the full local equivalent of the CI pipeline."""
    cmd_lint(args)
    cmd_test(argparse.Namespace(app=args.app, pytest_args=[]))
    if not args.skip_containers:
        cmd_build(argparse.Namespace(app=args.app, tag=None))
        cmd_scan(argparse.Namespace(app=args.app, terraform_dir="infrastructure", skip_iac=False))
    ok("Local CI pipeline passed.")


# ---------------------------------------------------------------- parser


def build_parser():
    p = argparse.ArgumentParser(prog="idp", description="Self-service CLI for the group1-advanced platform.")
    sub = p.add_subparsers(dest="command", required=True, metavar="<command>")

    def add(name, fn, help_, app=False):
        sp = sub.add_parser(name, help=help_, description=help_)
        if app:
            sp.add_argument("--app", default=DEFAULT_APP, help=f"service directory (default: {DEFAULT_APP})")
        sp.set_defaults(func=fn)
        return sp

    add("doctor", cmd_doctor, "check that required tooling is installed")
    add("list-services", cmd_list_services, "list Python services and templates in this repo")

    sp = add("new-service", cmd_new_service, "scaffold a new service repo from the platform template")
    sp.add_argument("name", help="service name, lowercase kebab-case (e.g. billing-service)")
    sp.add_argument("--output", help="target directory (default: sibling of this repo)")
    sp.add_argument("--git", action="store_true", help="git init + initial commit in the new repo")

    add("bootstrap", cmd_bootstrap, "create .venv, install deps and seed .env", app=True)
    add("lint", cmd_lint, "ruff check (same as CI)", app=True)
    sp = add("test", cmd_test, "run pytest (same as CI)", app=True)
    sp.add_argument("pytest_args", nargs="*", help="extra args passed to pytest")
    sp = add("build", cmd_build, "build the container image", app=True)
    sp.add_argument("--tag", help="image tag (default: <service>:local)")

    sp = add("up", cmd_up, "start Postgres + API containers locally", app=True)
    sp.add_argument("--port", type=int, default=3000)
    add("down", cmd_down, "stop and remove the local stack", app=True)
    sp = add("status", cmd_status, "check the local service health endpoint")
    sp.add_argument("--port", type=int, default=3000)

    sp = add("scan", cmd_scan, "run Gitleaks, Trivy and Checkov locally via containers", app=True)
    sp.add_argument("--terraform-dir", default="infrastructure")
    sp.add_argument("--skip-iac", action="store_true", help="skip Checkov")
    add("tf-validate", cmd_tf_validate, "terraform fmt/init/validate every module and environment")

    sp = add("ci", cmd_ci, "run lint, test, build and scan - the full CI pipeline locally", app=True)
    sp.add_argument("--skip-containers", action="store_true", help="only lint + test")
    return p


def main(argv=None):
    args = build_parser().parse_args(argv)
    try:
        args.func(args)
    except KeyboardInterrupt:
        die("interrupted", 130)


if __name__ == "__main__":
    main()
