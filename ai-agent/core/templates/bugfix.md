# Template: Roblox Bugfix Implementation

Use this template when fixing a gameplay, network, or UI bug in this Roblox project.

## 1. Problem Description
- **Symptom**: Describe the unexpected behavior (e.g. data loss when player leaves, pet stuttering/lag, multiple eggs purchased in one click).
- **Environment**: Does it occur in Roblox Studio local test, team test, or actual published game?
- **Logs**: Attach relevant print/warn/error output from the Output panel.

## 2. Root Cause Analysis
Explain why this issue happened. Check for common Roblox pitfalls:
- Event connection memory leak.
- UI scaling issue (using absolute offset rather than scale).
- Remote event parameter trust issues (exploit susceptibility).
- DataStore throttling/limitations (rate limit).
- Missing `pcall` on asynchronous API calls.
- Missing `game:BindToClose()` saving loop.
- Network Owner not set to Client, causing physics lag.

## 3. Solution
Explain what code changes were made to fix the issue.
Show the before/after code diff.

## 4. Verification Plan
Describe how you tested the fix:
- Solo play mode in Roblox Studio.
- Triggering the failure case manually and confirming it behaves correctly now.
- Checking that no errors are outputted to the developer console.
