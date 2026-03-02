---
domain: reddit-tracker
topic: reddit-api-scoring-karma-post-types
priority: high
ttl: 30d
---

# Reddit Platform — API, Scoring, Karma & Post Types

## Reddit Data API

### Authentication
- Reddit uses OAuth2 for API access; all requests require a bearer token
- Rate limit: 100 requests per minute per OAuth client (600/min for mod accounts)
- User-Agent header is mandatory — requests without it are deprioritized or blocked
- App types: `script` (personal), `web` (3rd-party), `installed` (mobile/desktop)

### Key Endpoints for Monitoring

#### Subreddit Listings
- `GET /r/{subreddit}/hot` — Posts ranked by Reddit's "hot" algorithm (recency + engagement)
- `GET /r/{subreddit}/new` — Chronological newest posts (critical for early detection)
- `GET /r/{subreddit}/rising` — Posts gaining traction faster than peers (best signal for breakouts)
- `GET /r/{subreddit}/top?t={hour|day|week}` — Highest-scoring posts within a time window
- `GET /r/{subreddit}/controversial?t={hour|day|week}` — Posts with high engagement but split up/down ratio

#### Post & Comment Data
- `GET /comments/{article_id}` — Full comment tree for a post
- `GET /r/{subreddit}/comments` — Latest comments across the subreddit (firehose)
- Each post object includes: `score`, `upvote_ratio`, `num_comments`, `created_utc`, `gilded`, `total_awards_received`, `is_crosspost`

#### Search
- `GET /r/{subreddit}/search?q={query}&sort=new&restrict_sr=true` — Subreddit-scoped search
- `GET /search?q={query}&sort=relevance&t=day` — Site-wide search with time filter
- Supports Lucene-style syntax: `title:keyword`, `selftext:keyword`, `author:username`, `flair:tag`

### Pagination
- Reddit uses cursor-based pagination with `after` and `before` fullname tokens
- Maximum 100 items per request (default 25)
- Listings capped at ~1000 items total — cannot paginate beyond that

## Reddit Scoring System

### Vote Score
- `score = upvotes - downvotes` (approximate — Reddit applies vote fuzzing)
- `upvote_ratio` — Fraction of votes that are upvotes (0.0 to 1.0)
- Vote fuzzing: Reddit adds/subtracts random votes to obscure true counts; ratios are more reliable than absolute scores

### Hot Ranking Algorithm
Reddit's hot ranking combines score magnitude with recency:
```
hot_score = log10(max(|score|, 1)) + sign(score) * (created_utc - epoch) / 45000
```
- Logarithmic score: the first 10 votes matter as much as the next 100
- Time decay: a post needs exponentially more votes to maintain rank as it ages
- Epoch reference: Reddit uses a fixed epoch (December 8, 2005)

### Best Ranking (Comments)
- Uses Wilson score confidence interval — favors comments with high upvote ratio AND sufficient sample size
- A comment with 10 up / 1 down outranks one with 100 up / 50 down

### Controversy Score
- `controversy = (upvotes + downvotes) / max(upvotes, downvotes)` when both > 0
- Higher controversy score = more evenly split votes
- Controversial posts show a dagger icon (†) on old Reddit

## Karma System

### Post Karma
- Earned from upvotes on link posts and text posts
- Not 1:1 with score — Reddit applies diminishing returns (approximately logarithmic)
- Subreddit-specific karma thresholds gate posting privileges in many communities

### Comment Karma
- Earned from upvotes on comments
- Also subject to diminishing returns at scale
- Many subreddits require minimum comment karma for participation

### Award Karma
- Earned when posts/comments receive premium awards
- Different awards grant different karma amounts
- Awards visible as icons on the post — a signal of high perceived value

### Karma Relevance to Trend Detection
- High-karma accounts posting about a topic is a stronger signal than low-karma accounts
- Sudden karma spikes on a topic across multiple users indicate organic interest
- Accounts with zero/very low karma posting identical content suggest coordinated campaigns

## Post Types

### Link Posts
- External URL submissions — the classic Reddit post type
- Engagement measured by: score, upvote_ratio, num_comments, crossposts
- A link appearing in multiple subreddits simultaneously is a strong breakout signal

### Text Posts (Self Posts)
- User-written content with a title and body (supports Markdown)
- Often longer-form discussion starters in niche communities
- Text posts that generate high comment-to-score ratios indicate active discussion

### Image & Video Posts
- Hosted on Reddit's own media infrastructure (i.redd.it, v.redd.it)
- Image posts in meme-oriented subreddits can go viral in under an hour
- Video view counts are available but not exposed in the standard API

### Crossposts
- A post shared from one subreddit to another, maintaining a link to the original
- Crosspost chains are a primary indicator of content spreading across communities
- `is_crosspost: true` and `crosspost_parent` fields in the post object

### Polls
- Reddit-native poll posts — votes are anonymized and results visible after voting
- High participation polls indicate community engagement with the topic

### Live Threads & Talk Posts
- Real-time discussion formats for breaking events
- Creation of a live thread for a topic signals perceived significance

## Subreddit Metadata

### Key Fields for Monitoring
- `subscribers` — Total subscriber count (used for normalizing engagement)
- `active_user_count` — Users online now (available via `GET /r/{subreddit}/about`)
- `created_utc` — Subreddit creation date (older = more established baseline)
- `public_description` — Community self-description and scope

### Subreddit Size Tiers

| Tier | Subscribers | Characteristics |
|------|------------|-----------------|
| Mega | >10M | Front-page feeder; high noise, fast velocity |
| Large | 1M-10M | Established communities; reliable trend signals |
| Medium | 100K-1M | Niche but active; early signals before mega-subs |
| Small | 10K-100K | Specialist communities; high signal-to-noise for domain topics |
| Micro | <10K | Very niche; useful for domain-expert sentiment only |

### Flair System
- Post flairs categorize content within a subreddit (e.g., "Discussion", "News", "OC")
- User flairs indicate community standing or expertise
- Flair-based filtering: `GET /r/{subreddit}/search?q=flair:News` — narrows monitoring to specific content types
