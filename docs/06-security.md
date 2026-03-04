# Security

## Network Security

### Security Group

The default security group allows:
- **Egress**: All outbound traffic (required for GitHub Actions communication)
- **Ingress**: None (SSM-only access by default)

SSH ingress is opt-in via `ssh_allowed_cidrs`. When enabled, restrict to specific IPs:

```hcl
# Only allow SSH from your office IP
ssh_allowed_cidrs = ["203.0.113.10/32"]
```

### VPC Isolation

The Mac instance runs in a dedicated VPC with a single public subnet. For enhanced isolation, consider:
- VPC Flow Logs for network monitoring
- Network ACLs for additional layer of filtering
- Private subnet with NAT gateway (increases cost, reduces attack surface)

## Instance Access

### SSM Session Manager (Default)

SSM is the recommended access method:
- No inbound ports required
- Audit trail via CloudTrail
- IAM-based access control
- No SSH key management

```bash
# Connect to the instance
aws ssm start-session --target <instance-id>
```

Enable session logging for compliance:
```hcl
enable_ssm_logging = true
```

### SSH (Opt-in)

SSH is available when `ssh_allowed_cidrs` is set. If using SSH:
- Use key-based authentication only
- Rotate keys regularly
- Restrict source IPs

## IMDSv2

Instance Metadata Service v2 (IMDSv2) is enforced. This prevents:
- SSRF-based credential theft
- Unauthorized access to instance metadata
- Token-based access only (requires PUT request for session token)

## EBS Encryption

Root volumes are encrypted by default using AWS-managed keys. For customer-managed keys (CMK), extend the `mac-instance` module.

## GitHub Runner Token Security

- Runner registration tokens expire after 1 hour
- Tokens are used once during `config.sh` and not stored
- The runner authenticates with GitHub using a JWT after registration
- Never commit tokens to version control
- Use `terraform apply -var` or environment variables to pass tokens

## IAM Least Privilege

The instance role includes only:
- `AmazonSSMManagedInstanceCore` — required for SSM connectivity
- Optional CloudWatch Logs permissions (when SSM logging is enabled)

No S3, ECR, or other service permissions are granted by default. Add permissions as needed for your CI/CD workflows.

## Recommendations for Production

1. **Enable VPC Flow Logs** — monitor network activity
2. **Use AWS Config** — track configuration changes
3. **Enable GuardDuty** — threat detection
4. **Rotate runner tokens** — use short-lived tokens, consider fine-grained PATs
5. **Use ephemeral runners** — clean environment per job, better isolation
6. **Bake AMIs** — reduce attack surface during bootstrap
7. **Restrict IAM** — only grant permissions the CI/CD jobs actually need
8. **Enable SSM session logging** — audit all shell access
