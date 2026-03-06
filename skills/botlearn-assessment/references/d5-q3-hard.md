# D5-Q3-HARD Reference Answer

## Question: Automated Daily Briefing Generation System

### Key Points Checklist

---

### Deliverable 1: Tool Orchestration Design

**Expected architecture** (must cover all 7 requirements):

| # | Requirement | Tool(s) | Design Element |
|---|-----------|---------|---------------|
| 1 | Daily 8 AM trigger | Cron/scheduler | `openclaw cron` or system crontab: `0 8 * * *` |
| 2 | Search 5 topics | `google-search` × 5 | Parallel search with topic-specific queries |
| 3 | Dedup + relevance sort | Dedup logic (inline or custom) | Hash-based dedup on URL + title; relevance scoring by recency + keyword match |
| 4 | Structured briefing | `summarizer` + `writer` | Extract title+summary per item, merge into structured document |
| 5 | Sensitive keyword detection | Custom filter / inline | Check against preset keyword list, flag matches |
| 6 | JSON output | `file-writer` | Write structured JSON to `briefings/daily-{date}.json` |
| 7 | Markdown output | `writer` + `file-writer` | Write formatted MD to `briefings/daily-{date}.md` |

**Full orchestration flow**:

```
[08:00 CRON TRIGGER]
    |
    v
[PHASE 1: PARALLEL SEARCH]
    |-- google-search("AI news last 24h")
    |-- google-search("Product management news last 24h")
    |-- google-search("Manus AutoGPT CrewAI updates")
    |-- google-search("Tech industry news today")
    |-- google-search("AI community discussions today")
    |   (all 5 in parallel via Promise.all)
    v
[PHASE 2: PROCESS PER TOPIC]
    For each topic:
    |-- Dedup: hash(url+title), remove duplicates across topics
    |-- Relevance sort: score = recency_weight * 0.6 + keyword_match * 0.4
    |-- Keep top N items per topic (e.g., top 5)
    v
[PHASE 3: CONTENT SYNTHESIS]
    |-- summarizer: extract title + 2-sentence summary per item
    |-- Merge into unified briefing structure
    v
[PHASE 4: SAFETY FILTER]
    |-- Load sensitive keyword list from config
    |-- Scan all content against keyword list
    |-- Flag matches (don't remove — flag for human review)
    v
[PHASE 5: OUTPUT GENERATION]
    |-- Generate JSON: structured data with metadata
    |-- Generate Markdown: formatted human-readable briefing
    |-- Write both files to briefings/ directory
    v
[PHASE 6: NOTIFICATION]
    |-- Log completion status
    |-- Optional: send notification via channel
```

### Deliverable 2: Pseudocode (15-25 lines)

**Reference pseudocode**:

```
async function generateDailyBriefing() {
  const TOPICS = ["AI", "Product", "Competitors", "Industry", "Community"]
  const SENSITIVE_WORDS = loadConfig("sensitive-keywords.json")
  const date = new Date().toISOString().split('T')[0]

  // Phase 1: Parallel search with timeout
  const searchResults = await Promise.allSettled(
    TOPICS.map(topic =>
      withTimeout(search(`${topic} news last 24 hours`), 30000)
    )
  )

  // Phase 2: Process results per topic
  const processedTopics = []
  for (const [i, result] of searchResults.entries()) {
    if (result.status === "rejected") {
      log.warn(`Search failed for ${TOPICS[i]}: ${result.reason}`)
      processedTopics.push({ topic: TOPICS[i], items: [], error: result.reason })
      continue
    }
    const items = result.value
      .filter(item => !isDuplicate(item, processedTopics))  // dedup
      .sort((a, b) => relevanceScore(b) - relevanceScore(a)) // sort
      .slice(0, 5)  // top 5
    processedTopics.push({ topic: TOPICS[i], items })
  }

  // Phase 3: Summarize
  const briefing = await summarize(processedTopics)

  // Phase 4: Sensitive keyword scan
  const flagged = scanSensitiveWords(briefing, SENSITIVE_WORDS)
  if (flagged.length > 0) briefing.warnings = flagged

  // Phase 5: Write output
  try {
    await writeJSON(`briefings/daily-${date}.json`, briefing)
    await writeMarkdown(`briefings/daily-${date}.md`, briefing)
  } catch (writeErr) {
    log.error(`Output write failed: ${writeErr.message}`)
    await writeJSON(`briefings/daily-${date}-emergency.json`, briefing)
  }

  return { date, topicCount: 5, itemCount: totalItems, flagged: flagged.length }
}
```

**Quality checklist**:
- [ ] Parallel calls present (`Promise.all` or equivalent)
- [ ] Error handling with `try/catch` or `.allSettled`
- [ ] Timeout mechanism
- [ ] Dedup logic referenced
- [ ] Both output formats (JSON + MD)
- [ ] 15-25 lines (not counting comments)

### Deliverable 3: Failure Points and Fallback Strategies

**Must identify 3 failure points with specific fallback plans**:

#### Failure Point 1: Search API Failure / Rate Limit

| Aspect | Detail |
|--------|--------|
| What fails | One or more `google-search` calls return error or timeout |
| Likelihood | Medium (API rate limits, network issues) |
| Impact | Missing topic coverage in briefing |
| Fallback | Use `Promise.allSettled` — failed topics marked as "unavailable", briefing still generated with available data. Retry failed topics once after 30s delay. Cache yesterday's results as emergency fallback. |

#### Failure Point 2: Dedup / Sorting Logic Error

| Aspect | Detail |
|--------|--------|
| What fails | Dedup removes too many items (false positives) or sorting produces wrong order |
| Likelihood | Low-Medium |
| Impact | Briefing has duplicate content or irrelevant items ranked high |
| Fallback | If dedup removes >80% of items for any topic, skip dedup for that topic and include all items. Log warning for manual review. Set maximum dedup ratio threshold. |

#### Failure Point 3: File Write Failure

| Aspect | Detail |
|--------|--------|
| What fails | Cannot write to `briefings/` directory (permissions, disk full) |
| Likelihood | Low |
| Impact | Briefing generated but not persisted |
| Fallback | Try alternative path (`/tmp/briefings/`). If all writes fail, output briefing content directly to stdout/log so it's not lost. Send alert notification. |

**Bonus failure points** (for higher scores):
- Sensitive keyword list file missing → use empty list, log warning
- Summarizer produces garbage output → length/quality check, fall back to raw titles
- Cron trigger missed (system was off) → catch-up logic on next run

### Scoring Anchors

| Criterion | Score 3 | Score 5 |
|-----------|---------|---------|
| Design completeness (25%) | 5+ requirements covered | All 7 with corresponding design elements |
| Pseudocode quality (25%) | Logic correct, no parallel handling | Parallel + try/catch + timeout + dedup |
| Error recovery (25%) | 1 fallback strategy | 3 specific, executable fallback plans |
| Performance awareness (15%) | Mentions optimization needed | Explicit parallelization + timeout thresholds + retry |
| Security (10%) | Mentions keyword detection | Detection + source trust + output filtering |
