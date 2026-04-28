# Terraform Exam Quick Revision

Minimal, high-impact Terraform commands for fast review.

## Core 8 Commands

```bash
terraform init
terraform fmt -recursive
terraform validate
terraform plan
terraform apply
terraform output
terraform state list
terraform destroy
```

## What Each Command Is For

- `terraform init`: Prepare the project (providers/modules).
- `terraform fmt -recursive`: Format all `.tf` files.
- `terraform validate`: Check syntax and config validity.
- `terraform plan`: Preview changes before applying.
- `terraform apply`: Create or update infrastructure.
- `terraform output`: Read exported values (for example, instance IP).
- `terraform state list`: See what Terraform currently manages.
- `terraform destroy`: Remove all managed resources.

## High-Value Extras (Frequently Asked)

```bash
terraform plan -out=tfplan
terraform apply tfplan
terraform apply -replace=module.my_compute.aws_instance.web_server
terraform show
terraform console
terraform version
```

- `-out=tfplan` + `apply tfplan`: Apply exactly what was reviewed.
- `-replace=...`: Force recreate one resource (useful for public IP assignment issues).

## 30-Second Workflow

```bash
terraform init
terraform fmt -recursive
terraform validate
terraform plan
terraform apply
terraform output
```

## Common Exam Pitfalls

- Applying without checking `terraform plan` first.
- Forgetting `terraform init` in a new folder.
- Expecting outputs to exist if resources were not changed/recreated.
- Confusing `terraform show` (state details) with `terraform output` (declared outputs only).
