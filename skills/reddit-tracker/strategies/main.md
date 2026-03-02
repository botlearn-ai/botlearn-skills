---
strategy: reddit-tracker
version: 1.0.0
steps: 6
---

# Reddit Tracker Strategy

## Step 1: Target Identification & Scope Definition
- Parse the user's request to identify: **target subreddits**, **topics/keywords**, **time horizon**, and **desired output** (trend report, sentiment summary, breakout alerts)
- IF specific subreddits are named THEN add them to the watch list directly
- IF only a topic or domain is given THEN identify the top 3-5 relevant subreddits by:
  - Searching Reddit for the topic and noting which subreddits surface most frequently
  - Checking subreddit recommendation resources and community directories
  - Including both mega-subs (broad reach) and niche subs (early signal) for the topic
- Determine monitoring mode:
  - **Snapshot** — One-time scan of current state (default if user asks "what's trending")
  - **Watch** — Continuous monitoring over a specified time window (if user asks "alert me" or "track")
- Record each subreddit's subscriber count and current active user count as baseline context from knowledge/domain.md

## Step 2: Data Collection & Velocity Tracking
- For each target subreddit, collect posts from three listing endpoints:
  - `/rising` — Primary signal source for early breakout detection
  - `/new` — Catch posts in the Seed phase that rising has not yet surfaced
  - `/hot` — Baseline for what the community's algorithm already considers trending
- For each collected post, record the initial engagement snapshot:
  - `score`, `upvote_ratio`, `num_comments`, `total_awards_received`, `created_utc`, `is_crosspost`
- IF monitoring mode is Watch THEN sample again after 15 minutes and 60 minutes to calculate velocity:
  - Upvote velocity: `(score_t2 - score_t1) / elapsed_minutes`
  - Comment velocity: `(comments_t2 - comments_t1) / elapsed_minutes`
  - Award velocity: awards received per hour
- Normalize all velocities using subreddit size and time-of-day baselines from knowledge/best-practices.md
- Flag posts that exceed breakout detection thresholds:
  - Upvote velocity > 2x the subreddit's 90th-percentile for the post's age
  - Comment velocity > 3x the subreddit's median within the first hour
  - Awards > 2 within the first 30 minutes (in communities where awards are uncommon)

## Step 3: Cross-Community Correlation
- Aggregate flagged posts and rising content across all monitored subreddits
- Detect cross-subreddit topic convergence using:
  - **URL deduplication** — Same link appearing in multiple subreddits (crosspost or independent)
  - **Keyword overlap** — Same key terms in post titles across different communities within a 6-hour window
  - **Entity matching** — Same named entities (people, companies, events) surfacing independently
- For each correlated topic, calculate the cross-community spread score:
  - `spread_score = (num_subreddits / expected_subreddits) * avg_normalized_velocity * diversity_factor`
  - `diversity_factor` increases when subreddits span different categories
- Classify the propagation pattern from knowledge/best-practices.md:
  - Hub-and-Spoke (top-down from mega-sub)
  - Grassroots (independent emergence in small subs — highest prediction value)
  - Cascade (sequential community hopping)
  - Synchronized (simultaneous appearance suggesting external trigger)
- IF a Grassroots pattern is detected THEN elevate the trend's priority — these are the signals that predict breakouts 24 hours early

## Step 4: Sentiment Analysis & Discussion Quality
- For each flagged trending post, analyze the comment section:
  - Sample top 20 comments by "best" ranking (Wilson score)
  - Classify each comment's sentiment: positive, negative, neutral, mixed
  - Calculate the sentiment distribution ratio for the thread
- Assess discussion quality using engagement quality tiers from knowledge/best-practices.md:
  - **Deep** — Long comments, citations, debate threads (genuine interest)
  - **Reactive** — Short affirmations, emojis, memes (viral but shallow)
  - **Hostile** — Insults, reports, mod intervention (controversial, unreliable signal)
  - **Astroturfed** — Identical phrasing, new accounts, coordinated timing (exclude from analysis)
- Check for community reaction markers:
  - Top comment alignment with post (endorsement vs. contradiction)
  - Moderator intervention (pinned comments, post locks, flair changes)
  - Controversial flag density in the comment tree
- IF astroturfing indicators are detected THEN flag the trend and discount its metrics per knowledge/anti-patterns.md
- IF top comment contradicts the post THEN note the divergence between post score and community consensus

## Step 5: Trend Prediction & Confidence Scoring
- For each detected trend, determine its lifecycle phase:
  - **Seed** (0-15 min, low/erratic velocity) — Too early for reliable prediction
  - **Ignition** (15-60 min, sharp acceleration) — Primary prediction window
  - **Surge** (1-4 hours, sustained high velocity) — Confirmed breakout
  - **Peak** (4-12 hours, velocity plateau then decline) — Maximum reach achieved
  - **Decay** (12-48 hours, declining velocity) — Trend exhaustion
- Calculate a composite trend confidence score (0-100):
  - Velocity strength (30%): How far above baseline thresholds is the engagement velocity?
  - Cross-community spread (25%): How many independent subreddits have surfaced this topic?
  - Sentiment alignment (15%): Is community sentiment consistent and positive/engaged?
  - Discussion quality (15%): Is engagement deep and organic, or shallow and potentially inauthentic?
  - Temporal fit (15%): Is the timing consistent with the subreddit's peak activity patterns?
- Estimate peak timing:
  - IF in Ignition phase THEN predict peak in 3-8 hours (adjusted by subreddit size and time-of-day)
  - IF in Surge phase THEN predict peak in 1-4 hours
  - IF already at Peak THEN report as "currently peaking" with estimated decay onset
- SELF-CHECK against anti-patterns from knowledge/anti-patterns.md:
  - Is this a repost surge, not a genuine trend?
  - Could vote manipulation be inflating the signal?
  - Is a megathread absorbing individual post activity?
  - Are bot accounts driving the engagement?
  - IF any check flags a concern THEN reduce confidence score by 15-30 points and note the risk factor

## Step 6: Report Generation & Output
- Present findings in a structured trend report:
  - **Trend Summary** — One-sentence description of the detected trend
  - **Confidence** — Score (0-100) with label: Low (<40), Medium (40-69), High (>=70)
  - **Phase** — Current lifecycle phase and estimated time to peak
  - **Scope** — Subreddits involved, propagation pattern, spread score
  - **Velocity Metrics** — Key engagement rates with normalization context
  - **Sentiment** — Community sentiment distribution and quality tier
  - **Evidence** — Links to the top 3-5 posts driving the trend, with per-post metrics
  - **Risk Factors** — Any detected anti-patterns or confidence-reducing signals
  - **Recommendation** — Actionable advice: monitor, act now, or wait for confirmation
- IF multiple trends are detected THEN rank by confidence score descending and present as a prioritized list
- IF monitoring mode is Watch THEN specify the next recommended check time based on the trend phase:
  - Seed phase → recheck in 15 minutes
  - Ignition phase → recheck in 30 minutes
  - Surge phase → recheck in 1 hour
  - Peak or Decay → recheck in 4 hours or close monitoring
- SELF-CHECK output completeness:
  - Does every trend have a confidence score and lifecycle phase?
  - Are raw metrics accompanied by normalization context?
  - Is the scope correctly qualified (subreddit-local vs. cross-community)?
  - Are risk factors and anti-pattern warnings included where applicable?
  - IF any check fails THEN revise the report before delivering
