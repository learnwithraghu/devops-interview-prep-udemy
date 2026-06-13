# Scenario 08: Versioned Lambda with Alias (Blue‑Green Deployment)

## 1. Question
"Implement a versioned Lambda function with an alias for blue‑green deployment. How would you promote a new version without downtime, and what CLI commands would you use?"

## 2. Interviewer's Point of View
The interviewer wants to verify that you understand Lambda versioning, alias routing, and how to perform traffic shifting for safe releases.

## 3. Steps to Setup the Scenario
1. Deploy the CloudFormation stack at `aws/lambda/practical/08-versioned/template.yaml`. It creates a Lambda (`DemoVersionedLambda`) and publishes its first version.
2. The stack also creates an alias named **live** that points to the published version.
3. Open the **Lambda console → Versions** to see the published version number (e.g., `1`).
4. In the **Aliases** tab you will see the **live** alias pointing to version `1` with 100 % traffic.

## 4. Step‑by‑Step Debugging & Fix
**Step 1: Publish a new version**
```bash
aws lambda update-function-code \
  --function-name DemoVersionedLambda \
  --zip-file fileb://new-code.zip
aws lambda publish-version --function-name DemoVersionedLambda
```
*Thoughts to share:* "I update the code and publish a new version, which receives a sequential numeric identifier (e.g., `2`)."

**Step 2: Shift traffic using the alias**
```bash
aws lambda update-alias \
  --function-name DemoVersionedLambda \
  --name live \
  --routing-config "AdditionalVersionWeights={Version=2,Weight=0.2}"
```
*Thoughts to share:* "I configure the alias to send 20 % of traffic to the new version while keeping 80 % on the stable version. This allows us to monitor the new version before a full cut‑over."

**Step 3: Verify**
- In the **CloudWatch Logs** for the function, confirm that both versions are receiving invocations.
- Use the **Test** button on the alias to ensure the correct version runs.
*Thoughts to share:* "The logs show requests hitting both versions according to the weight configuration."

**Step 4: Promote to 100 %**
```bash
aws lambda update-alias \
  --function-name DemoVersionedLambda \
  --name live \
  --function-version 2
```
*Thoughts to share:* "Once confidence is gained, I route all traffic to the new version by updating the alias to point exclusively to version 2."

## 5. Interview Summary Pitch
"I used Lambda versioning paired with an alias to achieve blue‑green deployment. By publishing a new version, then gradually shifting traffic with `update-alias` and `routing‑config`, I can validate the new code in production without impacting existing users. Once verified, I promote the alias to 100 % for a seamless rollout."
