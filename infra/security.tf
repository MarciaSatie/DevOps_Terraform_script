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

  ingress {
    from_port   = 443
    to_port     = 443
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
  name        = "A2-httpssh-security-group"
  description = "Allow HTTP from ALB and SSH for administration"
  vpc_id      = aws_vpc.main_vpc.id

  //These are incoming rules. We are opening "Port 80" (the standard port for websites) to "0.0.0.0/0" (everyone on the internet)
  // is the standard "open door" for HTTP web traffic. (we are using port 3000 now, so this not necessary anymore)
  # ingress {
  #   from_port       = 80
  #   to_port         = 80
  #   protocol        = "tcp"
  #   security_groups = [aws_security_group.alb_sg.id]
  # }
  # SSH PORT
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  # node JS Port:3000
  ingress {
    from_port       = 3000
    to_port         = 3000
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

# The Database Security Group
resource "aws_security_group" "db_sg" {
  name        = "A2-db-sg"
  description = "Allow inbound traffic from Web Servers"
  vpc_id      = aws_vpc.main_vpc.id

  ingress {
    description = "MongoDB from Web Tier"
    from_port   = 27017
    to_port     = 27017
    protocol    = "tcp"
    # THIS IS THE KEY LINE:
    security_groups = [aws_security_group.web_sg.id]
  }
  # this is to allow to install MongoDB manually (SSH)
  # Disabled, so we have to use bastion to connect to SSH
  # ingress {
  #   from_port   = 22
  #   to_port     = 22
  #   protocol    = "tcp"
  #   cidr_blocks = ["0.0.0.0/0"]
  # }

  # allow the database to "talk back" to the world (to download updates, for example).
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# This "calls" a website to find your current public IP automatically
data "http" "my_public_ip" {
  url = "https://ipv4.icanhazip.com"
}

# Bastion
# This starts a new Security Group specific for the "Bridge" (Bastion)
resource "aws_security_group" "bastion_sg" {
  name        = "A2-bastion-sg"
  description = "Allow SSH from my dynamic IP"
  vpc_id      = aws_vpc.main_vpc.id

  ingress {
    from_port = 22
    to_port   = 22
    protocol  = "tcp"
    # This allows any IP from 80.233.0.0 to 80.233.255.255
    cidr_blocks = ["80.233.0.0/16"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# Allow Bastion to SSH into DB Server
# This is the "Master Key" rule to fix the connection
resource "aws_security_group_rule" "fix_db_access" {
  type      = "ingress"
  from_port = 22
  to_port   = 22
  protocol  = "tcp"
  # This allows the WHOLE VPC to talk to the DB via SSH
  #he Security Group IDs can get "stale" or mismatched. By using the VPC CIDR (10.0.0.0/16), 
  #AWS allows any connection (VPC) from inside."
  cidr_blocks       = ["10.0.0.0/16"]
  security_group_id = aws_security_group.db_sg.id
}
#
