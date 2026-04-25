#!/bin/bash
# This runs INSIDE the AWS EC2 instance, not on your laptop
sudo yum install -y httpd sysstat net-tools

# 1. Start the web server
sudo systemctl start httpd
sudo systemctl enable httpd

# 1b. Write the web page content served by Apache
cat << 'EOF' > /var/www/html/index.html
<h1>DevOps Assignment 2</h1>
EOF

# 2. Create the metrics script file on the instance
cat << 'EOF' > /home/ec2-user/metrics.sh
#!/bin/bash
TOKEN=$(curl -s -X PUT "http://169.254.169.254/latest/api/token" -H "X-aws-ec2-metadata-token-ttl-seconds: 21600")
INSTANCE_ID=$(curl -s -H "X-aws-ec2-metadata-token: $TOKEN" http://169.254.169.254/latest/meta-data/instance-id)
REGION=$(curl -s -H "X-aws-ec2-metadata-token: $TOKEN" http://169.254.169.254/latest/dynamic/instance-identity/document | awk -F'"' '/region/{print $4}')

USEDMEMORY=$(free -m | awk 'NR==2{printf "%.2f\t", $3*100/$2 }')
TCP_CONN=$(netstat -an | wc -l)
TCP_CONN_PORT_80=$(netstat -an | grep 80 | wc -l)
IO_WAIT=$(iostat | awk 'NR==4 {print $5}')

aws cloudwatch put-metric-data --metric-name memory-usage --dimensions Instance="$INSTANCE_ID" --namespace "Custom" --value "$USEDMEMORY" --region "$REGION"
aws cloudwatch put-metric-data --metric-name Tcp_connections --dimensions Instance="$INSTANCE_ID" --namespace "Custom" --value "$TCP_CONN" --region "$REGION"
aws cloudwatch put-metric-data --metric-name TCP_connection_on_port_80 --dimensions Instance="$INSTANCE_ID" --namespace "Custom" --value "$TCP_CONN_PORT_80" --region "$REGION"
aws cloudwatch put-metric-data --metric-name IO_WAIT --dimensions Instance="$INSTANCE_ID" --namespace "Custom" --value "$IO_WAIT" --region "$REGION"
EOF

# 3. Make the script executable
chmod +x /home/ec2-user/metrics.sh

# 4. Set up the Cron Job to run every minute
(crontab -l 2>/dev/null; echo "* * * * * /home/ec2-user/metrics.sh") | crontab -