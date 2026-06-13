# GitHub Actions Interview Preparation

Welcome to the GitHub Actions section of the DevOps Interview Prep repository! 

This directory contains questions and practical scenarios designed to train you on CI/CD pipelines, runner environments, and workflow security.

## Directory Structure

- **`questions_list.md`**: The master list of GitHub Actions interview questions (Theory and Practical).
- **`theory/`**: Reserved for theoretical concept explanations.
- **`practical/`**: Contains the interactive, hands-on debugging scenarios and feature demonstrations.

## The Practical Scenarios

Unlike other tools where we run localized applications, **GitHub Actions can be executed natively right here in this repository!** 

Inside each scenario folder in `practical/`, you will find a `workflow.yml` file. To demonstrate these features live during an interview prep session, you can copy the relevant `workflow.yml` into the root `.github/workflows/` directory of your repository and trigger it manually via the Actions tab (`workflow_dispatch`).

### Current Scenarios (Ordered by Difficulty)

1. **`06-pr-secret-failure`**: (Debugging) A workflow that fails to authenticate on PRs from forks due to GitHub's security boundary on secrets.
2. **`07-oidc-aws-auth`**: (Feature Demo) Demonstrates how to authenticate to AWS securely using OpenID Connect (OIDC) instead of long-lived static access keys.
3. **`08-matrix-parallelization`**: (Feature Demo) Shows how to drastically speed up sequential tests by fanning them out into parallel jobs across multiple OS and Node.js versions using `strategy: matrix`.
4. **`09-environment-setup`**: (Feature Demo) Demonstrates using `actions/setup-*` steps to guarantee a specific toolchain version (like Node v18) rather than relying on unpredictable runner defaults.
5. **`10-path-filtering`**: (Feature Demo) Shows how to save CI minutes in a monorepo by only triggering workflows when files in specific directories (e.g., `docker/`) are modified.

### Instructor Guides
Inside every scenario folder is a `guide.md` that strictly follows our 5-part template:
1. **Question**: The exact scenario prompt.
2. **Interviewer's Point of View**: Why they are asking this.
3. **Steps to Setup the Scenario**: How to launch the demo.
4. **Step-by-Step Debugging & Fix**: The exact flow, including a 1-liner "Thoughts to share" script for verbalizing your debugging process.
5. **Interview Summary Pitch**: The perfect elevator pitch answer.
