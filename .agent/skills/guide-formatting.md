# Skill: Formatting `guide.md` (Instructor Guide)

Every practical scenario MUST have a `guide.md`. This file is the script for the instructor. It must follow this exact 5-part structure:

1. **Question:** The exact interview question being asked.
2. **Interviewer's Point of View:** What the interviewer is looking for, the hidden traps, and the core concepts being tested.
3. **Steps to Setup the Scenario:** Exact CLI commands to launch the broken state.
4. **Step-by-Step Debugging & Fix:** How to investigate the issue like a real engineer. Do NOT jump straight to the fix. Provide the commands (`docker ps`, `kubectl describe`, etc.). *Crucially*, include 1-liner "*Thoughts to share:*" for each step, serving as a script for what the candidate should say out loud to "speak their mind" while debugging. End this section with the exact fix/YAML diff needed.
5. **Interview Summary Pitch:** A polished, concise paragraph summarizing the troubleshooting flow. This is how the candidate should verbally explain their logic to an interviewer without just reciting literal CLI commands.
