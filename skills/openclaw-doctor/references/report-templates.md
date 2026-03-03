---
domain: openclaw-doctor
topic: report-templates
priority: low
ttl: 90d
---

# Report Templates

## Template 1: Quick Summary Card

```
🏥 OpenClaw Health: {overall_score}/100 {status_emoji}
{env_emoji} ENV {env_score} | {conf_emoji} CONF {conf_score} | {skill_emoji} SKILL {skill_score} | {rt_emoji} RT {rt_score} | {ws_emoji} WS {ws_score} | {sec_emoji} SEC {sec_score}
{IF issues.critical > 0}🔴 {issues.critical} critical issue(s) require immediate attention{/IF}
{IF issues.high > 0}🟡 {issues.high} high-priority issue(s) found{/IF}
{IF issues.total == 0}✅ No issues detected — system healthy{/IF}
```

**Variable mapping**:
- `status_emoji`: ✅ (>=80) | ⚠️ (60-79) | 🟡 (40-59) | 🔴 (<40)
- `*_emoji`: Same logic per dimension score

---

## Template 2: Issue Digest (Standard Report)

```markdown
# 🏥 OpenClaw Health Report

**Score**: {overall_score}/100 {status_emoji} | **Time**: {timestamp} | **Scope**: {scope}

## Dimension Scores

| Dimension | Score | Status | Weight |
|-----------|-------|--------|--------|
| Environment | {env_score}/100 | {env_emoji} | 15% |
| Configuration | {conf_score}/100 | {conf_emoji} | 15% |

| Skills | {skill_score}/100 | {skill_emoji} | 20% |
| Runtime | {rt_score}/100 | {rt_emoji} | 20% |
| Workspace | {ws_score}/100 | {ws_emoji} | 10% |
| Security | {sec_score}/100 | {sec_emoji} | 20% |

{IF previous_score}
**Trend**: {overall_score} vs {previous_score} ({score_delta >= 0 ? "+" : ""}{score_delta})
{/IF}

## Findings ({issues.total})

{FOR issue IN issues SORTED BY severity}
| {issue.severity_emoji} | {issue.id} | {issue.msg} |
{/FOR}

## Top Recommendations

{FOR rec IN recommendations LIMIT 5}
{rec.priority}. **{rec.action}**
   ```bash
   {rec.command}
   ```
   Impact: {rec.impact} | Effort: {rec.effort} | Auto-fix: {rec.auto_fixable ? "Yes" : "Manual"}
{/FOR}

---
Execute fixes? **[Y]es / [N]o / [D]etails**
```

---

## Template 3: Deep Analysis (Full Report)

```markdown
# 🏥 OpenClaw Deep Health Analysis

**Generated**: {timestamp}
**Agent ID**: {agent_id}
**Scope**: Full Diagnostic
**Duration**: {duration_ms}ms

## Executive Summary

Overall Health Score: **{overall_score}/100** {status_emoji}
{IF previous_score}Previous: {previous_score}/100 | Change: {score_delta}{/IF}

{IF issues.critical > 0}
⚠️ **{issues.critical} critical issue(s)** require immediate attention.
{/IF}

## Dimension Analysis

### Environment ({env_score}/100)

| Metric | Value | Status | Threshold |
|--------|-------|--------|-----------|
| Node.js | {env.node_version} | {node_status} | >= v18 (v20 recommended) |
| Memory | {env.memory.available_mb}MB / {env.memory.total_mb}MB | {mem_status} | > 30% available |
| Disk | {env.disk.available_gb}GB / {env.disk.total_gb}GB | {disk_status} | > 20% available |
| CPU Load | {env.cpu.load_avg_1m} on {env.cpu.cores} cores | {cpu_status} | < 0.7 per core |

### Configuration ({conf_score}/100)

| Check | Result |
|-------|--------|
| Config file exists | {config.config_exists ? "✅" : "❌"} |
| Valid JSON | {config.config_valid_json ? "✅" : "❌"} |
| Execution section | {config.sections.execution ? "✅" : "❌"} |
| Skills section | {config.sections.skills ? "✅" : "❌"} |
| Memory section | {config.sections.memory ? "✅" : "❌"} |
| Logging section | {config.sections.logging ? "✅" : "❌"} |
| Concurrency | {config.values.concurrency} (range: 5-50) |
| Timeout | {config.values.timeout_ms}ms (range: 5-60s) |

### Skills ({skill_score}/100)

| Metric | Value |
|--------|-------|
| Installed | {skills.installed_count} |
| Outdated | {skills.outdated.length} |
| Broken deps | {skills.broken_dependencies.length} |
| clawhub CLI | {skills.clawhub_available ? "Available" : "Not found"} |

{IF skills.skills.length > 0}
**Installed Skills**:
{FOR skill IN skills.skills}
- {skill.name} v{skill.version} ({skill.category}) {skill.has_skill_md ? "✅" : "⚠️ missing SKILL.md"}
{/FOR}
{/IF}

### Runtime ({rt_score}/100)

| Endpoint | Status | Latency |
|----------|--------|---------|
{FOR ep IN health.endpoints}
| {ep.endpoint} | {ep.status_code} {ep.status} | {ep.latency_ms}ms |
{/FOR}

**Gateway**: {health.gateway_url}
**OpenClaw Version**: {health.openclaw_version}

### Workspace ({ws_score}/100)

| Directory | Exists |
|-----------|--------|
{FOR dir, exists IN config.directories}
| {dir}/ | {exists ? "✅" : "❌"} |
{/FOR}

## Issue Details

{FOR issue IN issues}
### {issue.severity_emoji} [{issue.id}] {issue.msg}

- **Category**: {issue.category}
- **Severity**: {issue.severity}
- **Evidence**: {issue.evidence}
- **Impact**: {issue.impact_description}
- **Fix**: See Playbook {issue.playbook_id}
{/FOR}

## Repair Plan

{FOR rec IN recommendations}
### {rec.priority}. {rec.action}

| Field | Value |
|-------|-------|
| Issue | {rec.issue_id} |
| Impact | {rec.impact} |
| Effort | {rec.effort} |
| Auto-fixable | {rec.auto_fixable} |
| Expected improvement | +{rec.expected_score_change} points |

**Command**:
```bash
{rec.command}
```

**Rollback**:
```bash
{rec.rollback}
```
{/FOR}

## Raw Data

<details>
<summary>Click to expand raw collection data</summary>

```json
{JSON.stringify(raw_data, null, 2)}
```
</details>

---
*Report generated by @botlearn/openclaw-doctor v3.0.0*
```

---

## Template 4: Before/After Comparison

```markdown
## Fix Results

### Score Changes

| Dimension | Before | After | Change |
|-----------|--------|-------|--------|
{FOR dim IN dimensions}
| {dim.name} | {dim.before} | {dim.after} | {dim.delta >= 0 ? "+" : ""}{dim.delta} {dim.delta > 0 ? "✅" : dim.delta < 0 ? "⚠️" : "—"} |
{/FOR}

**Overall**: {before_total} → {after_total} ({total_delta >= 0 ? "+" : ""}{total_delta})

### Issues Resolved
{FOR issue IN resolved}
- ✅ [{issue.id}] {issue.msg}
{/FOR}

### Remaining Issues
{FOR issue IN remaining}
- ⏳ [{issue.id}] {issue.msg} ({issue.reason})
{/FOR}

### Next Steps
- Recommended recheck: {recheck_interval}
- {IF remaining.length > 0}Address remaining {remaining.length} issue(s){/IF}
- {IF remaining.length == 0}All issues resolved — schedule routine check{/IF}
```
