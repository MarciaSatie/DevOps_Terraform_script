# Assignment Requirement Status

- Note: No PDF files were found in this workspace, so this status is based on current Terraform files and notes in `leaner_notes/`.

## Completed

- AWS provider configured for `us-east-1`.
- VPC created (`10.0.0.0/16`) with DNS support and DNS hostnames enabled.
- Internet Gateway created and attached to the VPC.
- Subnets created:
- One private subnet in `us-east-1a`.
- Two public subnets in `us-east-1a` and `us-east-1b`.
- Public route table created with default route (`0.0.0.0/0`) to IGW.
- Public route table associated with both public subnets.
- ALB security group resource created.
- Existing IAM instance profile data source added (`LabInstanceProfile`).
- Terraform configuration validates successfully in this workspace.

## Missing (Likely if full assignment includes compute + load balancing)

- EC2/web server resource definition is not present.
- User data/bootstrap for web server is not present.
- Application Load Balancer (`aws_lb`) resource is not present.
- Target group and listener resources are not present.
- Auto Scaling Group and Launch Template are not present.
- Security group for EC2/web tier is not present.
- Separate SG rule to allow traffic from ALB SG to web SG on port 80 is not present.
- Outputs (for example ALB DNS name, instance public IP) are not present.
- Root module wiring and module folders (`modules/network`, `modules/compute`) are not present in this workspace.

## Needs Review / Potential Issue

- The ALB security group ingress currently references itself (`security_groups = [aws_security_group.alb_sg.id]`).
- If this SG is for internet-facing ALB, ingress is usually `cidr_blocks = ["0.0.0.0/0"]` on port 80/443.
- If this is intended to be a web-server SG, it should be a separate SG and allow source from ALB SG instead.

## Evidence checked

- `provider.tf`
- `vpc.tf`
- `leaner_notes/module-data-flow-network-compute.md`
- `leaner_notes/terraform-cheat-sheet-quick.md`
- `leaner_notes/terraform-cheat-sheet.md`
- `leaner_notes/troubleshooting-user-data.md`
