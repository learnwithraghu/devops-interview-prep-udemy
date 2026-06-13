# Questions for CloudFormation

## Theory Questions
1. What is the difference between a stack and a change set in CloudFormation?
2. Explain how pseudo‑parameters (e.g., `AWS::Region`, `AWS::AccountId`) are used inside templates.
3. How does the `DependsOn` attribute affect resource creation order?
4. What are the benefits and limitations of using **nested stacks**?
5. Describe drift detection and how you would resolve drift in a production stack.

## Practical Scenarios
1. A stack update fails because an **IAM role** cannot be attached to a Lambda function. Walk through the debugging steps.
2. You need to perform a **blue‑green deployment** of an ECS service using CloudFormation change sets. Outline the process.
3. A resource was manually edited in the console, causing drift. Show how to detect and correct it.
4. Implement a **cross‑region replication** of an S3 bucket using a CloudFormation template with export/import.
5. Use a **custom resource** (Lambda backed) to generate a random password during stack creation. Explain the required template configuration.
