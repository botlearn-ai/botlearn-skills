# Domain: Configuration Health

> Deep reference for Domain 2 in SKILL.md.
> Load this file when running L3 analysis or when SKILL.md thresholds need clarification.
>
> **Input:** `DATA.config`, `DATA.health`, `DATA.channels`, `DATA.tools`, `DATA.openclaw_json`, `DATA.status`
> **Output:** status (✅/⚠️/❌) + score (0–100) + findings + fix hints

---

## Analysis Process

Analysis runs in 4 sequential stages. Each stage builds on the previous.

```
Stage 1: CLI Validation    →  openclaw config validate
Stage 2: Content Analysis  →  section-by-section deep read
Stage 3: Consistency Check →  cross-field validation
Stage 4: Security Posture  →  gateway + auth + exposure assessment
```

---

## Stage 1 — CLI Validation

**Primary check:** `DATA.config.cli_validation`

| Field | Check | Status | Score Impact |
|-------|-------|--------|-------------|
| `cli_validation.ran` | false | ⚠️ openclaw CLI unavailable | -10 |
| `cli_validation.success` | false (exit ≠ 0) | ❌ Config failed validation | -40 |
| `cli_validation.success` | true | ✅ Config passes openclaw validate | 0 |

**Version extraction from validation output:**
```
Success output: "🦞 OpenClaw 2026.3.2 (85377a2) — The lobster in your shell. 🦞"
Parse:  version = cli_validation.openclaw_version  (e.g. "2026.3.2")
        commit  = cli_validation.openclaw_commit   (e.g. "85377a2")
```

Report the parsed version and commit as part of the Config domain output.
If `cli_validation.ran = false`: skip Stage 1 scoring, note CLI unavailable, continue to Stage 2.

---

## Stage 2 — Content Analysis

Proceed only if `DATA.config.json_valid = true`. If false, score is capped at 40.

### 2.1 Config File Presence

| Check | Condition | Score Impact |
|-------|-----------|-------------|
| `config_exists` | false | ❌ -50 (fatal — skip all remaining analysis) |
| `json_valid` | false | ❌ -40 (skip sections analysis) |

### 2.2 Required Sections

From `DATA.config.sections_missing`:

| Sections Missing | Score Impact |
|-----------------|-------------|
| `gateway` | ⚠️ -15 |
| `agents` | ⚠️ -15 |
| `messages` | ⚠️ -10 |
| `session` | ⚠️ -10 |
| `tools` | ⚠️ -5 |

Extra keys in `DATA.config.extra_keys`: flag each as ⚠️ note (no score impact — possible deprecated config).

### 2.3 Gateway Section

From `DATA.config.gateway`:

| Parameter | Healthy | Warning | Error | Score Impact |
|-----------|---------|---------|-------|-------------|
| `port` | 1024–65535 | < 1024 (privileged) | — | ⚠️ -5 |
| `bind` | loopback | lan / tailnet | — | ⚠️ -5 each |
| `mode` | ws+http | http-only | — | note only |
| `reload` | hybrid or hot | false / cold | — | ⚠️ -5 |
| `auth.type` | jwt or token | — | none (on non-loopback) | ❌ handled in Stage 4 |
| `control_ui` | false (on non-loopback) | — | true (on non-loopback) | ❌ handled in Stage 4 |
| `ssl.enabled` | true (on LAN) | — | false (on LAN with auth) | ⚠️ handled in Stage 4 |

### 2.4 Agents Section

From `DATA.config.agents`:

| Parameter | Healthy Range | Warning | Error | Score Impact |
|-----------|--------------|---------|-------|-------------|
| `max_concurrent` | 1–10 | 0 or >15 | — | ⚠️ -10 |
| `timeout_seconds` | 30–1800 | >3600 or <15 | <5 | ⚠️ -10 / ❌ -20 |
| `heartbeat.interval_minutes` | 5–120 | >240 | 0 | ⚠️ -10 / ❌ -15 |
| `heartbeat.auto_recovery` | true | false | — | ⚠️ -10 |
| `heartbeat.enabled` | true | false | — | ⚠️ -10 |
| `memory.auto_compact` | true | false | — | note only |
| `model.fallbacks` | ≥1 different model | empty or same as primary | — | ⚠️ -10 |
| `subagents.maxConcurrent` | scaled to hardware | default (8) on powerful machine | — | note only |

**Model Fallbacks:** If `agents.defaults.model.fallbacks` is empty or only contains the same model as `primary`, flag ⚠️ — single point of failure. Recommend `fix_cases.md` Case 2.7.

**Concurrency Tuning:** If machine has ≥8 CPU cores and ≥16GB RAM (from `DATA.env`) but `maxConcurrent` ≤ 4 and `subagents.maxConcurrent` ≤ 8, add a note suggesting scaling up. Recommend `fix_cases.md` Case 2.8.

### 2.5 Session Configuration

From `DATA.config.session` and `DATA.openclaw_json`:

| Parameter | Healthy | Warning | Error | Score Impact |
|-----------|---------|---------|-------|-------------|
| `session` section | present | missing entirely | — | ⚠️ -10 |
| `dmScope` | `per-channel-peer` or `per-account-channel-peer` | `main` (all DMs shared) | — | ⚠️ -10 |
| `reset` | configured (daily or idle) | missing | — | ⚠️ -5 |
| `maintenance.mode` | `enforce` | `warn` or missing | — | ⚠️ -5 |
| `maintenance.maxDiskBytes` | set | unset | — | note only |
| `parentForkMaxTokens` | set and ≤ 200000 | unset or > 200000 | — | note only |

If session config is missing or minimal, recommend `fix_cases.md` Case 2.9 with full recommended config.

### 2.6 Models & Rate Limit

From `DATA.config.models`, `DATA.models` and `DATA.logs`:

**Rate Limit:**

| Parameter | Healthy | Warning | Error | Score Impact |
|-----------|---------|---------|-------|-------------|
| `rateLimit.interval` | ≥500 | <500 or unset | — | ⚠️ -5 |
| `rateLimit.maxRequests` | 1–20 | >50 or unset | — | ⚠️ -5 |
| 429 errors in recent logs | 0 | 1–5 in last hour | >5 in last hour | ⚠️ -10 / ❌ -20 |
| `providers.*.rotateKeys` | true (if multi-key) | false with multi-key | — | note only |

Cross-reference: scan `DATA.logs` and `DATA.gateway_err_log` for `429`, `rate limit`, `Too Many Requests`.
If 429 errors detected, flag as ⚠️ or ❌ and recommend `fix_cases.md` Case 2.5.

**Model Context Window:**

Scan all configured models from `DATA.models` (agent/models.json) and `DATA.config.models`:

| Parameter | Healthy | Warning | Error | Score Impact |
|-----------|---------|---------|-------|-------------|
| `contextWindow` per model | ≥100000 | 50000–99999 | <50000 | ⚠️ -10 / ❌ -20 per model |
| `maxTokens` per model | ≥16384 | 4096–16383 | <4096 | ⚠️ -10 / ❌ -20 per model |

For each model with undersized window, output: model name, current values, recommended values.
Recommended: `contextWindow >= 100000`, `maxTokens >= 16384`. For complex skills: `contextWindow >= 500000`, `maxTokens >= 65536`.
If any model flagged, recommend `fix_cases.md` Case 2.6.

### 2.7 Tools Section

From `DATA.config.tools`:

| Parameter | Healthy | Warning | Score Impact |
|-----------|---------|---------|-------------|
| `profile` | set | unset / "default" | note only |
| `mcp_servers` | ≥1 | 0 | ⚠️ -5 |
| `enabled` list | non-empty | empty | ⚠️ -5 |

### 2.8 Gateway Runtime Status

Primary source: `DATA.health` (from `openclaw health --json`). Cross-validate with `DATA.status.overview.gateway`.

| Check | Source | Pass | Error | Score Impact |
|-------|--------|------|-------|-------------|
| `gateway_reachable` | `DATA.health` | true | false | ❌ -30 |
| `gateway_operational` | `DATA.health` | true | false | ❌ -20 |
| Max endpoint latency | `DATA.health` max latency | <500ms | >500ms | ⚠️ -10 |
| All endpoints 200 | `DATA.health` | true | false | ⚠️ -10 |
| Latency cross-check | `status.overview.gateway.latency_ms` | <200ms | >500ms | note only |
| Auth type match | `status.overview.gateway.auth_type` vs config | match | mismatch | ⚠️ note |
| Bind mode match | `status.overview.gateway.bind` vs config | match | mismatch | ⚠️ note |

If `DATA.status.overview.up_to_date = false`: flag ⚠️ (no score impact) with the latest version available
from `DATA.status.overview.latest_version`. Show current vs latest.

If `DATA.status.overview.tailscale_on = true`: note Tailscale network active — affects network exposure
assessment in Stage 4 (treat as `bind=tailnet` equivalent for security posture).

If `DATA.status.diagnosis.config_valid = false` AND `DATA.config.cli_validation.success = true`:
flag as inconsistency ⚠️ — two validation methods disagree.

### 2.9 Channels

Primary source: `DATA.channels`. Cross-validate with `DATA.status.channels[]`.

| Check | Source | Pass | Warning | Score Impact |
|-------|--------|------|---------|-------------|
| `enabled_count ≥ 1` | `DATA.channels` | true | 0 | ⚠️ -10 |
| Channels with issues | `DATA.channels` | 0 | any | ⚠️ -5 each (max -20) |
| Channel state mismatch | `status.channels[].state` ≠ "active" for enabled | 0 | any | ⚠️ -5 each |

For each channel in `DATA.status.channels[]`, if `enabled=true` but `state` is not "active" or "connected",
report channel name + state as a finding. Cross-reference against `DATA.channels` for confirmation.

### 2.10 CLI Tools

From `DATA.tools`:

| Check | Pass | Error | Score Impact |
|-------|------|-------|-------------|
| Core CLI tools all present | true | any missing | ❌ -15 per tool |
| Core MCP tools all present | true | any missing | ❌ -15 per tool |
| openclaw or clawhub available | at least one | neither | ❌ -30 |

---

## Stage 3 — Consistency Checks

From `DATA.config.consistency_issues` (pre-computed by collect-config.sh):

Each item has: `severity` (critical/warning), `field`, `message`.

| Severity | Score Impact |
|----------|-------------|
| `critical` | ❌ -20 each |
| `warning` | ⚠️ -10 each |

Report each consistency issue verbatim with the `field` and `message` from the data.

---

## Stage 4 — Security Posture Assessment

Evaluate gateway security configuration as a combined judgment:

| Configuration Combination | Risk | Status | Score Impact |
|--------------------------|------|--------|-------------|
| `bind=loopback`, any auth | Low risk | ✅ | 0 |
| `bind=lan`, SSL + auth configured | Acceptable | ⚠️ | -5 |
| `bind=lan`, auth configured, no SSL | Plaintext auth | ⚠️ | -15 |
| `bind=lan`, `auth.type=none` | **Critical** | ❌ | -35 |
| `bind=tailnet`, auth configured | Low-Medium | ⚠️ | -5 |
| `bind=tailnet`, `auth.type=none` | Medium | ⚠️ | -15 |
| `controlUI=true` on non-loopback | **Critical** | ❌ | -25 |

Assign a security label to include in the output:
- **Secure**: loopback bind, or LAN+SSL+auth → no security deductions
- **Acceptable**: some exposure but mitigated
- **At Risk**: meaningful exposure without mitigations
- **Critical Exposure**: unauthenticated non-loopback access

---

## Scoring

```
Base score: 100
Apply all score impacts (cumulative, across all 4 stages).
Floor: 0. Ceiling: 100.
```

| Score Range | Status |
|-------------|--------|
| ≥ 75 | ✅ |
| 55–74 | ⚠️ |
| < 55 | ❌ |

---

## Output Format

Produce in REPORT_LANG (all labels and descriptions translated; field names, versions, commands in English):

```
[Configuration Health — translated domain label] [STATUS] — Score: XX/100
[One-sentence summary in REPORT_LANG]

[Validation label in REPORT_LANG]:
  openclaw config validate → [passed/failed — in REPORT_LANG]
  OpenClaw [version] ([commit])   (if version parsed)

[Config File label in REPORT_LANG]:
  [file path]: [valid/invalid/missing]  [X/5 sections present]
  [Extra keys note if any]

[Gateway label in REPORT_LANG]:
  Runtime: [reachable/unreachable] at [url]  latency: Xms
  Config:  bind=[mode]  auth=[type]  reload=[mode]  controlUI=[on/off]
  Security: [Secure / Acceptable / At Risk / Critical Exposure — in REPORT_LANG]

[Agents label in REPORT_LANG]:
  maxConcurrent=[X]  timeout=[X]s  heartbeat=[X]min  autoRecovery=[on/off]
  model=[default_model]

[Tools label in REPORT_LANG]:
  profile=[X]  MCP servers: [X]  enabled tools: [X]

[Channels label in REPORT_LANG]:
  [X] enabled, [X] with issues

[If consistency issues exist — Consistency Issues label in REPORT_LANG:]
  [severity — translated]: [message, field in English]

[If any ⚠️/❌ — Findings label in REPORT_LANG, ordered by severity:]
- [Evidence citing DATA field and actual value]

[Fix Hints label in REPORT_LANG:]
- [Config key + recommended value]
  Rollback: [how to revert]
```
