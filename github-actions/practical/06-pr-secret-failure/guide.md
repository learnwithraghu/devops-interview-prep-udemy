# Scenario 06: PR Secret Failure

## 1. Question
"A workflow triggered by a Pull Request fails to authenticate to an external API, but the exact same code works fine when pushed directly to the main branch. What could be the cause, and how do you resolve it safely?"

## 2. Interviewer's Point of View
The interviewer wants to test your understanding of GitHub Actions security models, specifically that secrets are not passed to workflows triggered by pull requests from *forks* by default. They also want to see if you are aware of the dangerous `pull_request_target` trigger and why you shouldn't use it carelessly.

## 3. Steps to Setup the Scenario
1. Go to your repository **Settings** -> **Secrets and variables** -> **Actions**.
2. Click **New repository secret**. Name it `MY_API_TOKEN` and give it any dummy value (e.g., `12345`).
3. Push these changes to your repository so the workflow is active.
4. To demonstrate the success, navigate to the **Actions** tab.
5. In the left sidebar, click on **06 PR Secret Failure**.
6. On the right side, click the **Run workflow** dropdown, select the `main` branch, and click the green **Run workflow** button.
7. Click on the run that appears, click the `test` job, and show that the secret is available.
8. Then, discuss the theoretical concept of a fork PR failing.

## 4. Step-by-Step Debugging & Fix
**Step 1: Check workflow logs in the UI**
Navigate to the **Actions** tab, select the failed workflow run, and click on the `test` job on the left. Expand the `Attempt to use Secret` step to view the output.
*Thoughts to share:* "First, I'd review the workflow execution logs in the Actions UI. I see it's failing because the environment variable populated by the secret is empty. This tells me the workflow does not have access to the repository secret in this context."

**Step 2: Check the trigger event**
*Thoughts to share:* "Next, I'll check what triggered this run. It was triggered by a `pull_request` from a fork. By default, GitHub prevents secrets from being exposed to pull requests from forks to stop malicious actors from extracting secrets via malicious code changes."

**Step 3: Discuss the fix (No code diff needed, process discussion)**
*Thoughts to share:* "To fix this, we should NOT blindly change the trigger to `pull_request_target`, as that runs the workflow in the context of the base repository and exposes secrets to unreviewed code. Instead, we should either run tests that don't require secrets on PRs, use mocked APIs for testing, or require a maintainer to approve workflow runs for external forks."

## 5. Interview Summary Pitch
"If a workflow fails on a PR but works on `main` due to an authentication error, it's almost certainly because GitHub prevents repository secrets from being passed to workflows triggered by pull requests from forks. This is a critical security feature. To resolve it safely, I would recommend mocking the external dependency for PR tests so secrets aren't needed. I would strongly advise against simply changing the trigger to `pull_request_target` unless the workflow explicitly requires maintainer approval first, as that would expose our production secrets to untrusted code."
