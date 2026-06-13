# Agent Instructions for DevOps Interview Prep Repository

Welcome! If you are an AI agent or a language model operating in this repository, this document outlines the core vision, architecture, and strict conventions of this project. **Please read and adhere to these rules before creating or modifying any content.**

## 1. Project Vision
This repository is a comprehensive, hands-on interview preparation guide for DevOps engineers. It covers multiple technologies (Kubernetes, Docker, Terraform, AWS, Jenkins, GitHub Actions, Linux) and splits the learning into two distinct phases: **Theory** and **Practical Scenarios**. 

The goal of the practical scenarios is to simulate real-world, broken environments that the student must troubleshoot and fix live, mirroring a technical interview.

## 2. Directory Structure
The repository is organized strictly by technology. Every technology folder MUST follow this exact structure:

```text
[technology-name]/
  ├── questions_list.md      # The master list of questions
  ├── theory/                # (Optional) Deep dives for theoretical questions
  └── practical/             # The hands-on debugging scenarios
      ├── shared-app/        # (Optional) A single, unified app codebase used by all scenarios
      ├── 01-scenario-name/  # Scenario folder
      │   ├── guide.md       # The instructor/debugging guide
      │   └── [config files] # The broken manifest, docker-compose.yml, etc.
      └── 02-scenario-name/
```

## 3. Formatting Conventions

### A. The `questions_list.md`
This file acts as the question bank for the technology. It must ALWAYS be divided into two sections:
1. `## Theory Questions` (Usually questions 1-5)
2. `## Practical Scenarios` (Usually questions 6-10)

The practical scenarios should be ordered by increasing difficulty (e.g., Beginner to Advanced).

### B. Practical Scenario Folders
- Every scenario must have its own dedicated folder inside `practical/`.
- The folder name should be numbered and descriptive (e.g., `06-oom-killed`).
- The folder must contain the **broken state** of the application (e.g., a bad `Dockerfile`, a misconfigured `docker-compose.yml`, or a failing Kubernetes `deployment.yaml`).

### C. The `guide.md` (Instructor Guide)
Every practical scenario MUST have a `guide.md`. This file is the script for the instructor. It must follow this exact 5-part structure:

1. **Question:** The exact interview question being asked.
2. **Interviewer's Point of View:** What the interviewer is looking for, the hidden traps, and the core concepts being tested.
3. **Steps to Setup the Scenario:** Exact CLI commands to launch the broken state.
4. **Step-by-Step Debugging & Fix:** How to investigate the issue like a real engineer. Do NOT jump straight to the fix. Provide the commands (`docker ps`, `kubectl describe`, etc.). *Crucially*, include 1-liner "Thoughts to share" for each step, serving as a script for what the candidate should say out loud to "speak their mind" while debugging. End this section with the exact fix/YAML diff needed.
5. **Interview Summary Pitch:** A polished, concise paragraph summarizing the troubleshooting flow. This is how the candidate should verbally explain their logic to an interviewer without just reciting literal CLI commands.

## 4. Rules for Creating New Content
- **Never give away the answer in the initial manifest:** The broken configuration files must look like standard, realistic files. Do not add comments like `# THIS IS BROKEN` to the code.
- **Keep it realistic:** Scenarios should mimic real production outages (e.g., OOM kills, network isolation, disk space exhaustion, misconfigured load balancers).
- **Emphasize the "Why":** When writing the `guide.md`, ensure the debugging steps teach the user *why* they are running a specific command.
- **Reuse where possible:** Use a `shared-app/` directory for the base application code if multiple scenarios can be built around the same stack. This prevents redundant code and keeps the focus on the DevOps configurations.
