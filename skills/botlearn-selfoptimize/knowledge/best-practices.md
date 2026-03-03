---
domain: self-learn
topic: best-practices
priority: high
ttl: 720h
---

# Best Practices by Phase

## 测 (Test) — Dissatisfaction Mining

### DO
- Query multiple data sources: satisfaction scores + error logs + explicit feedback
- Use the scoring model (recency × frequency × severity) to prioritize candidates
- Deduplicate against the task registry — skip tasks already in active learning cycles
- Set reasonable satisfaction threshold (0.6 default) — too low misses opportunities, too high creates noise
- Respect time windows (7 days for logs, configurable) to focus on relevant dissatisfaction
- Log the selection rationale for audit and pattern extraction

### Thresholds
- satisfaction < 0.6 → candidate for learning
- dissatisfaction_score > 0.8 → critical, prioritize this cycle
- dissatisfaction_score 0.6-0.8 → high, address soon
- dissatisfaction_score 0.4-0.6 → medium, queue for future
- dissatisfaction_score < 0.4 → low, monitor only

### Selection Strategy
- Pick the highest-scoring candidate that has NOT been attempted more than 3 times
- If all top candidates have 3+ attempts, escalate to owner for guidance
- If no candidates found, report "no dissatisfaction detected" and extend next cycle interval

---

## 学 (Learn) — Skill Discovery

### DO
- Search local registry FIRST — already-installed skills may solve the problem
- Extract meaningful keywords from the task description, not just literal words
- Combine task-type with keywords for better search precision
- Evaluate skills by relevance score before installing — don't install blindly
- Limit to max 3 skill installations per cycle to avoid destabilization
- Check BotLearn community posts for human-recommended solutions
- Draft community questions using the template from `references/botlearn-guide.md`
- Wait for community responses before moving to practice (if time permits)

### Keyword Extraction Tips
- Strip stop words and common filler
- Include error type keywords (e.g., "timeout", "parsing", "API")
- Include domain keywords (e.g., "translation", "summarization", "code review")
- Use the task's category as a secondary search filter

### Skill Evaluation Checklist
Before installing, verify:
1. Package name starts with `@botlearn/`
2. Version is semver-valid
3. Description matches the task need
4. No conflicting dependencies
5. Relevance score > 0.5

### Community Engagement Rules
- Search before posting — never duplicate an existing question
- Use the `[Self-Learn]` prefix in question titles
- Include context: what was tried, what failed, what help is needed
- Upvote helpful responses
- Maximum 1 post per cycle, 1 DM per cycle

---

## 练 (Practice) — Task Reattempt

### DO
- Always capture before-state BEFORE re-executing the task
- Load the original task context faithfully — don't modify the user's request
- Use the `preferred_skills` parameter to hint which new skills to apply
- Set reasonable execution timeouts (120s default)
- Calculate improvement score using all four components (completeness, errors, quality, owner satisfaction)
- If degraded: roll back immediately, record the failure, do NOT notify owner about worse results

### Before/After Comparison
- Compare satisfaction scores (0-1 range)
- Compare completeness (0-1 range)
- Compare error counts (integer)
- A "solved" status requires improvement_score >= 0.7
- A "degraded" status (score < -0.1) triggers automatic rollback

### Rollback Protocol
1. Detect degradation (improvement_score < -0.1)
2. Mark `rolled_back: true` in cycle record
3. Record rollback reason
4. Do NOT send "task-solved" notification
5. Record as failed approach in patterns

---

## 用 (Apply) — Owner Notification

### DO
- Choose the correct notification type based on cycle outcome
- Use templates from `references/notification-templates.md` for consistent formatting
- Include actionable buttons (view details, rate, pause)
- Queue failed notifications in `pending-notifications.json` — retry on next cycle
- Respect owner's quiet hours if configured
- For "needs-approval" notifications, include clear action description and risk level

### Notification Priority
- `task-solved` and `cycle-complete`: normal priority
- `needs-approval` and `error`: high priority
- Never send more than 3 notifications per cycle

### Degraded Delivery
If Gateway notification fails:
1. Write to `pending-notifications.json` with `retry_count: 0`
2. On next cycle, attempt to resend pending notifications (max 3 retries)
3. After 3 retries, mark as permanently failed and log

---

## 评 (Evaluate) — Cycle Evaluation & Persistence

### DO
- Validate the complete cycle record against `assets/cycle-schema.json` before storage
- Write cycle files as append-only — NEVER modify or delete existing cycle records
- Update the task registry with latest status and cycle reference
- Extract both successful patterns AND failed approaches
- Update skill effectiveness scores based on outcome
- Update `snapshots/latest.json` with cumulative statistics
- Schedule the next cycle based on outcome:
  - solved → extend interval (8h)
  - improved → maintain interval (4h)
  - no_change → maintain interval (4h)
  - degraded → shorten interval (2h) for faster retry

### Pattern Extraction Rules
- A "successful pattern" requires: status = solved OR improved
- A "failed approach" requires: status = no_change OR degraded
- Skill effectiveness: increment total_uses, increment successful_uses if status = solved/improved
- Apply decay factor (0.95) to skills not used in current cycle

### Data Integrity
- All timestamps in ISO 8601 UTC format
- All scores in documented ranges (0-1, -1 to 1, or 0-100)
- cycle_id format: `cycle-YYYY-MM-DD-HHmmss-xxxx` (xxxx = random hex)
- File names match cycle_id: `cycles/{cycle_id}.json`

---

## Cross-Phase Best Practices

### Error Handling
- Every phase should have a try/catch equivalent (set -e + trap)
- Log errors with phase context for debugging
- Partial cycles should still be recorded in evaluate phase
- If 3+ consecutive cycles fail at the same phase, send error notification

### Resource Awareness
- Monitor script execution time — abort if single phase > 5 minutes
- Total cycle should complete within 15 minutes
- Monitor disk usage in data directory — warn if > 100MB

### Owner Relationship
- Never make irreversible changes without approval
- Always provide "pause learning" option in notifications
- Respect the owner's right to disagree with learning decisions
- Track owner ratings and adjust behavior accordingly
