# Scenario 07: Environment Variable Mismatch

## 1. Question
"Your Postman collection runs perfectly in the 'dev' environment, but every single request returns a 404 in 'staging'. How do you debug this?"

## 2. Interviewer's Point of View
The interviewer wants to see that you understand Postman Environments — how they work, how variables are scoped, and how to inspect the actual resolved value of a variable at runtime. They want to hear you talk about the **Environment quick-look panel** and **variable override order** (Collection → Environment → Global).

## 3. Steps to Setup the Scenario

**Import the collection and both environments:**
1. Open **Postman** → **Import**.
2. Import `collection.json`.
3. Import `dev-env.json` (this becomes the "Dev" environment).
4. Import `staging-env.json` (this becomes the "Staging" environment — **this one is broken**).

**Trigger the broken state:**
1. In the top-right dropdown, select the **Staging** environment.
2. Open the collection **"07 - Env Variable Mismatch"**.
3. Click on **GET {{base_url}}/todos/1** and click **Send**.
4. You will see a **404 Not Found** response.

**UI Tip:** Look at the request URL bar — it shows the resolved URL. Can you spot the problem just from looking at it?

**Now switch to Dev and compare:**
1. Change the environment dropdown to **Dev**.
2. Click **Send** again.
3. You will now see a **200 OK** response with a JSON body.

## 4. Step-by-Step Debugging

**Step 1: Check the resolved URL in the request bar**

With Staging selected, look at the URL bar in Postman. It will show:
```
https://jsonplaceholder.typicode.com/api/todos/1
```
*Thoughts to share:* "The request URL looks slightly different. In staging, the path has an extra `/api` segment. That's suspicious — the API doesn't have a `/api` prefix. Let me check the environment variable."

**Step 2: Inspect the environment variable value**

Click the **eye icon** (🔍) next to the environment dropdown in the top-right corner of Postman. This opens the Environment Quick Look panel.

Look at the values:
```
Dev environment:
  base_url = https://jsonplaceholder.typicode.com       ✅

Staging environment:
  base_url = https://jsonplaceholder.typicode.com/api   ❌  (extra /api)
```
*Thoughts to share:* "There it is — the `base_url` in the Staging environment has a wrong value. Someone added `/api` to the base URL, which doesn't exist on this API. This is a classic environment misconfiguration. In a real scenario, this staging environment file would be managed in a secrets manager or a config repo, and someone committed the wrong value."

**Step 3: Fix the staging environment variable**

1. In Postman, go to **Environments** (left sidebar or top menu).
2. Click on **Staging**.
3. Find the `base_url` variable.
4. Change the CURRENT VALUE from:
   ```
   https://jsonplaceholder.typicode.com/api
   ```
   to:
   ```
   https://jsonplaceholder.typicode.com
   ```
5. Click **Save**.

**Step 4: Verify the fix**

Switch back to the **Staging** environment, open the request, and click **Send**. You should now get a **200 OK**.

*Thoughts to share:* "Fixed. The root cause was a bad value in the staging environment file, not a code issue. This is why it's important to version-control your Postman environment files and review them during deployment config reviews."

## 5. Interview Summary Pitch
"When a collection works in dev but fails in staging, my first step is to inspect the environment variables using Postman's Eye icon (quick-look panel) to compare the resolved variable values between environments. In this case, the `base_url` in staging had an extra `/api` path segment that doesn't exist on the API. The fix was simply correcting the variable value in the staging environment. In production, I would store environment configs in a secrets manager and use environment-specific overrides, validated as part of the deployment pipeline."
