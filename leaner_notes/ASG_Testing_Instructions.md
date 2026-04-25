# Guide: Testing AWS Auto Scaling & Load Balancing

This guide provides step-by-step instructions for testing the resilience, distribution, and dynamic scaling of your infrastructure as required for Assignment 2.

---

## Test 1: Resilience & Self-Healing (The "Chaos" Test)
**Objective**: Prove that the Auto Scaling Group (ASG) maintains the "Desired Capacity" even if an instance fails.

1.  **Open AWS Console**: Navigate to **EC2** > **Instances**.
2.  **Identify a Target**: Pick one of your two running `t2.nano` instances named `A2-Web-Server`.
3.  **Terminate**: Select the instance, click **Instance State** > **Terminate Instance**.
4.  **Monitor the ASG**:
    - Go to **Auto Scaling Groups** > **Activity** tab.
    - You will see a status: *"Terminating instance..."* followed shortly by *"Launching a new EC2 instance"*.
5.  **Success Criteria**: Within 2-3 minutes, you should again see **two** running instances in your console.

---

## Test 2: Traffic Distribution (Step 6 of Assignment)
**Objective**: Demonstrate that the Application Load Balancer (ALB) is distributing requests across multiple servers.

1.  **Open Terminal**: Use your Linux Mint terminal.
2.  **Run the Curl Loop**:
    ```bash
    while true; do curl -s http://YOUR-ALB-DNS-NAME | grep "Instance ID"; sleep 0.5; done
    ```
    *(Note: Replace `YOUR-ALB-DNS-NAME` with the output from your Terraform run).*
3.  **Observe**: Watch the output.
4.  **Success Criteria**: You should see the Instance IDs alternating (e.g., `i-0abc...` then `i-0xyz...`). Take a screenshot of this for your report.

---

## Test 3: Dynamic Scaling (The "Stress" Test)
**Objective**: Trigger the CloudWatch Alarm (CPU > 70%) to force the ASG to scale up to a 3rd instance.

1.  **SSH into your Instance**:
    ```bash
    ssh -i "your-key.pem" ec2-user@YOUR-INSTANCE-PUBLIC-IP
    ```
2.  **Install Stress Tool**:
    ```bash
    sudo amazon-linux-extras install epel -y
    sudo yum install stress -y
    ```
3.  **Initiate High Load**:
    ```bash
    # This runs 1 CPU worker for 300 seconds (5 minutes)
    stress --cpu 1 --timeout 300
    ```
4.  **Watch CloudWatch**:
    - Go to **CloudWatch** > **Alarms**.
    - Watch the `A2-High-CPU-Alarm`. It will move from "OK" to **"In Alarm"**.
5.  **Check ASG Response**:
    - Go to **Auto Scaling Groups** > **Details**.
    - You will see the "Desired Capacity" change from **2 to 3**.
6.  **Success Criteria**: A third instance is automatically launched to help with the load.

---

## Test 4: Custom Metrics Verification (Step 7)
**Objective**: Ensure your `user_data.sh` script is successfully pushing data.

1.  **Open CloudWatch**: Navigate to **Metrics** > **All metrics**.
2.  **Locate Namespace**: Look for the custom namespace labeled **"Custom"**.
3.  **Graph Data**: Select `memory-usage` or `Tcp_connections`.
4.  **Success Criteria**: You see a line graph showing data points being recorded every minute.

---

## Summary for the Report
- **Self-Healing**: Shows high availability.
- **ALB Distribution**: Shows Step 6 compliance.
- **Stress Test**: Justifies your Choice of Metric (CPU Utilization) and proves the Scaling Policy works.
- **Custom Metrics**: Demonstrates OS-level monitoring capability.
