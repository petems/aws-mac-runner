# Troubleshooting

## Instance Won't Launch

### "InsufficientInstanceCapacity" Error

Mac instances require dedicated hosts, and capacity is limited per AZ.

**Fix:**
- Try a different availability zone
- Try a different region
- Wait and retry — capacity is released as other users' 24h allocations expire
- Check the [AWS Health Dashboard](https://health.aws.amazon.com/) for known issues

### "Host limit exceeded" Error

Your dedicated host quota is 0 (the default).

**Fix:**
1. Request a quota increase via Service Quotas console
2. Wait for approval (1-2 business days)
3. Ensure you're requesting the right instance type quota

### Instance Stuck in "Pending"

Mac instances take longer to launch than typical EC2 instances (5-15 minutes).

**Actions:**
1. Wait at least 15 minutes
2. Check the instance system log:
   ```bash
   aws ec2 get-console-output --instance-id <id>
   ```
3. If still stuck after 20 minutes, terminate and re-launch

## Runner Not Appearing in GitHub

### Bootstrap Script Failed

Connect via SSM and check logs:

```bash
aws ssm start-session --target <instance-id>

# Check bootstrap log
cat /var/log/mac-runner-bootstrap.log

# Check cloud-init log
cat /var/log/cloud-init-output.log

# Check runner configuration
su - ec2-user
cd ~/actions-runner
cat _diag/Runner_*.log | tail -50
```

### Token Expired

Runner tokens are valid for 1 hour. If `terraform apply` took too long, the token may have expired.

**Fix:**
1. Generate a new token
2. SSM into the instance
3. Re-run the configuration:
   ```bash
   su - ec2-user
   cd ~/actions-runner
   ./config.sh remove --token <OLD_OR_NEW_TOKEN>
   ./config.sh --url <REPO_URL> --token <NEW_TOKEN> --unattended --replace
   sudo ./svc.sh install $(whoami)
   sudo ./svc.sh start
   ```

### Runner Shows "Offline"

The runner service may have stopped.

```bash
# Check service status
cd ~/actions-runner
sudo ./svc.sh status

# Restart if stopped
sudo ./svc.sh start

# Check runner logs for errors
ls -la _diag/
tail -100 _diag/Runner_*.log
```

## Slow Boot / Long Bootstrap

Mac instances have a longer boot time than standard EC2 instances. The full bootstrap (user data + script execution) can take 10-15 minutes.

### Speed Up Options

1. **Bake a custom AMI** — pre-install tools, skip bootstrap
2. **Reduce installed tools** — edit `install-common-tools.sh` to only install what you need
3. **Increase EBS performance** — already tuned to 10K IOPS / 400 MiB/s

## SSM Connection Issues

### "TargetNotConnected" Error

The SSM agent may not have started yet (give it 5-10 minutes after launch) or the instance may not have the required IAM role.

**Check:**
```bash
# Verify instance profile is attached
aws ec2 describe-instances --instance-ids <id> \
  --query 'Reservations[].Instances[].IamInstanceProfile'

# Check SSM agent status (if you can SSH)
sudo systemctl status amazon-ssm-agent
```

### Session Manager Plugin Not Installed

```bash
# macOS
brew install --cask session-manager-plugin

# Verify
session-manager-plugin --version
```

## Terraform Issues

### "Error releasing host" on Destroy

Dedicated hosts cannot be released until the 24-hour minimum period has passed, and all instances must be terminated first.

**Fix:**
1. Terraform should handle the order, but if it fails:
   ```bash
   # Terminate the instance first
   aws ec2 terminate-instances --instance-ids <id>
   # Wait for termination
   aws ec2 wait instance-terminated --instance-ids <id>
   # Then retry destroy
   terraform destroy
   ```

### State Drift

If you manually changed resources outside Terraform:

```bash
# Refresh state
terraform refresh

# Check for drift
terraform plan
```

## User Data Script Debugging

User data scripts run as root. The bootstrap switches to `ec2-user` for runner installation.

```bash
# Full user data output
cat /var/log/cloud-init-output.log

# Bootstrap-specific log
cat /var/log/mac-runner-bootstrap.log

# Check if scripts were extracted
ls -la /tmp/mac-runner-scripts/
```
