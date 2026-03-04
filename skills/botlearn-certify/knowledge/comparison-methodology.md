# Comparison Methodology

## Core Principle: Dynamic Dimension Matching

This certification system does **NOT** hardcode dimension names or counts. The assessment skill may evolve its dimension framework over time (e.g., from 5 dimensions to 10, or rename dimensions). The comparison engine must handle this gracefully.

## Dimension Matching Algorithm

### Step 1: Extract Dimensions from Both Reports

Parse each report's score table using regex patterns:

```
Pattern A: | D{N} | {Name} | ... | {Score} | ...
Pattern B: | {Name} | {Score} | ...
Pattern C: **{Name}**: {Score}/100
```

Result: Two arrays of `{ name: string, score: number }`

### Step 2: Match Dimensions by Name

For each dimension in the FRESH report:
1. **Exact match**: Find identical name in HIST report
2. **Normalized match**: Lowercase, strip whitespace, remove special chars, then compare
3. **Fuzzy match**: If normalized match fails, use substring containment
   - "Reasoning & Planning" matches "Reasoning"
   - Cross-language matches are skipped (no CN↔EN fuzzy matching)
4. **Unmatched**: Mark as "New dimension" — no delta calculated

For each dimension in HIST report not matched:
- Mark as "Removed dimension" — noted but not scored

### Step 3: Calculate Deltas

```
For each matched pair:
  delta = fresh_score - hist_score
  delta_pct = delta (already in percentage points)
  direction = "↑" | "↓" | "→"
  significance:
    |delta| >= 10  → "significant"
    |delta| >= 5   → "moderate"
    |delta| < 5    → "minor"
```

### Step 4: Overall Comparison

```
overall_delta = fresh_overall - hist_overall
time_gap = fresh_date - hist_date (in days)

growth_rate = overall_delta / max(time_gap, 1) * 30   # normalized to monthly
```

## No-History Mode (Baseline Certificate)

When `HAS_HISTORY = false`:
- Skip all comparison logic
- All delta fields = "N/A"
- Comparison section: "First assessment — future certifications will show growth trajectory"
- Certificate type: "Baseline Certificate"
- Still perform full classification and specialty assignment

## Edge Cases

| Case | Handling |
|------|----------|
| Different number of dimensions | Match what can be matched, note differences |
| Score = 0 in both | Delta = 0, direction = "→", note as unchanged |
| Score decreased significantly (>15 pts) | Flag with warning, suggest targeted practice |
| Time gap < 1 day | Warn that scores may not meaningfully differ |
| Identical scores | Celebrate consistency |
