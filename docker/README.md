# Docker Interview Preparation

Welcome to the Docker section of the DevOps Interview Prep repository! 

This directory contains a comprehensive question bank and hands-on debugging scenarios to test and train practical Docker skills.

## Directory Structure

- **`questions_list.md`**: The master list of Docker interview questions, split into Theory and Practical Scenarios.
- **`theory/`**: Reserved for deep dives and theoretical concept explanations.
- **`practical/`**: Contains the interactive, hands-on debugging scenarios.

## The Practical Scenarios

The `practical/` directory contains scenarios designed to mimic real-world production outages and misconfigurations. 

### The `shared-app` Testbed
Inside `practical/shared-app`, you will find a simple Node.js + Redis application. **This is the unified codebase used by all Docker scenarios.** 
Instead of writing 5 different applications, we use this single app. It has specific "flaws" built into its code (like a memory leak on the `/leak` endpoint, or rapid disk writing on the `/log-spam` endpoint) that allow us to trigger the exact bugs needed for the scenarios just by altering the `docker-compose.yml` or `Dockerfile`.

### Current Scenarios (Ordered by Difficulty)
Each scenario resides in its own folder and contains a specifically broken configuration pointing to the `shared-app`:

1. **`06-oom-killed`**: The container is crashing with Exit Code 137. Focuses on `docker inspect` and resource constraints.
2. **`07-image-optimization`**: A massively bloated `Dockerfile.bad`. Focuses on `docker history`, layer caching, and multi-stage builds.
3. **`08-networking-issue`**: Containers failing to communicate due to custom bridge network isolation. Focuses on Docker internal DNS and network debugging.
4. **`09-secure-credentials`**: A database password exposed in plain text. Focuses on understanding the risks of environment variables and mitigating them via `.env` files or Secrets.
5. **`10-disk-space-leak`**: The host disk is filling up rapidly. Focuses on `docker system df` and identifying anti-patterns like writing logs directly to the container's writable layer instead of `stdout`.

### Instructor Guides
Inside every scenario folder, there is a `guide.md`. This is the instructor's script. It contains:
1. The Question.
2. The Interviewer's Point of View.
3. The Setup commands.
4. Step-by-Step Debugging (with a script of what to say out loud to "speak your mind").
5. The final "Interview Summary Pitch" summarizing the answer perfectly.
