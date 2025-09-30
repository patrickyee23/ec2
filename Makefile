INSTANCE_TYPE?=c8g.2xlarge

apply destroy:
	@sed -i '' '/pyee-ec2/d' ~/.ssh/known_hosts
	@terraform $@ -var=instance_type=$(INSTANCE_TYPE) -auto-approve

instance_id:
	@terraform output -raw instance_id

start stop:
	@aws ec2 $@ --instance-ids `make instance_id`

connect:
	@aws ssm start-session --target `make instance_id`

ssh:
	@ssh pyee-dev
