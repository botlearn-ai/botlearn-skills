# BotLearn Awesome Skills — 用户使用指南

## 目录

- [快速开始](#快速开始)
- [安装 Skill](#安装-skill)
- [Skill 如何工作](#skill-如何工作)
- [触发词速查表](#触发词速查表)
- [Skill 分类一览](#skill-分类一览)
- [依赖关系与安装顺序](#依赖关系与安装顺序)
- [测试与验证](#测试与验证)
- [卸载与回滚](#卸载与回滚)
- [故障排除](#故障排除)

---

## 快速开始

BotLearn Awesome Skills 为你的 OpenClaw Agent 提供 **20 个独立可安装的能力单元**。每个 Skill 安装后即刻生效，无需额外配置。

```bash
# 安装一个 Skill
clawhub install @botlearn/code-gen

# 安装后，直接对话即可触发
# 用户: "帮我写一个用户注册的 REST API"
# Agent 自动激活 code-gen Skill，按策略流程生成代码
```

---

## 安装 Skill

### 基本安装

```bash
clawhub install @botlearn/<skill-name>
```

安装过程是**原子操作**，任一步骤失败则自动回滚，不会产生半安装状态。

### 安装流程详解

```
clawhub install @botlearn/code-gen
         │
         ▼
   ┌─────────────────┐
   │ 1. 下载 manifest │  从 npm Registry 获取包信息
   └────────┬────────┘
            ▼
   ┌─────────────────┐
   │ 2. 依赖检查     │  确认所需依赖 Skill 已安装
   └────────┬────────┘
            ▼
   ┌─────────────────┐
   │ 3. 兼容性检查   │  Agent 版本 >= 最低要求
   └────────┬────────┘
            ▼
   ┌─────────────────┐
   │ 4. 知识注入     │  knowledge/*.md → Agent 记忆
   └────────┬────────┘
            ▼
   ┌─────────────────┐
   │ 5. 策略注册     │  SKILL.md + strategies/ → 技能系统
   └────────┬────────┘
            ▼
   ┌─────────────────┐
   │ 6. 冒烟测试     │  运行 smoke test，分数 >= 60 则通过
   └────────┬────────┘
            ▼
     ✅ 安装成功 / ❌ 自动回滚
```

### 安装示例

```bash
# 信息检索类
clawhub install @botlearn/google-search
clawhub install @botlearn/academic-search    # 需要先安装 google-search

# 内容处理类
clawhub install @botlearn/summarizer
clawhub install @botlearn/translator

# 编程辅助类
clawhub install @botlearn/code-gen
clawhub install @botlearn/code-review

# 创意生成类
clawhub install @botlearn/brainstorm
clawhub install @botlearn/copywriter         # 需要先安装 sentiment-analyzer
```

---

## Skill 如何工作

安装后的 Skill 通过三层架构为 Agent 赋能：

### 第一层：知识记忆（Knowledge）

Skill 的 `knowledge/` 目录中的领域知识被注入 Agent 长期记忆。Agent 在处理相关任务时会自动检索这些知识。

知识文件包含三类：
- **domain.md** — 领域核心知识（概念、术语、方法论）
- **best-practices.md** — 最佳实践和推荐做法
- **anti-patterns.md** — 应避免的反模式和常见错误

每份知识带有 TTL（过期时间），到期后提示更新。

### 第二层：触发词激活（Triggers）

每个 Skill 定义了一组触发词。当用户输入匹配到触发词时，Agent 自动激活对应 Skill。

**示例**：

| 你说的话 | 触发的 Skill | 触发词匹配 |
|---------|-------------|-----------|
| "帮我搜索一下 React 最新动态" | google-search | "search for" |
| "写一个登录功能的代码" | code-gen | "write code" |
| "帮我总结这篇文章" | summarizer | "summarize" |
| "这段代码有什么问题" | code-review | "check this code" |
| "帮我头脑风暴一下产品方向" | brainstorm | "brainstorm" |

### 第三层：策略执行（Strategy）

激活后，Agent 按照 `strategies/main.md` 定义的多步骤流程执行任务。策略支持：

- **顺序步骤** — 按步骤 1→2→3→... 依次执行
- **条件分支** — IF/THEN 逻辑根据上下文做决策
- **知识引用** — 在具体步骤中引用 knowledge/ 文档
- **自检循环** — 完成后自检，不通过则回到上游步骤修正

---

## 触发词速查表

### 信息检索类

| Skill | 触发词 |
|-------|--------|
| **google-search** | `search for`, `find information`, `look up`, `google`, `search the web`, `find sources` |
| **academic-search** | `find papers`, `academic search`, `research`, `literature review`, `arxiv`, `scholar`, `scholarly articles`, `cite`, `citation`, `peer-reviewed`, `scientific literature` |
| **rss-manager** | `rss`, `feed`, `subscribe`, `digest`, `news feed`, `aggregator`, `syndication`, `feed reader` |
| **twitter-intel** | `twitter`, `tweet`, `KOL`, `trending`, `X platform`, `twitter intelligence`, `twitter analysis`, `influencer tracking`, `twitter trends`, `social listening` |
| **reddit-tracker** | `reddit`, `subreddit`, `trending`, `community`, `hotspot`, `reddit trends`, `what's hot on reddit` |

### 内容处理类

| Skill | 触发词 |
|-------|--------|
| **summarizer** | `summarize`, `summary`, `key points`, `TLDR`, `digest`, `main ideas`, `boil down` |
| **translator** | `translate`, `translation`, `翻译`, `convert to [language]`, `say this in`, `how do you say`, `localize` |
| **rewriter** | `rewrite`, `rephrase`, `paraphrase`, `reword`, `adapt for audience` |
| **keyword-extractor** | `extract keywords`, `key terms`, `topic extraction`, `keyword analysis`, `find keywords`, `identify topics`, `extract key phrases` |
| **sentiment-analyzer** | `sentiment`, `opinion mining`, `analyze tone`, `polarity`, `sentiment analysis`, `emotional tone`, `opinion detection`, `feeling analysis` |

### 编程辅助类

| Skill | 触发词 |
|-------|--------|
| **code-gen** | `write code`, `generate function`, `create API`, `implement feature`, `code this` |
| **code-review** | `review code`, `code review`, `check this code`, `find bugs`, `security audit`, `review my code`, `check for vulnerabilities`, `code quality` |
| **debugger** | `debug`, `fix bug`, `why is this failing`, `error`, `stack trace`, `exception`, `not working`, `unexpected behavior`, `crash`, `broken` |
| **refactor** | `refactor`, `clean up code`, `improve code quality`, `apply design pattern`, `reduce complexity`, `simplify code`, `restructure code`, `reduce duplication` |
| **doc-gen** | `generate docs`, `document this`, `write README`, `API documentation`, `changelog`, `add JSDoc`, `OpenAPI spec`, `document the API`, `write documentation` |

### 创意生成类

| Skill | 触发词 |
|-------|--------|
| **writer** | `write an article`, `write about`, `compose`, `draft article`, `blog post` |
| **brainstorm** | `brainstorm`, `generate ideas`, `ideation`, `think of ways`, `creative solutions`, `come up with ideas`, `brainstorming session` |
| **storyteller** | `write a story`, `tell a story`, `create a narrative`, `fiction`, `storytelling` |
| **copywriter** | `write copy`, `marketing copy`, `landing page`, `ad copy`, `CTA`, `sales copy` |
| **social-media** | `social media post`, `tweet`, `LinkedIn post`, `Instagram caption`, `TikTok script`, `create a post`, `social content`, `post for` |

---

## Skill 分类一览

### A. 信息检索类（5 个）

帮助 Agent 从互联网、学术数据库、社交媒体等渠道高效获取信息。

| Skill | 描述 | 核心能力 |
|-------|------|---------|
| **google-search** | Google 高级搜索 | 构建精准搜索查询，过滤噪音，提升搜索结果相关性 |
| **academic-search** | 学术论文检索 | 搜索 arXiv/Google Scholar，提取关键发现，比较分析 |
| **rss-manager** | RSS 订阅管理 | 聚合多源 RSS，去重，生成每日摘要 |
| **twitter-intel** | Twitter/X 情报分析 | 追踪 KOL，过滤噪音，提取趋势洞察 |
| **reddit-tracker** | Reddit 热点追踪 | 监控 subreddit，检测趋势，预测热度 |

### B. 内容处理类（5 个）

帮助 Agent 理解、转换、分析文本内容。

| Skill | 描述 | 核心能力 |
|-------|------|---------|
| **summarizer** | 长文总结 | 提取核心论点，保留关键细节，支持多文档比较 |
| **translator** | 多语言翻译 | 上下文感知翻译，术语一致性，文化适配 |
| **rewriter** | 内容改写 | 风格转换，受众适配，通过 AI 检测 |
| **keyword-extractor** | 关键词提取 | 多层级关键词提取，主题聚类，语义分析 |
| **sentiment-analyzer** | 情感分析 | 多粒度情感识别，方面级分析，讽刺检测 |

### C. 编程辅助类（5 个）

帮助 Agent 编写、审查、调试、重构代码和生成文档。

| Skill | 描述 | 核心能力 |
|-------|------|---------|
| **code-gen** | 代码生成 | 生成完整代码，含错误处理、类型标注、测试 |
| **code-review** | 代码审查 | 安全漏洞、性能问题、代码气味检测 |
| **debugger** | Bug 调试 | 根因分析，假设驱动，修复建议 + 回归测试 |
| **refactor** | 代码重构 | 识别代码气味，应用设计模式，保持行为等价 |
| **doc-gen** | 文档生成 | API 文档、README、Changelog、JSDoc |

### D. 创意生成类（5 个）

帮助 Agent 生成高质量的创意内容。

| Skill | 描述 | 核心能力 |
|-------|------|---------|
| **writer** | 文章写作 | 结构化文章，证据支撑，风格一致 |
| **brainstorm** | 头脑风暴 | 多维度创意生成，可行性评估，优先级排序 |
| **storyteller** | 故事创作 | 叙事结构，角色发展，情感节奏 |
| **copywriter** | 营销文案 | 受众分析，痛点提取，CTA 设计，A/B 变体 |
| **social-media** | 社交媒体内容 | 平台适配，标签优化，发布时机，互动预测 |

---

## 依赖关系与安装顺序

### 无依赖 Skill（12 个）

以下 Skill 无任何依赖，可以按任意顺序安装：

```
google-search, rss-manager, twitter-intel, reddit-tracker,
summarizer, translator, keyword-extractor, sentiment-analyzer,
code-gen, code-review, brainstorm, storyteller
```

### 有依赖 Skill（8 个）

以下 Skill 依赖其他 Skill，必须先安装依赖项：

```
依赖关系图：

google-search ──→ academic-search
summarizer ──────→ rewriter
summarizer ──┐
             ├──→ writer
keyword-extractor ┘
sentiment-analyzer → copywriter → social-media
code-review ──────→ debugger
code-review ──────→ refactor
code-gen ─────────→ doc-gen
```

| 要安装的 Skill | 必须先安装 |
|---------------|-----------|
| academic-search | google-search |
| rewriter | summarizer |
| writer | summarizer + keyword-extractor |
| copywriter | sentiment-analyzer |
| social-media | copywriter (+ sentiment-analyzer) |
| debugger | code-review |
| refactor | code-review |
| doc-gen | code-gen |

**推荐安装顺序**（全量安装）：

```bash
# 第一批：无依赖（可并行）
clawhub install @botlearn/google-search
clawhub install @botlearn/rss-manager
clawhub install @botlearn/twitter-intel
clawhub install @botlearn/reddit-tracker
clawhub install @botlearn/summarizer
clawhub install @botlearn/translator
clawhub install @botlearn/keyword-extractor
clawhub install @botlearn/sentiment-analyzer
clawhub install @botlearn/code-gen
clawhub install @botlearn/code-review
clawhub install @botlearn/brainstorm
clawhub install @botlearn/storyteller

# 第二批：有依赖（按依赖拓扑序）
clawhub install @botlearn/academic-search
clawhub install @botlearn/rewriter
clawhub install @botlearn/debugger
clawhub install @botlearn/refactor
clawhub install @botlearn/doc-gen
clawhub install @botlearn/writer
clawhub install @botlearn/copywriter
clawhub install @botlearn/social-media
```

---

## 测试与验证

### L1 冒烟测试（安装时自动）

- 安装时自动执行，无需手动操作
- 每个 Skill 1 个代表性任务
- 超时 60 秒
- 通过阈值：60/100 分
- 失败则自动回滚安装

### L2 基准测试（用户主动触发）

- 每个 Benchmark 维度 10 个测试任务（简单 ×3, 中等 ×4, 困难 ×3）
- Judge LLM 独立评分 3 次，取中位数
- 目标：安装 Skill 后评分提升 ≥ 30 分

| Benchmark 维度 | 关联 Skills |
|---------------|------------|
| Information Retrieval | google-search, academic-search, rss-manager, twitter-intel, reddit-tracker |
| Content Understanding | summarizer, translator, rewriter, keyword-extractor, sentiment-analyzer |
| Code Generation | code-gen, code-review, debugger, refactor, doc-gen |
| Creative Generation | writer, brainstorm, storyteller, copywriter, social-media |

### L3 回归测试（发布前 CI）

- 安装新 Skill 后，重跑所有已安装 Skill 的冒烟测试
- 确保无 Skill 评分下降 > 5%

---

## 卸载与回滚

### 自动回滚

安装过程中若任一步骤失败，系统会自动执行回滚：

1. `POST /memory/rollback` — 移除已注入的知识
2. `POST /skills/unregister` — 注销已注册的策略

### 错误恢复

| 错误场景 | 系统行为 |
|---------|---------|
| 依赖缺失 | 提示用户先安装所需依赖 |
| Agent 版本不兼容 | 显示最低版本要求，引导升级 |
| 知识注入失败 | 全部回滚，报告失败的文档 |
| 策略注册失败 | 回滚已注入知识，报告错误 |
| 冒烟测试不通过 | 回滚全部，显示测试分数和改进建议 |
| 网络超时 | 自动重试 3 次（间隔 1s/2s/4s），全部失败后回滚 |

---

## 故障排除

### 安装失败

**Q: 安装时提示"依赖缺失"**

```bash
# 先安装依赖 Skill
clawhub install @botlearn/google-search
# 然后再安装目标 Skill
clawhub install @botlearn/academic-search
```

**Q: 冒烟测试不通过**

冒烟测试要求得分 ≥ 60/100。如果失败：
- 检查 Agent 版本是否满足 `compatibility.openclaw` 要求
- 确认依赖 Skill 均已正确安装
- 重试安装

**Q: Agent 版本不兼容**

需升级 OpenClaw Agent 至 `>=0.5.0`。

### 运行时问题

**Q: Skill 没有被触发**

- 确认 Skill 已成功安装
- 尝试使用更明确的触发词（参见[触发词速查表](#触发词速查表)）
- 例如：用 "summarize this article" 而非 "tell me what this says"

**Q: Skill 输出质量不佳**

- 提供更具体的指令和上下文
- 运行基准测试评估 Skill 性能
- 确认相关依赖 Skill 也已安装（如 `writer` 需要 `summarizer` + `keyword-extractor`）
