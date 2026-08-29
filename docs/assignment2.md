# Assignment 2 - Proposed Improvements

## 1. Security

- Keep cross-account trust limited to the exact `EnvControlLambdaRole`.
- Keep `ec2:StartInstances` and `ec2:StopInstances` restricted by
  `ec2:ResourceTag/EnvControl=True`.
- Do not hard-code real account IDs or resource IDs.
- Use AWS Organizations SCPs or permission boundaries in a larger enterprise.

## 2. Reliability

- Use an EC2 paginator for `DescribeInstances`.
- Start only `stopped` instances.
- Stop only `running` instances.
- Configure retry policy and a dead-letter queue if EventBridge is used.
- Add CloudWatch alarms for Lambda errors and throttles.

## 3. Observability

- Use structured CloudWatch Logs.
- Record requested action and affected instance IDs.
- Use CloudTrail to audit `AssumeRole`, `StartInstances`, and `StopInstances`.
- Add a dashboard for Lambda invocations, errors, duration, and throttles.

## 4. Testing

Unit tests should verify:

- only `EnvControl=True` instances are selected
- untagged instances are ignored
- already-running instances are not started again
- already-stopped instances are not stopped again
- invalid actions return an error
- STS/API failures are surfaced

Terraform CI checks:

```bash
terraform fmt -check
terraform validate
tflint
checkov -d .
```

## 5. Deployment

Recommended pipeline:

1. Pull request
2. Terraform format/validate
3. Security scan
4. Terraform plan
5. Peer approval
6. Terraform apply

For production, store Terraform state remotely with encryption and locking,
and separate state per account/environment.

## 6. Scheduling

The assignment does not explicitly require a schedule. If automatic start/stop
is required later, EventBridge or EventBridge Scheduler can invoke the same
Lambda with:

```json
{"action":"start"}
```

or:

```json
{"action":"stop"}
```
