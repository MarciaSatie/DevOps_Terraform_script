
// ------ ALB Target Group -------------------------------------------------
// Application Load Balancer (ALB)
resource "aws_lb" "main_alb" {
  name               = "A2-WebApp-ALB"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb_sg.id]
  subnets            = [aws_subnet.public_1.id, aws_subnet.public_2.id]

  tags = {
    Name = "A2-App-Load-Balancer"
  }
}

# 1. The Destination (Target Group)
resource "aws_lb_target_group" "web_tg" {
  name        = "A2-Web-TargetGroup"
  port        = 80
  protocol    = "HTTP"
  vpc_id      = aws_vpc.main_vpc.id
  target_type = "instance"

  health_check {
    protocol            = "HTTP"
    path                = "/"
    matcher             = "200"
    interval            = 30
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 2
  }
}
// The ALB Listener
# Load Balancer (the "Bouncer") and the Target Group (the "Waiting Room").
# The Listener is the "Ear" of the Load Balancer. It listens for people calling Port 80 and tells them: "Go to the Target Group!"
resource "aws_lb_listener" "front_end" {
  load_balancer_arn = aws_lb.main_alb.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.web_tg.arn
  }
}
