#!/bin/bash
# Export MongoDB URL as environment variable for the app to use
export MONGO_URL="${mongo_url}?tls=false"

# Start the simple Node.js app
node /home/ec2-user/app.js