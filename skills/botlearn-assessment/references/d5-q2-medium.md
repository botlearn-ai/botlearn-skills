# D5-Q2-MEDIUM Reference Answer

## Question: Multi-Tool Workflow for Weekly Competitor Monitoring Report

### Key Points Checklist

---

### Complete Workflow Design

**Expected flow** (8-10 steps):

```
Step 1: TRIGGER (weekly schedule)
  → Input: 3 competitor names [Manus, AutoGPT, CrewAI]
  → Input: date range = last 7 days

Step 2: PARALLEL SEARCH (google-search × 3)
  → Search: "{competitor} updates news {date range}" for each competitor
  → Run all 3 searches in parallel (key optimization point)
  → Output: 3 sets of search results

Step 3: SUMMARIZE (summarizer × 3)
  → For each competitor: extract key update points from search results
  → Input: raw search results per competitor
  → Output: structured update summaries (bullet points)

Step 4: CONDITIONAL CHECK
  → IF any competitor search returned 0 results:
    → Fallback: search "{competitor} GitHub releases" or "{competitor} blog"
    → IF still 0: mark as "No updates found this week"

Step 5: READ OPENCLAW FEATURES (file-reader)
  → Read: OpenClaw current feature list / changelog
  → Output: structured feature set for comparison

Step 6: GAP ANALYSIS (reasoning / summarizer)
  → Compare: competitor updates vs OpenClaw features
  → Identify: capability gaps, areas where OpenClaw leads, areas behind
  → Output: structured comparison data

Step 7: GENERATE REPORT (writer)
  → Input: competitor summaries + gap analysis
  → Format: Markdown with comparison tables
  → Structure: per-competitor section + summary table + gap analysis

Step 8: TRANSLATE SUMMARY (translator)
  → Input: report summary section only (not full report)
  → Target: Chinese
  → Output: Chinese summary appended to report

Step 9: SAVE (file-writer)
  → Save: Markdown report to local file
  → Path: reports/competitor-weekly-{date}.md

Step 10: NOTIFY
  → Output: completion message with report path
```

### Tool Coverage (25%)

**Required tools and their roles**:

| Tool | Role in Workflow | Required? |
|------|-----------------|-----------|
| `google-search` | Search competitor updates | Yes |
| `summarizer` | Extract key points from search results | Yes |
| `file-reader` | Read OpenClaw's own feature list | Yes |
| `writer` | Generate the Markdown report | Yes |
| `translator` | Translate summary to Chinese | Yes |
| `file-writer` / output | Save the report | Optional (implied) |

Score 3: Covers 4 main tools. Score 5: All tools with parameter descriptions.

### Data Flow Description (30%)

**Each step must have explicit input/output**:

```
google-search output → summarizer input (raw results → key points)
summarizer output → writer input (structured summaries → report sections)
file-reader output → gap analysis input (OpenClaw features → comparison)
writer output → translator input (report summary → Chinese translation)
```

**Score 3**: Partial data flow described.
**Score 5**: Every step has explicit input source and output destination with data format notes.

### Conditional Branch Handling (20%)

**Must include at least 2 conditional branches**:

1. **Empty search results fallback**:
   ```
   IF google-search returns 0 results for a competitor:
     → TRY alternative search (GitHub releases, official blog)
     → IF still empty: mark "No updates this week"
   ```

2. **Feature comparison edge case**:
   ```
   IF OpenClaw feature file not found:
     → Skip gap analysis section
     → Note in report: "OpenClaw feature comparison unavailable"
   ```

3. **Translation failure** (bonus):
   ```
   IF translator fails:
     → Skip Chinese summary
     → Report still valid in English
   ```

### Efficiency Optimization (15%)

**Key optimization: parallel search**

```
// BAD: Sequential (3× latency)
result1 = await search("Manus updates");
result2 = await search("AutoGPT updates");
result3 = await search("CrewAI updates");

// GOOD: Parallel (1× latency)
[result1, result2, result3] = await Promise.all([
  search("Manus updates"),
  search("AutoGPT updates"),
  search("CrewAI updates"),
]);
```

**Additional optimizations**:
- Summarization of 3 competitors can also run in parallel (after search completes)
- Translation runs last (sequential dependency on writer output)

### Workflow Executability (10%)

The workflow description should be concrete enough that a developer could implement it directly:
- Step numbers with clear sequencing
- Tool names matching actual available skills
- Data format expectations at each boundary
- Error handling at each step

### Scoring Anchors

| Criterion | Score 3 | Score 5 |
|-----------|---------|---------|
| Tool coverage | 4 tools mentioned | All tools with parameter descriptions |
| Data flow | Some input/output mentioned | Every step has explicit I/O with formats |
| Conditional branches | 1 branch identified | 2+ branches with fallback strategies |
| Efficiency | Mentions parallelism | Explicitly identifies which steps can parallelize |
| Executability | Pseudo-steps | Ready to translate to code directly |
