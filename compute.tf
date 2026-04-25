/* This is a Launch Template: 
  - This is the "blueprint" that tells the Auto Scaling Group exactly how to build each web server instance.
  - Instead of launching one instance at a time, we define a template. It stores the AMI ID (your master image).
  - The Instance Type (t2.nano/nano), and the Security Group. It also attaches that IAM Role we just found so your custom scripts can talk to CloudWatch.

  -EC2 and ASG
*/

// ------ Variables -------------------------------------------------
variable "web_server_ami" {
  description = "AMI ID for web server instances"
  type        = string
  default     = "ami-0c101f26f147fa7fd"
}

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t2.nano"
}

variable "iam_profile_name" {
  description = "LabInstanceProfile: IAM instance profile provided for this assigment."
  type        = string
  default     = "LabInstanceProfile"
}
// ------ EC2 -------------------------------------------------

// Create EC2 Instance
# this specific resource block aws_instance is what tells AWS to create a virtual server (EC2).
resource "aws_instance" "web_server" {
  ami                         = var.web_server_ami
  instance_type               = var.instance_type
  subnet_id                   = aws_subnet.public_1.id
  vpc_security_group_ids      = [aws_security_group.web_sg.id]
  associate_public_ip_address = true

  # use a "User Data" script to automatically install Apache (httpd) the moment the server starts.
  # This script runs on startup
  user_data = file("${path.module}/user_data.sh")

  tags = { Name = "A2-Dev-Master-Instace" }

  iam_instance_profile = var.iam_profile_name
}

# 1. The Sleep Resource
resource "time_sleep" "wait_for_node_install" { # Changed the name here
  depends_on      = [aws_instance.web_server]
  create_duration = "90s"
}

# 2. The AMI Resource
resource "aws_ami_from_instance" "web_server_custom_ami" {
  name                    = "A2-web-master-ami-${formatdate("YYYYMMDD-hhmmss", timestamp())}"
  source_instance_id      = aws_instance.web_server.id
  snapshot_without_reboot = true

  # Now this matches the name above!
  depends_on = [time_sleep.wait_for_node_install]
}
// ------ AMI -------------------------------------------------
# AMI: Launch template for future reuse of this instance setup
resource "aws_launch_template" "web_jt" {
  name_prefix   = "A2-web-template"
  image_id      = aws_ami_from_instance.web_server_custom_ami.id
  instance_type = var.instance_type
  user_data     = filebase64("${path.module}/asg_start.sh")

  key_name = "devops02"

  network_interfaces {
    associate_public_ip_address = true
    security_groups             = [aws_security_group.web_sg.id]
  }

  iam_instance_profile {
    name = var.iam_profile_name
  }

  tag_specifications {
    resource_type = "instance"
    tags = {
      Name = "A2-Auto-Scale-instance"
    }
  }
}

// ------ Auto Scaling Group (ASG) ---------------------------------------
# The ASG is the "Manager." It uses the Launch Template (the blueprint) to hire "workers" (EC2 instances). 
# It ensures that if an instance crashes, a new one is born, and it places them across your two subnets for safety.
resource "aws_autoscaling_group" "web_asg" {
  name                      = "A2-Web-ASG"
  desired_capacity          = 2 // This tells AWS to start with 2 servers immediately.
  max_size                  = 4 // The absolute limit of servers we will pay for, even if traffic is huge.
  min_size                  = 1
  health_check_type         = "ELB"
  health_check_grace_period = 300
  vpc_zone_identifier       = [aws_subnet.public_1.id, aws_subnet.public_2.id] // This tells the ASG which "neighborhoods" (subnets) it's allowed to build in.
  target_group_arns         = [aws_lb_target_group.web_tg.arn]                 // This "plugs" your new servers into the Load Balancer's waiting room automatically.

  launch_template {
    id      = aws_launch_template.web_jt.id
    version = "$Latest"
  }
}

# A scaling policy is the instruction set for the ASG. 
# It doesn't run all the time; it waits for a "trigger" (like high CPU) to know when to add or remove a server.
resource "aws_autoscaling_policy" "scale_up" {
  name                   = "A2-Scale-Up-Policy"
  scaling_adjustment     = 1 // Add exactly one server when this is triggered.
  adjustment_type        = "ChangeInCapacity"
  cooldown               = 300 // Wait 5 minutes (300 seconds) before scaling again.
  autoscaling_group_name = aws_autoscaling_group.web_asg.name
}

resource "aws_autoscaling_policy" "scale_down" {
  name                   = "A2-Scale-Down-Policy"
  scaling_adjustment     = -1 // Remove exactly one server when this is triggered.
  adjustment_type        = "ChangeInCapacity"
  cooldown               = 300
  autoscaling_group_name = aws_autoscaling_group.web_asg.name
}

# ------ The Database Instance-------------------------------------
resource "aws_instance" "db_server" {
  ami                    = var.web_server_ami
  instance_type          = "t2.nano"
  subnet_id              = aws_subnet.public_1.id
  vpc_security_group_ids = [aws_security_group.db_sg.id]

  key_name = "devops02"

  user_data = file("${path.module}/db_install.sh")

  tags = { Name = "A2-Database-Server" }
}
# Database Add the AMI Resource
resource "aws_ami_from_instance" "db_custom_ami" {
  name               = "A2-database-master-ami-${formatdate("YYYYMMDD-hhmmss", timestamp())}"
  source_instance_id = aws_instance.db_server.id

  # This tells Terraform: "Don't take the picture until the server is actually ready"
  depends_on = [aws_instance.db_server]
}
