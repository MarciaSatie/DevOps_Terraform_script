# Project Architecture Diagram

```mermaid
flowchart LR
  Internet[(Internet)] --> IGW[Internet Gateway]
  IGW --> ALB[Application Load Balancer\nHTTP 80, HTTPS 443]

  subgraph VPC[VPC: A2-Assigment2-VPC (10.0.0.0/16)]
    direction LR

    subgraph AZA[Availability Zone A: us-east-1a]
      direction TB
      PUB1[Public Subnet 1\n10.0.1.0/24]
      PRIV1[Private Subnet\n10.0.10.0/24]
      MASTER[Master EC2\nA2-Dev-Master-Instace]
      APP1[ASG App Instance]
      DB[DB Instance\nA2-Database-Server]
    end

    subgraph AZB[Availability Zone B: us-east-1b]
      direction TB
      PUB2[Public Subnet 2\n10.0.2.0/24]
      APP2[ASG App Instance]
    end

    TG[Target Group\nHTTP :3000]
    ASG[Auto Scaling Group\nA2-Web-ASG]
    LT[Launch Template\naws_launch_template.web_jt]
    AMI[Custom AMI\naws_ami_from_instance]

    ALB --> TG
    TG --> APP1
    TG --> APP2

    ASG --> APP1
    ASG --> APP2
    LT --> ASG
    AMI --> LT
    MASTER -->|CreateImage| AMI

    WEB_SG[Web SG\nAllow 3000 from ALB SG\nAllow 22 from Internet]
    ALB_SG[ALB SG\nAllow 80/443 from Internet]
    DB_SG[DB SG\nAllow 27017 from Web SG\nAllow 22 from Internet]

    ALB_SG -.attached to.-> ALB
    WEB_SG -.attached to.-> MASTER
    WEB_SG -.attached to.-> APP1
    WEB_SG -.attached to.-> APP2
    DB_SG -.attached to.-> DB

    PUB1 --- MASTER
    PUB1 --- APP1
    PUB1 --- DB
    PUB2 --- APP2
    PRIV1 -.currently unused by instances.- MASTER
  end

  CW[CloudWatch Alarms\nCPU high/low] -->|Scale up/down| ASG
```

## How It Works

1. Internet traffic reaches the ALB through the Internet Gateway.
2. ALB listeners route requests to the target group on port 3000.
3. The ASG keeps app instances running across both public subnets (AZ-a and AZ-b).
4. A master EC2 instance is configured and used to create a custom AMI.
5. The launch template uses that custom AMI for ASG instance launches.
6. CloudWatch alarms trigger scale-up and scale-down policies.

## Important Current-State Note

- Your private subnet exists but is not currently hosting instances.
- Your DB instance is currently deployed in Public Subnet 1.
