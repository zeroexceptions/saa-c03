### Auto Scaling Groups (ASG)
 
### Overview
Automatic scaling can occur via:
 
- **Capacity Settings** — set the expected range of capacity
  - Manual Scaling
- **Health Check Replacements** — replace instances if they are determined unhealthy
  - EC2 or ELB Health Checks
- **Scaling Policies** — set complex rules to determine when to scale up or down
  - Simple Scaling
  - Step Scaling
  - Target Tracking Scaling
  - Predictive Scaling


### Notes
ASGs are used to scale EC2 instances.
ECS with EC2 → ✅ works
EKS with EC2 → ✅ works
Fargate → ❌ **does not use** ASGs
 