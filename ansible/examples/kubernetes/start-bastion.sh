
#!/bin/bash
aws ec2 run-instances --image-id ami-01a6e31ac994bbc09 --count 1 --instance-type t2.micro  --key-name aws-key --security-group-ids  sg-04478606325c4fc53 --user-data file://user_data.sh --tag-specifications 'ResourceType=instance,Tags=[{Key=Name,Value=Bastion}]'