---
domain: meta-learning
topic: self-improvement
priority: high
ttl: 90d
---

# Self-Improvement Domain Knowledge

## Overview

The self-improvement skill enables AI agents to capture and organize learnings, errors, and feature requests during their work sessions. This creates a feedback loop for continuous improvement.

## Core Concepts

- **Learnings**: Corrections, knowledge gaps, and best practices discovered during work
- **Errors**: Command failures, exceptions, and unexpected behaviors with context
- **Feature Requests**: User-requested capabilities that don't exist yet
- **Promotion**: Elevating recurring learnings to permanent project memory (CLAUDE.md, AGENTS.md)

## File Structure

All entries are stored in `.learnings/` directory:
- `LEARNINGS.md` — corrections, knowledge gaps, best practices
- `ERRORS.md` — command failures, exceptions
- `FEATURE_REQUESTS.md` — user-requested capabilities

## Entry ID Format

`TYPE-YYYYMMDD-XXX` where TYPE is LRN, ERR, or FEAT.

## Priority Levels

- **critical**: Blocks core functionality, data loss risk, security issue
- **medium**: Moderate impact, workaround exists
- **high**: Significant impact, affects common workflows
- **low**: Minor inconvenience, edge case

## Promotion Criteria

Promote to project memory when learning is broadly applicable, prevents recurring mistakes, or documents project-specific conventions.
