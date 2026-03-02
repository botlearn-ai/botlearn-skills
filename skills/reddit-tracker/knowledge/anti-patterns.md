---
domain: reddit-tracker
topic: anti-patterns
priority: medium
ttl: 30d
---

# Reddit Tracker — Anti-Patterns

## Vote & Score Anti-Patterns

### 1. Vote Manipulation Blindness
- **Problem**: Treating upvote scores at face value without accounting for vote manipulation, brigading, or bot networks; a post with 10K upvotes may have been artificially boosted
- **Fix**: Cross-validate score with independent signals — comment quality and diversity, account age distribution of commenters, upvote-to-unique-commenter ratio. A genuinely popular post has a diverse, organic commenter base; a manipulated one has sparse or formulaic comments relative to its score

### 2. Conflating Upvotes with Quality
- **Problem**: Assuming high-score posts represent high-quality or important information; Reddit's upvote system rewards early timing, emotional triggers, and community in-jokes more than accuracy or significance
- **Fix**: Evaluate post quality independently of score — check if claims are sourced, if expert commenters corroborate or challenge the post, and whether the upvote ratio aligns with the comment sentiment. A post with 5K upvotes but a top comment debunking it is a misinformation signal, not a quality signal

### 3. Ignoring Vote Fuzzing
- **Problem**: Relying on exact upvote/downvote counts for precision analysis; Reddit deliberately fuzzes vote counts to prevent manipulation detection, so absolute numbers are approximate
- **Fix**: Use `upvote_ratio` and relative rank changes instead of absolute score changes. Track a post's position in the subreddit listing over time rather than its raw score. Velocity trends are reliable even when individual data points are fuzzed

### 4. Score Snapshot Fallacy
- **Problem**: Measuring a post's score at a single point in time and drawing conclusions; a post at 500 points could be rising rapidly toward 5K or slowly decaying from 2K
- **Fix**: Always sample engagement metrics at multiple time points to calculate velocity. A minimum of 3 data points over 30+ minutes is required to establish a reliable trend direction

## Trend Detection Anti-Patterns

### 5. Single-Subreddit Myopia
- **Problem**: Declaring a topic as "trending on Reddit" based on activity in only one subreddit; a topic trending in r/technology may be completely unknown in broader Reddit
- **Fix**: Always check at least 3-5 related subreddits before classifying a trend as cross-community. Use the cross-subreddit spread score from best-practices.md. Qualify all trend claims with scope — "trending in r/technology" is different from "trending across Reddit"

### 6. Repost Conflation
- **Problem**: Counting reposts and duplicates as separate trend signals; the same content reposted across subreddits by the same user or bot network inflates apparent spread
- **Fix**: Deduplicate by URL, image hash, and text similarity before counting cross-subreddit appearances. Check if the poster accounts are related (similar names, creation dates, post histories). A genuine trend has diverse original posters, not one account spamming copies

### 7. Survivorship Bias in Trend Analysis
- **Problem**: Only studying posts that reached the front page and generalizing their patterns; for every front-page post, hundreds had similar early signals but failed to break out
- **Fix**: Maintain a baseline of posts that showed early breakout signals but did NOT reach the front page. Calculate precision and recall — what fraction of flagged posts actually broke out, and what fraction of actual breakouts were detected early? Tune thresholds based on both

### 8. Ignoring Megathread Absorption
- **Problem**: Missing that a topic's individual posts are being removed by moderators who consolidate discussion into a megathread; this makes the topic appear to have declining post volume when it actually has concentrated, high-volume discussion
- **Fix**: Monitor for megathread creation (pinned/stickied posts with "Megathread" or "Discussion Thread" in the title). When a megathread exists, measure trend engagement through the megathread's comment volume and velocity, not through individual post counts

## Community & Context Anti-Patterns

### 9. Ignoring Subreddit Culture
- **Problem**: Applying the same engagement thresholds and interpretation rules to all subreddits; r/science has strict sourcing norms while r/memes rewards absurdity — the same engagement patterns mean completely different things
- **Fix**: Build per-subreddit behavioral profiles. Calibrate velocity thresholds, sentiment interpretation, and content quality signals relative to each community's baseline. A 50-comment discussion in r/AskHistorians is exceptional; the same count in r/AskReddit is negligible

### 10. Bot & Karma Farm Blindness
- **Problem**: Including engagement from bot accounts and karma farming operations in trend calculations; these accounts artificially inflate metrics and can create phantom trends
- **Fix**: Flag and discount engagement from accounts that match bot patterns: account age < 30 days + high post frequency + identical comment patterns + posts exclusively to karma-farming subreddits. Weight signals from accounts with established, diverse histories more heavily

### 11. Astroturfing Detection Failure
- **Problem**: Failing to recognize coordinated inauthentic behavior — marketing campaigns, political operations, or corporate PR disguised as organic community interest
- **Fix**: Check for: (1) multiple accounts posting about the same product/topic within a short window with suspiciously positive framing, (2) comments that read like ad copy or talking points, (3) accounts with histories that show sudden topic pivots, (4) submission timing patterns that suggest coordination (e.g., 5 posts about the same startup within 10 minutes from accounts in different subreddits)

### 12. Timezone Ignorance
- **Problem**: Interpreting low engagement during off-peak hours as lack of interest; a post submitted at 3 AM EST to a US-centric subreddit will naturally underperform regardless of topic quality
- **Fix**: Always normalize engagement by the subreddit's hourly activity baseline. Compare a post's velocity against other posts submitted in the same time window, not against the subreddit's all-time averages. Flag posts that show strong velocity during off-peak hours as especially significant

## Output Anti-Patterns

### 13. Trend Report Without Confidence Levels
- **Problem**: Presenting trend detections as binary (trending / not trending) without indicating confidence or supporting evidence strength
- **Fix**: Every trend detection should include: confidence level (high/medium/low), number of confirming signals, time horizon for the prediction, and explicit list of evidence supporting the classification

### 14. Missing Temporal Context
- **Problem**: Reporting a trend without specifying its lifecycle phase — is it emerging, peaking, or decaying? A trend already at peak is not actionable for early detection
- **Fix**: Always classify the trend's current phase (Seed, Ignition, Surge, Peak, Decay) and provide estimated time to peak or time since peak. Include the velocity curve direction (accelerating, stable, decelerating)
