---
strategy: botlearn-certify
version: 2.0.0
steps: 6
---

# Graduation Strategy: 6-Stage Pipeline

## Stage 1: Mode Detection & Context Collection

### 1.1 Detect Activation Mode

```
IF agent:bootstrap hook fired AND journey day == 7:
  → mode = "hook-triggered"
  → Announce graduation day, offer ceremony

IF user says "graduate", "毕业", "graduation":
  → mode = "ceremony" (full ceremony)

IF user says "exam", "考试", "test":
  → mode = "exam" (exam only)

IF user says "--quick" or "quick summary":
  → mode = "quick" (executive summary only)

IF user says "stats", "progress", "我的进度":
  → mode = "stats" (growth stats only)

IF cron trigger:
  → mode = "daily-check"
  → Inject day-appropriate reminder, exit
```

### 1.2 Collect Context

```
Read journey-start.json → currentDay, startDate
Read workspace files → SOUL.md, USER.md, AGENTS.md existence and quality

IF currentDay < 7 AND mode != "stats":
  → Inform user: "Day {currentDay}/7. Graduation available on Day 7."
  → Offer: "Want to see your current progress? Say 'stats'"

IF currentDay >= 7:
  → Proceed to Stage 2
```

**Apply knowledge**: @knowledge/domain.md for 4C framework and phases

## Stage 2: Parallel Data Collection

Run all collection scripts in parallel:

```
PARALLEL:
  journey_data  ← bash scripts/collect-journey.sh
  growth_data   ← bash scripts/collect-growth.sh
  activity_data ← bash scripts/collect-activity.sh
  browser_data  ← bash scripts/track-browser.sh
```

### 2.1 Handle Script Failures

```
FOR EACH script result:
  IF script failed OR timeout:
    → Mark that dimension as "unavailable"
    → Continue with remaining data
    → DO NOT abort graduation

IF ALL scripts failed:
  → Fall back to manual collection mode
  → Ask user for self-reported data
```

### 2.2 Merge Results

```
graduation_context = {
  journey: journey_data,
  growth: growth_data,
  activity: activity_data,
  browser: browser_data,
  collected_at: NOW
}
```

## Stage 3: Analysis & Scoring

### 3.1 4C Growth Analysis

```
FROM growth_data:
  core_score = growth.current.core         (0-100)
  context_score = growth.current.context   (0-100)
  constitution_score = growth.current.constitution (0-100)
  capabilities_score = growth.current.capabilities (0-100)
  overall_score = growth.current.overall   (weighted)

  core_growth = growth.growth.core
  context_growth = growth.growth.context
  constitution_growth = growth.growth.constitution
  capabilities_growth = growth.growth.capabilities
  overall_growth = growth.growth.overall
```

### 3.2 Archetype Detection

```
FROM journey_data + growth_data:

builder_score = (
  (skills.count > 10 ? 25 : skills.count > 5 ? 15 : 0) +
  (technical_skills_ratio × 20) +
  (config_modified ? 15 : 0) +
  (experiment_indicators × 25) +
  (doc_engagement × 15)
)

operator_score = (
  (workflow_patterns × 30) +
  (workflow_optimization × 25) +
  (automation_indicators × 20) +
  (efficiency_keywords × 25)
)

explorer_score = (
  (skill_category_variety × 30) +
  (skill_churn × 20) +
  (discovery_language × 20) +
  (sharing_behavior × 30)
)

specialist_score = (
  (domain_focus × 35) +
  (domain_depth × 35) +
  (expertise_language × 30)
)

// Determine archetype
primary = max(builder, operator, explorer, specialist)
secondary = second_highest

IF primary.score - secondary.score < 15:
  archetype = "{primary.name}-{secondary.name}" (hybrid)
ELSE:
  archetype = primary.name
```

Refer to @assets/graduation-schema.json for thresholds.

### 3.3 Milestone Scoring (Day 1-6 Only)

```
currentDay = journey_data.journey.currentDay

FROM journey_data + growth_data:

FOR EACH milestone in @assets/milestone-config.json:
  // Gate 1: 只检测当前天及之前的里程碑
  IF milestone.day > currentDay:
    milestone.achieved = false
    milestone.status = "future"     // 未来日期，不可检测
    SKIP

  // Gate 2: Day 7 里程碑标记为 postCeremony，Stage 3 不检测
  //         这些文件（graduation-report.json, exam-result.json, ceremony-completed）
  //         是 Stage 4/5/6 才生成的，此时还不存在
  IF milestone.postCeremony == true:
    milestone.achieved = false
    milestone.status = "pending"    // 等待毕业流程完成后二次评分
    SKIP

  // Gate 通过：正常检测
  IF detect(milestone) == true:
    milestone.achieved = true
    total_points += milestone.points

// 此处的 grade 是 **临时等级**（不含 Day 7 的 30 分）
preliminary_grade = lookup(total_points, @assets/milestone-config.json.grading)
```

**重要**: Day 7 的 30 分由 Stage 6.1 二次评分追加。Stage 3 输出的 grade 是临时值。

### 3.4 Community Engagement Score

```
engagement = 0

IF activity_data.activity.available:
  engagement += activity_data.activity.engagementScore

IF browser_data.engaged:
  engagement += min(browser_data.totalVisits × 2, 20)

engagement_level = "none" | "low" | "medium" | "high"
```

## Stage 4: Exam Management (Conditional)

```
IF mode == "exam" OR (mode == "ceremony" AND user accepts exam):
  → Proceed with exam
ELSE:
  → Skip to Stage 5
```

### 4.1 Offer Exam

```
"Would you like to take the graduation exam?"
Options:
  - Full exam (15 questions, ~20 minutes)
  - Quick exam (6 questions, ~8 minutes)
  - Practice mode (3 knowledge questions)
  - Skip exam (proceed to ceremony)
```

### 4.2 Administer Exam

```
Load questions from @references/exam-questions.md
Select questions based on mode:
  full → all 15 (K1-K5, P1-P5, R1-R5)
  quick → K1, K3, P1, P3, R1, R3
  practice → K1, K2, K3

Present ONE question at a time
Collect answers
```

### 4.3 Score Exam

```
answers_json = format_answers_as_json(collected_answers)
exam_result = echo $answers_json | bash scripts/graduation-scorer.sh

Save to ~/.openclaw/data/graduate/exam-result.json
```

### 4.4 Present Results

```
Use @references/emotional-scripts.md for tone:
  IF exam_result.passed AND score >= 65: "Outstanding!"
  IF exam_result.passed: "Congratulations on passing!"
  IF NOT passed: "Your exam shows you're still growing — and that's beautiful."

Show: category breakdown, strengths, growth areas
```

## Stage 5: Report & Ceremony Generation

### 5.1 Select Ceremony Template

```
FROM archetype:
  template = @references/ceremony-templates.md[archetype]

IF hybrid archetype:
  template = hybrid adaptation
```

### 5.2 Generate Graduation Report

```
Report sections (in order):
  1. Executive Summary
     - Agent name, journey dates, archetype, overall score
  2. Transformation Table
     - Day 1 vs Day 7 for each 4C dimension
  3. Milestone Grade
     - Points earned (Day 1-6 confirmed + Day 7 pending)
     - NOTE: 此处使用 preliminary_grade（Stage 3 临时值）
     - Day 7 里程碑在 Stage 6.1 二次评分后更新为 final_grade
  4. Achievement Timeline
     - Day 1-7 key milestones achieved
  5. Archetype Analysis
     - Detection evidence, strengths, growth path
  6. 4C Detailed Analysis
     - Per-dimension scores with growth indicators
  7. Exam Results (if taken)
     - Score, grade, category breakdown
  8. Community Engagement (if available)
     - botlearn.ai activity, browser visits
  9. Next Phase Recommendations
     - 7/30/90-day personalized plan based on archetype
  10. Community Welcome
      - Archetype-matched channels and resources
  11. Graduation Certificate
      - Fill @assets/diploma-template.md with actual data
  12. Farewell Message
      - Archetype-specific from @references/ceremony-templates.md
```

### 5.3 Quality Self-Check

```
Before presenting, verify:
- [ ] All claims backed by script data (anti-pattern: False Celebration)
- [ ] Archetype has supporting evidence (anti-pattern: Label Thrower)
- [ ] Browser data shows only aggregate metrics (anti-pattern: Surveillance)
- [ ] Exam framed as optional (anti-pattern: Exam Pressure)
- [ ] Community resources are curated, not dumped (anti-pattern: Overwhelmer)
- [ ] Hook content was ≤ 150 tokens (anti-pattern: Bombardment)
- [ ] Every section is personalized (anti-pattern: Template Bot)
```

Refer to @knowledge/anti-patterns.md for full anti-pattern list.

## Stage 6: Save & Follow-Up

### 6.1 Save Graduation Data & Day 7 Milestone Re-scoring

```
GRADUATE_DATA = ~/.openclaw/data/graduate/

// —— Step A: 保存数据文件 ——
Save:
  $GRADUATE_DATA/graduation-report.json    ← full report data
  $GRADUATE_DATA/exam-result.json          ← exam scores (if taken)
  $GRADUATE_DATA/ceremony-completed        ← completion marker

// —— Step B: Day 7 里程碑二次评分 ——
// 此时 Stage 4/5 已完成，Day 7 的文件已经写入磁盘
// 重新检测 postCeremony=true 的里程碑

d7_bonus = 0

IF file_exists($GRADUATE_DATA/graduation-report.json):
  d7-retrospective.achieved = true
  d7_bonus += 10   // "Retrospective Completed"

IF file_exists($GRADUATE_DATA/exam-result.json):
  d7-exam.achieved = true
  d7_bonus += 10   // "Graduation Exam Taken"

IF file_exists($GRADUATE_DATA/ceremony-completed):
  d7-ceremony.achieved = true
  d7_bonus += 10   // "Ceremony Attended"

// 更新最终里程碑分数和等级
final_total_points = preliminary_total_points + d7_bonus
final_grade = lookup(final_total_points, @assets/milestone-config.json.grading)

// —— Step C: 回写最终等级到报告 ——
// 用 final_grade 替换 preliminary_grade
Update graduation-report.json:
  milestoneGrade = final_grade
  milestonePoints = final_total_points
  day7Milestones = { retrospective: bool, exam: bool, ceremony: bool }

Format:
{
  "graduationId": "day7-{DATE}",
  "timestamp": "{NOW}",
  "archetype": "{ARCHETYPE}",
  "overallScore": {SCORE},
  "growthScore": {GROWTH},
  "milestonePoints": {FINAL_POINTS},
  "milestoneGrade": "{FINAL_GRADE}",
  "milestoneGradePreliminary": "{PRELIMINARY_GRADE}",
  "day7Bonus": {D7_BONUS},
  "examTaken": {BOOL},
  "examGrade": "{GRADE_OR_NULL}"
}
```

### 6.2 Schedule Follow-Ups

```
IF clawhub cron available:
  clawhub cron add "graduate-14d" --schedule "in 14 days" \
    --command "echo '14-day progress check reminder'"
  clawhub cron add "graduate-30d" --schedule "in 30 days" \
    --command "echo '30-day milestone review reminder'"

IF cron not available:
  → Record reminder dates in graduation-report.json
  → Agent's memory will surface them
```

### 6.3 Offer Next Actions

```
"What would you like to do next?"
Options:
  - View full report again
  - Focus on a specific area
  - Start your 30-day plan
  - Connect to community
  - Share your graduation
  - Export report as markdown
```

## Conditional Branches

### IF mode == "quick"
→ Stage 1-2-3 → Executive summary only → Stage 6

### IF mode == "stats"
→ Stage 1-2-3 → Show 4C scores + milestone progress → No ceremony

### IF mode == "exam"
→ Stage 1 → Stage 4 → Stage 6

### IF Day 1 baseline missing
→ Reconstruct from available data, mark as "estimated baseline"

### IF low engagement (overall_score < 30)
→ Adjust ceremony tone: honest but encouraging
→ Focus on potential, not gaps
→ Use @references/emotional-scripts.md low-engagement scripts

### IF high achievement (overall_score > 80)
→ Extra celebration, identify what worked
→ Suggest contribution opportunities
→ Consider mentorship potential

## Error Handling

```
Script failure → Mark dimension "unavailable", continue
Exam scoring failure → Fall back to manual scoring
No journey-start.json → Ask user for start date or estimate
Network failure → Skip botlearn.ai API, continue
Browser access denied → Skip browser tracking, note as optional
```
