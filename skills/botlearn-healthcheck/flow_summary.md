# Phase 6 — Fix Summary

After the fix cycle completes (or is skipped), generate a final summary of actions taken.

## 6.1 — Summary Content

Present to the user (in REPORT_LANG):

```
## Fix Summary

| # | Issue | Domain | Action | Result |
|---|-------|--------|--------|--------|
| 1 | [issue description] | [domain] | [fix applied / skipped / manual] | [fixed / failed / skipped] |

Total: [X] fixed, [X] skipped, [X] failed
```

## 6.2 — Post-Fix Verification

If any fixes were applied:

1. Re-run affected domain checks (Phase 2, targeted mode)
2. Compare before/after scores
3. Present delta:

```
## Score Changes

| Domain | Before | After | Change |
|--------|--------|-------|--------|
| [domain] | XX/100 | XX/100 | +X / -X / = |

Overall: [improved / unchanged / degraded]
```

## 6.3 — Append to Report

Update the previously generated report files:

- **MD report**: Append the fix summary and score changes sections at the end
- **HTML report**: Re-generate with updated data if feasible, otherwise note fixes in MD only

## 6.4 — Remaining Issues

If any issues remain unfixed (skipped or failed), output:

```
## Remaining Issues

[X] issues still open:
1. [issue] — [reason: skipped by user / fix failed / requires manual action]
   Recommended: [command or action]

Next health check will re-evaluate these items.
```

## 6.5 — Final Message

End with a closing message (in REPORT_LANG):

- All fixed: "All issues resolved. System health restored."
- Partial: "X issues fixed, X remaining. Run health check again after manual fixes."
- None fixed: "No fixes applied. Review the report for manual action items."

Include the report file paths for reference:
```
Reports:
  MD:   $OPENCLAW_HOME/memory/health-reports/healthcheck-<timestamp>.md
  HTML: $OPENCLAW_HOME/memory/health-reports/healthcheck-<timestamp>.html
```
