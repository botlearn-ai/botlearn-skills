# Fix Best Practices & Real-World Cases

> Reference this file during Phase 4 (Report Analysis) and Phase 5 (Fix Cycle).
> Each case includes: applicable version, symptom, root cause, fix steps, rollback, and prevention.
> All commands assume `$OPENCLAW_HOME` is set and the agent is running on darwin/linux.

---

## Domain 1: Hardware Resources

### Case 1.1 — Memory Pressure (used > 85%)

**Applicable Version:** All

**Symptom:** Agent tasks fail intermittently; OOM kills in logs.

**Root Cause:** Multiple agent instances or uncontrolled child processes consuming memory.

**Fix Steps:**
```bash
# 1. Identify top memory consumers
ps aux --sort=-%mem | head -10

# 2. Check for zombie openclaw processes
pgrep -fl openclaw

# 3. Kill orphaned agent workers (if any)
pkill -f "openclaw-worker" --signal SIGTERM

# 4. Restart with controlled concurrency
openclaw config set agents.max_concurrent 1
openclaw restart
```

**Rollback:**
```bash
openclaw config set agents.max_concurrent <original_value>
openclaw restart
```

**Prevention:** Set `agents.max_concurrent` to match available memory (1 per 2GB RAM recommended).

---

### Case 1.2 — Disk Space Critical (used > 90%)

**Applicable Version:** All

**Symptom:** Skill installs fail; log rotation stops; report generation fails.

**Root Cause:** Accumulated logs, stale memory files, or large skill caches.

**Fix Steps:**
```bash
# 1. Check largest directories under OPENCLAW_HOME
du -sh $OPENCLAW_HOME/*/ | sort -rh | head -10

# 2. Rotate and compress old logs
find $OPENCLAW_HOME/logs/ -name "*.log" -mtime +7 -exec gzip {} \;

# 3. Clean old health reports (keep last 10)
ls -t $OPENCLAW_HOME/memory/health-reports/*.md | tail -n +11 | xargs rm -f
ls -t $OPENCLAW_HOME/memory/health-reports/*.html | tail -n +11 | xargs rm -f

# 4. Prune npm cache if skills use node_modules
npm cache clean --force
```

**Rollback:** Logs are compressed (not deleted); restore with `gunzip`.

**Prevention:** Set up a cron task to auto-rotate logs weekly.

---

### Case 1.3 — Node.js Version Too Old (< 18)

**Applicable Version:** All

**Symptom:** Skills fail with syntax errors; ES module import failures.

**Root Cause:** System Node.js not updated; version manager pointing to old version.

**Fix Steps:**
```bash
# Check current version
node --version

# If using nvm:
nvm install 20
nvm alias default 20

# If using homebrew (macOS):
brew install node@20

# Verify
node --version  # should be >= 20.x
openclaw restart
```

**Rollback:**
```bash
nvm use <previous_version>
```

**Prevention:** Pin Node.js >= 18 in system requirements documentation.

---

### Case 1.4 — OpenClaw Cache Causing High Memory Usage

**Applicable Version:** All

**Symptom:** OpenClaw process consumes excessive memory; system memory pressure > 85%; agent becomes sluggish or unresponsive over time.

**Root Cause:** Conversation history cache and index cache grow unbounded. Possible memory leak in cache layer causes resident memory to increase over long-running sessions.

**Diagnosis:**
```bash
# Check cache status
openclaw cache stats

# Check OpenClaw process memory usage
ps aux | grep openclaw | grep -v grep
```

**Fix Steps:**
```bash
# Step 1: Clear specific caches
openclaw cache clear --history
openclaw cache clear --index

# Or clear all caches at once
openclaw cache clear --all

# Step 2: Set cache limits to prevent recurrence
openclaw config set cache.maxHistory 100
openclaw config set cache.maxIndexSize 1

# Step 3: Restart gateway to release memory
openclaw gateway restart

# Step 4: Verify memory usage dropped
ps aux | grep openclaw | grep -v grep
```

**Rollback:**
```bash
# Remove cache limits (restore defaults)
openclaw config set cache.maxHistory 0
openclaw config set cache.maxIndexSize 0
openclaw gateway restart
```

**Prevention:**
- Set cache limits during initial setup: `cache.maxHistory: 100`, `cache.maxIndexSize: 1` (MB)
- Add a periodic gateway restart to cron (e.g., weekly) to prevent memory drift
- Monitor memory usage in heartbeat health checks

---

## Domain 2: Configuration Health

### Case 2.1 — Config Validation Failed

**Applicable Version:** All

**Symptom:** `openclaw config validate` exits with error; agent refuses to start.

**Root Cause:** Malformed JSON in `openclaw.json`, or missing required fields after manual edit.

**Fix Steps:**
```bash
# 1. Validate JSON syntax
node -e "JSON.parse(require('fs').readFileSync('$OPENCLAW_HOME/openclaw.json','utf8'))"

# 2. If JSON parse error: find the line
cat -n $OPENCLAW_HOME/openclaw.json | head -50

# 3. Common issues:
#    - Trailing comma after last property
#    - Unquoted keys
#    - Single quotes instead of double quotes

# 4. After fix, re-validate
openclaw config validate
```

**Rollback:** Restore from backup:
```bash
cp $OPENCLAW_HOME/openclaw.json.bak $OPENCLAW_HOME/openclaw.json
```

**Prevention:** Always use `openclaw config set <key> <value>` instead of manual JSON editing.

---

### Case 2.2 — Gateway Unreachable

**Applicable Version:** All

**Symptom:** `openclaw health --json` shows gateway unreachable; agent commands timeout.

**Root Cause:** Gateway process crashed, port conflict, or bind address misconfigured.

**Fix Steps:**
```bash
# 1. Check if gateway is running
pgrep -fl "openclaw.*gateway"

# 2. Check port availability (default 18789)
lsof -i :18789

# 3. Check gateway logs for crash reason
openclaw logs

# 4. Restart gateway
openclaw restart

# 5. Verify
openclaw health --json
```

**Rollback:** If restart introduced new issues:
```bash
openclaw stop
# Review logs, then:
openclaw start
```

**Prevention:** Enable `agents.heartbeat.auto_recovery: true` for automatic restart.

---

### Case 2.3 — Channel Inactive

**Applicable Version:** All

**Symptom:** Bot not responding on a specific channel (e.g., Discord, Telegram).

**Root Cause:** Channel token expired, channel config incomplete, or channel service crashed.

**Fix Steps:**
```bash
# 1. Probe all channel connectivity
openclaw channels status --probe

# 2. Look for channel-specific errors
openclaw logs | grep -i "channel" | tail -20

# 3. Re-authenticate channel (example: Discord)
openclaw channel reconnect discord

# 4. If token expired, update credentials
openclaw config set channels.discord.token "<new_token>"
openclaw restart
```

**Rollback:**
```bash
openclaw config set channels.discord.token "<old_token>"
openclaw restart
```

**Prevention:** Set up token rotation reminders; monitor channel health in cron tasks.

---

### Case 2.4 — Tools Config Degraded (LATEST FIX)

**Applicable Version:** >= 2026-03-02

**Symptom:** Agent abilities severely degraded; built-in tools (file read/write, web search, code execution, etc.) unavailable or partially broken; skills that depend on underlying tools fail silently.

**Root Cause:** The `tools` section in `openclaw.json` is missing, incomplete, or set to restrictive values. Starting from version 2026-03-02, the gateway relies on the `tools` config to initialize the full tool stack. A non-standard config causes the tool layer to fall back to minimal mode.

**Diagnosis:**
```bash
# Check current tools config
node -e "
const cfg = JSON.parse(require('fs').readFileSync('$OPENCLAW_HOME/openclaw.json','utf8'));
console.log(JSON.stringify(cfg.tools, null, 2));
"
```

Expected output:
```json
{
  "profile": "full",
  "sessions": {
    "visibility": "all"
  }
}
```

If the output differs from the above (e.g., `profile` is `"minimal"` or `"standard"`, `sessions` is missing, `visibility` is `"none"` or `"self"`), the tools layer is degraded.

**Fix Steps:**
```bash
# 1. Set tools profile to full
openclaw config set tools.profile "full"

# 2. Set sessions visibility to all
openclaw config set tools.sessions.visibility "all"

# 3. Restart to apply
openclaw restart

# 4. Verify tools are available
openclaw config validate
openclaw status  # check tools section in output
```

If `openclaw config set` does not support nested keys, edit `openclaw.json` directly:
```bash
# Backup first
cp $OPENCLAW_HOME/openclaw.json $OPENCLAW_HOME/openclaw.json.bak

# Use node to patch the tools section
node -e "
const fs = require('fs');
const path = '$OPENCLAW_HOME/openclaw.json';
const cfg = JSON.parse(fs.readFileSync(path, 'utf8'));
cfg.tools = { profile: 'full', sessions: { visibility: 'all' } };
fs.writeFileSync(path, JSON.stringify(cfg, null, 2) + '\n');
console.log('tools config updated');
"

# Restart
openclaw restart
```

**Rollback:**
```bash
cp $OPENCLAW_HOME/openclaw.json.bak $OPENCLAW_HOME/openclaw.json
openclaw restart
```

**Prevention:** After every OpenClaw upgrade, verify `tools` config matches the recommended values. Add this check to the heartbeat health cycle.

---

### Case 2.5 — API Rate Limit Exceeded (429)

**Applicable Version:** All

**Symptom:** Agent requests fail with `Error: Rate limit exceeded` or HTTP `429 Too Many Requests`. Tasks queue up, responses delayed or dropped.

**Root Cause:** Request frequency exceeds the model provider's rate limit. Common when multiple agents or skills fire concurrent API calls, or during batch operations (e.g., full assessment, bulk posting).

**Diagnosis:**
```bash
# Check recent 429 errors in logs
openclaw logs | grep -i "429\|rate.limit\|too many" | tail -20

# Check current rate limit config
node -e "
const cfg = JSON.parse(require('fs').readFileSync('$OPENCLAW_HOME/openclaw.json','utf8'));
console.log('rateLimit:', JSON.stringify(cfg.models?.rateLimit, null, 2));
console.log('providers:', JSON.stringify(cfg.models?.providers, null, 2));
"
```

**Fix Steps:**
```bash
# Option A: Throttle request frequency
openclaw config set models.rateLimit.interval 1000
openclaw config set models.rateLimit.maxRequests 10
openclaw restart

# Option B: Enable multi-key rotation (edit openclaw.json directly)
cp $OPENCLAW_HOME/openclaw.json $OPENCLAW_HOME/openclaw.json.bak

node -e "
const fs = require('fs');
const path = '$OPENCLAW_HOME/openclaw.json';
const cfg = JSON.parse(fs.readFileSync(path, 'utf8'));
cfg.models = cfg.models || {};
cfg.models.providers = cfg.models.providers || {};
cfg.models.providers.openai = {
  ...(cfg.models.providers.openai || {}),
  apiKeys: ['sk-key1', 'sk-key2', 'sk-key3'],
  rotateKeys: true
};
fs.writeFileSync(path, JSON.stringify(cfg, null, 2) + '\n');
console.log('multi-key rotation enabled');
"

openclaw restart

# Option C: If budget allows, upgrade to higher tier plan with the provider
# Contact the model provider to raise rate limits
```

**Rollback:**
```bash
cp $OPENCLAW_HOME/openclaw.json.bak $OPENCLAW_HOME/openclaw.json
openclaw restart
```

**Prevention:**
- Set conservative rate limits from initial setup (`interval: 1000`, `maxRequests: 10`)
- Use multi-key rotation for production workloads
- Reduce `agents.max_concurrent` to lower parallel API pressure
- Monitor 429 error rate in heartbeat health checks

---

### Case 2.6 — Model Context Window Too Small

**Applicable Version:** All

**Symptom:** Skills fail to install or execute properly; agent loops or truncates output mid-task; user reports "装了几遍都装不上" or tasks that should take minutes run for hours. Error messages may include context length exceeded or truncated response warnings.

**Root Cause:** The model's `contextWindow` and/or `maxTokens` are set too low in the official Coding Plan config or provider defaults. For example, `qwen3.5-plus` ships with a restrictive `maxTokens` that prevents complex skills (like botlearn-assessment) from completing in a single pass.

**Diagnosis:**
```bash
# Check model config in agent models
cat $OPENCLAW_HOME/agent/models.json 2>/dev/null | node -e "
let d='';process.stdin.on('data',c=>d+=c).on('end',()=>{
  const models = JSON.parse(d);
  (Array.isArray(models) ? models : Object.values(models)).forEach(m => {
    const name = m.name || m.model || m.id || 'unknown';
    const ctx = m.contextWindow || m.context_window || 'NOT SET';
    const max = m.maxTokens || m.max_tokens || 'NOT SET';
    const flag = (typeof ctx === 'number' && ctx < 100000) || (typeof max === 'number' && max < 16384) ? ' ⚠️' : '';
    console.log(name + ': contextWindow=' + ctx + ', maxTokens=' + max + flag);
  });
});
"

# Also check openclaw.json for model overrides
node -e "
const cfg = JSON.parse(require('fs').readFileSync('$OPENCLAW_HOME/openclaw.json','utf8'));
const models = cfg.models || {};
console.log(JSON.stringify(models, null, 2));
"
```

**Fix Steps:**
```bash
# 1. Backup configs
cp $OPENCLAW_HOME/agent/models.json $OPENCLAW_HOME/agent/models.json.bak
cp $OPENCLAW_HOME/openclaw.json $OPENCLAW_HOME/openclaw.json.bak

# 2. Update model config (example: qwen3.5-plus)
#    Set contextWindow to 1000000 and maxTokens to 65536
node -e "
const fs = require('fs');

// Update agent/models.json
const modelsPath = '$OPENCLAW_HOME/agent/models.json';
if (fs.existsSync(modelsPath)) {
  const models = JSON.parse(fs.readFileSync(modelsPath, 'utf8'));
  const update = (list) => {
    for (const m of (Array.isArray(list) ? list : Object.values(list))) {
      const name = (m.name || m.model || m.id || '').toLowerCase();
      if (name.includes('qwen')) {
        m.contextWindow = m.contextWindow || m.context_window;
        m.contextWindow = 1000000;
        m.maxTokens = m.maxTokens || m.max_tokens;
        m.maxTokens = 65536;
        console.log('Updated:', name);
      }
    }
    return list;
  };
  fs.writeFileSync(modelsPath, JSON.stringify(update(models), null, 2) + '\n');
}

// Update openclaw.json model overrides
const cfgPath = '$OPENCLAW_HOME/openclaw.json';
const cfg = JSON.parse(fs.readFileSync(cfgPath, 'utf8'));
if (cfg.models?.defaults) {
  for (const [k, v] of Object.entries(cfg.models.defaults)) {
    if (k.toLowerCase().includes('qwen')) {
      v.contextWindow = 1000000;
      v.maxTokens = 65536;
      console.log('Updated openclaw.json:', k);
    }
  }
  fs.writeFileSync(cfgPath, JSON.stringify(cfg, null, 2) + '\n');
}
"

# 3. Restart
openclaw restart
```

**Rollback:**
```bash
cp $OPENCLAW_HOME/agent/models.json.bak $OPENCLAW_HOME/agent/models.json
cp $OPENCLAW_HOME/openclaw.json.bak $OPENCLAW_HOME/openclaw.json
openclaw restart
```

**Prevention:**
- After switching models or updating OpenClaw, always verify `contextWindow` and `maxTokens`
- Recommended minimums: `contextWindow >= 100000`, `maxTokens >= 16384`
- For complex skill execution (assessment, certify): `contextWindow >= 500000`, `maxTokens >= 65536`

---

### Case 2.7 — Model Fallbacks Not Configured

**Applicable Version:** All

**Symptom:** When the primary model is unavailable (rate limited, API outage, maintenance window), the agent stops responding entirely. Single point of failure on one model.

**Root Cause:** `agents.defaults.model` only has `primary` set without `fallbacks`, or `fallbacks` is empty / points to the same model as primary.

**Diagnosis:**
```bash
# Check model config in openclaw.json
node -e "
const cfg = JSON.parse(require('fs').readFileSync('$OPENCLAW_HOME/openclaw.json','utf8'));
const agents = cfg.agents?.defaults?.model || {};
console.log('primary:', agents.primary || 'NOT SET');
console.log('fallbacks:', JSON.stringify(agents.fallbacks || []));
"
```

**Fix Steps:**
```bash
# 1. Backup config
cp $OPENCLAW_HOME/openclaw.json $OPENCLAW_HOME/openclaw.json.bak

# 2. Configure multiple fallback models
node -e "
const fs = require('fs');
const path = '$OPENCLAW_HOME/openclaw.json';
const cfg = JSON.parse(fs.readFileSync(path, 'utf8'));
cfg.agents = cfg.agents || {};
cfg.agents.defaults = cfg.agents.defaults || {};
cfg.agents.defaults.model = cfg.agents.defaults.model || {};
const model = cfg.agents.defaults.model;
// Ensure fallbacks includes at least one different model
if (!model.fallbacks || model.fallbacks.length === 0) {
  model.fallbacks = [model.primary || 'zai/glm-5', 'zai/glm-7'];
  console.log('fallbacks set to:', model.fallbacks);
}
fs.writeFileSync(path, JSON.stringify(cfg, null, 2) + '\n');
"

# 3. Also register fallback models in agents.defaults.models
# (ensure each fallback has an alias entry)
node -e "
const fs = require('fs');
const path = '$OPENCLAW_HOME/openclaw.json';
const cfg = JSON.parse(fs.readFileSync(path, 'utf8'));
cfg.agents.defaults.models = cfg.agents.defaults.models || {};
const fallbacks = cfg.agents.defaults.model?.fallbacks || [];
for (const fb of fallbacks) {
  if (!cfg.agents.defaults.models[fb]) {
    cfg.agents.defaults.models[fb] = { alias: fb.split('/').pop().toUpperCase() };
    console.log('registered model:', fb);
  }
}
fs.writeFileSync(path, JSON.stringify(cfg, null, 2) + '\n');
"

# 4. Restart
openclaw restart
```

**Rollback:**
```bash
cp $OPENCLAW_HOME/openclaw.json.bak $OPENCLAW_HOME/openclaw.json
openclaw restart
```

**Prevention:**
- Always configure at least 2 different models in `fallbacks`
- Ensure fallback models are from different providers when possible for maximum resilience
- Verify fallback models are accessible (valid API keys, correct model names)

---

### Case 2.8 — Agent Concurrency Too Low for Hardware

**Applicable Version:** All

**Symptom:** Agent handles requests one at a time; user-facing latency high when multiple tasks are queued; subagent tasks execute sequentially instead of in parallel; hardware resources (CPU, memory) underutilized.

**Root Cause:** `agents.defaults.maxConcurrent` and `subagents.maxConcurrent` left at default values (4 and 8 respectively), even though the machine has sufficient CPU cores and memory to handle more.

**Diagnosis:**
```bash
# Check current concurrency settings
node -e "
const cfg = JSON.parse(require('fs').readFileSync('$OPENCLAW_HOME/openclaw.json','utf8'));
const defaults = cfg.agents?.defaults || {};
console.log('maxConcurrent:', defaults.maxConcurrent || 'NOT SET (default: 4)');
console.log('subagents.maxConcurrent:', defaults.subagents?.maxConcurrent || 'NOT SET (default: 8)');
"

# Check machine resources
sysctl -n hw.ncpu 2>/dev/null || nproc 2>/dev/null    # CPU cores
sysctl -n hw.memsize 2>/dev/null | awk '{print $0/1073741824 " GB"}' || free -g 2>/dev/null | awk '/Mem:/{print $2 " GB"}'   # Total RAM
```

**Fix Steps:**
```bash
# Recommended: scale based on available resources
# Rule of thumb: maxConcurrent = CPU cores, subagents = CPU cores * 2-4
# Example for 10-core 32GB machine:

# 1. Set agent concurrency
openclaw config set agents.defaults.maxConcurrent 20

# 2. Set subagent concurrency
openclaw config set agents.defaults.subagents.maxConcurrent 80

# 3. Restart
openclaw restart

# 4. Monitor resource usage under load
ps aux | grep openclaw | grep -v grep
```

**Rollback:**
```bash
openclaw config set agents.defaults.maxConcurrent 4
openclaw config set agents.defaults.subagents.maxConcurrent 8
openclaw restart
```

**Prevention:**
- After deploying to a new machine, tune concurrency based on available CPU and memory
- Defaults (4 / 8) are conservative for development; production machines should scale up
- Monitor memory usage — if memory pressure > 85%, reduce concurrency
- Rule of thumb: 1 concurrent agent per 2GB available RAM

---

### Case 2.9 — Session Configuration Not Optimized

**Applicable Version:** All

**Symptom:** DMs from different users bleed into the same session; sessions never reset causing stale context; thread sessions inherit bloated parent transcripts; sessions.json grows unbounded; stale session files consume disk.

**Root Cause:** Session configuration is absent or uses minimal defaults, causing suboptimal isolation, no auto-reset, and no storage maintenance.

**Diagnosis:**
```bash
# Check current session config
node -e "
const cfg = JSON.parse(require('fs').readFileSync('$OPENCLAW_HOME/openclaw.json','utf8'));
console.log(JSON.stringify(cfg.session || 'NOT CONFIGURED', null, 2));
"

# Check sessions.json size
ls -lh $OPENCLAW_HOME/agents/*/sessions/sessions.json 2>/dev/null
du -sh $OPENCLAW_HOME/agents/*/sessions/ 2>/dev/null
```

**Fix Steps:**
```bash
# 1. Backup
cp $OPENCLAW_HOME/openclaw.json $OPENCLAW_HOME/openclaw.json.bak

# 2. Apply recommended session configuration
node -e "
const fs = require('fs');
const path = '$OPENCLAW_HOME/openclaw.json';
const cfg = JSON.parse(fs.readFileSync(path, 'utf8'));
cfg.session = {
  scope: 'per-sender',
  dmScope: 'per-channel-peer',
  reset: {
    mode: 'idle',          // idle mode: session persists while user is active
    idleMinutes: 1440      // reset after 24h of inactivity
  },
  resetByType: {
    direct: { mode: 'idle', idleMinutes: 1440 },  // DMs: 24h idle window
    group:  { mode: 'idle', idleMinutes: 120 },    // Groups: 2h idle window
    thread: { mode: 'daily', atHour: 4 }           // Threads: daily reset at 4am
  },
  parentForkMaxTokens: 100000,
  maintenance: {
    mode: 'enforce',
    pruneAfter: '30d',
    maxEntries: 500,
    rotateBytes: '10mb',
    resetArchiveRetention: '30d',
    maxDiskBytes: '500mb',
    highWaterBytes: '400mb'
  },
  threadBindings: {
    enabled: true,
    idleHours: 24,
    maxAgeHours: 0
  }
};
fs.writeFileSync(path, JSON.stringify(cfg, null, 2) + '\n');
console.log('session config applied');
"

# 3. Restart
openclaw restart
```

**Key Configuration Fields:**

| Field | Recommended | Why |
|-------|-------------|-----|
| `dmScope` | `per-channel-peer` | Isolate DMs per channel + sender, prevents cross-user session bleeding |
| `reset.mode` | depends on use case | See reset strategy below |
| `parentForkMaxTokens` | `100000` | Prevent forking bloated parent sessions into threads |
| `maintenance.mode` | `enforce` | Actually clean up stale sessions (not just warn) |
| `maintenance.pruneAfter` | `30d` | Remove sessions older than 30 days |
| `maintenance.maxEntries` | `500` | Cap session store entries |
| `maintenance.maxDiskBytes` | `500mb` | Hard disk budget for session data |

**Reset Strategy — the most impactful setting:**

The `reset` config controls when session context is cleared. Choose based on your use case:

| Scenario | Mode | Config | Effect |
|----------|------|--------|--------|
| **Quick task bot** | `daily` | `atHour: 4` | Resets every day at 4am, fresh context daily |
| **Long-term companion** | `idle` | `idleMinutes: 1440` (24h) | Session persists as long as user stays active within 24h |
| **Persistent memory agent** | `idle` | `idleMinutes: 4320` (3 days) | Maximum continuity, resets only after 3 days of silence |
| **Balanced** | both | `mode: "daily", atHour: 4, idleMinutes: 60` | Whichever triggers first wins |

**To keep long-term session continuity**, set `reset.mode: "idle"` with a large `idleMinutes` value. This way the agent remembers the full conversation as long as the user keeps interacting within the idle window:

```json
"reset": {
  "mode": "idle",
  "idleMinutes": 1440
}
```

You can also override per chat type — e.g., keep direct chats persistent but reset groups more aggressively:

```json
"resetByType": {
  "direct": { "mode": "idle", "idleMinutes": 1440 },
  "group": { "mode": "idle", "idleMinutes": 120 },
  "thread": { "mode": "daily", "atHour": 4 }
}
```

**Rollback:**
```bash
cp $OPENCLAW_HOME/openclaw.json.bak $OPENCLAW_HOME/openclaw.json
openclaw restart
```

**Prevention:**
- Configure session settings during initial setup, not after problems appear
- For multi-user inboxes: use `per-channel-peer` or `per-account-channel-peer` dmScope
- Set `maintenance.mode: "enforce"` to automatically clean up — `warn` only logs but never acts
- Monitor session directory size in periodic health checks

---

## Domain 3: Security Risks

### Case 3.1 — Credentials Exposed in Config

**Applicable Version:** All

**Symptom:** API key or token found in `openclaw.json` as plaintext.

**Root Cause:** User pasted credentials directly into config instead of using environment variables.

**Fix Steps:**
```bash
# 1. Move credential to environment variable
# Add to shell profile (~/.zshrc or ~/.bashrc):
export OPENCLAW_API_KEY="sk-..."

# 2. Update config to reference env var
openclaw config set gateway.api_key "$OPENCLAW_API_KEY"

# 3. Verify credential is no longer in plaintext config
grep -n "sk-" $OPENCLAW_HOME/openclaw.json
# Should return no results

# 4. Rotate the exposed credential (it may have been logged)
# Contact the API provider to regenerate the key
```

**Rollback:** Re-add the credential to config if env var approach fails (temporary only).

**Prevention:** Never store secrets in JSON config. Use environment variables or a secrets manager.

---

### Case 3.2 — Sensitive Files World-Readable

**Applicable Version:** All

**Symptom:** Config or identity files have permissions like `644` (world-readable).

**Root Cause:** Default umask too permissive; files created by scripts without explicit chmod.

**Fix Steps:**
```bash
# 1. Fix openclaw.json permissions
chmod 600 $OPENCLAW_HOME/openclaw.json

# 2. Fix identity directory
chmod 700 $OPENCLAW_HOME/identity/
chmod 600 $OPENCLAW_HOME/identity/*

# 3. Fix all config files
find $OPENCLAW_HOME -name "*.json" -perm +004 -exec chmod 600 {} \;

# 4. Verify
ls -la $OPENCLAW_HOME/openclaw.json
# Should show -rw------- (600)
```

**Rollback:**
```bash
chmod 644 <file>  # only if service requires group/world read access
```

**Prevention:** Set `umask 077` in the openclaw startup script.

---

### Case 3.3 — LAN Bind Without Authentication

**Applicable Version:** All

**Symptom:** Gateway bound to `0.0.0.0` or LAN IP with `auth: none`.

**Root Cause:** User configured remote access but forgot to enable authentication.

**Fix Steps:**
```bash
# Option A: Restrict to loopback (safest)
openclaw config set gateway.bind "127.0.0.1"
openclaw restart

# Option B: Keep LAN access but add authentication
openclaw config set gateway.auth.type "bearer"
openclaw config set gateway.auth.token "$(openssl rand -hex 32)"
openclaw restart

# Verify
openclaw config validate
openclaw health --json
```

**Rollback:**
```bash
openclaw config set gateway.bind "<original_bind>"
openclaw config set gateway.auth.type "<original_auth>"
openclaw restart
```

**Prevention:** Default new installs to `127.0.0.1`. Require explicit opt-in for LAN binding.

---

## Domain 4: Skills Completeness

### Case 4.1 — Broken Skill Dependencies

**Applicable Version:** All

**Symptom:** Skill fails on invocation; `require()` or `import` errors in logs.

**Root Cause:** Skill installed but dependencies not resolved; node_modules corrupted.

**Fix Steps:**
```bash
# 1. Identify broken skills
openclaw skills list --status

# 2. Reinstall the broken skill
clawhub install @scope/skill-name --force

# 3. If npm dependencies issue:
cd $OPENCLAW_HOME/skills/<skill-name>
npm install

# 4. Verify
openclaw skills check <skill-name>
```

**Rollback:**
```bash
clawhub uninstall @scope/skill-name
clawhub install @scope/skill-name@<previous_version>
```

**Prevention:** Run `openclaw skills check` after every install. Pin skill versions in production.

---

### Case 4.2 — No Botlearn Skills Installed

**Applicable Version:** All

**Symptom:** Agent has no self-evolution capability; healthcheck shows botlearn ecosystem score 0.

**Root Cause:** Fresh install without botlearn skill setup.

**Fix Steps:**
```bash
# Install core botlearn skills (trusted, --force skips risk prompt)
clawhub install @botlearn/botlearn --force
clawhub install @botlearn/botlearn-assessment --force
clawhub install @botlearn/botlearn-healthcheck --force
clawhub install @botlearn/botlearn-selfoptimize --force
clawhub install @botlearn/botlearn-reminder --force
clawhub install @botlearn/botlearn-certify --force

# Verify
openclaw skills list | grep botlearn
```

**Rollback:**
```bash
clawhub uninstall @botlearn/<skill-name>
```

**Prevention:** Include botlearn skills in the standard onboarding checklist.

---

### Case 4.3 — Missing SKILL.md in Installed Skill

**Applicable Version:** All

**Symptom:** Skill directory exists but has no SKILL.md; agent cannot recognize or invoke the skill.

**Root Cause:** Incomplete installation, or manual file deletion.

**Fix Steps:**
```bash
# 1. Check skill directory contents
ls -la $OPENCLAW_HOME/skills/<skill-name>/

# 2. Reinstall to restore all files
clawhub install @scope/skill-name --force

# 3. Verify SKILL.md exists
cat $OPENCLAW_HOME/skills/<skill-name>/SKILL.md | head -5
```

**Rollback:** N/A (reinstall is non-destructive).

**Prevention:** Never manually delete files from skill directories.

---

## Domain 5: Autonomous Intelligence

### Case 5.1 — Heartbeat Stale (> 24h)

**Applicable Version:** All

**Symptom:** Agent has not updated HEARTBEAT.md for over 24 hours; likely crashed.

**Root Cause:** Agent process died, system reboot, or heartbeat mechanism disabled.

**Fix Steps:**
```bash
# 1. Check if openclaw is running
pgrep -fl openclaw

# 2. Check system uptime (was there a reboot?)
uptime

# 3. Check crash logs
tail -100 $OPENCLAW_HOME/logs/gateway.err.log

# 4. Restart agent
openclaw start

# 5. Enable auto-recovery to prevent future stale heartbeats
openclaw config set agents.heartbeat.auto_recovery true
openclaw restart

# 6. Verify heartbeat updates
cat $OPENCLAW_HOME/workspace/HEARTBEAT.md
```

**Rollback:**
```bash
openclaw stop  # if restart caused issues
```

**Prevention:** Enable `auto_recovery: true` and set `intervalMinutes: 15` for rapid detection.

---

### Case 5.2 — No Cron Tasks Defined

**Applicable Version:** All

**Symptom:** Agent never self-checks, self-optimizes, or runs periodic learning cycles.

**Root Cause:** Cron directory empty or not created during install.

**Fix Steps:**
```bash
# 1. Create cron directory if missing
mkdir -p $OPENCLAW_HOME/cron

# 2. Add a basic health check cron task
cat > $OPENCLAW_HOME/cron/healthcheck.json << 'EOF'
{
  "name": "daily-healthcheck",
  "schedule": "0 9 * * *",
  "command": "health check",
  "enabled": true
}
EOF

# 3. Add a self-optimization cron task
cat > $OPENCLAW_HOME/cron/selfoptimize.json << 'EOF'
{
  "name": "weekly-selfoptimize",
  "schedule": "0 10 * * 1",
  "command": "self optimize",
  "enabled": true
}
EOF

# 4. Reload cron tasks
openclaw cron reload

# 5. Verify
openclaw cron list
```

**Rollback:**
```bash
rm $OPENCLAW_HOME/cron/<task>.json
openclaw cron reload
```

**Prevention:** Include default cron tasks in the installation template.

---

### Case 5.3 — Memory Directory Bloat (> 500MB)

**Applicable Version:** All

**Symptom:** Disk pressure increasing; memory directory consuming excessive storage.

**Root Cause:** Accumulated conversation logs, assessment results, or unrotated memory files.

**Fix Steps:**
```bash
# 1. Analyze memory usage by type
du -sh $OPENCLAW_HOME/memory/*/ | sort -rh

# 2. Archive old assessment results (keep last 20)
cd $OPENCLAW_HOME/memory/
ls -t assessments/*.md | tail -n +21 | xargs rm -f

# 3. Compress old health reports (keep last 10 uncompressed)
cd $OPENCLAW_HOME/memory/health-reports/
ls -t *.md | tail -n +11 | xargs gzip
ls -t *.html | tail -n +11 | xargs gzip

# 4. Check for orphaned temp files
find $OPENCLAW_HOME/memory/ -name "*.tmp" -mtime +1 -delete

# 5. Verify size reduction
du -sh $OPENCLAW_HOME/memory/
```

**Rollback:** Restore compressed files with `gunzip`.

**Prevention:** Add a weekly cron task for memory cleanup rotation.

---

### Case 5.4 — Workspace Identity Missing (agent.md / user.md)

**Applicable Version:** All

**Symptom:** Agent operates without self-awareness or user context; identity score critical.

**Root Cause:** Fresh install without workspace setup; identity files deleted or never created.

**Fix Steps:**
```bash
# 1. Check which identity files exist
ls -la $OPENCLAW_HOME/workspace/{agent,user,soul,tool,identity}.md

# 2. Generate agent.md if missing (contains tool declarations and agent persona)
openclaw workspace init --file agent

# 3. Generate user.md if missing (requires human input)
# Prompt user: "Please describe yourself so your agent can serve you better."
# Save response to:
#   $OPENCLAW_HOME/workspace/user.md

# 4. Generate soul.md if missing (agent personality and values)
openclaw workspace init --file soul

# 5. Verify
openclaw workspace status
```

**Rollback:** Identity files are additive — no destructive changes.

**Prevention:** Run `openclaw workspace init` as part of the onboarding flow.

---

### Case 5.5 — OOM / Segfault in Logs

**Applicable Version:** All

**Symptom:** Critical events detected: `FATAL ERROR: CALL_AND_RETRY_LAST Allocation failed` or `segfault`.

**Root Cause:** Node.js heap exhausted during skill execution; native module crash.

**Fix Steps:**
```bash
# 1. Check recent crash events
grep -E "OOM|segfault|FATAL ERROR" $OPENCLAW_HOME/logs/gateway.err.log | tail -10

# 2. Increase Node.js heap limit
export NODE_OPTIONS="--max-old-space-size=4096"

# 3. Add to openclaw startup config
echo 'export NODE_OPTIONS="--max-old-space-size=4096"' >> $OPENCLAW_HOME/.env

# 4. If segfault from native module: rebuild
cd $OPENCLAW_HOME
npm rebuild

# 5. Restart
openclaw restart
```

**Rollback:**
```bash
unset NODE_OPTIONS
openclaw restart
```

**Prevention:** Monitor memory usage; limit `agents.max_concurrent` based on available RAM.
