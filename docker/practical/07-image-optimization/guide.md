# Scenario 07: Dockerfile Optimization

## 1. Question
"Our CI pipeline is slow because the Docker image takes a long time to build and is over 1GB in size. Walk me through how you would optimize this Dockerfile."

## 2. Interviewer's Point of View
The interviewer wants to see if you understand how Docker's layer caching works. They are testing your knowledge of base images (Alpine/slim vs. full OS) and the order of operations in a Dockerfile (copying `package.json` before the full source code to cache `npm install`).

## 3. Steps to Setup the Scenario
Navigate to the directory and build the bad image:
```bash
cd docker/practical/07-image-optimization
docker build -t app:bad -f Dockerfile.bad .
```
Notice how long it takes and check the final image size:
```bash
docker images | grep app
```

## 4. Step-by-Step Debugging
**Step 1: Check image layers and size**
```bash
docker history app:bad
```
*Thoughts to share:* "Before rewriting anything, I want to see exactly which layers are consuming the most space using `docker history`. It looks like the base Ubuntu image and the `apt-get` installations are massive."

**Step 2: Identify the anti-patterns in the Dockerfile**
*Thoughts to share:* "Looking at the Dockerfile, I see we are using a full Ubuntu OS, installing unnecessary tools like `vim`, and copying the entire source code before running `npm install`, which breaks the cache on every code change."

**Step 3: The Fix (Refactoring)**
*Thoughts to share:* "I'll swap this out for an `alpine` node image, which is much smaller. Then, I'll copy *only* the `package.json` first, run `npm install`, and *then* copy the rest of the code. That way, our dependencies are cached unless `package.json` actually changes."

Create an optimized `Dockerfile`:
```dockerfile
# Optimized Dockerfile
FROM node:18-alpine

WORKDIR /app

# Only copy package.json first to leverage Docker layer caching
COPY package*.json ./
RUN npm install --production

# Copy the rest of the application
COPY src/ ./src/

# Use a non-root user for security
USER node

CMD ["node", "src/app.js"]
```

Build and compare sizes:
```bash
docker build -t app:good .
docker images | grep app
```

## 5. Interview Summary Pitch
"To optimize a bloated Dockerfile, I would first run `docker history` to identify which layers are taking up the most space. I would replace the heavy base OS image with a minimal version, such as Alpine Linux or a distroless image. Then, I would structure the `COPY` instructions to take advantage of Docker layer caching—copying `package.json` and installing dependencies *before* copying the application code. I would also implement a `.dockerignore` file to exclude local artifacts, and if the build process is complex, I would use multi-stage builds to keep the final production image strictly limited to the runtime and compiled code."
