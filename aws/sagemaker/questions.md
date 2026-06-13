# Questions for SageMaker

## Theory Questions
1. What are the main components of Amazon SageMaker (Studio, Notebook Instances, Training Jobs, Deployments, Pipelines) and how do they interact?
2. Explain the differences between built‑in algorithms, your own containers, and SageMaker JumpStart models.
3. How does SageMaker Neo optimize model inference, and when would you use it?
4. Describe the role of IAM execution roles in SageMaker and what permissions they typically need.
5. What are the options for model hosting (real‑time endpoint, async inference, batch transform) and their cost implications?

## Practical Scenarios
1. A training job fails with `ResourceLimitExceeded` despite having enough compute resources. Diagnose the possible cause.
2. You need to deploy a model to a real‑time endpoint with automatic scaling based on request volume. Outline the steps using the SDK/CLI.
3. Implement a SageMaker Pipeline that retrains a model daily and promotes it to production only if a validation metric improves.
4. An endpoint returns `AccessDenied` errors when invoked from a Lambda function. Explain how to fix the IAM role/trust relationship.
5. Optimize inference latency for a large PyTorch model by converting it to a SageMaker Neo compiled model and redeploying.
