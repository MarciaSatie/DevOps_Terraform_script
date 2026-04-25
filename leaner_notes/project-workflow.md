# Terraform Project Workflow

This document explains how the Terraform files in this project work together, what each file is responsible for, and how the EC2 startup script fits into the deployment flow.

## 1. Big Picture

This project builds a small web application stack on AWS using Terraform.

The stack is made of:

- A VPC with public and private networking
- Security groups for the Application Load Balancer and EC2 instances
- An Application Load Balancer (ALB)
- An EC2 instance and an Auto Scaling Group pattern
- CloudWatch alarms and scaling policies
- A startup script that configures Apache and sends custom metrics

Terraform reads the `.tf` files, builds a dependency graph, and creates resources in the correct order. Most files do not run independently. Instead, they reference values from other files, which is how Terraform connects the whole infrastructure.

## 2. File Roles

### provider.tf

This file defines the Terraform provider and AWS region.

- `terraform { required_providers { ... } }` tells Terraform which provider plugin to download and use.
- `provider "aws" { region = "us-east-1" }` tells Terraform where to create the infrastructure.

Without this file, Terraform would not know which cloud provider to talk to or which region to use.

### vpc.tf

This file creates the network foundation.

It defines:

- `aws_vpc.main_vpc` for the main private network
- `aws_internet_gateway.igw` so the VPC can reach the internet
- `aws_subnet.public_1` and `aws_subnet.public_2` for public instances and the ALB
- `aws_subnet.private_1` for private networking
- `aws_route_table.public_rt` for internet routing
- `aws_route_table_association` resources to connect the public subnets to the route table

This is the base layer for the rest of the project because the ALB, EC2 instances, and security groups all reference the VPC and subnets created here.

### security.tf

This file controls network access.

It defines:

- `aws_security_group.alb_sg` for the load balancer
- `aws_security_group.web_sg` for the EC2 instances
- `data "aws_iam_instance_profile" "lab_profile"` to read an existing IAM instance profile

The security groups work together like this:

- `alb_sg` allows inbound HTTP traffic from the internet
- `web_sg` allows inbound HTTP traffic only from the ALB security group

That means users can reach the ALB, but they cannot directly reach the web server except through the load balancer.

The `data` block is important because it does not create anything. It reads an existing AWS resource called `LabInstanceProfile` and makes it available to other Terraform resources.

### alb.tf

This file creates the application delivery layer.

It defines:

- `aws_lb.main_alb` as the Application Load Balancer
- `aws_lb_target_group.web_tg` as the target group that receives traffic
- `aws_lb_listener.front_end` as the listener on port 80

The ALB listens on HTTP port 80 and forwards requests to the target group. The target group then routes traffic to EC2 instances.

The health check inside the target group probes `/` over HTTP and expects status `200`. This is how the ALB decides whether a target is healthy.

### compute.tf

This file contains the compute layer and scaling logic.

It defines:

- Variables for the AMI and instance type
- `aws_instance.web_server` for a single EC2 instance
- `aws_launch_template.web_jt` for reusable instance settings
- `aws_autoscaling_group.web_asg` for scaling EC2 instances
- `aws_autoscaling_policy.scale_up` and `scale_down`
- `aws_cloudwatch_metric_alarm.high_cpu` and `low_cpu`

This is the most connected file in the project because it links the network, security, startup script, ALB, and CloudWatch pieces together.

### outputs.tf

This file prints useful values after deployment.

It currently exposes:

- `alb_dns_name`, which shows the public DNS name of the load balancer

This is useful because you can open the load balancer URL directly after `terraform apply`.

### user_data.sh

This file runs inside the EC2 instance when it boots.

Terraform passes this script into the EC2 instance through the `user_data` setting in `compute.tf`.

The script does the following:

- Installs Apache and monitoring tools
- Starts and enables the Apache service
- Writes a simple HTML page to `/var/www/html/index.html`
- Creates a custom metrics script at `/home/ec2-user/metrics.sh`
- Adds a cron job to run the metrics script every minute

This is what turns a plain EC2 instance into a web server with metrics reporting.

## 3. How the Files Depend on Each Other

The project works because Terraform builds references between files.

### Network dependencies

- `alb.tf` and `compute.tf` both reference `aws_vpc.main_vpc` from `vpc.tf`
- `aws_subnet.public_1` and `aws_subnet.public_2` from `vpc.tf` are used by the ALB and EC2 resources
- `security.tf` attaches security groups to the same VPC

### Security dependencies

- `alb_sg` is attached to the ALB in `alb.tf`
- `web_sg` is attached to the EC2 instance and launch template in `compute.tf`
- `web_sg` allows traffic from `alb_sg`, which means only the ALB can reach the web server on port 80

### Compute dependencies

- `compute.tf` uses the AMI and instance type values
- `aws_instance.web_server` uses `user_data = file("${path.module}/user_data.sh")` to load the shell script as plain text
- `aws_launch_template.web_jt` uses `user_data = filebase64("${path.module}/user_data.sh")` because launch templates expect base64 encoded user data
- The launch template uses the same AMI, instance type, and IAM instance profile as the instance resource

### ALB and ASG dependencies

- The Auto Scaling Group in `compute.tf` sends instances to `aws_lb_target_group.web_tg` from `alb.tf`
- The launch template creates EC2 instances that match what the ALB expects
- The ALB listener forwards traffic to the target group, and the target group forwards traffic to the instances

### Monitoring dependencies

- The CloudWatch alarms in `compute.tf` watch CPU usage on the Auto Scaling Group
- The alarms trigger the scaling policies
- The scaling policies increase or decrease the number of EC2 instances in the Auto Scaling Group

## 4. Execution Flow

Terraform processes this project in a dependency order.

### Step 1: Provider setup

Terraform loads `provider.tf` first so it knows the AWS account and region.

### Step 2: Network creation

Terraform creates the VPC, subnets, route table, internet gateway, and route associations from `vpc.tf`.

### Step 3: Security setup

Terraform creates the security groups and reads the existing IAM instance profile from `security.tf`.

### Step 4: Load balancer setup

Terraform creates the ALB, target group, and listener from `alb.tf`.

### Step 5: Compute setup

Terraform creates the EC2 instance, launch template, Auto Scaling Group, scaling policies, and alarms from `compute.tf`.

### Step 6: Instance startup

When an EC2 instance launches, AWS runs `user_data.sh` automatically.

That script installs Apache, writes the web page, and sets up the custom metrics collection loop.

### Step 7: Output values

Terraform prints the ALB DNS name from `outputs.tf` so you can test the deployment in a browser.

## 5. Terraform Methods and Functions Used Here

### `data`

Used to read existing infrastructure instead of creating new infrastructure.

Example:

- `data "aws_iam_instance_profile" "lab_profile"` reads an existing IAM profile named `LabInstanceProfile`

### `resource`

Used to create AWS resources.

Examples:

- `aws_vpc`
- `aws_subnet`
- `aws_security_group`
- `aws_lb`
- `aws_instance`
- `aws_autoscaling_group`

### `output`

Used to print useful values after `terraform apply`.

Example:

- `output "alb_dns_name"`

### `file()`

Reads a local file as plain text.

Used for EC2 user data:

- `user_data = file("${path.module}/user_data.sh")`

### `filebase64()`

Reads a local file and encodes it in base64.

Used for launch template user data:

- `user_data = filebase64("${path.module}/user_data.sh")`

### `var.*`

Reads Terraform input variables.

Used in `compute.tf` for:

- `var.web_server_ami`
- `var.instance_type`

This makes the AMI and instance type reusable instead of hardcoded in multiple places.

### Resource references

Terraform uses resource addresses to connect objects together.

Examples:

- `aws_vpc.main_vpc.id`
- `aws_subnet.public_1.id`
- `aws_security_group.web_sg.id`
- `aws_lb_target_group.web_tg.arn`

These references are what create the dependency graph. Terraform knows it must build the referenced resource before the resource that uses it.

## 6. Why the AMI and Launch Template Are Linked

The AMI ID is the base image for the server.

In `compute.tf`, both these resources use the same variable:

- `aws_instance.web_server`
- `aws_launch_template.web_jt`

That means if you change `var.web_server_ami`, both resources will use the updated AMI the next time Terraform plans and applies changes.

This is the correct approach when you want one configuration value to control multiple resources.

## 7. Important Runtime Detail

There are two different ways the startup script is passed to AWS:

- `aws_instance` uses `file()` because the field expects plain text user data
- `aws_launch_template` uses `filebase64()` because launch template user data expects base64 encoded content

This difference matters. Using the wrong function usually causes a broken instance bootstrap or invalid launch template configuration.

## 8. What Happens When You Run Terraform

Typical workflow:

```bash
terraform init
terraform plan
terraform apply
```

- `init` downloads the AWS provider and prepares the working directory
- `plan` shows what Terraform will create or change
- `apply` creates or updates the AWS resources

After a successful apply, Terraform writes the state file locally so it can track what it created.

## 9. Practical Summary

The project is organized in layers:

- `provider.tf` tells Terraform where to work
- `vpc.tf` builds the network
- `security.tf` controls access and reads the IAM profile
- `alb.tf` exposes the application to the internet
- `compute.tf` launches and scales the web servers
- `user_data.sh` configures the instance at boot time
- `outputs.tf` prints the ALB address

The important idea is that Terraform is not just running files in order. It is building a dependency graph from references like `aws_vpc.main_vpc.id`, `var.web_server_ami`, and `filebase64(...)`.

That is what makes the whole stack work as one connected system.
