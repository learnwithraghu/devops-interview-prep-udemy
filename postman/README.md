# Postman — DevOps / SRE Interview Prep

This folder covers **Postman from the perspective of a DevOps or SRE engineer** — not just manual API exploration, but as a professional tool for health monitoring, environment management, token automation, CI/CD gating, and contract testing.

## Why Postman Matters for DevOps/SRE Interviews

| Use Case | Why It Matters |
|---|---|
| Health Check Validation | Quickly verify that deployed services respond correctly |
| Environment Management | Manage dev/staging/prod configs without code changes |
| Auth Token Automation | Automate token refresh so pipelines don't break on expiry |
| CI/CD Gating with Newman | Block a deployment if any API contract test fails |
| Contract Testing | Catch breaking API changes before they reach production |

## Prerequisites

- **Postman** — already installed on your machine
- **Newman** (for scenario 09 only) — install once:
  ```bash
  npm install -g newman
  ```

## Folder Structure

```
postman/
  README.md
  questions_list.md
  practical/
    06-health-check-monitor/
      guide.md
      collection.json          ← Import into Postman
    07-env-variable-mismatch/
      guide.md
      collection.json
      dev-env.json             ← Import as Environment
      staging-env.json         ← Import as Environment (broken)
    08-auth-token-expiry/
      guide.md
      collection.json
    09-newman-ci-gate/
      guide.md
      collection.json
      run.sh                   ← The broken CI gate script
    10-contract-testing/
      guide.md
      collection.json
```

## How to Import a Collection

1. Open **Postman**
2. Click **Import** (top left)
3. Drag the `collection.json` file from the scenario folder
4. For environment files: **Environments** tab → **Import**

## Difficulty Guide

| Scenario | Topic | Stars |
|---|---|---|
| 06-health-check-monitor | Running test assertions on API responses | ⭐ |
| 07-env-variable-mismatch | Debugging broken environment variables | ⭐ |
| 08-auth-token-expiry | Pre-request script for token automation | ⭐⭐ |
| 09-newman-ci-gate | Newman CLI + CI/CD exit code gating | ⭐⭐ |
| 10-contract-testing | Detecting breaking API changes via schema tests | ⭐⭐⭐ |
