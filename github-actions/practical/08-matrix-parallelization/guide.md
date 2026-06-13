# Scenario 08: Matrix Parallelization

## 1. Question
"Your test suite takes too long to run sequentially across different operating systems and language versions. How can you parallelize it using GitHub Actions?"

## 2. Interviewer's Point of View
The interviewer is looking for your knowledge of the `strategy: matrix` feature. They want to see if you understand how to dynamically generate multiple job combinations and run them concurrently to save CI wall-clock time.

## 3. Steps to Setup the Scenario
This is a feature demo. The workflow is already located in `.github/workflows/08-matrix-parallelization.yml`.
1. Navigate to the **Actions** tab in your repository.
2. In the left sidebar, click on **08 Matrix Parallelization**.
3. On the right side, click the **Run workflow** dropdown and click the green **Run workflow** button.
4. Refresh the page to see the new workflow run appear. Click on it.
5. You will now see **9 different jobs** (e.g., `test (ubuntu-latest, 16.x)`) running concurrently on the left side of the Actions UI!

## 4. Step-by-Step Debugging & Fix
**Step 1: Explain the problem with sequential jobs**
*Thoughts to share:* "If we run tests for Windows, Ubuntu, and macOS sequentially, and each takes 10 minutes, our CI pipeline takes 30 minutes. We need to fan this out."

**Step 2: Introduce the Matrix Strategy**
*Thoughts to share:* "I can use `strategy: matrix` to define arrays of operating systems and Node versions. GitHub Actions will automatically create a Cartesian product of these variables—in this case, 3 OSs times 3 Node versions equals 9 concurrent jobs."

**Step 3: Discuss `fail-fast`**
*Thoughts to share:* "By default, if one matrix job fails, GitHub cancels all the other running ones. If we want all tests to finish regardless of individual failures, we should explicitly set `fail-fast: false` in the strategy block."

## 5. Interview Summary Pitch
"To drastically reduce CI execution time for multi-environment test suites, I would utilize GitHub Actions' Matrix Strategy. By defining arrays for operating systems, language versions, or other parameters under `strategy: matrix`, GitHub automatically generates and runs all combinations as parallel jobs. I would also configure `fail-fast: false` if I want to see the complete test matrix results even if one specific combination fails. This parallelization turns what would be hours of sequential testing into a pipeline that finishes in the time it takes the longest single job to run."
