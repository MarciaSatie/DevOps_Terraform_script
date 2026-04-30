#!/bin/bash
# 1. Add MongoDB Repo
cat <<EOF | sudo tee /etc/yum.repos.d/mongodb-org-7.0.repo
[mongodb-org-7.0]
name=MongoDB Repository
baseurl=https://repo.mongodb.org/yum/amazon/2023/mongodb-org/7.0/x86_64/
gpgcheck=1
enabled=1
gpgkey=https://pgp.mongodb.com/server-7.0.asc
EOF

# 2. Install MongoDB
sudo yum install -y mongodb-org

# 3. Configure to listen to Web Servers
sudo sed -i 's/bindIp: 127.0.0.1/bindIp: 0.0.0.0/' /etc/mongod.conf

# 4. Start and Enable
sudo systemctl start mongod
sudo systemctl enable mongod

# 5. Seed MongoDB with initial information
for attempt in {1..10}; do
	if mongosh --quiet --eval 'db.adminCommand({ ping: 1 })' >/dev/null 2>&1; then
		break
	fi
	sleep 2
done

mongosh --quiet <<'EOF'
const museumDb = db.getSiblingDB('assigment02');
museumDb.bootstrap.updateOne(
	{ _id: 'welcome' },
	{
		$set: {
			message: 'MongoDB was installed and initialized successfully.',
			updatedAt: new Date()
		}
	},
	{ upsert: true }
);
EOF