# env-control

This project is for the Cloud Infrastructure Engineer assignment.

The goal is to run a Lambda function in one AWS account and use it to start or stop EC2 instances in another AWS account.

Only EC2 instances with this tag are controlled:

```text
EnvControl = True
```

## Setup

The solution uses two AWS accounts.

### Management account

Contains:

- `EnvControl` Lambda
- `EnvControlLambdaRole`
- `TerraformDeploymentRole`
- Terraform state S3 bucket

### Target account

Contains:

- `EnvControlRole`
- `TerraformTargetDeploymentRole`
- test EC2 instance

The Lambda runs with `EnvControlLambdaRole` and assumes `EnvControlRole` in the target account.

`EnvControlRole` can:

- describe EC2 instances
- start EC2 instances
- stop EC2 instances

Start and stop are limited to instances with:

```text
EnvControl = True
```

Real AWS account IDs and resource IDs are not hard-coded in the Terraform files.

## Project Structure

```text
env-control/
├── .github/
│   └── workflows/
│       └── terraform.yml
├── bootstrap/
│   ├── management/
│   └── target/
├── docs/
│   ├── assignment2.md
│   └── cicd.md
├── lambda/
│   └── env_control.py
├── backend.tf
├── eventbridge.tf
├── iam_management.tf
├── iam_target.tf
├── lambda.tf
├── locals.tf
├── outputs.tf
├── providers.tf
├── test_ec2.tf
├── terraform.tfvars.example
├── variables.tf
├── versions.tf
├── .gitignore
└── README.md
```

## How It Works

The deployment flow is:

```text
Code
  |
  v
GitHub
  |
  v
GitHub Actions
  |
  +--> terraform fmt
  +--> terraform validate
  +--> terraform plan
  +--> terraform apply
  |
  v
Management AWS Account
  |
  +--> EnvControl Lambda
  +--> EnvControlLambdaRole
  |
  | AssumeRole
  v
Target AWS Account
  |
  +--> EnvControlRole
  +--> EC2 with EnvControl=True
```

The Lambda accepts two actions.

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

For `start`, it looks for stopped instances with `EnvControl=True`.

For `stop`, it looks for running instances with `EnvControl=True`.

## Test EC2

The test EC2 instance is created by Terraform, so no manual EC2 setup is needed.

Tags:

```text
Name       = EnvControl-Test
EnvControl = True
ManagedBy  = Terraform
```

The Amazon Linux AMI is retrieved from AWS Systems Manager Parameter Store, so the AMI ID is not hard-coded.

## GitHub Actions

The workflow is in:

```text
.github/workflows/terraform.yml
```

The flow is:

```text
Push / Pull Request
        |
        v
Format Check
        |
        v
Validate
        |
        v
Terraform Plan
        |
        v
Approval
        |
        v
Terraform Apply
```

GitHub connects to AWS using OIDC, so AWS access keys are not stored in GitHub.

## Bootstrap

The GitHub deployment roles need to exist before the workflow can connect to AWS.

This setup is done once.

### Management account

Run from:

```text
bootstrap/management
```

This creates:

- GitHub OIDC provider
- `TerraformDeploymentRole`
- Terraform state S3 bucket
- required IAM permissions

Example:

```bash
cd bootstrap/management
terraform init
terraform plan
terraform apply
```

### Target account

Run from:

```text
bootstrap/target
```

This creates:

- `TerraformTargetDeploymentRole`
- trust with the management deployment role
- IAM and EC2 permissions needed by Terraform

Example:

```bash
cd bootstrap/target
terraform init
terraform plan
terraform apply
```

## GitHub Variables

Add these under:

```text
Repository
-> Settings
-> Secrets and variables
-> Actions
-> Variables
```

Required variables:

```text
AWS_REGION
MANAGEMENT_ACCOUNT_ID
TARGET_ACCOUNT_ID
MANAGEMENT_DEPLOY_ROLE_ARN
TARGET_DEPLOYMENT_ROLE_ARN
TF_STATE_BUCKET
TF_STATE_KEY
```

Real account IDs and role ARNs are passed through GitHub variables and are not committed to the repository.

## Terraform State

Terraform state is stored in S3 because GitHub runners are temporary.

The state bucket is configured with:

- encryption
- versioning
- public access block
- Terraform state locking

Example state key:

```text
env-control/terraform.tfstate
```

## Lambda Package

Lambda source:

```text
lambda/env_control.py
```

Terraform packages it as:

```text
lambda/env_control.zip
```

The plan job uploads the Terraform plan and Lambda ZIP as artifacts.

The apply job downloads them before running `terraform apply`.

This is needed because plan and apply run on different GitHub runners.

## IAM

The Lambda uses:

```text
EnvControlLambdaRole
```

and assumes:

```text
EnvControlRole
```

in the target account.

The target role allows:

```text
ec2:DescribeInstances
ec2:StartInstances
ec2:StopInstances
```

Start and stop are restricted with:

```text
ec2:ResourceTag/EnvControl = True
```

This prevents the Lambda from controlling unrelated EC2 instances.

## Optional EventBridge Schedule

EventBridge is included but disabled by default.

To enable it:

```hcl
enable_schedules = true
```

Default schedule:

- Start: Monday to Friday at 09:00 JST
- Stop: Monday to Friday at 20:00 JST

EventBridge cron expressions use UTC.

## Validation

Terraform:

```bash
terraform init -backend=false
terraform fmt -check -recursive
terraform validate
```

Lambda Python syntax:

```bash
python -m py_compile ./lambda/env_control.py
```

GitHub Actions also runs the Terraform checks automatically.

## Cleanup

To remove the main resources:

```bash
terraform destroy
```

Bootstrap resources should be removed separately if the full CI/CD setup is no longer needed.

## More Details

See:

```text
docs/cicd.md
docs/assignment2.md
```
