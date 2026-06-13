# Scenario 06: Container Exiting with Code 137 (OOMKilled)

## 1. Question
"Our application container periodically crashes and exits with code 137, but there are no application errors in the logs. How do you troubleshoot this?"

## 2. Interviewer's Point of View
The interviewer is looking to see if you immediately recognize that exit code 137 is almost always related to an Out Of Memory (OOM) event. They want to see your methodology: do you check the Docker daemon/container state first (`docker ps`, `docker inspect`) before diving into application code or assuming a different error?

## 3. Steps to Setup the Scenario
Run the following commands to start the broken environment:
```bash
docker-compose up -d
curl http://localhost:3000/leak
```
Watch the container crash shortly after the curl request.

## 4. Step-by-Step Debugging
**Step 1: Check the container status**
```bash
docker ps -a
```
*Thoughts to share:* "First, I'd check the container's exit code to understand why it stopped using `docker ps -a`. Ah, exit code 137 usually means it was killed by the OOM killer."

**Step 2: Inspect the container for root cause**
```bash
docker inspect <container_id_or_name> | grep -i "oom"
```
*Thoughts to share:* "To confirm my suspicion, I'll run `docker inspect` and check the `OOMKilled` flag. Yes, it's set to true, so the kernel definitely stepped in."

**Step 3: Check memory limits and apply the fix**
*Thoughts to share:* "Now I need to check if we imposed a strict memory limit on the container that's too low, or if the app actually has a memory leak. Let's look at the `docker-compose.yml`."

Look at the `docker-compose.yml` file. Notice the strict memory limit. To fix this, increase the memory limit:
```diff
-        limits:
-          memory: 50M
+        limits:
+          memory: 512M
```
Apply the fix:
```bash
docker-compose up -d
```

## 5. Interview Summary Pitch
"To troubleshoot a container crashing repeatedly without application errors, I would first run `docker ps -a` to check the exit code. If I see exit code 137, I immediately suspect an Out Of Memory (OOM) issue. I would verify this by running `docker inspect` on the container and looking for the `OOMKilled: true` flag. Once confirmed, I would review the container's resource limits in the orchestration file (like `docker-compose.yml` or Kubernetes manifests) and consult with the development team to determine if the application has a memory leak or simply requires a higher memory limit."
