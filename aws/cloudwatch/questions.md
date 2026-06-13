# Questions for CloudWatch

## Theory Questions
1. What are the main components of Amazon CloudWatch (metrics, logs, alarms, dashboards) and how do they differ?
2. Explain the difference between custom metrics and AWS‑provided metrics. How do you publish a custom metric?
3. How does CloudWatch retention work for metrics and logs?
4. What are metric math expressions and when would you use them?
5. Describe how CloudWatch Contributor Insights can be used for troubleshooting.

## Practical Scenarios
1. An alarm is constantly flapping (going from OK to ALARM). Walk through the steps to diagnose and fix it.
2. You need to monitor the latency of an API Gateway endpoint and create a dashboard widget. Outline the necessary resources.
3. A Lambda function logs are missing from CloudWatch Logs after a recent deployment. How would you troubleshoot?
4. Implement a log‑based metric that counts error‑level log entries from an EC2 instance.
5. Set up a cross‑account CloudWatch alarm that notifies a Slack channel via SNS when CPU usage exceeds a threshold.
