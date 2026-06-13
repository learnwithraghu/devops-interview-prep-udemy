# Scenario 07: Java Lambda Cold‑Start Mitigation

## 1. Question
"A Java‑based Lambda function experiences noticeable cold‑start latency (several seconds) on the first invocation. How can you reduce this latency and demonstrate the improvement?"

## 2. Interviewer's Point of View
The interviewer wants to see that you understand Lambda cold starts, especially for Java runtimes, and that you know mitigation strategies such as provisioned concurrency, lightweight runtimes, and initialization tricks.

## 3. Steps to Setup the Scenario
1. Deploy the CloudFormation stack located at `aws/lambda/practical/07-cold-start/template.yaml`. It creates a **JavaColdStartDemo** function with **Provisioned Concurrency = 5**.
2. Open the **AWS Console → Lambda → Functions → JavaColdStartDemo**.
3. In the **Test** tab, invoke the function twice:
   - First invocation will show a longer duration (cold start).
   - Subsequent invocations should be fast because provisioned concurrency keeps containers warm.
4. Observe the **Duration** metric in the **Monitoring** tab and note the reduction.

## 4. Step‑by‑Step Debugging & Fix
**Step 1: View cold‑start metrics**
- In the Lambda console, click **Monitoring → View logs in CloudWatch**. Look for the `REPORT` line that includes `Init Duration`.
*Thoughts to share:* "The first run shows an `Init Duration` of ~3000 ms, indicating a cold start."

**Step 2: Verify provisioned concurrency**
- Navigate to **Configuration → Concurrency** and confirm **Provisioned Concurrency** is set to **5**.
*Thoughts to share:* "Provisioned concurrency pre‑creates execution environments, eliminating the init delay on subsequent invocations."

**Step 3: Compare without provisioned concurrency**
- Temporarily set **Provisioned Concurrency** to **0** (or delete the alias) and re‑invoke the function.
- Note the increase in `Init Duration`.
*Thoughts to share:* "Disabling provisioned concurrency brings back the cold start, confirming its impact."

**Step 4: Alternative mitigations** (briefly mention)
- Use a lighter runtime (e.g., Node.js) for latency‑sensitive workloads.
- Reduce package size, use GraalVM native images, or leverage **SnapStart** for Java 11+.

## 5. Interview Summary Pitch
"The latency was caused by the Java runtime’s heavy initialization. By enabling provisioned concurrency, we keep a pool of warm containers ready, which eliminates the init delay. In production, we’d size the concurrency to match expected traffic and consider lighter runtimes or SnapStart for further improvement."
