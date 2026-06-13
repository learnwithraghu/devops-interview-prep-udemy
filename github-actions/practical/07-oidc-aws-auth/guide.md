# Scenario 07: AWS OIDC Authentication

## 1. Question
"You need to deploy an application to AWS using GitHub Actions. How do you authenticate the workflow without storing long-lived AWS IAM access keys as GitHub Secrets?"

## 2. Interviewer's Point of View
The interviewer is looking for modern DevSecOps practices. Long-lived credentials are a massive security risk. They want to hear "OIDC" (OpenID Connect) and see if you understand the basic workflow of assuming a role via a JWT token.

## 3. Steps to Setup the Scenario
This is a feature demo. The workflow is already located in `.github/workflows/07-oidc-aws-auth.yml`.
1. Navigate to the **Actions** tab in your repository.
2. In the left sidebar, click on **07 OIDC AWS Auth**.
3. *Note: Since this requires real AWS infrastructure to succeed, it will fail on the `Configure AWS Credentials` step unless you actually set up OIDC in your AWS account.* You can trigger it via the **Run workflow** button to show the interface, then open the workflow file itself to discuss the code.

## 4. Step-by-Step Debugging & Fix
**Step 1: Identify the old way vs new way**
*Thoughts to share:* "Historically, we would store `AWS_ACCESS_KEY_ID` and `AWS_SECRET_ACCESS_KEY` in GitHub Secrets. But those are long-lived and require manual rotation. If they leak, it's a huge breach."

**Step 2: Explain the OIDC solution**
*Thoughts to share:* "Instead, I will use OpenID Connect (OIDC). First, I need to create an IAM Identity Provider in AWS that trusts GitHub's OIDC URL. Then, I create an IAM Role that this provider can assume, strictly scoped to this specific repository and branch."

**Step 3: Update the Workflow**
*Thoughts to share:* "In the workflow YAML, I must add `permissions: id-token: write` so GitHub Actions can generate the JWT. Then, I use the `configure-aws-credentials` action and pass the `role-to-assume` ARN. AWS verifies the JWT and grants temporary, short-lived STS credentials for the deployment."

## 5. Interview Summary Pitch
"To securely authenticate GitHub Actions with AWS, I would use OpenID Connect (OIDC) instead of storing long-lived IAM access keys. First, I would configure AWS to trust GitHub's OIDC provider and create an IAM Role that restricts access to a specific repository and branch. In the workflow, I would set `permissions: id-token: write` to allow GitHub to generate a JWT token. I would then use the `configure-aws-credentials` action to pass this token to AWS, which verifies the identity and returns temporary, short-lived session credentials. This completely eliminates the risk of leaked static keys."
