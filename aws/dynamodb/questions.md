# Questions for DynamoDB

## Theory Questions
1. What are the differences between DynamoDB's provisioned capacity and on‑demand capacity modes?
2. Explain how DynamoDB achieves high availability and durability across multiple AZs.
3. How does the partition key and sort key design affect query performance?
4. What are Global Secondary Indexes (GSIs) and Local Secondary Indexes (LSIs), and when would you use each?
5. Describe DynamoDB Streams and how they can be used for change data capture.

## Practical Scenarios
1. A table's read throttling spikes during a traffic surge. How would you diagnose and mitigate it?
2. You need to migrate a large relational dataset into DynamoDB with minimal downtime. Outline the steps.
3. An application receives "AccessDeniedException" when writing items. Troubleshoot the IAM policy required.
4. Implement a GSI to query items by a non‑key attribute and explain the necessary index configuration.
5. Set up a DynamoDB Stream to trigger a Lambda function for real‑time processing of new items.
