---
domain: meta-learning
topic: self-improvement-best-practices
priority: high
ttl: 90d
---

# Self-Improvement Best Practices

## Logging

- Log immediately while context is fresh
- Be specific — future agents need to understand quickly
- Include reproduction steps for errors
- Link related files for easier fixes
- Suggest concrete fixes, not just "investigate"

## Entry Management

- Use consistent categories for filtering
- Search existing entries before creating duplicates
- Link related entries with "See Also" references
- Bump priority on recurring issues

## Promotion

- Promote aggressively — if in doubt, add to CLAUDE.md
- Distill learnings into concise rules
- Target the right file: CLAUDE.md for conventions, AGENTS.md for workflows
- Update original entry status to "promoted"

## Hook Integration

- Enable UserPromptSubmit hook for automatic reminders
- Use PostToolUse hook for error detection on Bash commands
- Keep hook overhead minimal (~50-100 tokens)

## Periodic Review

- Review before starting major tasks
- Resolve fixed items promptly
- Escalate recurring issues to systemic fixes
