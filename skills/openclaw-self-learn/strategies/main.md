---
strategy: openclaw-self-learn
version: 2.0.0
stages: 6
pipeline: bootstrap-test-learn-practice-apply-evaluate
---

# Five-Phase Learning Pipeline (测学练用评)

## Overview

```
[Stage 0: Bootstrap] → [测 Test] → [学 Learn] → [练 Practice] → [用 Apply] → [评 Evaluate]
                             ↑                                                        |
                             └────────────────── Schedule Next ───────────────────────┘
```

Each stage has a dedicated script, clear inputs/outputs, and error handling.

---

## Stage 0: Bootstrap — 首次运行检测与初始化

**Purpose**: Ensure the skill's runtime environment is ready before executing any phase.
**When**: Every activation (both scheduled and manual). Runs fast if already initialized.

### Steps

1. **Check initialization marker**
   ```bash
   SNAPSHOT_FILE="${OPENCLAW_HOME:-$HOME/.openclaw}/data/self-learn/snapshots/latest.json"
   if [ -f "$SNAPSHOT_FILE" ]; then
     echo "✅ Already initialized, proceeding to Stage 1"
     # → Jump to Stage 1
   else
     echo "🔧 First run detected, starting setup..."
     # → Continue to step 2
   fi
   ```

2. **Verify requirements** (from `requirement.md`)
   ```bash
   # Required checks
   node --version    # >= 18
   curl --version    # any
   jq --version      # >= 1.6
   bash --version    # >= 4.0
   clawhub --version 2>/dev/null || openclaw --version 2>/dev/null  # at least one
   ```
   - IF any required check fails → STOP, report missing dependency with install instructions
   - IF all pass → continue

3. **Install dependency skill**
   ```bash
   # Check if google-search is installed
   clawhub list 2>/dev/null | grep -q "google-search" || clawhub install @botlearn/google-search
   ```

4. **Set script permissions**
   ```bash
   chmod +x scripts/collect-dissatisfaction.sh
   chmod +x scripts/search-skills.sh
   chmod +x scripts/attempt-task.sh
   chmod +x scripts/notify-owner.sh
   chmod +x scripts/record-cycle.sh
   ```

5. **Initialize data directory**
   ```bash
   DATA_DIR="${OPENCLAW_HOME:-$HOME/.openclaw}/data/self-learn"
   mkdir -p "$DATA_DIR"/{cycles,tasks,patterns,snapshots}
   [ -f "$DATA_DIR/tasks/registry.json" ] || echo '{"version":"2.0.0","tasks":{}}' > "$DATA_DIR/tasks/registry.json"
   [ -f "$DATA_DIR/patterns/successful-patterns.json" ] || echo '{"version":"2.0.0","patterns":[]}' > "$DATA_DIR/patterns/successful-patterns.json"
   [ -f "$DATA_DIR/patterns/failed-approaches.json" ] || echo '{"version":"2.0.0","approaches":[]}' > "$DATA_DIR/patterns/failed-approaches.json"
   [ -f "$DATA_DIR/patterns/skill-effectiveness.json" ] || echo '{"version":"2.0.0","skills":{}}' > "$DATA_DIR/patterns/skill-effectiveness.json"
   [ -f "$DATA_DIR/snapshots/latest.json" ] || echo '{"version":"2.0.0","total_cycles":0,"last_cycle":null,"summary":{}}' > "$DATA_DIR/snapshots/latest.json"
   [ -f "$DATA_DIR/pending-notifications.json" ] || echo '[]' > "$DATA_DIR/pending-notifications.json"
   ```

6. **Ask owner about optional setup** (manual trigger only; skip in auto/heartbeat mode)
   - "是否要配置 BotLearn 社区连接？" → IF yes → run `setup.md` Step 6
   - "是否要注册定时自动学习？" → IF yes → offer three options from `setup.md` Step 7:
     - Option A: OpenClaw Crontab (推荐)
     - Option B: System Crontab
     - Option C: Gateway Heartbeat

7. **Smoke test**
   ```bash
   for f in scripts/*.sh; do bash -n "$f" && echo "✅ $f OK" || echo "❌ $f FAILED"; done
   ```
   - IF any script fails syntax check → STOP, report error

8. **Record bootstrap completion**
   - Log: "Bootstrap completed at {timestamp}"
   - → Proceed to Stage 1

### Conditional Branches

- **IF already initialized (step 1 passed)**: Skip directly to Stage 1 (< 1ms overhead)
- **IF scheduled/heartbeat trigger**: Skip step 6 (don't prompt owner), use defaults for optional config
- **IF requirements fail**: Report specific missing deps, provide install commands, STOP
- **IF data directory already partially exists**: Only create missing subdirs/files, don't overwrite existing data

---

## Stage 1: 测 (Test) — Dissatisfaction Mining

**Script**: `scripts/collect-dissatisfaction.sh`
**Input**: Memory API sessions, error logs, feedback data
**Output**: Ranked candidates array with dissatisfaction scores

### Steps

1. **Run collection script**
   ```bash
   RESULT=$(bash scripts/collect-dissatisfaction.sh)
   ```

2. **Parse candidates**
   ```
   candidates = RESULT.candidates
   count = RESULT.candidates_found
   ```

3. **Select target task**
   - Sort by `dissatisfaction_score` descending
   - Pick the highest-scoring candidate NOT in task registry as `in_progress`
   - Pick candidate with attempts < 3 (avoid over-retrying)
   - IF no candidates found → report "no dissatisfaction" → skip to Stage 5 (evaluate with empty cycle)

4. **Record selection**
   - Store selected task_id, session_id, dissatisfaction_score, selection_reason
   - Mark task as `in_progress` in task registry

### Conditional Branches

- **IF candidates_found == 0**: Log "clean state, no learning needed" → extend next interval to 8h → go to Stage 5
- **IF all top candidates have attempts >= 3**: Send `needs-approval` notification asking owner which task to focus on → WAIT for response or timeout (60 min)
- **IF Memory API unreachable**: Retry once after 30s → if still fails, send `error` notification → abort cycle

---

## Stage 2: 学 (Learn) — Skill Discovery

**Script**: `scripts/search-skills.sh`
**Input**: Keywords from target task, task type
**Output**: Ranked skill candidates, community posts

### Steps

1. **Extract keywords from target task**
   - Parse `original_request` for domain terms
   - Extract error types if present (timeout, parsing, API error, etc.)
   - Determine task category (information-retrieval, content-processing, programming-assistance, creative-generation)

2. **Run search script**
   ```bash
   SEARCH=$(bash scripts/search-skills.sh --keywords "$KEYWORDS" --task-type "$TASK_TYPE")
   ```

3. **Evaluate results**
   - Filter candidates with `relevance_score > 0.5`
   - Check if any already-installed skills could help (source: local_registry)
   - Select top 3 candidates for installation (or fewer if not enough quality matches)

4. **Community search (if search results insufficient)**
   - IF `candidates_found < 2` AND BotLearn token available:
     - Check community_posts from search results
     - IF helpful posts found → extract skill recommendations from posts
     - IF no helpful posts → draft community question using @references/botlearn-guide.md template
     - Post question (requires: search first, `[Self-Learn]` prefix, include context)
   - IF expert agent identified in community → send DM request (max 1 per cycle)

5. **Install skills** (max 3 per cycle)
   ```bash
   for skill in $SELECTED_SKILLS; do
     clawhub install "$skill"
   done
   ```
   - IF installing > 3 skills → send `needs-approval` notification → WAIT
   - Verify installation success via `clawhub list`

6. **Record learn phase data**
   - Store: keywords, search sources, skills_found, skills_installed, community_interactions

### Conditional Branches

- **IF npm/community search fails (network)**: Use local_registry results only → proceed with what's available
- **IF BotLearn token not configured**: Skip community search → note in cycle record
- **IF rate limited by BotLearn API**: Wait for reset → use cached results
- **IF no relevant skills found anywhere**: Record "no skills found" → still proceed to Stage 3 (reattempt with existing capabilities)

---

## Stage 3: 练 (Practice) — Task Reattempt

**Script**: `scripts/attempt-task.sh`
**Input**: task_id, session_id, installed skills
**Output**: Before/after comparison, improvement score, status

### Steps

1. **Check preconditions**
   - Verify target task is still valid (not cancelled by owner)
   - Check `@knowledge/anti-patterns.md` for "The Blind Retrier" — if no new skills installed AND no community knowledge gained, record `skipped` and note reason

2. **Run reattempt script**
   ```bash
   ATTEMPT=$(bash scripts/attempt-task.sh \
     --task-id "$TASK_ID" \
     --session-id "$SESSION_ID" \
     --new-skills "$SKILLS_CSV")
   ```

3. **Parse results**
   ```
   before = ATTEMPT.before_state
   after = ATTEMPT.after_state
   improvement = ATTEMPT.improvement_score
   status = ATTEMPT.status
   ```

4. **Handle outcomes**

   **IF status == "solved" (score >= 0.7)**:
   - Celebrate! Record solution approach
   - Prepare `task-solved` notification for Stage 4

   **IF status == "improved" (score >= 0.1)**:
   - Record improvement details
   - Prepare `cycle-complete` notification with positive update

   **IF status == "no_change" (score -0.1 to 0.1)**:
   - Record what was tried
   - Prepare `cycle-complete` notification noting no change
   - Consider different approach next cycle

   **IF status == "degraded" (score < -0.1)**:
   - Trigger rollback (script handles this)
   - Record as failed approach
   - Do NOT prepare task-solved notification
   - Prepare `cycle-complete` notification noting rollback

5. **Record practice phase data**
   - Store: before_state, after_state, improvement_score, status, rolled_back

### Conditional Branches

- **IF task execution times out (> 120s)**: Kill execution → status = "no_change" → record timeout → proceed
- **IF Memory API cannot load task context**: Use best-effort reconstruction → proceed with warning
- **IF rolled back**: Record rollback reason → add to failed-approaches.json

---

## Stage 4: 用 (Apply) — Owner Notification

**Script**: `scripts/notify-owner.sh`
**Input**: notification type, cycle data
**Output**: delivery status, notification ID

### Steps

1. **Determine notification type**
   - `task-solved`: if practice status == "solved"
   - `cycle-complete`: default for all other outcomes
   - `needs-approval`: if pending approval requests from earlier stages
   - `error`: if any phase encountered a critical error

2. **Build notification data**
   - Use cycle data collected from stages 1-3
   - Format using templates from @references/notification-templates.md
   - Include action buttons appropriate to the notification type

3. **Send notification**
   ```bash
   NOTIF=$(bash scripts/notify-owner.sh \
     --type "$NOTIFY_TYPE" \
     --data "$NOTIFY_JSON")
   ```

4. **Handle delivery result**

   **IF delivery_status == "delivered"**:
   - Record notification_id
   - Proceed to Stage 5

   **IF delivery_status == "queued"**:
   - Notification saved to pending-notifications.json
   - Will retry on next cycle
   - Proceed to Stage 5

   **IF delivery_status == "failed"**:
   - Log delivery failure
   - Proceed to Stage 5 (don't let notification failure block evaluation)

5. **Retry pending notifications** (from previous cycles)
   - Check `pending-notifications.json` for items with retry_count < 3
   - Attempt to resend each
   - Remove successfully delivered, increment retry_count for failures

### Conditional Branches

- **IF owner responds with feedback during notification wait**: Incorporate rating into cycle record
- **IF owner clicks "Pause Learning"**: Set a pause flag → next scheduled trigger respects pause → send confirmation

---

## Stage 5: 评 (Evaluate) — Cycle Evaluation & Persistence

**Script**: `scripts/record-cycle.sh`
**Input**: Complete cycle record (stdin JSON)
**Output**: cycle_id, stored status, patterns extracted

### Steps

1. **Collect owner rating** (if available)
   - Check if owner has rated this cycle (from notification callback)
   - Default to null if no rating received

2. **Build complete cycle record**
   - Assemble all phase data into structure matching @assets/cycle-schema.json
   - Include: version, cycle_id, timestamp, trigger, target_task, phases{}, outcome{}, metrics{}
   - Generate cycle_id: `cycle-YYYY-MM-DD-HHmmss-xxxx`

3. **Record cycle**
   ```bash
   echo "$CYCLE_JSON" | bash scripts/record-cycle.sh
   ```

4. **Parse recording results**
   ```
   stored = RECORD.stored
   patterns_extracted = RECORD.patterns_extracted
   total_cycles = RECORD.total_cycles
   ```

5. **Extract learning insights**
   - Review successful-patterns.json for recurring approaches
   - Review failed-approaches.json to avoid repeating mistakes
   - Check skill-effectiveness.json for poorly performing skills (< 40%)

6. **Schedule next cycle**
   Based on outcome:
   - `solved` → next interval: 8h (success, relax)
   - `improved` → next interval: 4h (standard)
   - `no_change` → next interval: 4h (standard, try different approach)
   - `degraded` → next interval: 2h (urgent, retry soon)
   - `abandoned` → next interval: 4h (standard)
   - No candidates found → next interval: 8h (nothing to do)

7. **Generate report**
   - Level 1 summary card (always)
   - Level 2 cycle summary (for notifications)
   - Level 3 deep analysis (on demand only)
   - Use templates from @references/cycle-report-templates.md

### Conditional Branches

- **IF schema validation fails**: Log errors → store partial record with `validation_warning` flag
- **IF disk space > 100MB**: Add warning to next cycle notification
- **IF 5+ consecutive no_change**: Suggest owner intervention in next notification

---

## Error Handling Protocol

### Per-Phase Error Recovery

| Phase | Error | Recovery |
|-------|-------|----------|
| 测 | Memory API down | Retry 1x → abort with error notification |
| 测 | No candidates | Skip to evaluate, schedule 8h |
| 学 | Network failure | Use local registry only |
| 学 | Rate limited | Wait + use cached results |
| 练 | Execution timeout | Status = no_change, record timeout |
| 练 | Task context missing | Best-effort reconstruction |
| 用 | Notification failed | Queue for retry |
| 评 | Schema validation | Store with warning flag |
| 评 | Disk write failed | Log critical error, send notification |

### Abort Conditions (stop cycle immediately)
- Memory API unreachable after retry
- Disk write permission denied
- Owner has set "pause learning" flag
- 3+ consecutive critical errors

### Partial Cycle Recording
Even if a cycle is aborted, record what was completed:
- Set outcome.status = "abandoned"
- Include phases completed so far
- Note abort reason in outcome.lessons_learned

---

## Self-Correction Checklist

Before completing each cycle, verify:

- [ ] Only one cycle running at a time (check registry)
- [ ] Target task is not already solved
- [ ] Skills installed ≤ 3 (or approval obtained)
- [ ] Community posts searched before posting
- [ ] Improvement score calculated from real before/after data
- [ ] Rollback triggered if degraded
- [ ] Notification sent (or queued)
- [ ] Cycle record passes schema validation
- [ ] Task registry updated
- [ ] Patterns extracted
- [ ] Snapshot updated
- [ ] Next cycle scheduled

---

## Safety Checkpoints

### Pre-Cycle
1. Check for pause flag → IF set, skip cycle
2. Check for in-progress cycle → IF found, wait or abandon stale (> 30min)
3. Verify data directory writable

### Mid-Cycle
4. Monitor total elapsed time → abort if > 15 minutes
5. Check each phase duration → abort phase if > 5 minutes
6. Verify no credentials in outgoing data

### Post-Cycle
7. Validate cycle record schema
8. Verify append-only write (no existing files modified)
9. Confirm notification delivery or queuing
