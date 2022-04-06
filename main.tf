# Configure the AWS Provider
provider "aws" {
  region = var.region
}

# AWS USER-ROLE-POLICY
# PLEASE CONFIGURE THIS TO MEET YOUR SPECIFIC SECURITY NEEDS
# THE USER-ROLE-POLICY COMBINATION BELOW ALLOWS THE TERRAFORM PLAN TO APPLY - PLEASE CHANGE ACCORDINGLY

#AWS IAM User - resource
#https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_user

resource "aws_iam_user" "ml_user" {
  name = "ml-user"
  path = "/system/"

  tags = {
    tag-key = "tag-value"
  }
}

resource "aws_iam_access_key" "ml_user" {
  user = aws_iam_user.ml_user.name
}     

# AWS IAM Role - resource
#https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role
# Should create an IAM Role for Sagemaker Notebook to use
# Feel free to consume the module - for ease this sample repo will use the resource directly

resource "aws_iam_role" "role" {
  name = "root_module_role"

  # Terraform's "jsonencode" function converts a
  # Terraform expression result to valid JSON syntax.
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Sid    = ""
        Principal = {
          Service =["ec2.amazonaws.com", "sagemaker.amazonaws.com", "lambda.amazonaws.com", "sns.amazonaws.com", "iam.amazonaws.com","logs.amazonaws.com"]
        }
      },
    ],
  })

  tags = {
    tag-key = "tag-value"
  }
}

resource "aws_iam_policy" "policy" {
  name        = "policy_for_mlops_data"
  #user 	      = aws_iam_user.ml_user.name
  path        = "/"
  description = "Policy for MLOps data framework"

  # Terraform's "jsonencode" function converts a
  # Terraform expression result to valid JSON syntax.
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "ec2:*",
	  "sagemaker:*",
	  "lambda:*",
	  "s3:*",
	 "sns:*",
	"iam:*", 
	"logs:*",
        ]
        Effect   = "Allow"
        Resource = "*"
      },
    ], 
  })
}

resource "aws_iam_role_policy_attachment" "role_attach" {
  role       = aws_iam_role.role.name
  policy_arn = aws_iam_policy.policy.arn
}

resource "aws_iam_policy_attachment" "user-attach" {
  name       = "test-attachment"
  users      = [aws_iam_user.ml_user.name,"main-user"]
  roles      = [aws_iam_role.role.name]
  policy_arn = aws_iam_policy.policy.arn
}

# AWS S3 bucket
#https://github.com/terraform-aws-modules/terraform-aws-s3-bucket
module "s3_bucket" {
  source = "terraform-aws-modules/s3-bucket/aws"

  bucket_prefix = "my-s3-bucket"
  acl    = "private"

  versioning = {
    enabled = false
  }

}

# AWS SNS Topic Resource
#https://github.com/terraform-aws-modules/terraform-aws-sns 

module "sns_topic" {
  source  = "terraform-aws-modules/sns/aws"
  version = "~> 3.0"

  name  = "my-topic0101"
  create_sns_topic = true
}

# AWS Lambda
#https://github.com/terraform-aws-modules/terraform-aws-lambda

module "lambda_function" {
  source = "terraform-aws-modules/lambda/aws"

  function_name = "my-lambda0101"
  description   = "My awesome lambda function"
  handler       = "index.lambda_handler"
  runtime       = "python3.8"
  attach_cloudwatch_logs_policy = true
  attach_policies = true
  #create_role = true
  #create_function = true
  source_path = "src/lambda-function1.py"

  tags = {
    Name = "lambda-tags-1"
  }
}

# AWS Sagemaker Notebook doesn't have a public module so you can make your own and bring it in here or just create the resource directly like so
# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/sagemaker_notebook_instance

resource "aws_sagemaker_code_repository" "example" {
  code_repository_name = "my-notebook-instance-code-repo"

  git_config {
    repository_url = "https://github.com/hashicorp/terraform-provider-aws.git"
  }
}

resource "aws_sagemaker_notebook_instance" "ni" {
  name                    = "my-notebook-instance"
  role_arn                = aws_iam_role.role.arn
  instance_type           = "ml.t2.medium"
  default_code_repository = aws_sagemaker_code_repository.example.code_repository_name

  tags = {
    Name = "ml-data"
  }
}
