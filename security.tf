// ------- Security Groups -----------------------------------
resource "aws_security_group" "alb_sg" {
  name        = "A2-alb-security-group"
  description = "Allow HTTP inbound traffic from internet to ALB"
  vpc_id      = aws_vpc.main_vpc.id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "web_sg" {
  name        = "A2-web-security-group"
  description = "Allow HTTP inbound traffic from ALB"
  vpc_id      = aws_vpc.main_vpc.id

  //These are incoming rules. We are opening "Port 80" (the standard port for websites) to "0.0.0.0/0" (everyone on the internet)
  // is the standard "open door" for HTTP web traffic.
  ingress {
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    security_groups = [aws_security_group.alb_sg.id]
  }
  //These are outgoing rules. Setting the protocol to -1 and port 0 means the Load Balancer is allowed to talk to "anything" on the way out (like our web servers)
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

//data blocks are for reading existing info, while resource blocks are for building new things.
data "aws_iam_instance_profile" "lab_profile" {
  name = "LabInstanceProfile"
}
