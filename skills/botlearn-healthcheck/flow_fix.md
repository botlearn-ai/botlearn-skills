# Phase 5 — Fix Cycle

Execute fixes for issues identified in the health report, with user confirmation at every step.
Reference **`fix_cases.md`** for proven fix steps, rollback commands, and prevention strategies per domain.
Reference **`openclaw_knowledge.md`** for platform defaults, CLI commands, and version-specific changes.

## 5.1 — Safety Rules

**Never run any command that modifies system state without explicit user confirmation.**

- Each fix must be confirmed individually
- Always show rollback command before executing
- If user declines a fix, skip it and move to the next
- If a fix fails, report the failure and suggest manual intervention

## 5.2 — Per-Fix Protocol

For each issue (ordered by severity: errors first, then warnings):

```
STEP 1: Show fix plan
  - Issue: [description]
  - Domain: [domain name]
  - Severity: [error / warning]
  - Fix command: [exact command]
  - Rollback command: [exact rollback]
  - Risk: [low / medium / high]

STEP 2: Await user confirmation
  → User confirms → proceed to STEP 3
  → User declines → skip, move to next issue
  → User asks for details → provide explanation, re-ask

STEP 3: Execute fix
  - Run the fix command
  - Capture output

STEP 4: Verify result
  - Re-run the relevant check from Phase 2
  - Compare before/after status
  - Report: [fixed / partially fixed / failed]

STEP 5: Record outcome
  - Track: { issue, fix_applied, result, timestamp }
  - This data feeds into Phase 6 summary
```

## 5.3 — Batch Mode

If user says "fix all" or equivalent:
- Still show all fix plans as a batch summary first
- Await single confirmation for the entire batch
- Execute sequentially, reporting each result
- Stop on any critical failure and ask user how to proceed

## 5.4 — Scope Limits

Do NOT attempt fixes that:
- Require root/sudo access (suggest the command, let user run manually)
- Modify network configuration
- Uninstall or downgrade OpenClaw
- Delete user data or memory files

For these cases, output the recommended command and instruct the user to run it manually.
