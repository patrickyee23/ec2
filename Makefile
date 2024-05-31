apply destroy:
	@sed -i '' '/pyee-ec2/d' ~/.ssh/known_hosts
	@terraform $@ -auto-approve
