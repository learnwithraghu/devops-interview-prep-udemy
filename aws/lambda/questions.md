# Questions for Lambda

## Theory Questions
1. What are the different invocation types for AWS Lambda (synchronous vs asynchronous) and when would you use each?
2. Explain how Lambda integrates with other AWS services via event sources.
3. Discuss Lambda's scaling model and the concept of concurrency limits.
4. What are the size limits for a Lambda deployment package (code + layers) and how can you work around them?
5. How does the execution environment lifecycle affect cold starts, and what mitigations exist?

## Practical Scenarios
1. A Lambda function times out after 3 seconds even though the code only needs ~1 second. Diagnose the issue.
2. You need to reduce cold start latency for a Java Lambda. Describe the steps you would take.
3. Implement a versioned Lambda with an alias for blue‑green deployment. Outline the required AWS CLI commands.
4. A function writes logs but they never appear in CloudWatch. Troubleshoot the missing log group.
5. You must secure a Lambda that accesses a VPC‑only RDS instance without exposing credentials. Explain the IAM role and VPC configuration needed.
