# Scenario 09: Newman CI Gate (Broken Exit Code)

## 1. Question
"You want to add a Postman collection run as a quality gate in your deployment pipeline — if any API test fails, the deployment must stop. How do you implement this using Newman, and what is the most common mistake teams make when doing this?"

## 2. Interviewer's Point of View
The interviewer is testing whether you know that Newman (the CLI runner for Postman) returns a **non-zero exit code** when tests fail — and that a CI pipeline script must be written to actually check that exit code. The most common mistake is ignoring the exit code, which means the gate doesn't actually gate anything.

## 3. Steps to Setup the Scenario

**Prerequisites — install Newman:**
```bash
npm install -g newman
```
Verify it is installed:
```bash
newman --version
```

**Import the collection into Postman (optional for viewing):**
1. Open **Postman** → **Import** → drag `collection.json`.

**Trigger the broken state (the gate that doesn't gate):**
```bash
cd postman/practical/09-newman-ci-gate
bash run.sh
```

Watch the output. Newman will report test **failures**, but the script will still print "✅ Deployment proceeding..." at the end. This is the bug — the CI gate is not actually stopping anything.

**UI Tip (Newman terminal output):** Newman prints a summary table at the end. Look for the row that says `failed`. Even when it's non-zero, the broken `run.sh` ignores it.

## 4. Step-by-Step Debugging

**Step 1: Run the script and observe the output**
```bash
bash run.sh
```
The Newman output will end with something like:
```
┌─────────────────────────┬──────────┬──────────┐
│                         │ executed │   failed │
├─────────────────────────┼──────────┼──────────┤
│              iterations │        1 │        0 │
│                requests │        2 │        0 │
│            test-scripts │        2 │        0 │
│      prerequest-scripts │        0 │        0 │
│              assertions │        4 │        1 │   ← failure here
├─────────────────────────┼──────────┼──────────┤
│ total run duration: ...                       │
└───────────────────────────────────────────────┘
```
And then:
```
✅ Deployment proceeding...
```

*Thoughts to share:* "There are test failures in the Newman summary, but the script continued to the next step and said deployment is proceeding. The CI gate is broken. Let me look at the `run.sh` script."

**Step 2: Inspect the run.sh script**
```bash
cat run.sh
```
You will see:
```bash
#!/bin/bash
newman run collection.json
echo "✅ Deployment proceeding..."
```

*Thoughts to share:* "The problem is on line 3. The script runs Newman and then immediately prints the success message — it never checks whether Newman exited with an error. In shell scripting, a command that fails returns a non-zero exit code (`$?`). If we don't check it, the script just carries on."

**Step 3: Check Newman's exit code manually**
```bash
newman run collection.json
echo "Newman exit code: $?"
```
When tests fail, you will see `Newman exit code: 1`.

*Thoughts to share:* "Newman returned exit code 1, which means there were failures. The fix is to make the script stop as soon as Newman exits with a non-zero code."

**Step 4: Fix the run.sh script**

Open `run.sh` and apply the fix:
```bash
#!/bin/bash
set -e   # Exit the script immediately if any command fails

newman run collection.json

echo "✅ All API tests passed. Deployment proceeding..."
```

Now run it again:
```bash
bash run.sh
```

This time the script will exit with a non-zero code as soon as Newman reports failures — the deployment step never runs.

*Thoughts to share:* "The `set -e` flag at the top of the script tells bash to exit immediately if any command returns a non-zero exit code. This is the simplest and most reliable way to honour Newman's failure signal in a CI/CD pipeline."

## 5. Interview Summary Pitch
"To use Postman as a CI/CD quality gate, I export the collection and run it via Newman — the Postman CLI runner. Newman returns a non-zero exit code when any test assertion fails. The most common mistake I see is that the pipeline script ignores that exit code, which means the 'gate' doesn't actually block anything. The fix is to add `set -e` to the shell script, or explicitly check `$?` after the Newman command. In a proper CI pipeline like GitHub Actions, I would also use the `--reporters cli,junit` flag to get a JUnit XML report that the CI system can parse and display as a test summary."
