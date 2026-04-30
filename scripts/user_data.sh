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
const { MongoClient } = require('mongodb');

const MONGO_URL = process.env.MONGO_URL || 'mongodb://127.0.0.1:27017';
const DB_NAME = 'assigment02';
const COLLECTION = 'bootstrap';

const client = new MongoClient(MONGO_URL);
let cachedMessage = null;

async function getDbMessage() {
  if (cachedMessage) return cachedMessage;
  try {
    await client.connect();
    const db = client.db(DB_NAME);
    const doc = await db.collection(COLLECTION).findOne({ _id: 'welcome' });
    cachedMessage = doc && doc.message ? doc.message : 'No message found in DB';
    return cachedMessage;
  } catch (err) {
    return `DB error: ${err.message}`;
  }
}

const server = http.createServer(async (req, res) => {
  const msg = await getDbMessage();
  res.writeHead(200, { 'Content-Type': 'text/plain' });
  res.end(`Server Hostname: ${os.hostname()}\nDB message: ${msg}\n`);
});

server.listen(3000, '0.0.0.0');
EOF

# Install Node deps for the app and start with pm2 as ec2-user
cd /home/ec2-user || exit 0
sudo -u ec2-user npm init -y
sudo -u ec2-user npm install mongodb --no-audit --no-fund
sudo npm install -g pm2
sudo chown -R ec2-user:ec2-user /home/ec2-user
sudo -u ec2-user pm2 start /home/ec2-user/app.js --name assigment02-app || sudo -u ec2-user pm2 start app.js --name assigment02-app
sudo -u ec2-user pm2 save





