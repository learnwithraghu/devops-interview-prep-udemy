# Scenario 06: Performance Benchmark

## 1. Question

"You have a CI workflow that compiles code, runs integration tests, and optionally runs a heavy performance‑benchmark job. The workflow is triggered manually. Explain how you would expose a custom input that lets the user decide whether the benchmark runs, and how you would ensure the benchmark job runs only when requested."

## 2. Interviewer's Point of View

The interviewer wants to assess your ability to design flexible CI pipelines, expose runtime parameters via `workflow_dispatch`, and conditionally execute jobs based on inputs, all while keeping routine builds fast.

## 3. Steps to Setup the Scenario

1. Create a workflow file at `.github/workflows/performance-benchmark.yml`.
2. Add a `workflow_dispatch` trigger with an input, e.g., `run_benchmark`, defaulting to `false`.
3. Define three jobs: `build`, `test`, and `benchmark`.
4. Guard the `benchmark` job with an `if:` condition that checks the input value (e.g., `if: ${{ inputs.run_benchmark == 'true' }}`).
5. Document the workflow location and explain how a user can manually trigger it from the GitHub Actions UI, setting the input as needed.

## 4. Step‑by‑Step Debugging & Fix

*Step 1 – Verify Manual Trigger:* Open **Actions**, locate **Performance Benchmark**, click **Run workflow**, and confirm the input field appears.
*Step 2 – Test Both Paths:* Run the workflow with the input set to `false` (or default) and observe only `build` and `test` jobs execute. Then run it with the input set to `true` and verify the `benchmark` job also runs.
*Step 3 – Common Pitfalls:* Discuss issues such as misspelling the input name, using the wrong datatype (`true` vs. `'true'`), or forgetting the `${{ }}` interpolation in the `if:` expression. Explain how to inspect job logs to determine why a job was skipped.

## 5. Interview Summary Pitch

"To build an adaptable CI pipeline, I would expose a boolean input on the `workflow_dispatch` trigger (e.g., `run_benchmark`). Using that input, I would guard the heavy benchmark job with an `if:` condition so it only runs on demand. This keeps the pipeline fast for typical builds while still allowing an in‑depth performance analysis when needed, demonstrating both efficiency and flexibility."

## Udemy Video Name

Performance Benchmark
