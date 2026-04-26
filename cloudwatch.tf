
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
