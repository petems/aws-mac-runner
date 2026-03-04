# Cost Management

## Understanding Mac Instance Billing

### The 24-Hour Rule

Mac dedicated hosts have a **24-hour minimum allocation period**. Once you allocate a host (`terraform apply`), you are billed for at least 24 hours, even if you:

- Stop the instance immediately
- Destroy the instance
- Leave the host idle

You must **release the dedicated host** to stop billing (after the 24h minimum).

### Pricing (On-Demand, us-east-2, as of 2024)

| Instance Type | Chip | Per-Hour | Per-Day (24h min) | Per-Month (approx) |
|--------------|------|----------|-------------------|-------------------|
| mac2.metal | M1 | ~$1.083 | ~$26.00 | ~$780 |
| mac2-m2.metal | M2 | ~$1.209 | ~$29.00 | ~$870 |
| mac2-m2pro.metal | M2 Pro | ~$1.527 | ~$36.65 | ~$1,100 |

> Prices vary by region. Check the [EC2 pricing page](https://aws.amazon.com/ec2/pricing/on-demand/) for current rates.

### Additional Costs

| Resource | Approximate Cost |
|----------|-----------------|
| 200GB gp3 EBS (10K IOPS, 400 MiB/s) | ~$25/month |
| Data transfer (outbound) | $0.09/GB after 100GB free |
| CloudWatch Logs (if SSM logging enabled) | ~$0.50/GB ingested |

## Cost Optimization

### Savings Plans

For long-term use, [Compute Savings Plans](https://aws.amazon.com/savingsplans/) can reduce costs up to 44%:

| Commitment | Discount |
|-----------|----------|
| 1-year, no upfront | ~17% |
| 1-year, all upfront | ~28% |
| 3-year, all upfront | ~44% |

### Stop vs Destroy

| Action | Host Released? | Billing Stops? | Data Preserved? |
|--------|---------------|----------------|-----------------|
| Stop instance | No | No | Yes |
| Terminate instance | No | No | No (unless EBS persists) |
| Release host | Yes | Yes (after 24h) | N/A |
| `terraform destroy` | Yes | Yes (after 24h) | No |

**Stopping the instance does not stop billing.** You must release the dedicated host.

### Tips

1. **Use `terraform destroy` when done** — this releases the host (after the 24h minimum)
2. **Don't leave hosts idle** — if the runner is not being used, tear down
3. **Monitor with AWS Cost Explorer** — set up billing alerts
4. **Consider scheduling** — allocate hosts only during work hours (not implemented in this project, but achievable with Lambda/EventBridge)

## Setting Up Billing Alerts

```bash
# Create a billing alarm (requires us-east-1 for billing metrics)
aws cloudwatch put-metric-alarm \
  --region us-east-1 \
  --alarm-name "mac-runner-daily-cost" \
  --metric-name EstimatedCharges \
  --namespace AWS/Billing \
  --statistic Maximum \
  --period 86400 \
  --threshold 50 \
  --comparison-operator GreaterThanThreshold \
  --evaluation-periods 1 \
  --alarm-actions "arn:aws:sns:us-east-1:ACCOUNT_ID:billing-alerts"
```
