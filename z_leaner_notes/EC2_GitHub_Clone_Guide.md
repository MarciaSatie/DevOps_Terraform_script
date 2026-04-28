# Clone a GitHub Repository on AWS EC2 (`t2.nano`)

This guide shows a simple and reliable way to clone and run a Node.js project on an EC2 `t2.nano` instance.

## 1. Connect to EC2

From your local terminal:

```bash
ssh -i /path/to/your-key.pem ec2-user@<EC2_PUBLIC_IP>
```

## 2. Install required tools

```bash
sudo yum update -y
sudo yum install -y git
curl -fsSL https://rpm.nodesource.com/setup_20.x | sudo bash -
sudo yum install -y nodejs
```

Check versions:

```bash
git --version
node -v
npm -v
```

## 3. Clone the GitHub repository

```bash
cd /home/ec2-user
git clone https://github.com/<owner>/<repo>.git
cd <repo>
```

Example:

```bash
git clone https://github.com/MarciaSatie/museum_app.git
cd museum_app
```

## 4. Install project dependencies

```bash
npm install --omit=dev
```

## 5. Create environment file (`.env`)

Create required variables for your app:

```bash
cat > .env <<'EOF'
PORT=3000
NODE_ENV=production
cookie_name=app_museum_cookie
cookie_password=replace_with_long_secret
JWT_SECRET=replace_with_long_secret
MONGO_URL=mongodb://<DB_PRIVATE_IP>:27017/museum
EOF
```

## 6. Start the app (quick way)

```bash
npm run dev
```

Or if no `dev` script exists:

```bash
node src/server.js
```

## 7. Start the app with PM2 (recommended)

```bash
sudo npm install -g pm2
pm2 start src/server.js --name app
pm2 save
pm2 startup
```

Run the `sudo ...` command shown by `pm2 startup`, then run:

```bash
pm2 save
```

## 8. Verify app is running

On the EC2 instance:

```bash
pm2 status
curl -I http://127.0.0.1:3000
```

From your browser:

- `http://<EC2_PUBLIC_IP>:3000`

## 9. Security Group rules

In AWS EC2 Security Group, allow inbound traffic to your app port:

- Type: Custom TCP
- Port: `3000`
- Source: your IP (recommended) or `0.0.0.0/0` (temporary for testing)

## 10. Update repository later

```bash
cd /home/ec2-user/<repo>
git pull origin main
npm install --omit=dev
pm2 restart app
```

## Notes for `t2.nano`

- `t2.nano` has very low memory.
- If installation fails due to memory, add a 1 GB swap file:

```bash
sudo fallocate -l 1G /swapfile || sudo dd if=/dev/zero of=/swapfile bs=1M count=1024
sudo chmod 600 /swapfile
sudo mkswap /swapfile
sudo swapon /swapfile
echo '/swapfile swap swap defaults 0 0' | sudo tee -a /etc/fstab
```
