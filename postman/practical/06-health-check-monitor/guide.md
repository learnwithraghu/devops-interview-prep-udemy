# Scenario 06: Health Check Monitor

## 1. Question
"You have just deployed a new REST API service. How would you use Postman to write a health check collection that validates the status code, response time, and JSON response shape — and what does 'failing tests' look like in the UI?"

## 2. Interviewer's Point of View
The interviewer wants to see that you understand Postman is not just a click-and-look tool. They are looking for knowledge of **Postman test scripts** (the `pm.test()` / `pm.expect()` API) and the ability to define pass/fail criteria programmatically. They also want to see that you know how to read the **Test Results** tab in the response panel.

## 3. Steps to Setup the Scenario

**Import the collection:**
1. Open **Postman**.
2. Click **Import** (top-left).
3. Drag `collection.json` from this folder into the import dialog.
4. Click **Import**.

You will see a new collection called **"06 - Health Check Monitor"** appear in your Collections sidebar.

**Trigger the broken state:**
- The collection has 3 requests. Two of them pass. One of them has a deliberately broken test — it checks for a JSON field called `"description"` which does not exist in the API response.
- Run the full collection: Right-click the collection → **Run collection**.
- In the **Collection Runner**, click **Run 06 - Health Check Monitor**.

**UI Tip:** After the run, look at the summary screen. You will see green checkmarks for passing tests and a red ❌ for the failing test. Click the failing test name to expand the assertion error message.

## 4. Step-by-Step Debugging

**Step 1: Identify the failing test in the Collection Runner**
After running the collection, look at the results panel.
```
GET /todos/1      → PASS (Status 200, Response time OK)
GET /users/1      → PASS (Status 200, has "email" field)
GET /posts/1      → FAIL ❌ (AssertionError: expected undefined to exist)
```
*Thoughts to share:* "I can see the failure is on the `/posts/1` request, specifically a test that is looking for a `description` field. My first instinct is to open the response body and check what fields actually exist."

**Step 2: Open the failing request and inspect the response**
1. In the collection, click on **GET /posts/1**.
2. Click **Send**.
3. In the response panel, click the **Body** tab.

You will see:
```json
{
  "userId": 1,
  "id": 1,
  "title": "...",
  "body": "..."
}
```
*Thoughts to share:* "The response has `id`, `userId`, `title`, and `body` — but no `description` field. The test assertion is checking for a field that simply does not exist in this API's contract. This could be a copy-paste error in the test script, or the API was updated and the field was renamed."

**Step 3: Fix the test**
1. In the **GET /posts/1** request, click the **Tests** tab (next to Params, Authorization, Headers, Body).
2. Find the broken assertion:
```javascript
// BROKEN
pm.test("Response has description field", function () {
    pm.expect(pm.response.json().description).to.exist;
});
```
3. Fix it to check for the correct field:
```javascript
// FIXED
pm.test("Response has body field", function () {
    pm.expect(pm.response.json().body).to.exist;
});
```
4. Click **Send** again and confirm the test now passes (green ✅ in the Test Results tab).

*Thoughts to share:* "The fix is simple — the assertion was checking the wrong field name. In a real production scenario, this kind of mismatch would indicate a contract violation where either the test or the API itself needs updating."

## 5. Interview Summary Pitch
"For health check validation, I write Postman test scripts using `pm.test()` and `pm.expect()` to assert the status code is 200, the response time is under an acceptable threshold like 500ms, and that key fields exist in the JSON body. When a test fails, the Collection Runner UI highlights exactly which assertion broke and what the actual vs expected values were. This gives us a fast, repeatable way to validate that a deployment hasn't broken the API contract — and we can automate it further with Newman in CI/CD."
