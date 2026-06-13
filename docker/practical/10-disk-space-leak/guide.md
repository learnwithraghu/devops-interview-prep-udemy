# Scenario 10: Host Disk Space Exhaustion

## 1. Question
"The host machine's disk space is filling up rapidly, causing alerts. You suspect Docker is the culprit. How do you find the root cause and permanently prevent it?"

## 2. Interviewer's Point of View
The interviewer wants to see if you know how to audit Docker disk usage (`docker system df`) and whether you understand the ephemeral nature of container filesystems. They are testing if you know the difference between logging to the writable container layer vs. logging to stdout or a mounted volume.

## 3. Steps to Setup the Scenario
Run the following commands to start the environment:
```bash
cd docker/practical/10-disk-space-leak
docker-compose up -d
```
Generate some massive disk writes inside the container's writable layer:
```bash
for i in {1..5}; do curl http://localhost:3000/log-spam; done
```

## 4. Step-by-Step Debugging & Fix
**Step 1: Verify disk usage across Docker**
```bash
docker system df
```
*Thoughts to share:* "First, I'll run `docker system df` to see if the disk space is being consumed by images, volumes, or container writable layers. It looks like the 'Containers' size is unusually high."

**Step 2: Find the offending container**
```bash
docker ps -q | xargs -I {} docker inspect -s {} | grep -E "Name|SizeRw"
```
*Thoughts to share:* "Now I need to find *which* container is bloating. I'll inspect the `SizeRw` (Size Read/Write layer) for all running containers. Ah, the API container is huge."

**Step 3: Investigate inside the container**
```bash
docker exec -it 10-disk-space-leak-api-1 sh
du -sh /* 2>/dev/null | grep -v "proc" | sort -rh | head -n 5
```
*Thoughts to share:* "I'll exec into the container and use `du -sh` to find the large files. I see a massive `/app/debug.log` file being written directly to the container layer."

**Step 4: The Fix**
*Thoughts to share:* "Writing large files to the container's writable layer is an anti-pattern. If these are application logs, the code should be updated to write to `stdout` so Docker's log driver can handle rotation. If it's persistent data, I need to mount a volume."

```diff
   api:
     build: 
       context: ../shared-app
     ports:
       - "3000:3000"
+    volumes:
+      - app_data:/app
+
+volumes:
+  app_data:
```
Apply the fix:
```bash
docker-compose up -d
```

## 5. Interview Summary Pitch
"If a host is rapidly running out of disk space, my first step is to run `docker system df` to determine if images, containers, or volumes are the culprit. If a container's writable layer is swelling, it usually means the application is writing logs or data directly to its local filesystem instead of stdout or a volume. I would find the specific container by inspecting `SizeRw` and then execute into it to find the large files using `du -sh`. To fix it, I would either refactor the app to stream logs to stdout so the Docker logging driver can handle log rotation, or I would mount an external Docker volume if the data is meant to be persistent."
