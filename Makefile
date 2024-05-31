INSTANCE_TYPE?=c7a.2xlarge

apply destroy:
	@sed -i '' '/pyee-ec2/d' ~/.ssh/known_hosts
	@terraform $@ -var=instance_type=$(INSTANCE_TYPE) -auto-approve
