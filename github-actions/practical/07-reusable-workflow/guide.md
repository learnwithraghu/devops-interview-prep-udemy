# Scenario 07: Reusable Workflows (DRY CI/CD)

## 1. Question
"You have 10 microservices, each with their own repository. Every repo has an identical 'build → test → push image' workflow. How do you avoid copy-pasting the same YAML 10 times, and how do you ensure a single fix propagates to all of them?"

## 2. Interviewer's Point of View
The interviewer is testing whether you know about **reusable workflows** (`workflow_call`). They want to see you distinguish between reusable workflows and composite actions, and understand how inputs/secrets are passed down. A bonus point is if you mention centralising shared workflows in a dedicated org-level repository.

## 3. Steps to Setup the Scenario (Feature Demo)
This scenario is a live demo in the repository itself. It has two parts:
- A **called workflow** (`.github/workflows/07-reusable-build.yml`) that defines the reusable steps.
- A **caller workflow** (`.github/workflows/07-reusable-caller.yml`) that invokes it.

To trigger it:
1. Navigate to the **Actions** tab of this repository.
2. In the left sidebar, click **"07 Reusable – Caller Workflow"**.
3. Click **Run workflow** → pick the `main` branch → click the green **Run workflow** button.
4. Once the run starts, click on it. You will see a job called `call-reusable`. Expand it and point out how the steps defined in the *other* file ran inside this job.

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
*Thoughts to share:* "In the caller, instead of writing `run: npm test` and `run: docker build`, I simply say `uses: ./github/workflows/07-reusable-build.yml` and pass the required `inputs`. This is exactly like calling a function. All 10 of my microservice repos could point to one central workflow."

**Step 3: Inspect the job output in the Actions UI**

1. In the **Actions** tab, open the triggered run.
2. Click on the **call-reusable** job.
3. Expand each step — notice the steps come from the *called* file, not the caller.

*Thoughts to share:* "See how the steps appear here even though the caller YAML had almost no steps? That's the power of reusable workflows. When I fix a bug in the reusable file, every caller immediately gets the fix on the next run."

**Step 4: Explain the difference vs Composite Actions**

*Thoughts to share:* "A composite action is for a single *step* — like wrapping a few shell commands. A reusable workflow is for an entire *job* or *chain of jobs*. If I want to share a whole deploy pipeline, I use reusable workflows. If I want to share a single 'setup environment' step, I use a composite action."

## 5. Interview Summary Pitch
"To avoid duplicating CI/CD YAML across multiple repositories, I use GitHub Actions **reusable workflows**. I create a central `.yml` file with `on: workflow_call` and declare any inputs and secrets it accepts. Each consuming repo then calls it with a `uses:` reference instead of copying the steps. This keeps the pipeline logic in one place — a bug fix or improvement in the reusable workflow automatically benefits every caller on their next run. For sharing at the organisation level, I store these reusable workflows in a dedicated shared repository and reference them as `org/shared-workflows/.github/workflows/build.yml@main`."
