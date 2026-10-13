# yuanskill-pro · 研究驱动地打磨提示词和 skill

版本 2.0.0。这是一个元技能，它优化的是「提示词 / skill」这个产物本身，不执行提示词里描述的任务。流程：先判断该不该做成 skill，再定能判对错的标准，调研竞品和最成熟的开源实现，逐段对比取舍，合成产物和配套工程，最后实测评分。

适合：一段 prompt 输出不稳、不准，想认真改；新建、重构、打磨一个 skill；写 meta-prompt。
不适合：前期调研和脑爆（用同包里的 yuan），直接写业务代码。

## 文件

| 文件 | 说明 |
|---|---|
| `SKILL.md` | 主入口：两种模式、工作流 0–8（含 0.5 形态判定）、12 条铁律、交付契约、踩坑点 |
| `references/01-research-and-benchmark.md` | 需求四问与需求卡、形态判定、客观检查项、竞品调研、开源挖掘、13 维对比 |
| `references/02-technique-library.md` | 提示词技术库、组合配方、约束三层、skill 字段级工程、模型与脚本分工 |
| `references/03-deliver-and-engineering.md` | 合成产物、配套工程、可容错三件套、安全三闸、发布清单 |
| `references/04-validate-and-iterate.md` | 三道闸自审、评测循环、改进纪律、踩坑点、去玄学 |
| `assets/eval-kit.md` | 测试用例、检查项、记分表、变化清单四张模板 |
| `CHANGELOG.md` | 相对 v1 的变化：抄了什么（逐条标来源）、保留了什么、新增了什么、没抄什么 |

## 安装（Claude Code）

所有项目都能用：

```bash
cp -R yuanskill-pro ~/.claude/skills/yuanskill-pro
```

只给某个项目用：

```bash
mkdir -p 你的项目/.claude/skills
cp -R yuanskill-pro 你的项目/.claude/skills/yuanskill-pro
```

装完新开一个会话生效。文件夹名必须是 `yuanskill-pro`，和 `SKILL.md` 里的 `name` 一致；顶部 YAML 头不要删，`references/` 和 `assets/` 的目录名、文件名不要改。

### 装之前看一眼有没有冲突

- 如果你装过旧版 `yuanskill`（v1），两个同时存在时，旧版会抢走触发（已实测）。二选一，或者每次点名 `/yuanskill-pro`。
- Anthropic 官方的 `skill-creator` 和它有部分重叠，不用卸载，按用途分：要脚手架和官方 eval 工具链用 skill-creator，要研究驱动的深度优化用 yuanskill-pro。拿不准就点名调用。

## 怎么用

直接说「帮我优化这段提示词」「这个 prompt 输出不稳」「帮我打磨一个 skill」就会触发，也可以点名 `/yuanskill-pro`。

它会先判断模式并告诉你，你可以否决：

- BASIC 快修：交付优化后的产物、关键改动、一次「有 / 无产物」的基线对比结论，加 1–3 条使用提示。
- DETAIL 全流程：动手前先问 2–3 个关键问题，最后交付形态判定结论、对比取舍表、产物和配套工程、评测结果、变化清单。

用的时候你会注意到三件事：

1. 它会先问「这该不该做成 skill」，有时会直接建议你放进项目说明文件就够了。
2. 它不只靠自审交付，会跑一次有产物和没产物的对比，用结果说明值不值得维护。
3. 产物是 skill 时，会过一遍字段级检查：description 怎么写才能被正确触发、正文体量上限、引用只一层。

## 其它平台

全部是纯 Markdown，不依赖脚本，按 Agent Skills 开放标准写的。平台不支持 skill 的话，把 `SKILL.md` 当提示词，`references/` 当知识库喂进去也能用。

## 来源

v2.0.0 是在 v1 骨架上，吸收了《图解Skill：AI提效实战指南》（宝玉著）里的技能工程和评测循环，并对照了作者开源的 baoyu-skills 实物。逐条来源见 `CHANGELOG.md`。

本技能自己还没有题库。第一次用它优化一个真实 prompt 时，建议把那次的测试用例存成第一批题库，放在你项目里的 `evals/`。
