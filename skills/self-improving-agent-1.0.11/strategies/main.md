---
domain: meta-learning
topic: self-improvement-strategy
priority: high
---

# Self-Improvement Strategy

## Phase 1: Detection

1. Monitor for triggers during work:
   - IF command fails THEN log to ERRORS.md
   - IF user corrects agent THEN log to LEARNINGS.md with category "correction"
   - IF user requests missing capability THEN log to FEATURE_REQUESTS.md
   - IF knowledge is outdated THEN log to LEARNINGS.md with category "knowledge_gap"
   - IF better approach found THEN log to LEARNINGS.md with category "best_practice"

## Phase 2: Logging

1. Generate entry ID: `TYPE-YYYYMMDD-XXX`
2. Fill in all required fields: Logged, Priority, Status, Area
3. Write Summary, Details, and Suggested Action
4. Search for related entries: `grep -r "keyword" .learnings/`
5. IF related entry exists THEN add "See Also" link and consider priority bump

## Phase 3: Review

1. IF starting major task THEN review relevant .learnings/ entries first
2. IF entry is resolved THEN update Status to "resolved" and add Resolution block
3. IF entry is recurring (3+ times) THEN consider promotion

## Phase 4: Promotion

1. IF learning is broadly applicable THEN:
   - Distill into concise rule
   - Add to appropriate target (CLAUDE.md, AGENTS.md, .github/copilot-instructions.md)
   - Update original entry Status to "promoted"
2. IF learning qualifies for skill extraction THEN:
   - Run extract-skill.sh helper
   - Create SKILL.md from template
   - Update entry with Skill-Path
