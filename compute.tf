/* This is a Launch Template: 
  - This is the "blueprint" that tells the Auto Scaling Group exactly how to build each web server instance.
  - Instead of launching one instance at a time, we define a template. It stores the AMI ID (your master image).
  - The Instance Type (t2.nano/nano), and the Security Group. It also attaches that IAM Role we just found so your custom scripts can talk to CloudWatch.

  -EC2 and ASG
*/
// ------ EC2 -------------------------------------------------

// Create EC2 Instance
# this specific resource block aws_instance is what tells AWS to create a virtual server (EC2).
resource "aws_instance" "web_server" {
  ami                         = "ami-0c101f26f147fa7fd"
  instance_type               = "t2.nano"
  subnet_id                   = aws_subnet.public_1.id
  vpc_security_group_ids      = [aws_security_group.web_sg.id]
  associate_public_ip_address = true

  # use a "User Data" script to automatically install Apache (httpd) the moment the server starts.
  # This script runs on startup
  user_data = file("${path.module}/user_data.sh")

  tags = { Name = "A2-DevOps-Web-Server" }
}
# AMI: Launch template for future reuse of this instance setup
resource "aws_launch_template" "web_jt" {
  name_prefix   = "A2-web-template"
  image_id      = "ami-0c101f26f147fa7fd"
  instance_type = "t2.nano"
  user_data     = filebase64("${path.module}/user_data.sh")

  network_interfaces {
    associate_public_ip_address = true
    security_groups             = [aws_security_group.web_sg.id]
  }

  iam_instance_profile {
    name = data.aws_iam_instance_profile.lab_profile.name
  }

  tag_specifications {
    resource_type = "instance"
    tags = {
      Name = "A2-Web-Server"
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

// -------- Cloudwatch ----------------------------------------------------
# The High-CPU Alarm (The "Trigger")
#We have the "Action" (Scale Up), but we need the "Brain" to decide when to do it. 
# We will use a CloudWatch Alarm to watch the average CPU usage of your servers. 
# If it goes too high (e.g., above 70%), it "pulls the trigger" on the Scale-Up policy.
resource "aws_cloudwatch_metric_alarm" "high_cpu" {
  alarm_name          = "A2-High-CPU-Alarm"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = "120"
  statistic           = "Average"
  threshold           = "70"

  dimensions = {
    AutoScalingGroupName = aws_autoscaling_group.web_asg.name
  }

  alarm_actions = [aws_autoscaling_policy.scale_up.arn]
}

// The Low-CPU Alarm (The "Cool Down")
# This "Low-CPU" alarm watches for when your servers are bored (e.g., below 30% CPU). 
# When that happens, it triggers the scale_down policy to remove a server.
resource "aws_cloudwatch_metric_alarm" "low_cpu" {
  alarm_name          = "A2-Low-CPU-Alarm"
  comparison_operator = "LessThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = "120"
  statistic           = "Average"
  threshold           = "30"

  dimensions = {
    AutoScalingGroupName = aws_autoscaling_group.web_asg.name
  }

  alarm_actions = [aws_autoscaling_policy.scale_down.arn]
}
