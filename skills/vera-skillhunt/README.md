# vera-skillhunt · 找 Skill、比 Skill、出选用报告

从一个任务描述、一张社媒截图、一份 Skill 名单或一个链接出发，帮你找到候选 Skill，回到原始仓库核实来源，按你的任务比较用途和限制，最后交一份中文 HTML 选用与上手报告。安装和小样实测只在你明确要求时执行。

适合：「帮我找做 PPT / 做图 / 做视频的 Skill」「这张截图里的 10 个 Skill 哪个适合我」「讲讲这几个 Skill 怎么用、效果怎样」。
不适合：自己从零写一个 Skill，或优化已有 Skill（用 yuanskill-pro）。

## 文件

| 文件 | 说明 |
|---|---|
| `SKILL.md` | 主入口：确定任务与输入、查找与核实、比较与讲解、按需安装与实测、生成报告 |
| `references/agent-adaptation.md` | 跨 Agent 适配：按实际能力（联网、读图、写文件、安装）选择做法 |
| `references/report.md` | 选用报告规范：内容结构、HTML 交互、`sources.json` 来源记录、交付检查 |
| `agents/openai.yaml` | 可选的宿主元数据，其他 Agent 不需要读取 |

## 安装

支持 Skills CLI 的 Agent：

```bash
npx skills add https://github.com/botlearn-ai/botlearn-skills --skill vera-skillhunt
```

Claude Code 手动安装：

```bash
cp -R vera-skillhunt ~/.claude/skills/vera-skillhunt
```

没有 Skill 入口的 Agent：把 `SKILL.md` 和 `references/` 下的文件一起发给它，说「请按 vera-skillhunt 的方法帮我……」。

## 用法

```
用 vera-skillhunt 帮我找 5 个做自媒体的 Skill，要涵盖封面、内容、图片、文本和视频，生成选用报告。
```

## 来源

为 BotLearn AI 领导力课程的学员专场直播（2026-10-13）编写。流程参考 [dangogit/skill-finder](https://github.com/dangogit/skill-finder)（Apache-2.0）的思路，内容为重新编写。
