SHELL := /bin/bash

AWS_PROFILE        := sunrise2023-z
AWS_DEFAULT_REGION := ap-northeast-1

AWS_KEYPAIR_NAME            := sunrise2023
AWS_SSM_KEYPAIR_PRIVATE_KEY := /sunrise2023/keypair/private_key

aws = docker run --rm \
  --env-file <(aws-vault exec $(AWS_PROFILE) -- env | grep "AWS_" | grep -v "AWS_VAULT") \
  -e AWS_DEFAULT_OUTPUT=text -e AWS_PAGER="" \
  -v $(CURDIR)/_files:/work/_files \
  -w /work \
  amazon/aws-cli

# https://hub.docker.com/r/hashicorp/terraform/tags/
TERRAFORM_VERSION := 1.5.3
TFSTATE_BUCKET    := $(AWS_PROFILE)-tfstate

TF_VARS  = TF_VAR_AWS_PROFILE=$(AWS_PROFILE)
TF_VARS += TF_VAR_AWS_DEFAULT_REGION=$(AWS_DEFAULT_REGION)
TF_VARS += TF_VAR_AWS_KEYPAIR_NAME=$(AWS_KEYPAIR_NAME)
TF_VARS += TF_VAR_AWS_SSM_KEYPAIR_PRIVATE_KEY=$(AWS_SSM_KEYPAIR_PRIVATE_KEY)

TO :=

terraform = docker run --rm -it \
  --env-file <(aws-vault exec $(AWS_PROFILE) -- env | grep "AWS_" | grep -v "AWS_VAULT") \
  -e TZ=Asia/Tokyo \
  $(addprefix -e ,$(TF_VARS)) \
  -v $(CURDIR):/app \
  -w /app/$(TO) \
  hashicorp/terraform:$(TERRAFORM_VERSION)

.PHONY: all init plan apply clean setup create_tfstate_backend create_ssh_key setup_rds change_hakaru_rds_root_password

all:
	@more Makefile

.credential.tfvars: .credential.tfvars.skelton
	$(error Please kindly run the command: `cp $< $@`. After that, open $@ and populate the data.)

init: .credential.tfvars
	$(terraform) init \
			-reconfigure \
			-get=true \
			-upgrade \
			-backend=true \
			-backend-config="region=$(AWS_DEFAULT_REGION)" \
			-backend-config="profile=$(AWS_PROFILE)" \
			-backend-config="bucket=$(TFSTATE_BUCKET)"

plan: init
	$(terraform) plan $(addprefix -var-file=/app/,global.hcl .credential.tfvars)

apply: init
	$(terraform) apply -auto-approve=false $(addprefix -var-file=/app/,global.hcl .credential.tfvars)

import: init
	$(terraform) import '$(IMPORT_RESOURCE)' $(IMPORT_FROM)

clean:
	find . -type d -name '.terraform' | xargs -n1 rm -rf

#
# 初回や一度だけ実行すれば良いターゲット for staff
#
.PHONY: setup create_tfstate_backend create_ssh_key get_ssh_key

# AWSアカウントを作ったら make apply の前に一度実行する
setup: create_tfstate_backend create_ssh_key

create_tfstate_backend:
	$(aws) s3api create-bucket --acl private --bucket $(TFSTATE_BUCKET) --create-bucket-configuration LocationConstraint=$(AWS_DEFAULT_REGION)
	$(aws) s3api put-bucket-versioning --bucket $(TFSTATE_BUCKET) --versioning-configuration Status=Enabled

create_ssh_key:
	ssh-keygen -t rsa -b 2048 -C "sunrise2023 $(AWS_PROFILE)" -f _files/id_rsa
	$(aws) ssm put-parameter \
	  --name "$(AWS_SSM_KEYPAIR_PRIVATE_KEY)" \
	  --description "ssh private key for keypair" \
	  --type "SecureString" \
	  --value "$$(base64 -b0 _files/id_rsa)"
	$(aws) ec2 import-key-pair --key-name "$(AWS_KEYPAIR_NAME)" --public-key-material "$$(base64 -b0 _files/id_rsa.pub)"

get_ssh_key: _files/id_rsa.pub

_files/id_rsa:
	$(aws) ssm get-parameter --name "$(AWS_SSM_KEYPAIR_PRIVATE_KEY)" --with-decryption --output text --query Parameter.Value | base64 -d > $@
	chmod 600 $@

_files/id_rsa.pub: _files/id_rsa
	ssh-keygen -y -f $< > $@

#
# make apply TO=hakaru が完了したら一度実行する
#
.PHONY: setup_rds

setup_rds: hakaru/_files/setup_rds.sh _files/changed_rds_password.txt hakaru/_files/setup_rds.sql
	sh -e $<

RANDOM_PASSWD = $(shell openssl rand -base64 32 | sed -e "s@/@@" |  fold -w 20 | head -1)

_files/changed_rds_password.txt:
	@$(aws) ssm put-parameter \
	  --name "/hakaru/rds/root/password" \
	  --type "SecureString" \
	  --overwrite \
	  --value "$(RANDOM_PASSWD)"
	@$(aws) rds modify-db-instance \
	  --db-instance-identifier "hakaru" \
	  --apply-immediately \
	  --master-user-password "$$($(aws) ssm get-parameter --name "/hakaru/rds/root/password" --output text --query Parameter.Value --with-decryption)"
	sleep 10
	touch $@

hakaru/_files/setup_rds.sql: hakaru/_files/setup_rds.sql.in
	@$(aws) ssm put-parameter \
		--name "/hakaru/rds/hakaru/password" \
		--type "SecureString" \
		--overwrite \
		--value "$(RANDOM_PASSWD)"
	@$(aws) ssm put-parameter \
		--name "/hakaru/rds/redash/password" \
		--type "SecureString" \
		--overwrite \
		--value "$(RANDOM_PASSWD)"
	cat $< \
	  | sed -e "s#@@HAKARU_PASSWORD@@#$$($(aws) ssm get-parameter --name "/hakaru/rds/hakaru/password" --output text --query Parameter.Value --with-decryption)#" \
	  | sed -e "s#@@REDASH_PASSWORD@@#$$($(aws) ssm get-parameter --name "/hakaru/rds/redash/password" --output text --query Parameter.Value --with-decryption)#" \
	  > $@
