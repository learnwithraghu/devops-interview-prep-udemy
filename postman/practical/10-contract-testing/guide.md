# Scenario 10: Contract Testing (Breaking API Change)

## 1. Question
"An upstream team deployed a new version of their API without notifying you. Your service broke in production because a field it relied on was removed. How could Postman contract tests have caught this before it reached production?"

## 2. Interviewer's Point of View
This is the most advanced Postman scenario. The interviewer wants to see that you understand **consumer-driven contract testing** — the idea that the consumer of an API writes explicit assertions about the response schema it depends on. When the provider changes the API, running the consumer's Postman collection against the new API version immediately reveals the breaking change. They also want to hear you mention that this can be automated via Newman in CI.

## 3. Steps to Setup the Scenario

**Import the collection:**
1. Open **Postman** → **Import** → drag `collection.json`.

**Trigger the broken state:**

The collection has two requests:
- **v1 contract check** — hits the real API and checks all expected fields (passes ✅)
- **v2 breaking change simulation** — simulates what happens when the upstream team removes the `email` field from the user response. This is done by checking for a field called `phone_number` which does not exist in the actual response (fails ❌)

Run the full collection:
1. Right-click the collection → **Run collection**.
2. Click **Run 10 - Contract Testing**.

**UI Tip:** In the Collection Runner results, you will clearly see which assertion broke and what the actual response contained vs. what you expected. This is your "contract violation report".

## 4. Step-by-Step Debugging

**Step 1: Run the collection and read the failure message**

In the Collection Runner, find the failing test. Click on it to expand the assertion error:
```
AssertionError: expected undefined to exist
  at assertion:0 in test-script
  GET https://jsonplaceholder.typicode.com/users/1
  Test: Consumer contract: response must have phone_number field
```
*Thoughts to share:* "The test is checking for a `phone_number` field in the user response. Let me check the actual response body to see what fields the API currently returns."

**Step 2: Inspect the actual API response**

1. Click on the **"GET /users/1 (v2 - breaking change)"** request.
2. Click **Send**.
3. In the **Body** tab of the response, look at the fields returned:

```json
{
  "id": 1,
  "name": "Leanne Graham",
  "username": "Bret",
  "email": "Sincere@april.biz",
  "address": { ... },
  "phone": "1-770-736-0800 x56442",
  "website": "hildegard.org",
  "company": { ... }
}
```
*Thoughts to share:* "The API returns a `phone` field — not `phone_number`. The upstream team renamed the field from `phone_number` to `phone` in their v2 release. This is a breaking change because any consumer relying on `phone_number` will now get `undefined` at runtime."

**Step 3: Understand the impact**

The contract test caught this because it explicitly asserted that `phone_number` must exist. Without this test, the bug would only surface when the production service tried to use `response.phone_number` and got `undefined` — probably causing a runtime crash or silent data corruption.

*Thoughts to share:* "This is exactly why we write contract tests. We are the consumers — we define what shape we expect from the API. When the provider changes something that breaks our expectation, we find out during the CI run rather than in production."

**Step 4: Report and remediate**

Two possible fixes:
- **Option A (Provider fix):** The upstream team adds `phone_number` back as an alias, maintaining backward compatibility.
- **Option B (Consumer fix):** You update your service to use `phone` instead of `phone_number`, and update the contract test to match.

Update the contract test to use the correct field:
```javascript
// BEFORE (broken contract)
pm.test("Consumer contract: response must have phone_number field", function () {
    pm.expect(pm.response.json().phone_number).to.exist;
});

// AFTER (updated contract)
pm.test("Consumer contract: response must have phone field", function () {
    pm.expect(pm.response.json().phone).to.exist;
});
```

**Step 5: Run Newman to automate this as a CI gate**
```bash
newman run collection.json
```
A non-zero exit code means a contract violation. Wire this into your pipeline before any deployment.

## 5. Interview Summary Pitch
"Contract testing with Postman means writing explicit assertions about every field your service depends on from an upstream API. When the upstream team changes their API — even something as small as renaming a field — running our Postman contract collection via Newman in CI immediately flags the violation with a non-zero exit code, blocking the deployment. This moves the detection point from production runtime to pre-deploy CI, which is exactly where you want to catch breaking changes. For more formal contract testing at scale, I would look at tools like Pact, but for REST API teams already using Postman, this is a lightweight and practical starting point."
