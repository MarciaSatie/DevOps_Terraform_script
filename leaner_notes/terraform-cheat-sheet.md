# Terraform Cheat Sheet

A quick reference for the most important Terraform commands.

## 1) Setup and Formatting

### Initialize project

```bash
terraform init
```

- Downloads providers and modules.
- Run first in every new Terraform folder.

### Format files

```bash
terraform fmt
terraform fmt -recursive
```

- Formats `.tf` files to standard style.

### Validate syntax and configuration

```bash
terraform validate
```

- Checks for syntax and configuration errors.

## 2) Planning and Applying

### Preview changes

```bash
terraform plan
```

- Shows what Terraform will add/change/destroy.
- Safe to run anytime.

### Save a plan file

```bash
terraform plan -out=tfplan
```

- Creates a reusable plan file.

### Apply changes

```bash
terraform apply
```

- Creates/updates infrastructure.

### Apply a saved plan

```bash
terraform apply tfplan
```

- Applies exactly the actions from the saved plan.

### Auto-approve (no prompt)

```bash
terraform apply -auto-approve
```

- Useful in CI/CD pipelines.

## 3) Destroying Resources

### Destroy everything in current state

```bash
terraform destroy
```

- Deletes managed infrastructure.

### Destroy with auto-approve

```bash
terraform destroy -auto-approve
```

## 4) Variables and Outputs

### Pass a variable directly

```bash
terraform plan -var="region=us-east-1"
```

### Use a variable file

```bash
terraform plan -var-file="dev.tfvars"
```

### Show output values

```bash
terraform output
terraform output instance_ip
```

## 5) State and Inspection

### Show current state summary

```bash
terraform show
```

### List resources in state

```bash
terraform state list
```

### Show one resource in state

```bash
terraform state show module.my_compute.aws_instance.web_server
```

### Refresh state from real infrastructure

```bash
terraform refresh
```

- Re-reads real cloud resources into state.

## 6) Targeted and Recovery Commands

### Replace one resource on next apply

```bash
terraform apply -replace=module.my_compute.aws_instance.web_server
```

- Useful when resource attributes only apply at creation time (like some public IP cases).

### Target specific resource/module (use carefully)

```bash
terraform plan -target=module.my_compute
terraform apply -target=module.my_compute
```

- Helpful for debugging, but avoid as normal workflow.

## 7) Useful Debug and Utility Commands

### Open Terraform console

```bash
terraform console
```

- Test expressions and inspect data quickly.

### Show provider versions in use

```bash
terraform providers
```

### Get Terraform version

```bash
terraform version
```

## 8) Typical Workflow

```bash
terraform init
terraform fmt -recursive
terraform validate
terraform plan
terraform apply
terraform output
```

## 9) Good Practices

- Always run `terraform plan` before `terraform apply`.
- Commit `.tf` files, but do not commit secrets.
- Use modules to keep networking/compute separated.
- Use outputs for values you need after apply (for example, instance IP).
- Prefer `-replace` over manual state hacks when recreating one resource.
