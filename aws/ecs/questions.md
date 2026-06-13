# Questions for ECS

## Theory Questions
1. What is the difference between Amazon ECS with EC2 launch type and Fargate launch type?
2. Explain how task definitions, services, and clusters interact in ECS.
3. How does service auto‑scaling work in ECS and what metrics can trigger scaling?
4. What are the networking options for ECS tasks (bridge, awsvpc, host) and when would you use each?
5. Describe how IAM roles for tasks (task‑execution role vs task role) are used.

## Practical Scenarios
1. A Fargate task fails to pull the container image due to authentication errors. How would you troubleshoot?
2. You need to perform a rolling update of a service with zero downtime. Outline the required steps.
3. An ECS service is stuck in `DEPROVISIONING` state after scaling down. How would you investigate?
4. Implement task placement constraints to ensure tasks run on instances with specific attributes.
5. Configure CloudWatch alarms to trigger auto‑scaling based on CPU utilization for an ECS service.
