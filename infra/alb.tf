
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
  port        = 3000
  protocol    = "HTTP"
  vpc_id      = aws_vpc.main_vpc.id
  target_type = "instance"

  health_check {
    protocol            = "HTTP"
    port                = 3000
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
    type = "redirect"
    redirect {
      port        = "443"
      protocol    = "HTTPS"
      status_code = "HTTP_301" # This means "Moved Permanently"
    }
  }
}
# The HTTPS (Port 443) Listener
resource "aws_lb_listener" "https" {
  load_balancer_arn = aws_lb.main_alb.arn
  port              = "443"
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-2016-08"
  certificate_arn   = aws_acm_certificate.self_signed_cert.arn


  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.web_tg.arn
  }
}

# This starts the definition of your certificate in AWS Certificate Manager (ACM)
resource "aws_acm_certificate" "self_signed_cert" {
  # This tells Terraform to read the private key file you generated. The ${path.module} ensures it looks in the same folder as your code.
  private_key = file("${path.module}/../secrets/webserver.key")
  # This uploads the public part of the certificate that browsers will see.
  certificate_body = file("${path.module}/../secrets/webserver_self.crt")

  # This is how you "create" the ACM entry using your own files.
  lifecycle {
    create_before_destroy = true
  }
}


