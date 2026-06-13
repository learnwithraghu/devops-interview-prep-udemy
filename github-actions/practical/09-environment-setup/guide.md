# Scenario 09: Environment Setup

## 1. Question
"A step in your workflow requires a specific version of Node.js (e.g., v18), but the GitHub-hosted runner uses a different default version, causing the build to fail. How do you ensure the correct version is always used?"

## 2. Interviewer's Point of View
The interviewer wants to ensure you don't rely on the pre-installed software on runners, which can change without notice and break builds. They are testing your knowledge of the `actions/setup-*` ecosystem.

## 3. Steps to Setup the Scenario
This is a feature demo. The workflow is already located in `.github/workflows/09-environment-setup.yml`.
1. Navigate to the **Actions** tab in your repository.
2. In the left sidebar, click on **09 Environment Setup**.
3. Click the **Run workflow** dropdown and click the green **Run workflow** button.
4. Click on the new workflow run that appears, then click on the `build` job on the left.
5. Expand the `Setup Specific Node Version` step in the logs to show the students how the action explicitly downloads and configures the exact version specified.

## 4. Step-by-Step Debugging & Fix
**Step 1: Explain the risk of default runner tools**
*Thoughts to share:* "GitHub-hosted runners come with lots of software pre-installed, but relying on the default `node` or `python` binary is risky because GitHub periodically updates these runner images. Our build might break randomly if the default version upgrades."

**Step 2: Introduce the Setup Actions**
*Thoughts to share:* "To guarantee reproducible builds, we must explicitly declare our toolchains. We can use official actions like `actions/setup-node`, `actions/setup-python`, or `actions/setup-go`."

**Step 3: Best Practices (`.nvmrc` and Caching)**
*Thoughts to share:* "Instead of hardcoding '18.x' in the YAML, a best practice is to point the setup action to a `.nvmrc` or `package.json` file. This ensures local dev and CI are always strictly synced. Additionally, these setup actions have built-in dependency caching which speeds up subsequent runs."

## 5. Interview Summary Pitch
"To ensure consistent and reproducible builds, we should never rely on the default software pre-installed on GitHub-hosted runners, as these images are periodically updated and can break our pipelines. Instead, I use official setup actions like `actions/setup-node`. I would configure the action to read the required version from a version-control file, such as `.nvmrc`, ensuring exact parity between local development environments and CI. Finally, I would leverage the built-in caching parameters of these setup actions to speed up dependency installation."
