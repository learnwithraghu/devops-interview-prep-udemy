# Agent Instructions for DevOps Interview Prep Repository

Welcome! If you are an AI agent or a language model operating in this repository, this document outlines the core vision of this project.

## Project Vision

This repository is a comprehensive, hands‑on interview preparation guide for DevOps engineers. It covers multiple technologies (Kubernetes, Docker, Terraform, AWS, Jenkins, GitHub Actions, Linux) and splits the learning into two distinct phases: **Theory** and **Practical Scenarios**.

The goal of the practical scenarios is to simulate real‑world, broken environments that the student must troubleshoot and fix live, mirroring a technical interview.

## Agent Skills

To ensure consistency, the strict formatting rules and conventions for this repository have been modularized into Agent Skills. When operating in this repository, you **MUST** automatically utilize these skills:

- **Repository Structure:** Defines the required directory layout and the format for `questions_list.md`. (Symlinked to `repository-structure.md`)
- **Guide Formatting:** Defines the mandatory 5‑part structure for all instructor `guide.md` files. (Symlinked to `guide-formatting.md`)
- **Content Creation:** Outlines the core philosophy (e.g., keeping broken states realistic, not giving away answers). (Symlinked to `content-creation.md`)

*Note for humans:* The skills are physically located in the `.agent/skills/` directory. For convenience, symlinks have been provided below in the repository root.

## Illustration Assets for Theory Guides

When a `guide.md` is generated for a Theory Question, an **assets** folder should be created alongside the guide (or within the same topic directory). The folder must contain the SVG and Excalidraw JSON files produced by the `metaphor-illustrator` skill.

- Asset path example: `nginx/theory/01-what-is-nginx/assets/01-concept.svg`
- Keep the same base name as the illustration index (`01`, `02`, …) and use the appropriate extension (`.svg` or `.excalidraw.json`).
- The `agents.md` file now mandates that any AI agent creating a `guide.md` automatically triggers the `metaphor-illustrator` skill and stores the results in this assets folder.

## Updated Workflow for Question Changes
1. **Edit `questions_list.md`.** When a scenario question is added, removed, or modified, locate the corresponding practical (or theory) guide in `github-actions/practical/XX‑<slug>/guide.md` **or** `theory/<topic>/guide.md`.
2. **Update the existing guide** (do **not** create a new folder). Replace the guide content following the 5‑part guide format (Question, Interviewer’s POV, Steps, Debug‑Fix, Summary) and ensure the `## Udemy Video Name` section matches the updated entry.
3. **Synchronize Udemy Video Name.** The guide must end with a `## Udemy Video Name` section that matches the short title used in the `Udemy Video Name` list of `questions_list.md`.
4. **Create or update any code assets** required by the new question (e.g., workflow YAML files, scripts, CloudFormation templates). Reference these assets in the guide steps.
5. **Cleanup obsolete resources.** If a question change renders existing code/assets unnecessary, delete or archive the related files to keep the repository tidy.
5a. **Cross‑Reference Validation:** After editing any `questions_list.md`, automatically verify that each practical folder and each workflow file has a matching entry. If mismatches are found, raise a warning and require correction before committing.
6. **Commit and push** the changes. No new practical‑scenario folders are to be created unless a brand‑new scenario number is introduced.
7. **Folder naming consistency:** When a scenario’s focus changes (e.g., from “PR Secret Failure” to “Performance Benchmark”), rename the practical folder to reflect the new topic (e.g., `06‑performance‑benchmark`). This keeps the folder name aligned with the scenario description.

## Metaphor‑Illustrator Skill
The `metaphor-illustrator` skill definition lives in `.agent/skills/metaphor-illustrator/` and can be invoked by any Codex‑compatible AI agent.
