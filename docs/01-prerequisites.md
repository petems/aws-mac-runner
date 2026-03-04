# Prerequisites

## AWS Account Requirements

### Service Quotas

AWS Mac dedicated hosts have a **default quota of 0** in most regions. You must request a quota increase before deploying.

1. Open the [Service Quotas console](https://console.aws.amazon.com/servicequotas/)
2. Navigate to **Amazon EC2** > **Running Dedicated mac2 Hosts** (or mac2-m2, mac2-m2pro)
3. Request a quota increase to at least **1**
4. Approval typically takes 1-2 business days

> **Important:** Request the quota for the specific instance type you plan to use:
> - `mac2.metal` — Apple M1
> - `mac2-m2.metal` — Apple M2
> - `mac2-m2pro.metal` — Apple M2 Pro

### IAM Permissions

The IAM user or role running Terraform needs permissions to manage:

- EC2 (instances, dedicated hosts, security groups, AMIs)
- VPC (VPCs, subnets, internet gateways, route tables)
- IAM (roles, policies, instance profiles)
- SSM (for session management)
- CloudWatch Logs (if SSM session logging is enabled)

A policy with `ec2:*`, `vpc:*`, `iam:*`, `ssm:*`, and `logs:*` scoped to your account will work. For production, scope permissions more tightly.

### Region Availability

Mac instances are not available in all regions. Check [AWS documentation](https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/ec2-mac-instances.html#mac-instance-considerations) for current availability. Common regions:

- `us-east-1` (N. Virginia)
- `us-east-2` (Ohio)
- `us-west-2` (Oregon)
- `eu-west-1` (Ireland)
- `ap-southeast-1` (Singapore)

## Local Tooling

| Tool | Minimum Version | Purpose |
|------|----------------|---------|
| [Terraform](https://www.terraform.io/downloads) | >= 1.5.0 | Infrastructure provisioning |
| [AWS CLI](https://aws.amazon.com/cli/) | >= 2.x | AWS operations, SSM sessions |
| [Session Manager Plugin](https://docs.aws.amazon.com/systems-manager/latest/userguide/session-manager-working-with-install-plugin.html) | Latest | SSM session connectivity |
| [GitHub CLI](https://cli.github.com/) | >= 2.x | Runner token generation |
| [tflint](https://github.com/terraform-linters/tflint) | >= 0.50 | Terraform linting (optional) |
| [shellcheck](https://www.shellcheck.net/) | >= 0.9 | Script linting (optional) |
| [pre-commit](https://pre-commit.com/) | >= 3.x | Git hooks (optional) |

## GitHub Requirements

- A GitHub repository or organization where you want to register the runner
- Permission to create self-hosted runners (repo admin or org owner)
- A **runner registration token** — see [04-github-runner-setup.md](04-github-runner-setup.md)

## Cost Awareness

Before proceeding, understand the billing implications:

- **Allocating a dedicated host starts a 24-hour minimum billing period** (~$26/day for mac2.metal On-Demand)
- Stopping the instance does **not** release the host — you keep paying
- You must explicitly release the host to stop billing (after the 24h minimum)
- See [05-cost-management.md](05-cost-management.md) for full details
