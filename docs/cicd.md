# GitHub -> AWS Automated CI/CD

## Flow

```text
Developer
   |
   | push / pull request
   v
GitHub
   |
   v
GitHub Actions
   |
   +--> terraform fmt -check
   +--> terraform validate
   +--> terraform plan
   |
   | GitHub OIDC
   v
Management AWS Account
TerraformDeploymentRole
   |
   +--> Lambda / IAM / EventBridge / Terraform state
   |
   | sts:AssumeRole
   v
Target AWS Account
TerraformTargetDeploymentRole
   |
   v
EnvControlRole
```

## One-time bootstrap

GitHub cannot assume an AWS deployment role until that role exists. Therefore
an administrator performs a one-time bootstrap:

1. Run `bootstrap/management` in the management account.
   - Creates GitHub OIDC provider
   - Creates `TerraformDeploymentRole`
   - Creates encrypted/versioned S3 Terraform state bucket
2. Run `bootstrap/target` in the target account.
   - Creates `TerraformTargetDeploymentRole`
   - Trusts `TerraformDeploymentRole`

This bootstrap is not part of each application deployment.

## Repository variables

In GitHub:

Settings -> Secrets and variables -> Actions -> Variables

Create:

- `AWS_REGION`
- `MANAGEMENT_ACCOUNT_ID`
- `TARGET_ACCOUNT_ID`
- `MANAGEMENT_DEPLOY_ROLE_ARN`
- `TARGET_DEPLOYMENT_ROLE_ARN`
- `TF_STATE_BUCKET`
- `TF_STATE_KEY` (for example `env-control/terraform.tfstate`)

No long-lived AWS access key or secret key is stored in GitHub.

## Pull request behavior

PR:
- format check
- init
- validate
- AWS authentication with OIDC
- Terraform plan

No apply is performed.

## Main branch behavior

Merge/push to `main`:
- validate
- plan
- wait for `production` environment approval
- apply the exact saved plan

Configure GitHub Environment `production` with required reviewers to create the
deployment approval gate.

## Why remote state is included

GitHub-hosted runners are ephemeral. A local `terraform.tfstate` would disappear
after each workflow run. The S3 backend stores state persistently and uses
Terraform's S3 lock file support to prevent concurrent state writes.
