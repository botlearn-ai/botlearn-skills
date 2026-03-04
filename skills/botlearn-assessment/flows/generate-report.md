---
flow: generate-report
parent: SKILL.md
scope: dual-format report generation (MD + HTML)
---

# Report Generation Flow

After all questions are answered/scored/submitted, generate BOTH Markdown and HTML reports.

## 1. Prepare Report Data

Collect all results into a structured JSON object:

```json
{
  "sessionId": "exam-{YYYYMMDD}-{HHmm}",
  "timestamp": "{ISO-8601}",
  "mode": "full" | "d1" | "d2" | "d3" | "d4" | "d5",
  "lang": "{detected language code, e.g. zh or en}",
  "dimensions": [
    {
      "id": "D1",
      "name": "Reasoning & Planning",
      "nameCN": "推理与规划",
      "weight": 0.25,
      "difficulty": "Medium",
      "multiplier": 1.2,
      "rawScore": 78,
      "adjScore": 74.1,
      "status": "answered",
      "question": "full question text...",
      "answer": "full answer text...",
      "confidence": "high",
      "skipReason": null,
      "criteria": [
        {
          "name": "Criterion name",
          "weight": 0.35,
          "score": 4,
          "justification": "CoT justification text"
        }
      ]
    }
  ],
  "overall": {
    "raw": 75.2,
    "adj": 71.4,
    "level": "Proficient"
  },
  "skipped": ["D2: missing web_search capability"]
}
```

## 2. Generate Markdown Report

Save to `results/exam-{sessionId}-{mode}.md`.

Follow the template defined in `flows/full-exam.md` or `flows/dimension-exam.md` depending on mode.

The MD report includes:
- Session info and exam rules
- Overall score table
- Per-dimension scores with difficulty and status
- Each submitted question card (already shown to user during exam)
- Skipped questions with reasons
- Improvement suggestions
- Self-evaluation disclaimers

## 3. Generate HTML Report

### 3.1 Save JSON data

```bash
# Save the structured data as JSON for the HTML generator
cat > results/exam-{sessionId}-data.json << 'JSONEOF'
{data JSON}
JSONEOF
```

### 3.2 Run HTML generator

```bash
node skills/botlearn-assessment/scripts/generate-html-report.js \
  --file=results/exam-{sessionId}-data.json \
  > results/exam-{sessionId}-report.html
```

### 3.3 HTML Report Features

The HTML report is a self-contained single file with:

1. **精美头部**: Session info on dark gradient background
2. **综合评分面板**: Large score display with level badge
3. **内嵌 SVG 雷达图**: Radar chart directly in HTML (no external file dependency)
4. **维度评分表**: Color-coded scores per dimension
5. **能力分析卡片**: Per-dimension analysis with:
   - Score bar visualization
   - Capability description (auto-generated based on score range)
   - Strongest/weakest dimension highlight
6. **答题详情**: Expandable question cards with:
   - Question text (collapsible)
   - Answer text (expanded by default)
   - Scoring criteria table (collapsible)
7. **响应式设计**: Works on desktop and mobile
8. **打印友好**: Print-specific CSS

## 4. Generate Radar SVG (Standalone)

For full exam mode, also generate a standalone SVG:

```bash
node skills/botlearn-assessment/scripts/radar-chart.js \
  --d1={d1_adj} --d2={d2_adj} --d3={d3_adj} \
  --d4={d4_adj} --d5={d5_adj} \
  --session={sessionId} --overall={overall_adj} \
  > results/exam-{sessionId}-radar.svg
```

## 5. Output Files Summary

After report generation, the following files exist:

```
results/
├── exam-{sessionId}-data.json      ← Structured exam data
├── exam-{sessionId}-full.md        ← Markdown report (full exam)
├── exam-{sessionId}-report.html    ← HTML report (beautiful, self-contained)
├── exam-{sessionId}-radar.svg      ← Standalone radar chart (full exam only)
└── INDEX.md                        ← Updated history index
```

For single-dimension exams:
```
results/
├── exam-{sessionId}-data.json
├── exam-{sessionId}-d{N}.md
├── exam-{sessionId}-report.html
└── INDEX.md
```

## 6. Announce Report Files

After saving all files, output to user in their language:

```
📊 报告已生成:

  📄 Markdown: results/exam-{sessionId}-full.md
  🌐 HTML:     results/exam-{sessionId}-report.html
  📈 雷达图:   results/exam-{sessionId}-radar.svg
  📦 数据:     results/exam-{sessionId}-data.json

打开 HTML 报告可查看精美的可视化评测结果，包括:
  - 能力雷达图
  - 维度得分柱状图
  - 逐题能力分析
  - 改进建议
```

## 7. Error Handling

```
IF node not available:
  → Skip HTML generation
  → Output warning: "HTML report skipped — Node.js not available"
  → Still save MD report

IF JSON serialization fails:
  → Save MD report only
  → Log warning in report

IF file write fails:
  → Output report content directly to user
  → Note: "Could not save to file, displaying inline"
```
