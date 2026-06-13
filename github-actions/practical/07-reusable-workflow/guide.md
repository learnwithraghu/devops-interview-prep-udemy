# Scenario 07: Reusable Workflows (DRY CI/CD)

## 1. Question
"You have 10 microservices, each with their own repository. Every repo has an identical 'build → test → push image' workflow. How do you avoid copy-pasting the same YAML 10 times, and how do you ensure a single fix propagates to all of them?"

## 2. Interviewer's Point of View
The interviewer is testing whether you know about **reusable workflows** (`workflow_call`). They want to see you distinguish between reusable workflows and composite actions, and understand how inputs/secrets are passed down. A bonus point is if you mention centralising shared workflows in a dedicated org-level repository.

## 3. Steps to Setup the Scenario (Feature Demo)
This scenario is a live demo in the repository itself. It has two parts:
- A **called workflow** (`.github/workflows/07-reusable-build.yml`) that defines the reusable steps.
- A **caller workflow** (`.github/workflows/07-reusable-caller.yml`) that invokes it **3 times in parallel**, simulating 3 different microservices (`auth-service`, `payment-service`, `notification-service`).

To trigger it:
1. Navigate to the **Actions** tab of this repository.
2. In the left sidebar, click **"07 Reusable – Caller Workflow"**.
3. Click **Run workflow** → pick the `main` branch → click the green **Run workflow** button.
4. Once the run starts, click on it. You will see **3 parallel jobs** appear simultaneously — `Build auth-service`, `Build payment-service`, and `Build notification-service`. Each one is powered by the *same* reusable workflow file, just with different inputs.
5. Click any one of the 3 jobs and expand the steps to show the steps come entirely from the called workflow.

**UI Tip (CLI):** You can also watch the trigger happen in real time:
```bash
# List recent workflow runs (requires GitHub CLI)
gh run list --limit 5
```

## 4. Step-by-Step Walkthrough

**Step 1: Open the called (reusable) workflow file**

Navigate to `.github/workflows/07-reusable-build.yml` in GitHub's file browser, or locally:
```bash
cat .github/workflows/07-reusable-build.yml
```
*Thoughts to share:* "The key thing to notice is the trigger at the top — `on: workflow_call`. This means this file can **never** run by itself. It can only be triggered by another workflow calling it. It also declares `inputs` and `secrets` so the caller can pass values in."

**Step 2: Open the caller workflow file**

```bash
cat .github/workflows/07-reusable-caller.yml
```
*Thoughts to share:* "Notice there are 3 jobs here — `auth-service`, `payment-service`, and `notification-service`. Each one uses the exact same `uses:` reference pointing to the reusable build workflow. The only difference is the `inputs` — node version and the service label. In a real organisation, these 3 jobs would live in 3 separate repositories, each calling the shared workflow from a central `org/shared-workflows` repo."

**Step 3: Inspect the parallel jobs in the Actions UI**

1. In the **Actions** tab, open the triggered run.
2. Notice all **3 jobs run at the same time** (parallel by default — no `needs:` between them). Point this out to the interviewer — this mimics 3 teams deploying their services independently.
3. Click into any job (e.g. `Build payment-service (Node 20)`) and expand the steps.
4. Point out: the steps come entirely from `.github/workflows/07-reusable-build.yml` even though the caller job had almost no content.

*Thoughts to share:* "See how 3 different services are building in parallel, each on a different Node.js version, all using the same reusable workflow? When the platform team fixes a bug in the reusable file — say they add a security scan step — every one of those 3 services automatically gets it on their next run, with zero changes to their own caller files."

**Step 4: Explain the difference vs Composite Actions**

*Thoughts to share:* "A composite action is for a single *step* — like wrapping a few shell commands. A reusable workflow is for an entire *job* or *chain of jobs*. If I want to share a whole deploy pipeline, I use reusable workflows. If I want to share a single 'setup environment' step, I use a composite action."

## 5. Interview Summary Pitch
"To avoid duplicating CI/CD YAML across multiple repositories, I use GitHub Actions **reusable workflows**. I create a central `.yml` file with `on: workflow_call` and declare any inputs and secrets it accepts. Each consuming repo then calls it with a `uses:` reference instead of copying the steps. This keeps the pipeline logic in one place — a bug fix or improvement in the reusable workflow automatically benefits every caller on their next run. For sharing at the organisation level, I store these reusable workflows in a dedicated shared repository and reference them as `org/shared-workflows/.github/workflows/build.yml@main`."
