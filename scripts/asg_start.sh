#!/bin/bash
# Prefer museum_app managed by PM2. Fall back to the simple Node app if needed.
if command -v pm2 >/dev/null 2>&1 && [ -f /home/ec2-user/museum_app/src/server.js ]; then
	sudo -u ec2-user pm2 resurrect || sudo -u ec2-user pm2 start /home/ec2-user/museum_app/src/server.js --name museum-app
else
	node /home/ec2-user/app.js &
fi