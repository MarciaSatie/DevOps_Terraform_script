# Troubleshooting: User Data Not Running

When your EC2 instance's user_data script doesn't execute or Apache doesn't start, use these commands to diagnose the issue.

## Step 1: Get the Instance Public IP

```bash
terraform output instance_ip
```

Save this IP—you'll need it to SSH into the instance.

## Step 2: SSH into the Instance

Replace `YOUR_PUBLIC_IP` with the IP from Step 1. Replace `your-key.pem` with your AWS EC2 key file path.

```bash
ssh -i your-key.pem ec2-user@YOUR_PUBLIC_IP
```

If using Windows or you don't have SSH, use AWS Systems Manager Session Manager from the AWS console instead.

## Step 3: Check if Apache Is Running

```bash
sudo systemctl status httpd
```

Expected output: `active (running)`. If it says `inactive (dead)`, Apache didn't start.

## Step 4: Check the User Data Script Log

```bash
sudo cat /var/log/cloud-init-output.log
```

This shows if the user_data script ran and where it failed. Look for error messages about `yum install -y httpd`.

## Step 5: Manually Start Apache (If It's Stopped)

```bash
sudo systemctl start httpd
```

Then check if port 80 is listening:

```bash
sudo netstat -tlnp | grep :80
```

Or with `ss`:

```bash
sudo ss -tlnp | grep :80
```

## Step 6: Verify the Index.HTML File Exists

```bash
sudo cat /var/www/html/index.html
```

If the file is missing, create it manually:

```bash
sudo bash -c 'echo "<h1>DevOps Assignment: Success!</h1><p>The network and server are working perfectly.</p>" > /var/www/html/index.html'
```

## Step 7: Test Locally on the Instance

```bash
curl -s http://localhost/
```

or

```bash
curl -s http://127.0.0.1/
```

If this returns the HTML, the server works locally.

## Step 8: Test from Your Local Machine

Open a browser and visit:

```
http://YOUR_PUBLIC_IP/
```

Replace `YOUR_PUBLIC_IP` with the value from Step 1.

## Common Issues and Quick Fixes

### Issue: "Permission denied (public key)"

- Your key file path is wrong, or the key file doesn't exist.
- Fix: Use the correct path to your `.pem` file.

### Issue: "Connection timed out"

- The instance doesn't have a public IP, or the security group doesn't allow port 22 (SSH) or port 80 (HTTP).
- Fix: Check terraform output, verify security group allows inbound TCP 22 and 80.

### Issue: Apache status shows "inactive (dead)"

- The user_data script didn't run, or yum install failed.
- Fix: Check `/var/log/cloud-init-output.log` to see the error.

### Issue: user_data script ran but index.html is empty or missing

- The instance ran the script on a previous launch, not the replacement.
- Fix: After replacing the instance and re-applying, destroy and re-create it with `terraform destroy` + `terraform apply`.

## Quick One-Liner to Check Everything

Once you're SSH'd into the instance, run all checks in one command:

```bash
echo "=== Apache Status ===" && sudo systemctl status httpd && echo "=== Port 80 Listening ===" && sudo ss -tlnp | grep :80 && echo "=== Index.html ===" && sudo cat /var/www/html/index.html
```
