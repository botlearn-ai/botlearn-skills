---
domain: openclaw-doctor
topic: anomaly-patterns
priority: medium
ttl: 60d
---

# Log Anomaly Patterns Reference

## ANOM-001: Error Spike

**Symptom**: Error count in a time window exceeds 3× the rolling average.

**Detection**: Group errors by hour/minute; compare against baseline.

**Common Causes**:
- External service outage (cascading errors)
- Deployment with breaking change
- Resource exhaustion (memory/disk)
- Config change without restart

**Diagnosis**:
```bash
# Check error distribution
scripts/collect-log-anomalies.sh | node -e "
  const d=JSON.parse(require('fs').readFileSync('/dev/stdin','utf8'));
  d.error_spikes.forEach(s => console.log(s.hour, s.count+'x', '(avg:'+s.average+')'));
"
```

**Fix**: Identify the error type dominating the spike, then apply corresponding fix playbook.

---

## ANOM-002: Stack Trace Accumulation

**Symptom**: Multiple stack traces (>5) in recent logs.

**Detection**: Pattern-match `at <function> (<file>:<line>)` sequences.

**Common Causes**:
- Unhandled exceptions in skill execution
- Incompatible skill versions after upgrade
- Corrupted state or configuration

**Diagnosis**:
1. Group stack traces by top frame
2. Identify most frequent crash point
3. Cross-reference with skill execution logs

**Fix**: Update or reinstall the failing skill; check dependency compatibility.

---

## ANOM-003: OOM / Heap Exhaustion

**Symptom**: `JavaScript heap out of memory`, `ENOMEM`, or `SIGKILL` in logs.

**Detection**: Pattern-match OOM-related keywords.

**Common Causes**:
- Memory leak in long-running skill
- Too many concurrent operations
- Large data set in memory store
- Insufficient Node.js heap size

**Diagnosis**:
```bash
# Check memory usage
scripts/collect-env.sh | node -e "
  const d=JSON.parse(require('fs').readFileSync('/dev/stdin','utf8'));
  console.log('Memory:', Math.round(d.memory.available_mb)+'MB available of '+d.memory.total_mb+'MB');
"
```

**Fix**: See PB-007 (Memory Optimization). Increase heap size, reduce concurrency, clean memory store.

---

## ANOM-004: Unhandled Promise Rejection

**Symptom**: `UnhandledPromiseRejectionWarning` or `PromiseRejectionHandledWarning` in logs.

**Detection**: Pattern-match unhandled promise keywords.

**Impact**: May crash process in future Node.js versions (--unhandled-rejections=throw).

**Common Causes**:
- Missing `catch()` on async operations
- Skill code with incomplete error handling
- Network timeouts without retry logic

**Fix**:
1. Identify the originating skill from stack trace
2. Update the skill: `clawhub update @botlearn/<skill>`
3. If custom skill, add `.catch()` to all promises

---

## ANOM-005: Time-Clustered Errors

**Symptom**: ≥5 errors within a 1-minute window.

**Detection**: Group errors by minute, flag clusters.

**Interpretation**:
| Cluster Size | Severity | Likely Cause |
|-------------|----------|--------------|
| 5-9 | info | Transient issue, monitor |
| 10-19 | warning | Systemic problem developing |
| 20+ | critical | Active incident, investigate immediately |

**Common Patterns**:
- Network blip → connection errors cluster
- Gateway restart → brief error burst (normal)
- Skill cascade failure → sustained cluster

---

## ANOM-006: Excessive Log Growth

**Symptom**: Total log size > 500MB or daily growth > 100MB.

**Detection**: Compare log file sizes and estimate growth rate.

**Common Causes**:
- Debug-level logging in production
- Log rotation disabled
- Verbose error loops (e.g., retry without backoff)
- Request logging at high traffic

**Fix**: See PB-005 (Log Cleanup & Rotation).
```bash
clawhub config set logging.level "info"
clawhub config set logging.rotation.enabled true
clawhub config set logging.rotation.maxSize "100MB"
```

---

## Anomaly Severity Quick Reference

| Anomaly Type | Default Severity | Escalation Trigger |
|-------------|-----------------|-------------------|
| Error spike (3×) | warning | >6× average → critical |
| Stack traces (>5) | warning | >20 → critical |
| OOM event | critical | Always critical |
| Segfault | critical | Always critical |
| Unhandled promise | warning | >10 occurrences → high |
| Time cluster (5+) | info | 20+ → critical |
| Log growth (>500MB) | warning | >1GB → critical |
