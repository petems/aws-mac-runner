# Teardown

## Before Destroying Infrastructure

**Always de-register the GitHub runner before destroying the instance.** Otherwise, a stale runner entry will remain in your GitHub settings.

### Step 1: De-register the Runner

**Option A: From the instance (recommended)**

```bash
# Connect via SSM
aws ssm start-session --target <instance-id>

# Switch to ec2-user and run cleanup
su - ec2-user
export GITHUB_RUNNER_TOKEN=$(gh api -X POST repos/{owner}/{repo}/actions/runners/registration-token --jq '.token')
~/aws-mac-runner/scripts/cleanup-host.sh
```

**Option B: From GitHub UI**

1. Go to **Settings > Actions > Runners**
2. Click the runner
3. Click **Remove runner**

**Option C: Via API**

```bash
# List runners to get the ID
gh api repos/{owner}/{repo}/actions/runners --jq '.runners[] | {id, name, status}'

# Remove by ID
gh api -X DELETE repos/{owner}/{repo}/actions/runners/{runner_id}
```

### Step 2: Destroy Infrastructure

```bash
cd terraform
terraform destroy
```

Review the plan and confirm. Terraform will:
1. Terminate the EC2 instance
2. Release the dedicated host (billing stops after 24h minimum)
3. Remove the security group, IAM resources, and VPC

### Step 3: Verify Host Release

After `terraform destroy`, confirm the dedicated host was released:

```bash
aws ec2 describe-hosts \
  --filter "Name=tag:Name,Values=mac-runner-mac-host" \
  --query 'Hosts[].{ID:HostId,State:State}'
```

The host should show as `released`. If it shows `pending` or `available`, the 24-hour period may not have elapsed yet.

## Partial Teardown

### Stop Instance Only (Keep Host)

This keeps the host allocated (you keep paying) but stops the instance:

```bash
aws ec2 stop-instances --instance-ids <id>
```

> **Note:** You will continue to be billed for the dedicated host.

### Remove Runner Only (Keep Infrastructure)

```bash
# SSM into the instance
aws ssm start-session --target <instance-id>

su - ec2-user
cd ~/actions-runner
sudo ./svc.sh stop
sudo ./svc.sh uninstall
./config.sh remove --token <TOKEN>
```

## Cost Reminder

After destroying, verify in [AWS Cost Explorer](https://console.aws.amazon.com/cost-management/) that no unexpected charges continue. It may take a few hours for billing to reflect the host release.
