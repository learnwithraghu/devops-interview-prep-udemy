# GitHub Actions Interview Questions

## Theory Questions
1. What is a GitHub Actions workflow, and what components make up a workflow file?
2. Explain the difference between a GitHub-hosted runner and a self-hosted runner.
3. How do you pass data or artifacts between different jobs in the same workflow?
4. What are GitHub Actions secrets, and how are they used in a workflow?
5. How can you trigger a workflow on a schedule (cron) vs. a pull request?

## Practical Scenarios
6. **Scenario:** In a CI workflow that compiles the code, runs integration tests, and can also execute a heavy performance‑benchmark job, you need to start the workflow on demand and choose whether the benchmark runs. How would you expose a custom input for this choice and ensure that the benchmark job is executed only when the input requests it?
7. **Scenario:** You have 10 microservices each with an identical build-test-push workflow. How do you avoid duplicating YAML across repos? Walk me through GitHub Actions Reusable Workflows.
8. **Scenario:** Your test suite job is taking too long. How can you parallelize it using GitHub Actions matrix strategies?
9. **Scenario:** A step in your workflow requires a specific version of Node.js, but the runner uses a different default version. How do you ensure the correct version is used?
10. **Scenario:** You want a workflow to run only when changes are made to specific directories (e.g., `src/` or `app/`). How do you configure this?

## Udemy Video Name

1. Workflow Basics
2. Runner Types
3. Job Data Transfer
4. Secrets Usage
5. Schedule vs PR
6. PR Fail Mystery
7. Reusable Workflows
8. Matrix Parallelism
9. Node Version Fix
10. Path-based Triggers
