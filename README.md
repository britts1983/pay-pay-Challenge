# EnvControl

Terraform + AWS Lambda implementation for cross-account EC2 environment control.

## Requirement mapping

- Management account: `111111111111` placeholder
- Management IAM role: `EnvControlLambdaRole`
- Target account: `222222222222` placeholder
- Target IAM role: `EnvControlRole`
- `EnvControlLambdaRole` can assume `EnvControlRole`
- Target role can:
  - list EC2 instances
  - start EC2 instances
  - stop EC2 instances
- Start/stop is restricted to EC2 instances tagged:

```text
EnvControl = True
```

No real AWS account ID or resource ID is committed to this repository.

## Repository structure

```text
env-control/
├── README.md
├── .gitignore
├── versions.tf
├── providers.tf
├── variables.tf
├── locals.tf
├── iam_management.tf
├── iam_target.tf
├── lambda.tf
├── eventbridge.tf
├── outputs.tf
├── terraform.tfvars.example
├── lambda/
│   └── env_control.py
└── docs/
    └── assignment2.md
```

## How it works

1. Lambda runs in the management account with `EnvControlLambdaRole`.
2. Lambda calls AWS STS `AssumeRole`.
3. It assumes `EnvControlRole` in the target account.
4. It searches for EC2 instances tagged `EnvControl=True`.
5. It starts only stopped instances or stops only running instances.

## Prerequisites

- Terraform >= 1.5
- Python 3.12 Lambda runtime
- AWS credentials for both test accounts if you want to deploy
- Permissions to create IAM/Lambda/EventBridge resources

## Configure

Copy the example variable file:

```bash
cp terraform.tfvars.example terraform.tfvars
```

Use only sandbox/test account IDs.

## Validate

```bash
terraform init
terraform fmt -check
terraform validate
terraform plan
```

## Apply

```bash
terraform apply
```

## Lambda test events

Start:

```json
{
  "action": "start"
}
```

Stop:

```json
{
  "action": "stop"
}
```

## Optional schedules

EventBridge schedules are disabled by default.

To enable them:

```hcl
enable_schedules = true
```

The default expressions are:

- Start: Monday-Friday 09:00 JST
- Stop: Monday-Friday 20:00 JST

EventBridge cron expressions are evaluated in UTC.

## Cleanup

```bash
terraform destroy
```


## Automated GitHub -> AWS deployment

The automated edition contains:

```text
.github/workflows/terraform.yml
backend.tf
bootstrap/
docs/cicd.md
```

Company-style flow:

```text
Code -> GitHub PR -> Validate -> Terraform Plan -> Review/Merge
     -> Production Approval -> Terraform Apply -> AWS
```

Authentication uses GitHub OIDC rather than stored AWS access keys. Terraform
state is stored in an encrypted/versioned S3 bucket created during the one-time
bootstrap.

See `docs/cicd.md` before enabling the pipeline.
