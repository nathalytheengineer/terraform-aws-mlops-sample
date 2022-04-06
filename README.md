# terraform-aws-mlops-sample
A sample repo that deploys the following AWS Resources for a quick-start Machine Learning development platform: 1 S3 bucket, 1 SNS, 1 Lambda function, 1 Sagemaker Notebook.

#### To use this code please git clone, set up your local terraform environment, your aws credentials for your aws account and navigate to the directory where main.tf lives.

Then run the following Terraform commands:

```
terraform init
terraform plan -out "plan.out"
terrafrom apply "plan.out"
```
