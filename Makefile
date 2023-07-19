PROFILE = "osmodies@gmail.com"
ENV = test
MAILID = "osmodies@gmail.com"
ACCOUNTID = "023712007260"
S3_BUCKET_NAME = codepipeline-git-custom-action-ACCOUNTID
GITLAB-TOKEN = "glpat-AaD_rhJFLBAQ_E15GLyr"
REGION = us-east-1
vpcId="vpc-08e0268520378ea9b"
subnetId1='subnet-04d605deca5cb80c7'
subnetId2='subnet-0f8d81dbf8f2a32b8'
Subnets = "subnet-04d605deca5cb80c7,subnet-0f8d81dbf8f2a32b8"
GIT_SOURCE_STACK_NAME="thirdparty-codepipeline-git-source"
ZIP_FILE_NAME="codepipeline_git.zip"
SSH_URL="git@gitlab.com:karthickcse05/cdk-demo.git"
SAMPLE_STACK_NAME="third-party-codepipeline-git-source-test"
SecretsManagerArn="arn:aws:secretsmanager:us-east-1:7137924343226:secret:codepipeline-feb6-vUgIhS"
.DEFAULT_GOAL := explain
.PHONY: explain
explain:
	###
	#
	# Welcome to the AWS Infrastructure Templates repo
	#
	##

.PHONY: install
install: ## Install all the dependencies we need
	npm install


.PHONY: generate-ssh-key 
generate-ssh-key:
	ssh-keygen -t rsa -b 4096 -C $(MAILID)


.PHONY: create-secret 
create-secret:
	aws secretsmanager create-secret --name codepipeline-feb6 --secret-string file://codepipeline_git_rsa --profile $(PROFILE) --region $(REGION) --query ARN --output text


.PHONY: create-bucket 
create-bucket:
	aws s3 mb s3://${S3_BUCKET_NAME} --region $(REGION) --profile $(PROFILE)


.PHONY: zip-code
zip-code:
	7z a codepipeline_git.zip ./lambda/lambda_function.py


.PHONY: upload-code-s3
upload-code-s3:
	aws s3 cp codepipeline_git.zip s3://codepipeline-git-custom-action-713792433226/codepipeline_git.zip --profile $(PROFILE)


.PHONY: create-vpc 
create-vpc:
	aws cloudformation create-stack \
		--stack-name vpc-gitlab \
		--template-body file://./cfn/vpc-privatepublic.yaml \
		--capabilities CAPABILITY_IAM --region $(REGION) --profile $(PROFILE)


.PHONY: create-custom-resource 
create-custom-resource:
	aws cloudformation create-stack \
		--stack-name ${GIT_SOURCE_STACK_NAME} \
		--template-body file://./cfn/third_party_git_custom_action.yaml \
		--parameters ParameterKey=SourceActionVersion,ParameterValue=1 \
		ParameterKey=SourceActionProvider,ParameterValue=CustomSourceForGit \
		ParameterKey=GitPullLambdaSubnet1,ParameterValue=${subnetId1} \
		ParameterKey=GitPullLambdaSubnet2,ParameterValue=${subnetId2} \
		ParameterKey=GitPullLambdaVpc,ParameterValue=${vpcId} \
		ParameterKey=LambdaCodeS3Bucket,ParameterValue=${S3_BUCKET_NAME} \
		ParameterKey=LambdaCodeS3Key,ParameterValue=${ZIP_FILE_NAME} \
		--capabilities CAPABILITY_IAM --region $(REGION) --profile $(PROFILE)



.PHONY: create-pipeline
create-pipeline:
	aws cloudformation create-stack \
		--stack-name ${SAMPLE_STACK_NAME} \
		--template-body file://./cfn/sample_pipeline_custom.yaml \
		--parameters ParameterKey=Branch,ParameterValue=master \
		ParameterKey=GitUrl,ParameterValue=${SSH_URL} \
		ParameterKey=SourceActionVersion,ParameterValue=1 \
		ParameterKey=SourceActionProvider,ParameterValue=CustomSourceForGit \
		ParameterKey=CodePipelineName,ParameterValue=sampleCodePipeline \
		ParameterKey=SecretsManagerArnForSSHPrivateKey,ParameterValue=${SecretsManagerArn} \
		ParameterKey=GitLabToken,ParameterValue=$(GITLAB-TOKEN) \
		--capabilities CAPABILITY_IAM --region $(REGION) --profile $(PROFILE)



.PHONY: get-output
get-output:
	aws cloudformation describe-stacks \
		--stack-name ${SAMPLE_STACK_NAME} --region $(REGION) --profile $(PROFILE) --output text --query "Stacks[].Outputs[?OutputKey=='CodePipelineWebHookUrl'].OutputValue" 
