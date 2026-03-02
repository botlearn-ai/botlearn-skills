# Implementation Plan — BotLearn OpenClaw Skills

## Phase 0: 基础设施

- [x] 1. 搭建 Skill 包基础结构和类型定义
  - [x] 1.1 创建 `packages/botlearn/src/types.ts`，定义所有共享类型（SkillManifest, SmokeTest, BenchmarkTest, RubricItem, SkillCategory, BenchmarkDimension, Agent API 接口类型）
    - _Requirements: 1_
  - [x] 1.2 创建 `packages/botlearn/src/validator.ts`，实现 manifest.json 校验器（验证必填字段、semver 格式、依赖引用合法性）
    - _Requirements: 1_
  - [x] 1.3 更新 `packages/botlearn/src/index.ts`，导出类型和工具函数
    - _Requirements: 1_
  - [x] 1.4 更新 `packages/botlearn/package.json`，添加 `"./skills/*"` subpath export 和 files 配置
    - _Requirements: 1_

- [x] 2. 创建 Skill 模板生成器
  - 创建 `packages/botlearn/scripts/create-skill.ts` 脚手架脚本，输入 skill name + category 自动生成目录结构（manifest.json, SKILL.md, knowledge/, strategies/, tests/）
  - _Requirements: 1_

---

## Phase 1: 无依赖 Skills（12 个，可并行）

### 信息检索类

- [x] 3. 实现 `google-search` Skill
  - [x] 3.1 编写 manifest.json（category: information-retrieval, dimension: information-retrieval, no deps）
  - [x] 3.2 编写 SKILL.md（角色: Search Query Specialist，触发词, 能力边界, 激活规则）
  - [x] 3.3 编写 knowledge/domain.md（搜索运算符语法: site:, filetype:, OR, -, 精确短语, 日期范围）
  - [x] 3.4 编写 knowledge/best-practices.md（查询构造模式、结果质量判断、来源可信度）
  - [x] 3.5 编写 knowledge/anti-patterns.md（过长查询、忽略来源验证、单一来源依赖）
  - [x] 3.6 编写 strategies/main.md（查询分解 → 多源搜索 → 去重 → 排序 → 验证，6 步）
  - [x] 3.7 编写 tests/smoke.json（1 个搜索任务 + rubric: 相关度、去噪、来源多样性）
  - [x] 3.8 编写 tests/benchmark.json（10 个任务: easy×3 medium×4 hard×3）
  - _Requirements: 2_

- [x] 4. 实现 `rss-manager` Skill
  - [x] 4.1 编写 manifest.json + SKILL.md
  - [x] 4.2 编写 knowledge/（RSS/Atom 解析、去重算法、重要性评分、主题建模）
  - [x] 4.3 编写 strategies/main.md（源监控 → 提取 → 去重 → 评分 → 聚类 → 摘要）
  - [x] 4.4 编写 tests/（smoke: 1 日报摘要任务; benchmark: 10 个任务）
  - _Requirements: 4_

- [x] 5. 实现 `twitter-intel` Skill
  - [x] 5.1 编写 manifest.json + SKILL.md
  - [x] 5.2 编写 knowledge/（Twitter API、KOL 识别、互动指标、机器人检测、趋势分析）
  - [x] 5.3 编写 strategies/main.md（源策展 → 信号过滤 → 观点提取 → 趋势检测 → 洞察综合）
  - [x] 5.4 编写 tests/（smoke: 1 热点分析任务; benchmark: 10 个任务）
  - _Requirements: 5_

- [x] 6. 实现 `reddit-tracker` Skill
  - [x] 6.1 编写 manifest.json + SKILL.md
  - [x] 6.2 编写 knowledge/（Reddit API、互动速度指标、社区规范、趋势检测）
  - [x] 6.3 编写 strategies/main.md（子版块监控 → 速度追踪 → 跨社区关联 → 情感分析 → 趋势预测）
  - [x] 6.4 编写 tests/（smoke: 1 趋势识别任务; benchmark: 10 个任务）
  - _Requirements: 6_

### 内容处理类

- [x] 7. 实现 `summarizer` Skill
  - [x] 7.1 编写 manifest.json + SKILL.md
  - [x] 7.2 编写 knowledge/（话语结构、论证映射、信息密度启发、摘要取舍）
  - [x] 7.3 编写 strategies/main.md（结构识别 → 论证提取 → 细节优先级 → 综合 → 准确性自检）
  - [x] 7.4 编写 tests/（smoke: 1 长文总结任务; benchmark: 10 个任务）
  - _Requirements: 7_

- [x] 8. 实现 `translator` Skill
  - [x] 8.1 编写 manifest.json + SKILL.md
  - [x] 8.2 编写 knowledge/（翻译理论、语言对模式、领域术语、常见陷阱）
  - [x] 8.3 编写 strategies/main.md（源分析 → 上下文建立 → 术语查找 → 草译 → 润色 → 一致性验证）
  - [x] 8.4 编写 tests/（smoke: 1 翻译任务; benchmark: 10 个任务）
  - _Requirements: 8_

- [x] 9. 实现 `keyword-extractor` Skill
  - [x] 9.1 编写 manifest.json + SKILL.md
  - [x] 9.2 编写 knowledge/（TF-IDF、语义相似度、主题建模、领域分类树）
  - [x] 9.3 编写 strategies/main.md（预处理 → 多层提取 → 聚类 → 排序 → 领域上下文化）
  - [x] 9.4 编写 tests/（smoke: 1 关键词提取任务; benchmark: 10 个任务）
  - _Requirements: 10_

- [x] 10. 实现 `sentiment-analyzer` Skill
  - [x] 10.1 编写 manifest.json + SKILL.md
  - [x] 10.2 编写 knowledge/（情感词典、方面级分析、讽刺检测、领域指标）
  - [x] 10.3 编写 strategies/main.md（分段 → 方面识别 → 情感线索 → 极性分类 → 置信评估 → 聚合）
  - [x] 10.4 编写 tests/（smoke: 1 情感分析任务; benchmark: 10 个任务）
  - _Requirements: 11_

### 编程辅助类

- [x] 11. 实现 `code-gen` Skill
  - [x] 11.1 编写 manifest.json + SKILL.md
  - [x] 11.2 编写 knowledge/domain.md（语言惯用法: TypeScript, Python, Go 常见模式）
  - [x] 11.3 编写 knowledge/best-practices.md（错误处理、类型安全、输入验证、测试伴随）
  - [x] 11.4 编写 knowledge/anti-patterns.md（any 滥用、silent catch、无验证、硬编码）
  - [x] 11.5 编写 strategies/main.md（需求分析 → 架构决策 → 接口设计 → 实现 → 自测 → 审查反思，6 步）
  - [x] 11.6 编写 tests/smoke.json（1 个 REST API 生成任务 + 详细 rubric）
  - [x] 11.7 编写 tests/benchmark.json（10 个代码生成任务）
  - _Requirements: 12_

- [x] 12. 实现 `code-review` Skill
  - [x] 12.1 编写 manifest.json + SKILL.md
  - [x] 12.2 编写 knowledge/（OWASP Top 10、漏洞模式、性能反模式、代码气味、清洁代码）
  - [x] 12.3 编写 strategies/main.md（静态分析 → 安全扫描 → 性能分析 → 模式检查 → 问题分类 → 修复建议）
  - [x] 12.4 编写 tests/（smoke: 1 审查任务含植入缺陷; benchmark: 10 个任务）
  - _Requirements: 13_

### 创意生成类

- [x] 13. 实现 `brainstorm` Skill
  - [x] 13.1 编写 manifest.json + SKILL.md
  - [x] 13.2 编写 knowledge/（SCAMPER, Six Hats, TRIZ, 创新模式, 可行性矩阵）
  - [x] 13.3 编写 strategies/main.md（问题重构 → 多维发散 → 生成 → 可行性评估 → 聚类 → 排序）
  - [x] 13.4 编写 tests/（smoke: 1 头脑风暴任务; benchmark: 10 个任务）
  - _Requirements: 18_

- [x] 14. 实现 `storyteller` Skill
  - [x] 14.1 编写 manifest.json + SKILL.md
  - [x] 14.2 编写 knowledge/（英雄旅程, 三幕, Kishōtenketsu, 角色原型, 类型约定, 节奏技巧）
  - [x] 14.3 编写 strategies/main.md（前提 → 角色设计 → 情节大纲 → 场景写作 → 节奏调整 → 一致性审查）
  - [x] 14.4 编写 tests/（smoke: 1 短篇创作任务; benchmark: 10 个任务）
  - _Requirements: 19_

---

## Phase 2: 有依赖 Skills（8 个，按序）

- [x] 15. 实现 `academic-search` Skill
  - [x] 15.1 编写 manifest.json（dependencies: `@botlearn/google-search: ^1.0.0`）+ SKILL.md
  - [x] 15.2 编写 knowledge/（学术数据库 API: arXiv, Scholar, Semantic Scholar; 论文结构; 引用分析; 方法论分类）
  - [x] 15.3 编写 strategies/main.md（关键词提取 → 数据库查询 → 摘要筛选 → 交叉验证 → 综合）
  - [x] 15.4 编写 tests/（smoke: 1 论文检索任务; benchmark: 10 个任务）
  - _Requirements: 3, depends on Task 3_

- [x] 16. 实现 `rewriter` Skill
  - [x] 16.1 编写 manifest.json（dependencies: `@botlearn/summarizer: ^1.0.0`）+ SKILL.md
  - [x] 16.2 编写 knowledge/（写作风格分类、受众分析、AI 检测规避模式）
  - [x] 16.3 编写 strategies/main.md（源分析 → 受众画像 → 风格映射 → 变体改写 → 自然度检查 → 准确性验证）
  - [x] 16.4 编写 tests/（smoke: 1 改写任务; benchmark: 10 个任务）
  - _Requirements: 9, depends on Task 7_

- [x] 17. 实现 `debugger` Skill
  - [x] 17.1 编写 manifest.json（dependencies: `@botlearn/code-review: ^1.0.0`）+ SKILL.md
  - [x] 17.2 编写 knowledge/（常见 Bug 模式、调试方法论、错误信息解读、堆栈分析）
  - [x] 17.3 编写 strategies/main.md（症状分析 → 假设 → 复现 → 根因隔离 → 修复 → 回归测试 → 验证）
  - [x] 17.4 编写 tests/（smoke: 1 调试任务; benchmark: 10 个任务）
  - _Requirements: 14, depends on Task 12_

- [x] 18. 实现 `refactor` Skill
  - [x] 18.1 编写 manifest.json（dependencies: `@botlearn/code-review: ^1.0.0`）+ SKILL.md
  - [x] 18.2 编写 knowledge/（GoF 设计模式、Fowler 重构目录、SOLID、复杂度指标）
  - [x] 18.3 编写 strategies/main.md（气味检测 → 模式匹配 → 重构计划 → 增量转换 → 等价性验证 → 质量测量）
  - [x] 18.4 编写 tests/（smoke: 1 重构任务; benchmark: 10 个任务）
  - _Requirements: 15, depends on Task 12_

- [x] 19. 实现 `doc-gen` Skill
  - [x] 19.1 编写 manifest.json（dependencies: `@botlearn/code-gen: ^1.0.0`）+ SKILL.md
  - [x] 19.2 编写 knowledge/（JSDoc, OpenAPI, README 约定、技术写作、Keep a Changelog 格式）
  - [x] 19.3 编写 strategies/main.md（代码分析 → API 提取 → 描述生成 → 示例创建 → 风格匹配 → 完整性检查）
  - [x] 19.4 编写 tests/（smoke: 1 文档生成任务; benchmark: 10 个任务）
  - _Requirements: 16, depends on Task 11_

- [x] 20. 实现 `writer` Skill
  - [x] 20.1 编写 manifest.json（dependencies: `@botlearn/summarizer: ^1.0.0`, `@botlearn/keyword-extractor: ^1.0.0`）+ SKILL.md
  - [x] 20.2 编写 knowledge/（文章结构: 倒金字塔/叙事/分析、论证框架、证据类型、风格指南）
  - [x] 20.3 编写 strategies/main.md（主题研究 → 大纲 → 论证构建 → 证据整合 → 初稿 → 风格检查 → 修订）
  - [x] 20.4 编写 tests/（smoke: 1 文章写作任务; benchmark: 10 个任务）
  - _Requirements: 17, depends on Task 7 + Task 9_

- [x] 21. 实现 `copywriter` Skill
  - [x] 21.1 编写 manifest.json（dependencies: `@botlearn/sentiment-analyzer: ^1.0.0`）+ SKILL.md
  - [x] 21.2 编写 knowledge/（AIDA, PAS, BAB, 4Ps 框架、受众细分、痛点提炼、CTA 设计、平台规范）
  - [x] 21.3 编写 strategies/main.md（受众分析 → 痛点 → 价值主张 → 框架选择 → 起草 → 变体生成 → 说服力检查）
  - [x] 21.4 编写 tests/（smoke: 1 文案任务; benchmark: 10 个任务）
  - _Requirements: 20, depends on Task 10_

- [x] 22. 实现 `social-media` Skill
  - [x] 22.1 编写 manifest.json（dependencies: `@botlearn/copywriter: ^1.0.0`）+ SKILL.md
  - [x] 22.2 编写 knowledge/（平台规范: Twitter/LinkedIn/Instagram/TikTok 字数限制/格式/算法偏好、标签策略、互动模式）
  - [x] 22.3 编写 strategies/main.md（平台分析 → 创意构思 → 格式适配 → 标签选择 → 时机优化 → 互动预测）
  - [x] 22.4 编写 tests/（smoke: 1 社交内容任务; benchmark: 10 个任务）
  - _Requirements: 21, depends on Task 21_

---

## Phase 3: 集成与验证

- [x] 23. Manifest 校验全量验证
  - 对 20 个 Skill 的 manifest.json 运行 validator.ts 校验
  - 验证所有依赖引用合法、版本格式正确、文件声明完整
  - _Requirements: 1_

- [x] 24. 交叉回归测试
  - 按依赖拓扑序安装所有 20 个 Skill
  - 每安装一个新 Skill 后，重跑已安装 Skill 的 smoke test
  - 验证无 Skill 评分下降 > 5%
  - 记录测试结果矩阵
  - _Requirements: 1_

- [x] 25. 构建与发布准备
  - 运行 `pnpm build` 验证 botlearn 包构建成功
  - 验证 subpath exports（`botlearn/skills/*`）正确解析
  - 更新 `packages/botlearn/README.md` 文档：Skill 列表、安装方式、接口说明
  - _Requirements: 1_
