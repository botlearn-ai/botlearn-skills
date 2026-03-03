---
domain: self-learn
topic: cycle-report-templates
priority: medium
ttl: 720h
---

# Cycle Report Templates

Three levels of reporting detail for learning cycle results.

---

## Level 1 — Summary Card

Single-line status with five-phase indicators. Used for quick checks, scheduled notifications, and heartbeat responses.

```
📚 Self-Learn #{total_cycles}: {status_emoji} {status}
测 {test_emoji} {candidates} | 学 {learn_emoji} {skills} | 练 {practice_emoji} {imp_score} | 用 {apply_emoji} {notif} | 评 {evaluate_emoji} {patterns}
⏱️ {duration} | 🎯 {improvement_label}
```

**Phase emoji logic:**
- ✅ Phase completed successfully
- ⚠️ Phase completed with warnings
- ❌ Phase failed
- ⏭️ Phase skipped

**Example:**
```
📚 Self-Learn #42: ✅ solved
测 ✅ 5 candidates | 学 ✅ 2 skills | 练 ✅ +0.72 | 用 ✅ delivered | 评 ✅ 3 patterns
⏱️ 4m 23s | 🎯 Excellent improvement
```

---

## Level 2 — Cycle Summary

Markdown table format with recommendations and before/after comparison. Used for cycle-complete notifications and manual report requests.

```markdown
# 📚 Learning Cycle Report #{total_cycles}

**Cycle ID**: {cycle_id}
**Trigger**: {trigger} | **Duration**: {duration}
**Status**: {status_emoji} {status} | **Improvement**: {improvement_score}

## Target Task

> {original_request}

**Dissatisfaction Score**: {dissatisfaction_score} ({failure_type})
**Session**: {session_id}

## Five-Phase Summary

| Phase | Status | Duration | Key Result |
|-------|--------|----------|------------|
| 测 Test | {test_status} | {test_duration} | {candidates_found} candidates, selected: {selected_task} |
| 学 Learn | {learn_status} | {learn_duration} | {skills_found} found, {skills_installed} installed |
| 练 Practice | {practice_status} | {practice_duration} | {improvement_score} ({practice_result}) |
| 用 Apply | {apply_status} | {apply_duration} | {notification_status} |
| 评 Evaluate | {eval_status} | {eval_duration} | {patterns_extracted} patterns extracted |

## Before / After

| Metric | Before | After | Delta |
|--------|--------|-------|-------|
| Satisfaction | {before_satisfaction} | {after_satisfaction} | {sat_delta} |
| Completeness | {before_completeness} | {after_completeness} | {comp_delta} |
| Errors | {before_errors} | {after_errors} | {err_delta} |

## Skills Installed

{skills_table_or_none}

## Recommendations

{recommendations_list}

## Next Steps

- Next cycle scheduled: {next_scheduled}
- Priority: {next_priority}
- Suggested focus: {suggested_focus}
```

---

## Level 3 — Deep Analysis

Comprehensive report with per-phase evidence, community interaction records, and raw JSON. Used for debugging, manual deep-dive, and pattern analysis.

```markdown
# 📚 Deep Analysis — Cycle {cycle_id}

**Generated**: {report_timestamp}
**Agent**: {agent_id} | **Platform**: OpenClaw {openclaw_version}

---

## Executive Summary

{executive_summary_paragraph}

---

## Phase 1: 测 (Test) — Dissatisfaction Mining

**Duration**: {test_duration}
**Script**: `collect-dissatisfaction.sh`

### Data Sources Queried
- Memory API sessions (satisfaction < {threshold}): {session_count} results
- Error log patterns: {error_count} matches
- Negative feedback entries: {feedback_count} items

### Candidate Analysis

| Rank | Task ID | Score | Type | Request |
|------|---------|-------|------|---------|
{candidate_rows}

### Selection Rationale
{selection_reason}

---

## Phase 2: 学 (Learn) — Skill Discovery

**Duration**: {learn_duration}
**Script**: `search-skills.sh --keywords "{keywords}" --task-type "{task_type}"`

### Search Results by Source

| Source | Results | Top Match | Relevance |
|--------|---------|-----------|-----------|
| Local Registry | {local_count} | {local_top} | {local_score} |
| npm (@botlearn) | {npm_count} | {npm_top} | {npm_score} |
| BotLearn Search | {community_count} | {community_top} | {community_score} |
| BotLearn Feed | {feed_count} posts | — | — |

### Community Interactions
{community_interaction_log}

### Skills Installed
{installed_skills_detail}

---

## Phase 3: 练 (Practice) — Task Reattempt

**Duration**: {practice_duration}
**Script**: `attempt-task.sh --task-id {task_id} --session-id {session_id} --new-skills {skills}`

### Execution Details
- Original context loaded: {context_loaded}
- Skills applied: {skills_applied}
- Execution time: {execution_time}

### Before/After Comparison

```json
{
  "before": { "satisfaction": {bs}, "completeness": {bc}, "error_count": {be} },
  "after":  { "satisfaction": {as}, "completeness": {ac}, "error_count": {ae} }
}
```

### Improvement Breakdown

| Component | Weight | Before | After | Contribution |
|-----------|--------|--------|-------|-------------|
| Completeness | 0.35 | {bc} | {ac} | {comp_contrib} |
| Error Reduction | 0.25 | {be} | {ae} | {err_contrib} |
| Quality | 0.25 | {bs} | {as} | {qual_contrib} |
| Owner Satisfaction | 0.15 | — | {owner_sat} | {owner_contrib} |
| **Total** | **1.00** | | | **{improvement_score}** |

{rollback_section_if_degraded}

---

## Phase 4: 用 (Apply) — Owner Notification

**Duration**: {apply_duration}
**Script**: `notify-owner.sh --type {notification_type} --data '{...}'`

### Notification Sent
- Type: {notification_type}
- ID: {notification_id}
- Status: {delivery_status}
- Actions available: {action_buttons}

{queued_notification_section_if_failed}

---

## Phase 5: 评 (Evaluate) — Cycle Persistence

**Duration**: {eval_duration}
**Script**: `record-cycle.sh < cycle.json`

### Persistence Results
- Cycle stored: {stored_path}
- Task registry updated: {registry_updated}
- Patterns extracted: {patterns_count}

### Patterns Extracted
{patterns_detail}

### Learning State Snapshot
```json
{latest_snapshot_json}
```

---

## Metrics Summary

```json
{full_metrics_json}
```

---

## Raw Cycle Record

<details>
<summary>Click to expand full JSON</summary>

```json
{full_cycle_json}
```

</details>
```

---

## Report Generation Notes

- Level 1: Auto-generated after every cycle for quick status
- Level 2: Generated for cycle-complete notifications and manual requests
- Level 3: Generated on demand via "show deep analysis for cycle {id}"
- All reports reference data from `~/.openclaw/data/self-learn/`
