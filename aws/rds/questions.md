# Questions for RDS

## Theory Questions
1. What are the main differences between Amazon RDS engine types (MySQL, PostgreSQL, Aurora, etc.) and when would you choose each?
2. Explain the high‑availability options for RDS (Multi‑AZ, Read Replicas) and their trade‑offs.
3. How does automated backup work in RDS and how can you restore to a point‑in‑time?
4. What is the purpose of the parameter group and option group in RDS?
5. Discuss the security features of RDS (encryption at rest, IAM authentication, VPC isolation).

## Practical Scenarios
1. An RDS instance is failing to accept connections after a recent patch. How would you troubleshoot connectivity?
2. You need to migrate a production MySQL database to an Aurora cluster with zero downtime. Outline the steps.
3. An automated backup failed due to insufficient storage. How would you resolve the issue and prevent future failures?
4. You notice high read latency on a read replica. Explain how you would diagnose and improve performance.
5. Implement a read‑only IAM role for a Lambda function to query an RDS database securely.
