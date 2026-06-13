# Scenario 06: Lambda Timeout

## 1. Question
"A Lambda function times out after 3 seconds even though the code only needs about 1 second. How do you diagnose and fix the issue?"

## 2. Interviewer's Point of View
The interviewer wants to see if you understand Lambda execution limits, function configuration, and how to use CloudWatch metrics for performance troubleshooting. They also expect you to discuss best‑practice mitigations like increasing timeout, optimizing code, and using provisioned concurrency.

## 3. Steps to Setup the Scenario
1. Deploy the CloudFormation stack in `template.yaml` (creates a Lambda with a 2‑second timeout). The stack is located at `aws/lambda/practical/06-timeout/template.yaml`.
2. In the **AWS Console**, navigate to **Lambda → Functions → DemoTimeoutLambda** and invoke it via the **Test** button.
3. Observe that the function fails with a timeout error after 3 seconds.

## 4. Step‑by‑Step Debugging & Fix
**Step 1: Check the function configuration**
- Open the Lambda console, click **Configuration → General configuration** and note the **Timeout** setting.
*Thoughts to share:* "First, I verify the configured timeout. It's set to 2 seconds, which is less than the observed 3‑second execution, so the function will inevitably time out."

**Step 2: Inspect CloudWatch logs**
- Go to **CloudWatch → Logs groups → /aws/lambda/DemoTimeoutLambda** and view the latest log stream.
*Thoughts to share:* "The log shows the function started, ran for ~2 seconds, then hit the timeout. This confirms the timeout is the bottleneck."

**Step 3: Identify the root cause**
- The function includes an artificial `sleep(3)` call to simulate work.
*Thoughts to share:* "The code is intentionally sleeping longer than the timeout. In real life, this could be a slow DB query or external API call."

**Step 4: Apply the fix**
- Update the stack (or directly edit in the console) to increase the timeout to 5 seconds.
```bash
aws cloudformation update-stack \
  --stack-name lambda-timeout-demo \
  --template-body file://template.yaml \
  --parameters ParameterKey=TimeoutSeconds,ParameterValue=5
```
*Thoughts to share:* "I raise the timeout to accommodate the workload, then re‑invoke to confirm success."

**Step 5: Optimize (optional)**
- Refactor the code to remove the unnecessary delay or move heavy work to asynchronous services (SQS, Step Functions).

## 5. Interview Summary Pitch
"The timeout error was caused by the Lambda’s configured timeout being shorter than its execution time. I verified this via the Lambda configuration and CloudWatch logs, then increased the timeout via a CloudFormation update. In production, I’d also look to eliminate long‑running calls or offload them to async services to avoid unnecessary timeouts."
