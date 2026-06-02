// This file prints messages to the Console


# AWS will generate a long, random URL for your Load Balancer (like my-alb-12345.us-east-1.elb.amazonaws.com). 
# Instead of hunting through the AWS Console to find it, we can tell Terraform to print it right in your terminal.
/*
  - output: This tells Terraform to share a piece of information after a successful run.
  - "alb_dns_name": This is just the label you will see in your terminal.
  - value = aws_lb.main_alb.dns_name: This pulls the actual web address from the Load Balancer we created in alb.tf.
*/

output "db_private_ip" {
  description = "Private IP of the MongoDB database server"
  value       = aws_instance.db_server.private_ip
}

# to see my IP to be added to Bastion Security Group.
output "detected_public_ip" {
  value = chomp(data.http.my_public_ip.response_body)
}

output "alb_dns_name" {
  description = "The URL of the website"
  value       = "https://${aws_lb.main_alb.dns_name}"
}

output "bastion_public_ip" {
  description = "The Public IP to use for your SSH Jump"
  value       = aws_instance.bastion.public_ip
}

output "database_private_ip" {
  description = "The internal IP of the DB (connect via Bastion)"
  value       = aws_instance.db_server.private_ip
}

output "detected_home_ip" {
  description = "The IP Terraform detected for your security group"
  value       = chomp(data.http.my_public_ip.response_body)
}
