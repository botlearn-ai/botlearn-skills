---
strategy: openclaw-graduate
version: 1.0.0
steps: 10
---

# Day 7 Graduation Strategy

## Step 1: Graduation Trigger & Intent Analysis

Detect graduation request and determine scope:

**Trigger Patterns**:
- "day 7", "retrospective", "7 days review"
- "what have i learned", "my progress"
- "growth report", "next steps"
- "毕业总结", "七天复盘", "成长报告"
- "graduate", "completion", "journey complete"

**Scope Options**:
- `--full`: Complete graduation ceremony with all components
- `--quick`: Executive summary only
- `--archetype`: Focus on archetype and growth path
- `--community`: Focus on A2A community welcome
- `--report`: Export report without ceremony

**Apply knowledge**: Refer to knowledge/Domain.md for understanding the 4 phases

## Step 2: Collect Journey Data (Day 1 + Day 7)

### 2.1 Day 1 Baseline Collection

**Primary Source**: Check for saved snapshot
```javascript
GET /memory/snapshots?label=day1-baseline

// If not found, reconstruct from:
- First session timestamp
- Initial configuration logs
- Early skill installations
```

**Reconstructed Baseline**:
```javascript
{
  "day1": {
    "timestamp": "[First activation]",
    "core": { "model": "default", "configured": false },
    "context": { "documents": 0, "personalized": false },
    "constitution": { "soulMd": false, "userMd": false },
    "capabilities": { "botlearnSkills": 0 },
    "tasks": { "completed": 0 }
  }
}
```

### 2.2 Day 7 Current State Collection

```javascript
{
  "day7": {
    "timestamp": "[Now]",
    "core": {
      "model": "[current]",
      "configured": true,
      "optimized": [check customization]
    },
    "context": {
      "documentCount": [count workspace docs],
      "memoryStructure": "[check organization]",
      "personalized": [check for user-specific content]
    },
    "constitution": {
      "soulMd": [exists? + completeness],
      "userMd": [exists? + completeness],
      "agentsMd": [exists? + completeness]
    },
    "capabilities": {
      "botlearnSkills": [count from clawhub list],
      "mostUsed": [top 3 with usage],
      "skillCombos": [discovered patterns]
    },
    "tasks": {
      "completed": [from session logs],
      "successRate": [calculate],
      "breakthroughs": [identify]
    }
  }
}
```

### 2.3 Session Analysis

```javascript
{
  "sessions": {
    "total": [N],
    "daysActive": [N],
    "requestTypes": { [categorize] },
    "skillsUsage": { [count per skill] },
    "satisfaction": { [positive/negative feedback] }
  }
}
```

**Apply knowledge**: Use knowledge/BestPractices.md for collection guidelines

## Step 3: Calculate 4C Growth Scores

### 3.1 Core Score (15% weight)
```javascript
coreScore = (
  (modelAppropriate() ? 30 : 0) +
  (configurationOptimized() ? 40 : 0) +
  (costEffective() ? 30 : 0)
)
```

### 3.2 Context Score (35% weight) ⭐
```javascript
contextScore = (
  (documentCount_scaled()) +  // 0-10=60, 10-20=80, 20+=100
  (memoryStructure() ? 40 : 0) +
  (personalizationDepth() ? 30 : 0)
)
```

### 3.3 Constitution Score (20% weight)
```javascript
constitutionScore = (
  (soulMd_completeness ? 35 : 0) +
  (userMd_completeness ? 35 : 0) +
  (agentsMd_completeness ? 30 : 0)
)
```

### 3.4 Capabilities Score (30% weight)
```javascript
capabilitiesScore = (
  (relevantSkills_scaled()) +  // Based on user's needs
  (skillUsageFrequency()) +     // Regular usage patterns
  (effectiveCombinations() ? 30 : 0)
)
```

### 3.5 Overall Score
```javascript
overallScore = (
  (coreScore * 0.15) +
  (contextScore * 0.35) +
  (constitutionScore * 0.20) +
  (capabilitiesScore * 0.30)
)

growthScore = overallScore - day1OverallScore
```

**Output**: 4C scores table with before/after

## Step 4: Detect Agent Archetype

### 4.1 Calculate Archetype Scores

```javascript
const scores = {
  builder: (
    (skillsInstalled > 10 ? 25 : 0) +
    (technicalSkillsRatio * 20) +
    (documentationRead * 15) +
    (customSkillAttempts * 25) +
    (experimentationFreq * 15)
  ),
  operator: (
    (repetitiveTaskPattern * 30) +
    (workflowOptimization * 25) +
    (automationKeywords * 20) +
    (efficiencyFocus * 25)
  ),
  explorer: (
    (skillCategoryVariety * 30) +
    (skillChurnRate * 20) +
    (discoveryLanguage * 20) +
    (sharingBehavior * 30)
  ),
  specialist: (
    (domainFocusScore * 35) +
    (domainSkillDepth * 35) +
    (expertiseLanguage * 30)
  )
}
```

### 4.2 Validate and Present

**Validation Criteria**:
- Highest score exceeds second by >15 points
- Score >60 (confidence threshold)
- Behavioral evidence supports

**IF not met**: Identify as "Hybrid" (e.g., "Builder-Operator")

**Presentation**:
1. Archetype name and definition
2. Why it fits (specific evidence)
3. Strengths of this archetype
4. Typical growth path
5. Community resources

**Apply knowledge**: Refer to knowledge/Domain.md for archetype definitions

## Step 5: Identify Achievements

### 5.1 Categorize by Phase

**Phase 1: Activation (Days 1-2)**
- Agent running and responsive
- First successful task
- Communication established

**Phase 2: Stability (Days 3-4)**
- Security baseline
- Personalization (SOUL/USER/AGENTS)
- Advanced task completed

**Phase 3: Reinforcement (Days 5-6)**
- Workflow optimized
- Self-improvement enabled
- Consistent performance

**Phase 4: Graduation (Day 7)**
- Retrospective complete
- Growth path defined
- Community connected

### 5.2 Find Breakthrough Moment

**Look for**:
- First complex task success
- First self-directed agent action
- First workflow iteration
- User's "aha" expression

### 5.3 Create Achievement Timeline

```markdown
Day 1: [Initial activation] 🎯
Day 2: [First task] ✅
Day 3: [Security/personalization] 🔒
Day 4: [Advanced task] 🚀
Day 5: [Workflow optimization] 🔄
Day 6: [Self-improvement] 📈
Day 7: [Graduation] 🎓
```

## Step 6: Generate Growth Report

### 6.1 Executive Summary

```markdown
🎓 OpenClaw Day 7 Graduation

Journey: Day 1 → Day 7
Archetype: [Name]
Key Achievement: [Specific]

Transformation Table:
| Dimension | Day 1 | Day 7 | Growth |
|-----------|-------|-------|--------|
| Capability | [XX]/100 | [YY]/100 | [+ZZ] ✨ |
```

### 6.2 Detailed 4C Analysis

For each dimension (Core, Context, Constitution, Capabilities):
- Day 1 state
- Day 7 state
- Growth explanation
- Specific evidence

### 6.3 Graduation Achievements

Checklist format with visual indicators
Highlight unique achievements
Identify breakthrough moment

### 6.4 Archetype Section

- Name and emoji
- What it means
- Why it fits (evidence)
- Strengths
- Growth path

**Apply knowledge**: Use knowledge/BestPractices.md for report structure

## Step 7: Design Next Phase Path

### 7.1 Personalized Recommendations

**Based on**:
- Archetype
- Demonstrated interests
- Current skill stack
- Goals (explicit or inferred)

**Algorithm**:
```javascript
function generateNextSteps(archetype, currentState) {
  const steps = {
    immediate: [],   // 7 days
    shortTerm: [],   // 30 days
    mediumTerm: []   // 90 days
  };

  // Archetype-specific
  switch(archetype) {
    case 'builder':
      steps.shortTerm.push("Develop custom skill", "Contribute to ecosystem");
      break;
    case 'operator':
      steps.shortTerm.push("Optimize workflows", "Multi-agent coordination");
      break;
    // ... etc
  }

  // Personalized based on usage
  if (highResearchUsage) {
    steps.immediate.push("Add @botlearn/academic-search");
  }

  return steps;
}
```

### 7.2 3-Phase Roadmap

**Immediate (7 days)**:
- 2-3 specific actions
- Low friction, high value
- Builds on current success

**Short-term (30 days)**:
- 2-3 goals
- Next complexity level
- Expands capabilities

**Medium-term (90 days)**:
- 1-2 major milestones
- Transformational outcomes
- Leadership opportunities

## Step 8: Welcome to A2A Community

### 8.1 Map User to Community

```javascript
function mapToCommunity(archetype, interests) {
  return {
    discordChannels: [
      `#${archetype}s`,
      ...archetypeSpecificChannels(archetype),
      ...interestBasedChannels(interests)
    ],
    forumCategories: [
      archetypeForumCategory(archetype),
      ...relevantForums(interests)
    ],
    peopleToFollow: suggestMentors(archetype, interests),
    firstAction: specificFirstAction(archetype)
  };
}
```

### 8.2 Create Warm Welcome

**NOT**: "Join our Discord at link"

**INSTEAD**: "Based on your [archetype] style and interest in [topic], you'll find your people in #[channel]. Many users there share workflows like yours. Here's a recent discussion about [specific thing]..."

**Include**:
- Specific channels (3-5 max)
- Why relevant to THIS user
- What to do there
- Expected outcome
- People to follow

**Apply knowledge**: Refer to knowledge/Domain.md for community structure

## Step 9: Assemble Graduation Ceremony

### 9.1 Structure (as defined in SKILL.md)

1. **Graduation Header** with emoji and title
2. **Executive Summary** (transformation table)
3. **Graduation Achievements** (4 phases checklist)
4. **Agent Archetype** (detection and explanation)
5. **4C Analysis** (detailed scores)
6. **Next Phase Planning** (7/30/90 day paths)
7. **A2A Community Welcome** (specific resources)
8. **Key Insights** (breakthroughs, DNA)
9. **Resources** (archetype-specific)
10. **Graduation Message** (inspiring send-off)

### 9.2 Apply Visual Formatting

- Headers for hierarchy (# ## ###)
- Tables for comparison
- Bulleted lists for readability
- Bold for emphasis
- Emojis for visual interest
- Blockquotes for key insights

### 9.3 Quality Check

Before presenting:
- [ ] All sections complete
- [ ] Data accurate and sourced
- [ ] Claims backed by evidence
- [ ] Personalized (not generic)
- [ ] Balanced (achievements + growth areas)
- [ ] Future-oriented and exciting
- [ ] Community resources curated
- [ ] Next steps actionable
- [ ] Graduation message feels earned

**Apply knowledge**: Check against knowledge/AntiPatterns.md to avoid pitfalls

## Step 10: Present and Follow Up

### 10.1 Graduation Ceremony Mode

**Present with ceremony**:
- "🎓 Congratulations! You've completed your 7-day OpenClaw journey!"
- This is a milestone—treat it like one
- Create "diploma moment"

**Offer options**:
- "View full graduation ceremony"
- "Quick summary"
- "Focus on specific area"
- "Export report"
- "Plan next phase"
- "Connect to community"

### 10.2 Save for Reference

```javascript
{
  "graduationId": "day7-2026-03-02",
  "timestamp": "[Now]",
  "day1Snapshot": {...},
  "day7Snapshot": {...},
  "archetype": "[detected]",
  "overallScore": [score],
  "growthScore": [score],
  "achievements": [...],
  "nextSteps": [...]
}
```

### 10.3 Schedule Follow-Ups

**Automatic**:
- 14 days: "How's your agent evolving?"
- 30 days: "Progress check — how's the growth path?"
- 90 days: "Major milestone review"

## Conditional Branches

### IF: --quick mode
- Executive summary only
- Skip detailed sections
- Offer to expand on interest
- Focus on next step

### IF: --archetype mode
- Emphasize archetype detection
- Go deep on archetype-specific path
- Provide archetype community resources
- Tailor all to archetype

### IF: --community mode
- Emphasize community welcome
- Detailed connection guidance
- Suggest specific channels and people
- Create engagement plan

### IF: Day 1 snapshot missing
- Reconstruct from available data
- Mark as "estimated baseline"
- Note limitations
- Suggest saving snapshot next time

### IF: Low engagement
- Adjust expectations
- Focus on potential
- Provide re-engagement suggestions
- Address blockers honestly

### IF: High achievement
- Celebrate appropriately
- Identify what worked
- Suggest contribution opportunities
- Consider mentorship potential

## Error Handling

### Data Collection Errors
```
Error: Can't access session logs
→ Use available data, note limitations
→ Mark as "partial graduation"
→ Offer to regenerate when data available
```

### Archetype Detection Failures
```
Error: Can't confidently determine
→ Present as "Evolving" or "Hybrid"
→ Explain patterns observed
→ Offer user to self-identify
→ Provide resources for multiple
```

### Report Generation Errors
```
Error: Report incomplete
→ Don't present partial as final
→ Identify missing sections
→ Offer to regenerate specific sections
→ Save progress for retry
```

## Self-Correction

### During ceremony generation, check:

**Am I**:
- ❌ Being too generic? → Add specific user data
- ❌ Overwhelming with data? → Summarize more
- ❌ Focusing on knowledge not outcomes? → Emphasize capabilities
- ❌ Being too positive/negative? → Balance both
- ❌ Leaving user hanging? → Provide clear next steps
- ❌ Making graduation feel unearned? → Reference specific achievements

**Should I**:
- ✅ Base everything on actual user data?
- ✅ Personalize every recommendation?
- ✅ Make growth visible and tangible?
- ✅ Create excitement for the future?
- ✅ Provide clear paths to community?
- ✅ Make this feel like a graduation?
