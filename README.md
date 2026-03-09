# aws-mac-runner

> Practical guide and Infrastructure as Code for running macOS GitHub Actions self-hosted runners on AWS EC2 Mac instances.

## Why?

GitHub's hosted macOS runners work for many projects, but when you need Apple Silicon (M1/M2/M2 Pro), custom toolchains, persistent caches, or more control over the build environment, self-hosted runners on AWS EC2 Mac instances are a solid option.

This repo provides production-ready Terraform modules and bootstrap scripts to get a macOS GitHub Actions runner running on AWS with minimal effort.

## What's Included

- **Terraform modules** — VPC, dedicated host, Mac instance, security groups, IAM, SSM
- **Bootstrap scripts** — Homebrew, Xcode CLI tools, common CI tools, GitHub runner agent
- **Documentation** — Prerequisites, architecture, cost management, security, troubleshooting
- **CI workflows** — Terraform validation, example macOS build workflow

## Quick Start

```bash
# 1. Clone
git clone https://github.com/your-org/aws-mac-runner.git
cd aws-mac-runner/terraform

# 2. Configure
cp terraform.tfvars.example terraform.tfvars
# Edit terraform.tfvars with your values

# 3. Generate a runner token (expires in 1 hour)
RUNNER_TOKEN=$(gh api -X POST repos/{owner}/{repo}/actions/runners/registration-token --jq '.token')

# 4. Deploy (starts 24h billing!)
terraform init
terraform apply -var="github_runner_token=$RUNNER_TOKEN"

# 5. Verify (wait ~10-15 min for bootstrap)
# Check Settings > Actions > Runners in your GitHub repo
```

> **Cost Warning:** Allocating a dedicated host starts a **24-hour minimum billing period** (~$26+/day). See [Cost Management](docs/05-cost-management.md).

> **Timing:** Dedicated host allocation takes 10-20 minutes, instance boot 5-10 minutes, plus bootstrap scripts. Expect **20-45 minutes total** from `terraform apply` to runner online.

## GitHub Runner Token

The runner registration token is short-lived (1 hour) and must be generated immediately before deploying.

**For a repository runner:**

```bash
# Replace {owner}/{repo} with your repository
RUNNER_TOKEN=$(gh api -X POST \
  repos/{owner}/{repo}/actions/runners/registration-token \
  --jq '.token')
```

**For an organization runner:**

```bash
# Replace {org} with your organization
RUNNER_TOKEN=$(gh api -X POST \
  orgs/{org}/actions/runners/registration-token \
  --jq '.token')
```

Pass the token to Terraform at apply time (never commit it to tfvars):

```bash
terraform apply -var="github_runner_token=$RUNNER_TOKEN"
```

Or combine token generation and deploy in one step:

```bash
terraform apply -var="github_runner_token=$(gh api -X POST repos/{owner}/{repo}/actions/runners/registration-token --jq '.token')"
```

See [GitHub Runner Setup](docs/04-github-runner-setup.md) for details on labels, ephemeral mode, and service management.

## Architecture

```
GitHub Actions  ──>  Internet Gateway  ──>  Public Subnet  ──>  Mac Instance
                                                                 (Dedicated Host)
```

- Single VPC, single AZ, single dedicated host
- SSM Session Manager for access (no inbound ports by default)
- IMDSv2 enforced, EBS encryption enabled
- Apple Silicon only (M1, M2, M2 Pro)

See [Architecture](docs/02-architecture.md) for the full diagram.

## Supported Instance Types

| Instance Type | Chip | Architecture |
|--------------|------|-------------|
| `mac2.metal` | Apple M1 | arm64 |
| `mac2-m2.metal` | Apple M2 | arm64 |
| `mac2-m2pro.metal` | Apple M2 Pro | arm64 |

## Documentation

| Document | Description |
|----------|-------------|
| [Prerequisites](docs/01-prerequisites.md) | AWS quotas, tooling, permissions |
| [Architecture](docs/02-architecture.md) | Design diagram and component details |
| [Getting Started](docs/03-getting-started.md) | Step-by-step deployment guide |
| [GitHub Runner Setup](docs/04-github-runner-setup.md) | Token generation, labels, service management |
| [Cost Management](docs/05-cost-management.md) | 24h billing, pricing, optimization |
| [Security](docs/06-security.md) | VPC isolation, SSM, IMDSv2, encryption |
| [Troubleshooting](docs/07-troubleshooting.md) | Common issues and solutions |
| [Teardown](docs/08-teardown.md) | Safe de-registration and destruction |
| [Agentless Puppet (Bolt)](docs/09-puppet-agentless.md) | Push config changes without rebuilding |

## Repository Structure

```
aws-mac-runner/
├── terraform/
│   ├── main.tf, variables.tf, outputs.tf    # Root module
│   ├── versions.tf, providers.tf            # Provider config
│   ├── terraform.tfvars.example             # Example variables
│   ├── backend.tf.example                   # Remote state example
│   ├── modules/
│   │   ├── networking/                      # VPC, subnet, IGW
│   │   ├── dedicated-host/                  # EC2 dedicated host
│   │   ├── mac-instance/                    # Mac EC2 instance
│   │   ├── security/                        # SG, IAM role, profile
│   │   └── ssm/                             # SSM session logging
│   └── examples/
│       └── apple-silicon-m2pro/             # M2 Pro example config
├── scripts/
│   ├── user-data.sh.tftpl                     # EC2 user data template
│   ├── bootstrap.sh                         # Orchestrator
│   ├── install-homebrew.sh
│   ├── install-xcode-cli-tools.sh
│   ├── install-common-tools.sh
│   ├── install-github-runner.sh
│   ├── configure-runner-service.sh
│   └── cleanup-host.sh
├── puppet/
│   ├── site-modules/                        # Custom Puppet modules (role, profile)
│   ├── data/                                # Hiera data (common.yaml)
│   ├── hiera.yaml                           # Hiera hierarchy config
│   ├── Puppetfile                           # Forge module dependencies
│   └── bolt/                                # Bolt agentless project
│       ├── Boltdir/                         # Bolt project config + inventory
│       └── plans/                           # Bolt plans (provision, cleanup)
├── docs/                                    # Guides (01-09)
├── .github/workflows/                       # CI pipelines
├── Makefile                                 # Common operations
└── .pre-commit-config.yaml                  # Code quality hooks
```

## Using the Runner in Workflows

```yaml
jobs:
  build:
    runs-on: [self-hosted, macOS, ARM64]
    steps:
      - uses: actions/checkout@v4
      - run: swift build
```

## Teardown

Always de-register the runner before destroying infrastructure:

```bash
# 1. De-register runner (from the instance via SSM)
scripts/cleanup-host.sh

# 2. Destroy infrastructure
cd terraform && terraform destroy
```

See [Teardown](docs/08-teardown.md) for detailed instructions.

## Development

```bash
# Install pre-commit hooks
pre-commit install

# Format Terraform
make fmt

# Validate Terraform
make validate

# Lint Terraform
make lint

# Lint scripts
make shellcheck
```

## License

[MIT](LICENSE)
