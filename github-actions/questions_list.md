# GitHub Actions Interview Questions

## Theory Questions
1. What is a GitHub Actions workflow, and what components make up a workflow file?
2. Explain the difference between a GitHub-hosted runner and a self-hosted runner.
3. How do you pass data or artifacts between different jobs in the same workflow?
4. What are GitHub Actions secrets, and how are they used in a workflow?
5. How can you trigger a workflow on a schedule (cron) vs. a pull request?

## Practical Scenarios
6. **Scenario:** A workflow triggered by a Pull Request fails, but works fine on the main branch. What could be the cause?
7. **Scenario:** You need to deploy an application to AWS using GitHub Actions. How do you authenticate without storing long-lived AWS access keys as secrets? (Hint: OIDC)
8. **Scenario:** Your test suite job is taking too long. How can you parallelize it using GitHub Actions matrix strategies?
9. **Scenario:** A step in your workflow requires a specific version of Node.js, but the runner uses a different default version. How do you ensure the correct version is used?
10. **Scenario:** You want a workflow to run only when changes are made to specific directories (e.g., `src/` or `app/`). How do you configure this?
