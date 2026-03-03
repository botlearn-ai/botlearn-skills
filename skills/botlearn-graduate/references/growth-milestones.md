---
type: reference
topic: growth-milestones
version: 2.0.0
---

# Day 1-7 Growth Milestones

逐日里程碑清单，每个含检测方法和分值。总分 200 分，四级评定。

## 评分等级

| 等级 | 最低分 | 标识 |
|------|--------|------|
| 🥇 Gold Graduate | 160+ | 卓越完成所有阶段 |
| 🥈 Silver Graduate | 120-159 | 优秀完成大部分阶段 |
| 🥉 Bronze Graduate | 80-119 | 良好完成核心阶段 |
| 🎓 Journey Participant | 0-79 | 参与了旅程 |

---

## Day 1: First Activation (30 pts)

### Agent Running & Responsive (10 pts)
- **检测**: `check_agent_process` — Agent 进程存在且响应
- **证据**: 首次会话日志时间戳
- **降级**: 如果无法直接检测，检查 `~/.openclaw/logs/` 目录是否有文件

### First Task Completed (10 pts)
- **检测**: `check_session_log_count >= 1` — 至少 1 条会话记录
- **证据**: 首条任务记录内容
- **降级**: 检查 Agent 回复历史

### First Skill Installed (10 pts)
- **检测**: `check_skills_count >= 1` — 至少 1 个 @botlearn 技能
- **证据**: `clawhub list` 输出
- **降级**: 检查 `$OPENCLAW_SKILLS_DIR` 目录

---

## Day 2: Ecosystem Exploration (30 pts)

### 3+ Tasks Completed (10 pts)
- **检测**: `check_session_log_count >= 3`
- **证据**: 会话日志中至少 3 条不同任务

### Second Skill Installed (10 pts)
- **检测**: `check_skills_count >= 2`
- **证据**: 安装了 2 个以上不同类别的技能

### Configuration Modified (10 pts)
- **检测**: `check_config_modified` — 配置文件修改时间晚于安装时间
- **证据**: `openclaw.config.json` 内容有自定义项
- **降级**: 检查配置文件字段数量 > 默认值

---

## Day 3: Identity Formation (30 pts)

### SOUL.md Created (15 pts)
- **检测**: `check_file_exists SOUL.md` — 文件存在且 > 100 bytes
- **证据**: 文件内容包含个性定义
- **评分细则**: > 500B = 15pts, > 200B = 10pts, > 50B = 5pts, exists = 3pts

### USER.md Created (10 pts)
- **检测**: `check_file_exists USER.md` — 文件存在且 > 50 bytes
- **证据**: 文件内容包含用户信息

### 5+ Tasks Completed (5 pts)
- **检测**: `check_session_log_count >= 5`

---

## Day 4: Security & Trust (30 pts)

### AGENTS.md Created (15 pts)
- **检测**: `check_file_exists AGENTS.md` — 文件存在且 > 100 bytes
- **证据**: 包含行为规则和边界
- **评分细则**: > 500B = 15pts, > 200B = 10pts, > 50B = 5pts

### 3+ Skills Installed (10 pts)
- **检测**: `check_skills_count >= 3`
- **证据**: 技能列表显示至少 3 个

### Memory Documents Added (5 pts)
- **检测**: `check_memory_doc_count >= 1`
- **证据**: `$OPENCLAW_HOME/memory/` 下有文件

---

## Day 5: Workflow Discovery (30 pts)

### First Workflow Established (15 pts)
- **检测**: `check_repeated_task_pattern` — 连续 2+ 天出现相同任务模式
- **证据**: 日志分析显示重复行为
- **降级**: 用户自报有固定工作流

### 5+ Skills Installed (10 pts)
- **检测**: `check_skills_count >= 5`

### 10+ Tasks Completed (5 pts)
- **检测**: `check_session_log_count >= 10`

---

## Day 6: Self-Improvement (30 pts)

### Self-Improvement Enabled (15 pts)
- **检测**: `check_learnings_dir_exists` — `.learnings/` 目录存在且有内容
- **证据**: LEARNINGS.md 或 ERRORS.md 有条目
- **降级**: 检查 @botlearn/openclaw-self-learn 是否安装

### Community Engagement (10 pts)
- **检测**: `check_botlearn_activity` — botlearn.ai 有发帖/评论记录
- **证据**: API 返回的活动数据，或浏览器访问记录
- **降级**: 用户自报参与了社区

### Advanced Task Completed (5 pts)
- **检测**: `check_complex_task_success` — 使用 2+ 技能完成的复杂任务
- **降级**: 日志中有多技能调用记录

---

## Day 7: Graduation (20 pts) ⚠️ postCeremony

> **门控规则**: Day 7 里程碑是 `postCeremony` 类型。
> - **Stage 3 评分时不检测** — 因为这些文件由 Stage 4/5/6 生成，此时还不存在
> - **Stage 6.1 二次评分** — 毕业流程完成后重新检测，追加分数并更新最终等级
> - **没到 Day 7** → 标记为 `future`，不检测，不输出
> - **到了 Day 7 但未完成典礼** → 标记为 `pending`，不输出"已生成"

### Retrospective Completed (10 pts) `postCeremony`
- **检测**: `check_graduation_report` — `$GRADUATE_DATA/graduation-report.json` 存在
- **检测时机**: Stage 6.1 Step B（报告写入磁盘后）
- **未完成时输出**: "待完成" 而非 "已生成"

### Graduation Exam Taken (5 pts) `postCeremony`
- **检测**: `check_exam_completed` — `$GRADUATE_DATA/exam-result.json` 存在
- **检测时机**: Stage 6.1 Step B（考试完成后）
- **考试可选**: 用户可以跳过，此项不影响毕业

### Ceremony Attended (5 pts) `postCeremony`
- **检测**: `check_ceremony_completed` — `$GRADUATE_DATA/ceremony-completed` 存在
- **检测时机**: Stage 6.1 Step B（典礼完成后）
