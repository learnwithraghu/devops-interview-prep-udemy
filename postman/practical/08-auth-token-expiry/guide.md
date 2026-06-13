# Scenario 08: Auth Token Expiry & Pre-request Script Bug

## 1. Question
"Your Postman collection that hits a Bearer-token-protected API was working fine yesterday, but today every request returns 401 Unauthorized — and you haven't changed anything. How do you debug this?"

## 2. Interviewer's Point of View
The interviewer wants to see that you understand **short-lived tokens** (like JWTs with a 1-hour expiry) and the Postman **Pre-request Script** mechanism for auto-refreshing them. They also want to see if you know how to use the **Postman Console** (`View → Show Postman Console`) to debug script execution — a critical skill for troubleshooting auth issues.

## 3. Steps to Setup the Scenario

**Import the collection:**
1. Open **Postman** → **Import**.
2. Import `collection.json` from this folder.

**Trigger the broken state:**
1. Open the collection **"08 - Auth Token Expiry"**.
2. Click on the request **GET /bearer (Protected Endpoint)**.
3. Click **Send**.
4. You will see a **401 Unauthorized** response.

**UI Tip:** Look at the **Pre-request Script** tab of this request. The bug is hidden in there — the script runs silently and doesn't crash, which makes this tricky.

## 4. Step-by-Step Debugging

**Step 1: Open the Postman Console to see script execution**

1. In Postman, go to the top menu: **View** → **Show Postman Console** (or press `Cmd+Alt+C` on Mac).
2. Click **Send** on the request again.
3. Watch the Console — you will see the `console.log` output from the pre-request script.

*Thoughts to share:* "My first step when a pre-request script is involved is to open the Postman Console. It shows me the output of any `console.log()` calls in the script, so I can see what value the token variable actually resolved to."

**Step 2: Spot the variable name mismatch in the console output**

The console will show:
```
Token fetched and stored: abc-fake-jwt-token-xyz
```
But the request is still failing. Look at the **Authorization** tab of the request — it uses:
```
Bearer {{auth_token}}
```

Now look at the Pre-request Script:
```javascript
// BUG: stores as 'authToken' (camelCase)
pm.environment.set("authToken", "abc-fake-jwt-token-xyz");
```

*Thoughts to share:* "The console shows the token was stored successfully, but the request uses `{{auth_token}}` with an underscore. The pre-request script is storing it as `authToken` with camelCase — a variable name mismatch. The `{{auth_token}}` variable is never set, so it resolves to an empty string and the Authorization header becomes `Bearer `, which is invalid."

**Step 3: Verify the mismatch via the Environment Quick-Look**

1. Click the **eye icon** 🔍 next to the environment dropdown.
2. Look for the variables set by the script.

You will see:
```
authToken = abc-fake-jwt-token-xyz    ← set by script (wrong name)
auth_token = (empty)                  ← what the request uses
```

**Step 4: Fix the pre-request script**

1. Click on the request **"GET /bearer (Protected Endpoint)"**.
2. Click the **Pre-request Script** tab.
3. Find this line:
```javascript
pm.environment.set("authToken", fakeToken);
```
4. Change it to:
```javascript
pm.environment.set("auth_token", fakeToken);
```
5. Click **Send**. The response should now be **200 OK**.

*Thoughts to share:* "Fixed. The root cause was a snake_case vs camelCase naming inconsistency between the pre-request script and the request variable. This is a common mistake when multiple engineers contribute to a shared collection."

## 5. Interview Summary Pitch
"When a collection starts returning 401s without any code change, I immediately suspect a token expiry issue. My debugging workflow is: first, open the **Postman Console** to trace the pre-request script execution and see what value the token variable is actually getting set to. Then, I use the **Environment Quick-Look panel** to compare the variable names the script is writing versus what the Authorization header is reading. In this case, it was a camelCase vs snake_case mismatch. In a real system, short-lived JWT tokens should be refreshed automatically using a pre-request script that calls the auth endpoint, stores the token in an environment variable, and uses it in the Authorization header — all without any manual intervention."
