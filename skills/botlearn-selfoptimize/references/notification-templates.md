---
domain: self-learn
topic: notification-templates
priority: medium
ttl: 720h
---

# Notification Templates

Four notification types for the "用" (Apply) phase. Each template includes structured content and action buttons.

---

## 1. cycle-complete — Learning Cycle Completed

```
📚 Learning Cycle Complete

Cycle: {cycle_id}
Status: {status_emoji} {status_label}
Improvement: {improvement_score}

Task: {original_request}
Skills Used: {skills_list}
Duration: {total_duration}

Lessons Learned:
{lessons_list}

[View Details]  [Rate This Cycle ⭐]  [Pause Learning]
```

**Status mapping:**
| Status | Emoji | Label |
|--------|-------|-------|
| solved | ✅ | Task Fully Resolved |
| improved | 📈 | Measurable Improvement |
| no_change | ➡️ | No Significant Change |
| degraded | 📉 | Performance Decreased (Rolled Back) |
| abandoned | ⏹️ | Cycle Abandoned |

**Improvement score display:**
- `>= 0.7`: "Excellent improvement (+{score})"
- `>= 0.3`: "Good improvement (+{score})"
- `>= 0.1`: "Slight improvement (+{score})"
- `>= -0.1`: "No change ({score})"
- `< -0.1`: "Degraded ({score}) — reverted"

---

## 2. task-solved — Task Successfully Resolved

```
✅ Task Solved!

Original Request: {original_request}

Solution Approach:
{solution_approach}

Skills That Helped:
{skills_with_descriptions}

Improvement Score: {improvement_score}

This task was previously unsatisfied (score: {before_satisfaction}).
After learning and reattempting, it is now resolved (score: {after_satisfaction}).

[View Solution]  [Rate Solution ⭐]
```

---

## 3. needs-approval — Approval Required

```
🔔 Approval Needed

Action: {action_description}

Details:
{action_details}

Risk Level: {risk_emoji} {risk_level}
Timeout: Defaults to {timeout_minutes} minutes

Why This Needs Approval:
{approval_reason}

[✅ Approve]  [❌ Reject]  [View Details]
```

**Actions requiring approval:**
| Action | Risk Level | Default Timeout |
|--------|-----------|-----------------|
| Install new skill (> 3 in cycle) | medium | 60 min |
| Post community question | low | 30 min |
| Send DM to expert | low | 60 min |
| Uninstall ineffective skill | medium | 120 min |
| Modify scheduled frequency | low | 60 min |

**Risk level emoji:**
- low: 🟢
- medium: 🟡
- high: 🔴

---

## 4. error — Error Notification

```
⚠️ Learning Error

Phase: {phase_emoji} {phase_name}
Error: {error_message}

Impact:
{impact_description}

Suggested Recovery:
{recovery_suggestion}

Cycle: {cycle_id}

[🔄 Retry]  [📋 View Logs]  [Dismiss]
```

**Phase emoji:**
| Phase | Emoji | Name |
|-------|-------|------|
| test | 🔍 | Dissatisfaction Mining |
| learn | 📖 | Skill Discovery |
| practice | 🏋️ | Task Reattempt |
| apply | 📤 | Owner Notification |
| evaluate | 📊 | Cycle Evaluation |

**Common errors:**
| Error | Phase | Recovery |
|-------|-------|----------|
| Memory API unreachable | test | Check Gateway status, retry in 5 min |
| No candidates found | test | Lower satisfaction threshold, extend time window |
| npm search failed | learn | Check network, try community search only |
| Community API rate limited | learn | Wait for rate limit reset, use cached results |
| Task execution timeout | practice | Increase timeout, simplify task scope |
| Notification delivery failed | apply | Queued in pending-notifications.json |
| Schema validation failed | evaluate | Check cycle record completeness |
