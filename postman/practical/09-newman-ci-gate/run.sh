#!/bin/bash
# ============================================================
# BROKEN CI Gate Script
# BUG: This script does NOT check Newman's exit code.
#      Even if Newman reports test failures, the deployment
#      step below will still execute.
# 
# FIX: Add 'set -e' at the top, or check '$?' after newman.
# ============================================================

newman run collection.json

# This line should NEVER run if Newman had failures.
# But because we don't check the exit code, it always runs.
echo "✅ Deployment proceeding..."
