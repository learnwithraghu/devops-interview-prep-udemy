# Scenario 09: Secure Credential Passing

## 1. Question
"Currently, our database password is being passed as a plain text environment variable in the Docker Compose file, which poses a security risk. How do you securely pass and manage credentials in Docker?"

## 2. Interviewer's Point of View
The interviewer wants to see if you understand the risks of environment variables in Docker (exposure via `docker inspect`) and whether you know the appropriate secure alternatives based on the environment (e.g., `.env` files for local dev, Docker Secrets or Kubernetes Secrets for production).

## 3. Steps to Setup the Scenario
Run the following commands to start the broken environment:
```bash
cd docker/practical/09-secure-credentials
docker-compose up -d
```

## 4. Step-by-Step Debugging & Fix
**Step 1: Identify the vulnerability**
Look at the `docker-compose.yml`. The database password is hardcoded as plain text in the `environment` block.
*Thoughts to share:* "I see the password is hardcoded directly in the compose file. This is a bad practice because anyone with read access to the repo can see the production secret."

**Step 2: Demonstrate the risk**
```bash
docker inspect 09-secure-credentials-api-1 | grep -i pass
```
*Thoughts to share:* "Even worse, if I run `docker inspect` on the running container, the plain text password is fully exposed in the environment variables block to anyone with access to the Docker daemon."

**Step 3: The Fix**
*Thoughts to share:* "For a local docker-compose setup, I will move this secret into a `.env` file that is excluded via `.gitignore`. For production Docker Swarm, I would use Docker Secrets."

1. Create a `.env` file:
```bash
echo "DB_PASSWORD=SuperSecretP@ssw0rd!" > .env
```
2. Edit `docker-compose.yml` to remove the hardcoded value:
```diff
     environment:
-      - DB_PASSWORD=SuperSecretP@ssw0rd!
+      - DB_PASSWORD=${DB_PASSWORD}
```
3. Ensure `.env` is in your `.gitignore` file.
Apply the fix:
```bash
docker-compose up -d
```

## 5. Interview Summary Pitch
"To pass sensitive credentials securely, I strongly avoid hardcoding them in Dockerfiles or Docker Compose files. While environment variables are convenient, passing them directly in plain text leaves them vulnerable to extraction via `docker inspect` or through child processes. Locally, I would use an external `.env` file that is strictly ignored by source control. In a production orchestration environment like Docker Swarm or Kubernetes, I would use native Secrets management. This ensures secrets are encrypted at rest, only mounted in memory (tmpfs) on the specific nodes running the application, and never exposed in the image metadata."
