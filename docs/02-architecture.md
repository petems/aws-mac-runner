# Architecture

## Overview

This project deploys a single macOS GitHub Actions runner on an AWS EC2 Mac instance. The architecture is intentionally simple: one dedicated host, one instance, one runner.

## Architecture Diagram

```
┌─────────────────────────────────────────────────────────────┐
│                        AWS Account                          │
│                                                             │
│  ┌───────────────────────────────────────────────────────┐  │
│  │                    VPC (10.0.0.0/16)                   │  │
│  │                                                       │  │
│  │  ┌─────────────────────────────────────────────────┐  │  │
│  │  │         Public Subnet (10.0.1.0/24)             │  │  │
│  │  │                AZ: us-east-2a                    │  │  │
│  │  │                                                 │  │  │
│  │  │  ┌───────────────────────────────────────────┐  │  │  │
│  │  │  │         Dedicated Host (mac2.metal)       │  │  │  │
│  │  │  │                                           │  │  │  │
│  │  │  │  ┌─────────────────────────────────────┐  │  │  │  │
│  │  │  │  │      Mac EC2 Instance               │  │  │  │  │
│  │  │  │  │                                     │  │  │  │  │
│  │  │  │  │  ┌──────────┐  ┌─────────────────┐  │  │  │  │  │
│  │  │  │  │  │ GitHub   │  │ Homebrew, jq,   │  │  │  │  │  │
│  │  │  │  │  │ Actions  │  │ Xcode CLI,      │  │  │  │  │  │
│  │  │  │  │  │ Runner   │  │ SwiftLint, etc. │  │  │  │  │  │
│  │  │  │  │  └──────────┘  └─────────────────┘  │  │  │  │  │
│  │  │  │  │                                     │  │  │  │  │
│  │  │  │  │  200GB gp3 EBS (encrypted)          │  │  │  │  │
│  │  │  │  │  10,000 IOPS / 400 MiB/s            │  │  │  │  │
│  │  │  │  └─────────────────────────────────────┘  │  │  │  │
│  │  │  └───────────────────────────────────────────┘  │  │  │
│  │  │                                                 │  │  │
│  │  └─────────────────────────────────────────────────┘  │  │
│  │           │                                           │  │
│  │           │ Internet Gateway                          │  │
│  └───────────┼───────────────────────────────────────────┘  │
│              │                                              │
└──────────────┼──────────────────────────────────────────────┘
               │
               ▼
   ┌───────────────────────┐
   │   GitHub Actions      │
   │   (job dispatch)      │
   └───────────────────────┘
```

## Component Details

### Networking

- **VPC** with DNS support and hostnames enabled
- **Single public subnet** in the target AZ — Mac dedicated hosts are pinned to one AZ
- **Internet Gateway** for outbound access (required for GitHub communication)
- No NAT gateway needed (instance is in a public subnet)

### Dedicated Host

- Required for all Mac instances — cannot run on shared tenancy
- **24-hour minimum allocation period** (billing starts immediately)
- `host_recovery = "off"` — not supported for Mac hosts
- `auto_placement = "on"` — allows instances to launch on any available host

### Mac Instance

- Runs on the dedicated host
- **arm64 architecture** (Apple Silicon only: M1, M2, M2 Pro)
- **200GB gp3 EBS** root volume with tuned IOPS/throughput for CI workloads
- **IMDSv2 enforced** — prevents SSRF-based credential theft
- User data script bootstraps the GitHub runner

### Security

- **Security group**: egress-only by default, SSH opt-in via `ssh_allowed_cidrs`
- **IAM role** with `AmazonSSMManagedInstanceCore` for SSM access
- **SSM Session Manager** as the default access method (no inbound ports, CloudTrail audit)

### Access Methods

| Method | Default | Inbound Ports | Audit Trail |
|--------|---------|---------------|-------------|
| SSM Session Manager | Yes | None | CloudTrail |
| SSH | Opt-in | 22 | No (unless logged) |

## Design Decisions

### Why Single-AZ?

Mac dedicated hosts are pinned to a specific availability zone. Multi-AZ would require multiple dedicated hosts, doubling the minimum cost. This project prioritizes simplicity and cost awareness.

### Why User Data Over AMI Baking?

User data scripts are transparent and easy to modify — ideal for a guide repository. For production use with faster boot times, consider baking a custom AMI with tools pre-installed. See the scripts as a reference for what to include in your AMI.

### Why No Auto-Scaling?

Mac instances on dedicated hosts have constraints (24h minimum, single instance per host) that make traditional auto-scaling impractical. For scaling strategies, consider maintaining a pool of pre-allocated hosts or using ephemeral runners with a scheduler.
