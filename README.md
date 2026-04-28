# DevOps Terraform Script

Terraform project for a scalable AWS web stack with VPC, ALB, ASG, CloudWatch alarms, and EC2 boot scripts.

## Project Layout

```text
.
├── infra/      # All Terraform configuration and state
├── scripts/    # EC2 startup scripts used by Terraform
├── secrets/    # Sensitive files (key pair, TLS cert/key/csr) - gitignored
├── leaner_notes/
└── root files  # docs and helper files
```

## Important Paths

- Terraform root: `infra/`
- Boot scripts: `scripts/user_data.sh`, `scripts/asg_start.sh`, `scripts/db_install.sh`
- ALB TLS files expected in `secrets/`:
	- `webserver.key`
	- `webserver_self.crt`

## Prerequisites

1. Terraform installed
2. AWS credentials configured (AWS CLI profile or environment variables)
3. Access to target AWS account/region
4. Existing key pair name used by Terraform (currently `devops02`)

## Run Terraform (New Structure)

Run all Terraform commands from repository root using `-chdir=infra`:

```bash
terraform -chdir=infra init
terraform -chdir=infra validate
terraform -chdir=infra plan
terraform -chdir=infra apply
```

Outputs:

```bash
terraform -chdir=infra output
```

Destroy when finished:

```bash
terraform -chdir=infra destroy
```

## Required Updates Before Apply

Review and update these values before deployment:

1. `infra/provider.tf`
- Confirm AWS region is correct.

2. `infra/compute.tf`
- Confirm AMI (`web_server_ami`) is valid in your region.
- Confirm instance type is what you want.
- Confirm key pair name exists in your AWS account (`key_name = "devops02"`).

3. `scripts/user_data.sh`
- If deploying `museum_app`, update `.env` placeholders created by script:
	- `cookie_password`
	- `JWT_SECRET`
	- `MONGO_URL` (replace `REPLACE_DB_PRIVATE_IP` with DB private IP)

4. TLS files in `secrets/`
- Ensure these exist and are valid for ALB HTTPS listener:
	- `webserver.key`
	- `webserver_self.crt`

## ASG Script Change Behavior

If you change `scripts/asg_start.sh` or `scripts/user_data.sh`, existing EC2 instances will not automatically rerun old user data.

Use one of these methods:

1. Instance refresh on the Auto Scaling Group
2. Terminate ASG instances manually and let ASG recreate them

## Common Checks After Apply

1. Validate infrastructure:

```bash
terraform -chdir=infra validate
```

2. Check ALB DNS output:

```bash
terraform -chdir=infra output alb_dns_name
```

3. Confirm scaling alarms in AWS Console:
- `A2-High-CPU-Alarm`
- `A2-Low-CPU-Alarm`

4. Confirm app target health:
- EC2 Console -> Target Groups -> target health

## Git Workflow Notes

You are currently working on branch `nodejs`.

Quick status:

```bash
git status
git branch -vv
```

Check merge ancestry between `nodejs` and `main`:

```bash
git merge-base --is-ancestor nodejs main; echo $?
git merge-base --is-ancestor main nodejs; echo $?
```

Interpretation:
- `0` means true
- `1` means false

## Troubleshooting

1. "No configuration files" error
- You are likely running Terraform from the wrong folder.
- Use `terraform -chdir=infra ...`

2. `file(...)` path errors
- Confirm scripts are still in `scripts/` and certs are in `secrets/`.

3. ALB HTTPS/cert issues
- Verify `secrets/webserver.key` and `secrets/webserver_self.crt` exist and match.

4. App not starting on ASG instances
- Check instance logs:
	- `/var/log/cloud-init-output.log`
	- `/var/log/user-data.log`
- Check PM2 process status on instance (`pm2 status`).
