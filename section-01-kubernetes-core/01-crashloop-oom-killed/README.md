# Scenario 01: CrashLoopBackOff - OOMKilled

## Description
This scenario simulates a Pod that gets killed by the kernel due to exceeding its memory limit, causing a CrashLoopBackOff.

## Difficulty
⭐ Beginner

## Deploy the Broken State
```bash
kubectl apply -f broken/deployment.yaml
```

## Expected Behavior
The Pod will start and immediately be killed with status `OOMKilled`, then enter CrashLoopBackOff.

## Debug
See [DEBUG.md](DEBUG.md) for step-by-step debugging instructions.

## Fix
See [fixed/deployment.yaml](fixed/deployment.yaml) for the corrected manifest.
