---
name: project-scaffold
description: 项目目录规范脚手架与审计器。先审计当前项目，再「仅补齐缺失」的统一规范骨架（CLAUDE.md / docs 五区 / .agents / .claude / .cursor），绝不覆盖已有文件。Use when user wants to initialize / standardize / refactor a project's directory layout, scaffold docs structure, or set up AI tool folders (.agents/.claude/.cursor) and CLAUDE.md. 触发关键词：规范目录 / 初始化项目结构 / 项目脚手架 / 建立目录规范 / 重构目录 / 补齐文档结构 / scaffold / project-scaffold。
---

# project-scaffold

把任意项目收敛到一套统一的规范骨架：`CLAUDE.md` + `docs/` 五区（plan / temp / architecture / tech / guide，每级带 README）+ 工具中立的 `.agents/`（skills 与 rules 真相源）+ 由同步脚本生成的 `.claude/{skills,rules}`、`.cursor/{skills,rules}`。

核心安全口径：**先审计、后补齐、不覆盖**。新项目=全量补齐，已有项目=增量补齐，同一条幂等路径，可反复运行。

---

## 定时机（何时触发本 skill）

- **手动 slash**：用户显式调用本 skill（如 `/project-scaffold`）。
- **关键词触发**：用户提到「规范目录 / 初始化项目结构 / 项目脚手架 / 建立目录规范 / 重构目录 / 补齐文档结构 / scaffold」。
- **不触发**：
  - 用户只是新建单个文件或普通文件夹（无「规范/初始化整套结构」意图）；
  - 用户在讨论某个具体模块的代码布局（属 v2 模块级规划，本 skill v1 不处理）；
  - 仅修改 `docs/` 下已有文档内容，未涉及结构补齐。

## 立目标

AI 在被触发时，**先输出一份「骨架审计报告」**（逐项标 ✓ 已存在 / ✗ 缺失），经用户确认后，**只创建缺失的文件夹与文件，对任何已存在文件零覆盖**，最终运行同步脚本把 `.agents/skills/` 与 `.agents/rules/` 分别镜像到 `.claude/{skills,rules}` 与 `.cursor/{skills,rules}`（rules 同步到 `.cursor/rules/` 时扩展名由 `.md` 改写为 `.mdc`）。

可观察成功标准：再次运行本 skill 时审计报告应全部为 ✓（幂等）；`git status` 中不出现对既有文件的改写（仅新增）。

---

## 理规则（按决策表机械执行）

### 标准骨架清单（v1 通用层）

```text
<project-root>/
├── CLAUDE.md                      # AI 约束（四原则，见 templates/CLAUDE.md）
├── .gitignore                     # 确保含 docs/temp 忽略规则
├── docs/
│   ├── README.md                  # docs 总览与归档边界
│   ├── plan/        README.md     # 开发计划
│   ├── temp/        README.md     # 临时文档；除 README 外不入库
│   ├── architecture/README.md     # 按模块沉淀的技术架构
│   ├── tech/        README.md + _template.md   # 技术方案 + 通用模板
│   └── guide/       README.md     # 脚本使用 / 工作流程等指南
├── .agents/
│   ├── skills/                    # ★ skills 唯一真相源
│   ├── rules/   karpathy-guidelines.md    # ★ rules 唯一真相源（*.md，带 cursor frontmatter）
│   └── sync-skills.sh             # 同步脚本（→ .claude / .cursor，覆盖 skills + rules）
├── .claude/
│   ├── skills/                    # 由 sync-skills.sh 生成，勿手改
│   └── rules/                     # 由 sync-skills.sh 生成（直接镜像 .md），勿手改
└── .cursor/
    ├── skills/                    # 由 sync-skills.sh 生成，勿手改
    └── rules/                     # 由 sync-skills.sh 生成（.md → .mdc 扩展名转换），勿手改
```

> `.agents/`、`.claude/`、`.cursor/` 各级**不放 README.md**（说明性内容统一写在 `CLAUDE.md` 与 SKILL.md，不在工具目录里重复）。docs 五区仍每级带 README。

> 模块级文件夹（src 布局、按项目类型的分层）**v1 不规划**：留待 v2 根据技术选型（package.json / pom.xml / go.mod / Cargo.toml / pyproject.toml 等）探测后确认。本 skill 命中时只处理上面这套通用层。

### 执行决策表

| 步 | 动作 | 规则 |
| --- | --- | --- |
| 1 | 定位项目根 | 取含 `.git` 的目录；找不到则 AskUserQuestion 确认根路径，**不臆测** |
| 2 | 审计 | 逐项检查清单中每个文件/夹是否存在，生成 ✓/✗ 报告 |
| 3 | 报告并确认 | 把报告展示给用户；**仅在用户确认后**写入 |
| 4 | 建目录 | 缺失的文件夹 → 创建；已存在 → 跳过 |
| 5 | 建 README/模板 | 缺失 → 用 `templates/` 对应文件创建；**已存在 → 一律跳过，绝不覆盖** |
| 6 | CLAUDE.md | 不存在 → 用 `templates/CLAUDE.md` 创建；**已存在 → 询问**是否「追加」四原则段（用 `>>`），绝不改写原内容 |
| 7 | .gitignore | 不含 `docs/temp/` 规则 → **追加** `templates/gitignore-snippet.txt` 片段；已含 → 跳过 |
| 8 | 同步 skills/rules | 拷入 `.agents/sync-skills.sh` 并运行：`.agents/skills/` → `.claude/skills/`、`.cursor/skills/`（整体镜像）；`.agents/rules/` → `.claude/rules/`（保留 `.md`）、`.cursor/rules/`（递归把 `.md` 改写为 `.mdc`，并清理孤儿 `.mdc`） |
| 9 | 复核 | 复跑审计，确认全 ✓；向用户汇报「新增 N 项 / 跳过 M 项已存在」 |

### 不变量（每次运行必须成立）

- **零覆盖**：除非用户对 CLAUDE.md 显式同意「追加」，否则不修改任何既有文件内容。
- **幂等**：连续运行两次，第二次新增数为 0。
- **temp 边界**：`docs/temp/` 除 `README.md` 外全部被 `.gitignore` 忽略。
- **真相源唯一**：skills 真内容只在 `.agents/skills/`，rules 真内容只在 `.agents/rules/`；`.claude/{skills,rules}`、`.cursor/{skills,rules}` 都是生成物，会被同步脚本整体重建，勿手改。
- **工具目录无 README**：`.agents/`、`.claude/`、`.cursor/` 各级不创建 README.md。

---

## 给示例

### 正例 1：已有项目增量补齐

用户：「给这个仓库规范一下目录」

✅ 正确流程：
1. 探测到项目根（含 `.git`）；
2. 输出审计：`docs/ ✗`、`CLAUDE.md ✓（已存在）`、`.agents/skills ✗`…
3. 用户确认后，创建 `docs/` 全套 + `.agents/`，**跳过已存在的 CLAUDE.md**（仅询问是否追加四原则段）；
4. 运行同步脚本，汇报「新增 12 项，跳过 1 项（CLAUDE.md 已存在）」。

✅ 通过：先审计后补齐、非破坏、幂等。

### 正例 2：CLAUDE.md 已存在

用户：「初始化项目结构」，但项目已有自定义 `CLAUDE.md`。

✅ 正确：**不覆盖**。提示「检测到已有 CLAUDE.md，是否在文末追加 Karpathy 四原则段？(y/N)」，用户同意才 `>>` 追加，原有内容一字不动。

### 反例 1：直接覆盖

❌ 用户说「规范目录」，AI 直接把模板 `CLAUDE.md` / `docs/README.md` 写入并覆盖了项目里已有的同名文件。

❌ 失败原因：违反「零覆盖」不变量，可能毁掉用户既有文档。正确做法是已存在即跳过。

### 反例 2：跳过审计、不确认就动手

❌ 触发后不出审计报告，直接批量创建一堆文件夹。

❌ 失败原因：用户无法预览影响面，违反「先审计、报告并确认」步骤。

### 反例 3：擅自规划模块目录

❌ 顺手在 `src/` 下按自己偏好建了一套分层目录。

❌ 失败原因：模块级布局属 v2、需按技术选型确认；v1 只做通用层。越界即误用。

---

## 划边界

- **只做通用层**：v1 仅脚手架 `CLAUDE.md / docs 五区 / .agents / .claude / .cursor`。模块级（按项目类型的源码分层）**不在范围**，命中此类请求 → 明确告知属 v2、转人工确认技术选型。
- **非破坏兜底**：任何会覆盖既有文件的操作一律降级为「跳过」或「询问后追加」；不确定项目根、不确定是否追加 → **AskUserQuestion**，不臆测。
- **rules 与 skills 走同一同步管道**：真相源 `.agents/rules/*.md`（推荐保留 Cursor 风格 frontmatter：`description / globs / alwaysApply`，Claude 也能正确读取），由 `sync-skills.sh` 镜像到 `.claude/rules/*.md`（直拷）与 `.cursor/rules/*.mdc`（扩展名转换）。本 skill 命中时若 `.agents/rules/karpathy-guidelines.md` 不存在则用 `templates/rules-karpathy.md` 铺底；不再单独维护 `.cursor/rules/`。
- **与相邻 skill 边界**：
  - 不替代 [skill-meta](../skill-meta/SKILL.md)——后者管单个 SKILL.md 的写法；本 skill 管项目级目录结构。
  - 在 `.agents/skills/` 内新增具体 skill 时，转交 skill-meta 把关质量。
- **安全红线**：模板与脚本不得含凭据、密钥、内网链接或敏感个人信息；同步脚本仅做本地文件拷贝，不联网。
