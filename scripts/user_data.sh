#!/bin/bash
# This runs INSIDE the AWS EC2 instance, not on your laptop
sudo yum install -y httpd sysstat net-tools cronie git nodejs

# 1. Start the web server
sudo systemctl start httpd
sudo systemctl enable httpd
sudo systemctl enable --now crond

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
(crontab -l 2>/dev/null; echo "* * * * * /home/ec2-user/metrics.sh >> /home/ec2-user/metrics.log 2>&1") | crontab -

# *********************************************************************************
# ------  Node JS (Extra) --------------------------------------

# Write the app file to the home directory
cat << 'EOF' > /home/ec2-user/app.js
const http = require('http');
const os = require('os');
const server = http.createServer((req, res) => {
  res.statusCode = 200;
  res.setHeader('Content-Type', 'text/plain');
  res.end(`Server Hostname: ${os.hostname()}\nNode.js is running from the Custom AMI!\n`);
});
server.listen(3000, '0.0.0.0');
EOF

# Clone and install museum_app as ec2-user
if [ ! -d /home/ec2-user/museum_app ]; then
  sudo -u ec2-user git clone https://github.com/MarciaSatie/museum_app.git /home/ec2-user/museum_app
fi

sudo -u ec2-user bash -lc 'cd /home/ec2-user/museum_app && npm install --omit=dev'
sudo npm install -g pm2

# Create .env if missing. Replace the placeholders for production use.
if [ ! -f /home/ec2-user/museum_app/.env ]; then
cat << 'EOF' > /home/ec2-user/museum_app/.env
PORT=3000
NODE_ENV=production
cookie_name=app_museum_cookie
cookie_password=replace_with_long_secret_min_32_chars
JWT_SECRET=replace_with_long_jwt_secret
MONGO_URL=mongodb://10.0.1.227:27017/museum
EOF
fi

# Start app with PM2. If env values are incomplete, fall back to simple app.js.
sudo -u ec2-user bash -lc 'cd /home/ec2-user/museum_app && pm2 delete museum-app || true && pm2 start src/server.js --name museum-app && pm2 save' || node /home/ec2-user/app.js &

# Ensure startup behavior after reboot.
if ! grep -q "museum-app" /etc/rc.local; then
  echo "sudo -u ec2-user pm2 resurrect || sudo -u ec2-user pm2 start /home/ec2-user/museum_app/src/server.js --name museum-app || node /home/ec2-user/app.js &" >> /etc/rc.local
fi
chmod +x /etc/rc.local

