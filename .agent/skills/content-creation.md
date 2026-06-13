# Skill: Rules for Creating New Practical Scenarios

- **Never give away the answer in the initial manifest:** The broken configuration files must look like standard, realistic files. Do not add comments like `# THIS IS BROKEN` to the code.
- **Keep it realistic:** Scenarios should mimic real production outages (e.g., OOM kills, network isolation, disk space exhaustion, misconfigured load balancers).
- **Emphasize the "Why":** When writing the `guide.md`, ensure the debugging steps teach the user *why* they are running a specific command.
- **Reuse where possible:** Use a `shared-app/` directory for the base application code if multiple scenarios can be built around the same stack. This prevents redundant code and keeps the focus on the DevOps configurations.
