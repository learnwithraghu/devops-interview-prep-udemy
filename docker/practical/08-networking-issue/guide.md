# Scenario 08: Container Networking Issue

## 1. Question
"We have two containers, an API and a Redis cache, but the API container is logging 'Connection Refused' or 'Name Not Resolved'. How do you debug container networking issues?"

## 2. Interviewer's Point of View
The interviewer wants to see if you understand Docker networks and internal DNS resolution. They are looking to see if you instinctively check the network attachments (`docker inspect`) rather than just assuming the application code is broken or Redis is down.

## 3. Steps to Setup the Scenario
Run the following commands to start the broken environment:
```bash
cd docker/practical/08-networking-issue
docker-compose up -d
```
Check the API logs to observe the connection error:
```bash
docker logs 08-networking-issue-api-1
```
*You will see `Redis Client Error Error: getaddrinfo ENOTFOUND redis`.*

## 4. Step-by-Step Debugging & Fix
**Step 1: Check if the containers are running**
```bash
docker ps
```
*Thoughts to share:* "First, I'll run `docker ps` to verify both the API and Redis containers are actually up and haven't crashed."

**Step 2: Inspect the networks**
```bash
docker inspect 08-networking-issue-api-1 | grep -A 5 "Networks"
docker inspect 08-networking-issue-redis-1 | grep -A 5 "Networks"
```
*Thoughts to share:* "Since they are both running, the issue is likely networking. I'll use `docker inspect` to see which Docker networks they are attached to. Ah, I see the API is on `api_network` and Redis is on `db_network`."

**Step 3: Test connectivity**
```bash
docker exec -it 08-networking-issue-api-1 sh
ping redis
```
*Thoughts to share:* "To prove it's a network isolation issue, I'll execute into the API container and try to ping Redis. As expected, it fails because Docker's embedded DNS only resolves hostnames for containers that share the same custom bridge network."

**Step 4: The Fix**
*Thoughts to share:* "I'll update the `docker-compose.yml` so that both containers share at least one network, like `api_network`."

```diff
   redis:
     image: redis:alpine
     networks:
-      - db_network
+      - api_network
```
Apply the fix:
```bash
docker-compose up -d
```

## 5. Interview Summary Pitch
"To debug a 'Connection Refused' or 'Name Not Resolved' issue between two containers, I would first verify that both containers are actually running. Next, I would run `docker inspect` on both containers to check their assigned networks. If they are on different custom bridge networks, Docker's internal DNS will not resolve their hostnames. I would also execute into the failing container and attempt to `ping` or `curl` the target container to confirm the network boundary. To fix it, I would update the Docker Compose file to ensure both containers are attached to the same network, allowing seamless communication."
