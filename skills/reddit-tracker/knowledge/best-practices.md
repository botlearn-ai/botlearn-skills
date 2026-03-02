---
domain: reddit-tracker
topic: velocity-trend-detection-cross-subreddit-correlation
priority: high
ttl: 30d
---

# Reddit Tracker — Best Practices

## Velocity-Based Trend Detection

### 1. Engagement Velocity Definition
Engagement velocity measures the rate of change in a post's engagement metrics over time, not the absolute values:
- **Upvote velocity** — Score change per minute: `(score_t2 - score_t1) / (t2 - t1)`
- **Comment velocity** — New comments per minute over a sliding window
- **Award velocity** — Awards received per hour (early awards are a strong signal)
- **Crosspost velocity** — Rate at which the post is crossposted to other subreddits

### 2. Velocity Curve Phases
Every breakout post follows a characteristic velocity curve:

| Phase | Time from Post | Velocity Behavior | Detection Signal |
|-------|---------------|-------------------|-----------------|
| Seed | 0-15 min | Low, erratic | Not yet detectable |
| Ignition | 15-60 min | Sharp acceleration | **Primary detection window** |
| Surge | 1-4 hours | Sustained high velocity | Confirmed breakout |
| Peak | 4-12 hours | Velocity plateau then decline | Maximum reach |
| Decay | 12-48 hours | Declining velocity | Trend exhaustion |

### 3. Velocity Normalization
Raw velocity must be normalized to produce comparable signals:
- **By subreddit size**: Divide by subscriber count — 50 upvotes/min in a 10K sub is more significant than in a 10M sub
- **By time-of-day**: Compare against the subreddit's historical hourly engagement baseline
- **By day-of-week**: Weekend vs weekday patterns differ significantly for many communities
- **By post type**: Image posts typically accelerate faster than text posts in the same subreddit

### 4. Breakout Detection Threshold
A post is flagged as a potential breakout when:
- Upvote velocity exceeds 2x the subreddit's 90th-percentile velocity for its post age
- Comment velocity exceeds 3x the median for the subreddit within the first hour
- OR the post receives 2+ awards within the first 30 minutes in a community where awards are rare

### 5. Multi-Metric Confirmation
Never rely on a single velocity metric. Confirm with at least two:
- High upvote velocity + high comment velocity = strong engagement (likely genuine trend)
- High upvote velocity + low comment velocity = passive consumption (may be meme/image virality, not discussion-worthy trend)
- Low upvote velocity + high comment velocity = controversial or niche discussion (check controversial flag)

## Cross-Subreddit Correlation

### 1. Same-Topic Detection
Identify when the same topic emerges across multiple independent subreddits:
- **URL matching** — Same link posted to different subreddits (crosspost or independent submission)
- **Keyword clustering** — Same key terms appearing in titles across different communities within a 6-hour window
- **Entity co-occurrence** — Same named entities (people, companies, products) surfacing in unrelated subreddits
- **Semantic similarity** — Post titles or bodies with high cosine similarity across communities

### 2. Cross-Community Spread Score
Calculate a spread score to quantify how broadly a topic has penetrated:
```
spread_score = (num_subreddits / expected_subreddits) * avg_normalized_velocity * diversity_factor
```
- `num_subreddits` — Count of distinct subreddits where the topic appeared
- `expected_subreddits` — Baseline expectation based on the topic domain (tech news may naturally span 3-5 subreddits)
- `avg_normalized_velocity` — Average engagement velocity across all subreddits (normalized per community)
- `diversity_factor` — Higher when subreddits span different categories (e.g., both r/technology and r/stocks discussing the same company)

### 3. Origin Tracing
Identify where a trend started to understand its trajectory:
- Sort all related posts by `created_utc` — the earliest post is likely the origin
- Check if the origin subreddit is a known "incubator" community (e.g., niche hobby subs often incubate trends before they reach mega-subs)
- Track the crosspost chain to map the exact spread path

### 4. Propagation Pattern Classification

| Pattern | Description | Significance |
|---------|------------|--------------|
| Hub-and-Spoke | One mega-sub post spawns crossposts | Top-down virality; already mainstream |
| Grassroots | Multiple small subs independently discover topic | Organic emergence; high prediction value |
| Cascade | Topic hops through communities sequentially | Building momentum; time-sensitive |
| Synchronized | Same topic appears simultaneously in unrelated subs | External event trigger (news, product launch) |

## Temporal Analysis Best Practices

### 1. Peak Activity Windows
Every subreddit has characteristic activity patterns:
- US-centric subs peak 9 AM - 12 PM EST on weekdays
- Global subs have multiple peaks across time zones
- Gaming subs peak evenings and weekends
- Finance subs spike at market open/close and during events

### 2. Anomaly Detection via Temporal Baseline
- Build a 30-day rolling baseline of hourly post and comment volume per subreddit
- Flag any hour where volume exceeds 2 standard deviations above the baseline
- Volume spikes during off-peak hours are particularly significant

### 3. Trend Timing Prediction
To predict when a trend will peak:
- Measure the velocity curve slope during the Ignition phase
- Compare against historical breakout curves for the same subreddit
- Apply time-of-day correction — a post entering Surge phase during a subreddit's peak hours will peak faster

## Sentiment Signal Extraction

### 1. Comment Sentiment Distribution
For any trending post, analyze the comment section:
- **Positive / Negative / Neutral** ratio in top-level comments
- **Controversial flag** density — high density indicates polarizing topic
- **Sentiment shift** — Compare early comments vs. later comments to detect narrative evolution

### 2. Community Reaction Markers
- Top comment agreeing with post = community endorsement
- Top comment contradicting post = community skepticism (even if post score is high)
- Pinned moderator comment = topic requires community governance attention
- Post locked by mods = extreme engagement or rule violations

### 3. Engagement Quality Tiers

| Tier | Indicator | Meaning |
|------|-----------|---------|
| Deep | Long comments, citations, debate threads | Genuine interest and expertise |
| Reactive | Short affirmative comments, emojis, memes | Viral moment but shallow engagement |
| Hostile | Insults, reports, mod intervention | Controversial topic, unreliable sentiment signal |
| Astroturfed | Identical phrasing, new accounts, coordinated timing | Inauthentic engagement — exclude from analysis |
