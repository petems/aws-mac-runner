# Getting Started

## Step 1: Clone the Repository

```bash
git clone https://github.com/your-org/aws-mac-runner.git
cd aws-mac-runner
```

## Step 2: Verify Prerequisites

Ensure you have all required tools and AWS quotas. See [01-prerequisites.md](01-prerequisites.md).

```bash
# Check tools
terraform version   # >= 1.5.0
aws --version       # >= 2.x
gh --version        # >= 2.x

# Check your AWS identity
aws sts get-caller-identity

# Check Mac dedicated host quota (should be >= 1)
aws service-quotas get-service-quota \
  --service-code ec2 \
  --quota-code L-A8448DC5 \
  --query 'Quota.Value'
```

## Step 3: Configure Terraform Variables

```bash
cd terraform
cp terraform.tfvars.example terraform.tfvars
```

Edit `terraform.tfvars` with your values:

```hcl
aws_region        = "us-east-2"
availability_zone = "us-east-2a"
instance_type     = "mac2.metal"

github_runner_url   = "https://github.com/your-org/your-repo"
github_runner_token = "REPLACE_AFTER_NEXT_STEP"
github_runner_name  = "mac-runner"
```

## Step 4: Generate a GitHub Runner Token

Runner tokens are short-lived (1 hour). Generate one right before applying:

```bash
# For a repository runner
RUNNER_TOKEN=$(gh api -X POST \
  repos/{owner}/{repo}/actions/runners/registration-token \
  --jq '.token')

# For an organization runner
RUNNER_TOKEN=$(gh api -X POST \
  orgs/{org}/actions/runners/registration-token \
  --jq '.token')

echo "Token: $RUNNER_TOKEN"
```

Update `terraform.tfvars` with the token, or pass it at apply time:

```bash
# Option A: Set in tfvars (remember to not commit this file)
sed -i '' "s/REPLACE_AFTER_NEXT_STEP/$RUNNER_TOKEN/" terraform.tfvars

# Option B: Pass as variable at apply time
terraform apply -var="github_runner_token=$RUNNER_TOKEN"
```

## Step 5: Initialize and Apply

```bash
# Initialize Terraform
terraform init

# Review the plan
terraform plan

# Apply (this allocates a dedicated host — 24h billing starts!)
terraform apply
```

> **Warning:** Running `terraform apply` will allocate a dedicated host, which starts the **24-hour minimum billing period** immediately. See [05-cost-management.md](05-cost-management.md).

## Step 6: Verify the Runner

After apply completes (instance boot + bootstrap takes ~10-15 minutes):

1. **Check instance status:**
   ```bash
   aws ec2 describe-instances \
     --filters "Name=tag:Name,Values=mac-runner-mac-runner" \
     --query 'Reservations[].Instances[].{ID:InstanceId,State:State.Name,IP:PublicIpAddress}'
   ```

2. **Connect via SSM to check runner status:**
   ```bash
   # Use the SSM connect command from Terraform output
   terraform output ssm_connect_command

   # Once connected:
   sudo su - ec2-user
   cd ~/actions-runner
   ./svc.sh status
   ```

3. **Check GitHub:**
   - Go to your repository **Settings > Actions > Runners**
   - The runner should appear as "Idle" with your configured labels

## Step 7: Run a Workflow

Create a workflow that targets your runner:

```yaml
name: macOS Build
on: push
jobs:
  build:
    runs-on: [self-hosted, macOS, ARM64]
    steps:
      - uses: actions/checkout@v4
      - name: Build
        run: swift build
```

## Next Steps

- [04-github-runner-setup.md](04-github-runner-setup.md) — Runner configuration details
- [05-cost-management.md](05-cost-management.md) — Understanding and managing costs
- [06-security.md](06-security.md) — Security considerations
- [08-teardown.md](08-teardown.md) — How to safely tear down
