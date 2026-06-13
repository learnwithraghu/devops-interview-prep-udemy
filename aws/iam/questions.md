# Questions for IAM

## Theory Questions
1. What are the differences between IAM users, groups, roles, and policies?
2. Explain the principle of least privilege and how it is applied in IAM.
3. How does AWS STS (Security Token Service) work and when would you use temporary credentials?
4. What is a service‑linked role and how does it differ from a regular IAM role?
5. Describe the process of cross‑account access using IAM roles.

## Practical Scenarios
1. A developer cannot access an S3 bucket despite being attached to a group with `AmazonS3ReadOnlyAccess`. How would you troubleshoot?
2. You need to grant a Lambda function permission to write to DynamoDB without granting broader access. Show the minimal IAM policy.
3. An external vendor requires read‑only access to a specific set of resources via a role. Explain how to set up a cross‑account role with a trust policy.
4. A CI pipeline needs to assume a role to deploy CloudFormation stacks. Outline the steps and required permissions.
5. You notice an IAM user has unused long‑lived access keys. Describe how to rotate and audit them.
