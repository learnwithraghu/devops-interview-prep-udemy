# AWS Interview Questions

## Theory Questions
1. Explain the difference between an Availability Zone and a Region.
2. What is a VPC, and what are the differences between public and private subnets?
3. Compare Amazon S3, EBS, and EFS. When would you use each?
4. What is the difference between an Application Load Balancer (ALB) and a Network Load Balancer (NLB)?
5. Explain the concept of IAM Roles and how they differ from IAM Users.

## Practical Scenarios
6. **Scenario:** An EC2 instance in a private subnet needs to download updates from the internet but cannot be accessed from the internet. How do you configure the networking?
7. **Scenario:** Your application hosted on EC2 instances behind an ALB is returning 504 Gateway Timeout errors. How do you investigate?
8. **Scenario:** You need to automatically scale your application based on the number of messages in an SQS queue. How do you set this up?
9. **Scenario:** An IAM User is getting an "Access Denied" error when trying to access an S3 bucket, despite having the `s3:*` permission attached. What could be blocking them?
10. **Scenario:** A Lambda function is running slower than expected and occasionally timing out. How do you troubleshoot and optimize it?
