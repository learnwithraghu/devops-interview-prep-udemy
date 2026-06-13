# Skill: DevOps Prep Repository Structure

When creating new content in the repository, you MUST follow this structure.

## Directory Structure
Organized strictly by technology:
```text
[technology-name]/
  ├── questions_list.md      # The master list of questions
  ├── theory/                # (Optional) Deep dives for theoretical questions
  └── practical/             # The hands-on debugging scenarios
      ├── shared-app/        # (Optional) A single, unified app codebase used by all scenarios
      ├── 01-scenario-name/  # Scenario folder
      │   ├── guide.md       # The instructor/debugging guide
      │   └── [config files] # The broken manifest, docker-compose.yml, etc.
```

## The `questions_list.md`
Must ALWAYS be divided into two sections:
1. `## Theory Questions` (Usually questions 1-5)
2. `## Practical Scenarios` (Usually questions 6-10)
Order practical scenarios by increasing difficulty.

## Practical Scenario Folders
- Every scenario must have its own dedicated folder inside `practical/`.
- The folder name should be numbered and descriptive (e.g., `06-oom-killed`).
- The folder must contain the **broken state** of the application (e.g., a bad `Dockerfile`, a misconfigured `docker-compose.yml`).
