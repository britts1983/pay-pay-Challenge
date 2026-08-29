# One-time bootstrap

The automated pipeline needs IAM roles and a remote Terraform state bucket
before GitHub Actions can deploy the main stack. This is a standard bootstrap
dependency.

Run these once with administrator credentials in sandbox/test accounts:

1. `bootstrap/management` against the management AWS account.
2. `bootstrap/target` against the target AWS account.

After that, normal changes flow automatically:

Code -> GitHub -> GitHub Actions -> OIDC -> Terraform Plan -> Approval -> Apply -> AWS
