# Scenario 10: Path Filtering

## 1. Question
"You are working in a monorepo. How do you configure a workflow to run *only* when changes are made to specific directories (e.g., `src/` or `app/`), thereby saving CI minutes on irrelevant changes like documentation updates?"

## 2. Interviewer's Point of View
The interviewer is testing your ability to optimize CI/CD pipelines. They want to see if you understand `paths` and `paths-ignore` triggers, which are essential for managing large codebases and reducing compute costs.

## 3. Steps to Setup the Scenario
This is a feature demo. The workflow is already located in `.github/workflows/10-path-filtering.yml`.
1. This workflow triggers automatically on a `push` event, but *only* if files in the `docker/` directory change.
2. Make a trivial change to any file inside the `docker/` folder and commit/push to `main`.
3. Navigate to the **Actions** tab in GitHub. You will see the **10 Path Filtering** workflow running automatically.
4. Next, make a trivial change to a file outside the `docker/` folder (like the root `README.md`) and push.
5. Navigate to the **Actions** tab again. Point out to the students that the workflow did **not** run this time, saving CI minutes!

## 4. Step-by-Step Debugging & Fix
**Step 1: Identify the waste**
*Thoughts to share:* "If we trigger a full heavy Docker build every time someone fixes a typo in `README.md`, we are wasting CI minutes and blocking the deployment queue."

**Step 2: Introduce Workflow-Level Filtering**
*Thoughts to share:* "We can fix this at the workflow trigger level. Under the `on: push:` block, we can specify a `paths:` array. The workflow will only trigger if at least one modified file matches the glob patterns."

**Step 3: Discuss `paths-ignore`**
*Thoughts to share:* "Alternatively, if we want it to run for almost everything *except* docs, we can use `paths-ignore: ['docs/**']`. However, you cannot mix `paths` and `paths-ignore` in the same trigger for the same event."

## 5. Interview Summary Pitch
"To optimize CI runs in a monorepo, I use GitHub Actions path filtering. By adding a `paths` or `paths-ignore` array to the `on: push` or `pull_request` triggers, I can restrict the workflow to execute only when relevant source code is modified—for instance, only triggering a container build if files inside the `src/` directory change. This drastically reduces wasted CI minutes on irrelevant commits like documentation updates. For more complex logic, like skipping individual jobs within the same workflow based on paths, I would use community actions like `dorny/paths-filter`."
