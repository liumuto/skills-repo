# skills-repo

> 探索、沉淀一批**实用的 AI Agent Skills**，并以统一的写作规范约束它们的质量。

本仓库是一个 **Skill 集合**：每个 skill 用一份 `SKILL.md` 描述「**何时触发、要做什么、怎么做、边界在哪**」，供 Claude Code / Agent 在合适的场景自动调用。

仓库的第一性原则是：**先有规范，再有 skill**。所有 skill 都以 [`skill-meta`](.agents/skills/skill-meta/SKILL.md) 这份元规范为参考标准，确保触发条件可机械判定、目标可衡量、边界清晰，避免 AI 误调或滥用。

---

## 目录结构

```text
skills-repo/
├── README.md                      # 本文件
├── docs/                          # 设计笔记 / 补充文档
└── .agents/
    └── skills/
        └── <skill-name>/
            └── SKILL.md           # 单个 skill 的定义（YAML frontmatter + 正文）
```

- 每个 skill 占一个目录，目录名即 skill 名（kebab-case）。
- 目录下必须有 `SKILL.md`；其 frontmatter 的 `name` 字段需与目录名**严格一致**。

---

## 现有 Skills

| Skill | 作用 | 何时触发 |
| --- | --- | --- |
| [skill-meta](.agents/skills/skill-meta/SKILL.md) | 所有 `SKILL.md` 的**写作元规范**——「写其它 skill 的 skill」 | 新增 / 修改 / 优化任一 `SKILL.md`，或提到「写个 skill / skill 规范 / authoring」时 |

> 随着探索推进，新的实用 skill 会陆续补充到此表。

---

## SKILL.md 写作规范（5 节范式）

每份 `SKILL.md` 必须写全以下 **5 节**，缺一不可（详见 [skill-meta](.agents/skills/skill-meta/SKILL.md)）：

| 节 | 必备内容 |
| --- | --- |
| **定时机** | 机制化触发条件（文件 glob / 用户意图 / 状态量）；标明自动 / 手动；列出**不触发**场景 |
| **立目标** | 一句话 = 主语 + 动词 + 可衡量 / 可观察的结果 |
| **理规则** | 命令式 / 代码块 / 决策表，可机械执行 |
| **给示例** | 至少 1 正 1 反，反例覆盖常见误用 |
| **划边界** | 能力上限 + 兜底策略 + 安全 / 隐私边界 + 与相邻 skill 的协作边界 |

并通过 **4 条红线**自查：**有证据 / 可观测 / 可校验 / 可复现**。

### Frontmatter 模板

```yaml
---
name: <kebab-case，与目录名一致>
description: <1-2 句中文（做什么 + 何时用）+ 一句英文 "Use when ..."；附触发关键词清单>
---
```

---

## 新增一个 Skill

1. 在 `.agents/skills/` 下新建目录，目录名用 kebab-case，例如 `my-skill/`。
2. 创建 `my-skill/SKILL.md`，套用上面的 frontmatter 模板 + 5 节范式。
3. 对照 [skill-meta](.agents/skills/skill-meta/SKILL.md) 的「反例速查表（黑名单 8 条）」逐条自查。
4. 在本 README 的「现有 Skills」表中登记一行。
5. 提交（建议用 Conventional Commits，例如 `feat(my-skill): ...`）。

> 不达标前**不写入** skill 目录；先以草稿形式观察，补全后再合入。

---

## 约定

- **提交规范**：Conventional Commits（`feat` / `fix` / `docs` / `refactor` ...）。
- **语言**：skill 内容以中文为主，frontmatter 的 `Use when ...` 用英文以便 agent loader 机械匹配。
- **安全红线**：任何 `SKILL.md` 不得包含凭据、密钥、内网链接或敏感个人信息。
