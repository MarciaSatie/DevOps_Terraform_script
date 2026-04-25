# Terraform Project Documentation: Elastic Web Architecture

This document summarizes the structured 'baby-steps' journey of building a scalable, load-balanced web infrastructure in AWS.

## Project Files Overview
- **provider.tf**: Configures the connection to AWS.
- **vpc.tf**: Defines the virtual network (VPC, Subnets, Gateways).
- **security.tf**: Handles firewall rules (Security Groups) and IAM profile lookups.
- **alb.tf**: Configures the Application Load Balancer and its Target Group.
- **compute.tf**: Defines the Launch Template and Auto Scaling Group (the "workers").
- **outputs.tf**: Displays the final website URL.

---

## 1. Networking Infrastructure (`vpc.tf`)

### The VPC (Virtual Private Cloud)
The VPC is our private "island" in the AWS cloud. It isolates our resources from everyone else.
- **Goal**: Create a secure, isolated network.
- **Concepts**: CIDR blocks (10.0.0.0/16) define our IP range.

### Internet Gateway (IGW)
The IGW acts as the "front door" allowing traffic to enter and leave the VPC.

### Subnets (Public and Private)
- **Public Subnets**: Placed in different Availability Zones (1a and 1b) for high availability. These hold our Load Balancer.
- **Private Subnet**: Intended for resources that shouldn't be directly accessible from the internet.

### Route Tables
These are the "GPS maps" that tell network traffic how to get to the Internet Gateway.

---

## 2. Security & Identity (`security.tf`)

### Load Balancer Security Group (`alb_sg`)
- **Ingress**: Opens Port 80 to the whole world (`0.0.0.0/0`).
- **Egress**: Allows the LB to talk to any destination.

### Web Server Security Group (`web_sg`)
- **Security Constraint**: Only allows incoming traffic on Port 80 if it comes from the Load Balancer's Security Group. This hides our servers from the direct internet.

### IAM Instance Profile (`data` block)
- **Why**: We use a `data` block because the `LabInstanceProfile` already exists in AWS Academy.
- **Purpose**: Gives our EC2 instances permission to send logs and metrics to CloudWatch.

---

## 3. Load Balancing (`alb.tf`)

### Application Load Balancer (ALB)
- **Role**: Receives traffic and distributes it across multiple servers.
- **High Availability**: Lives in two public subnets across different physical data centers.

### Target Group & Health Checks
- **Target Group**: A list of servers ready to receive traffic.
- **Health Check**: Pings the servers every 30 seconds. If a server doesn't respond, the LB stops sending users there.

### Listener
- **Action**: Listens on Port 80 and "forwards" the traffic to the Target Group.

---

## 4. Compute & Auto Scaling (`compute.tf`)

### Launch Template
- **Blueprint**: Contains the AMI ID, instance type (t2.micro), and the IAM profile.
- **User Data**: (In progress) A script that ensures the web server starts automatically on boot.

### Auto Scaling Group (ASG)
- **Desired Capacity (2)**: Always tries to keep 2 servers running.
- **Self-Healing**: If an instance dies, the ASG detects it and launches a replacement.

### Scaling Policies & CloudWatch Alarms
- **High CPU Alarm**: If CPU > 70%, trigger the Scale-Up policy (+1 server).
- **Low CPU Alarm**: If CPU < 30%, trigger the Scale-Down policy (-1 server).
- **Cooldown (300s)**: Prevents the system from adding/removing servers too quickly before the previous change has finished.

---

## 5. Outputs (`outputs.tf`)

### alb_dns_name
- **Utility**: Automatically prints the URL of your website in the terminal so you don't have to look it up in the AWS Console.

---

## Troubleshooting: The 502 Bad Gateway
We left off addressing why the Load Balancer might show a 502 error.
1. **Cause**: The instances are running, but the web service (Apache/Nginx) isn't started or is blocked.
2. **Fix**: Implementing `user_data` in the Launch Template to force-start the service upon launch.
