# 调教 Claude Code 的七种方法

> 来源：微信公众号文章《调教 Claude Code 的七种方法》，AGI Hunt，2026-06-19 03:00  
> 原文链接：https://mp.weixin.qq.com/s/KGWaCxSlCza9bA4g1cg-kw  
> Anthropic 官方原文：https://claude.com/blog/steering-claude-code-skills-hooks-rules-subagents-and-more

这篇文章整理了 Anthropic 关于 Claude Code 自定义机制的官方说明。核心不是提供零散 prompt 技巧，而是从架构层面说明：如何通过不同机制控制 Claude Code 的行为。

Claude Code 的行为可以通过七种方式定制：

- `CLAUDE.md`
- Rules
- Skills
- Subagents
- Hooks
- Output Styles
- `append-system-prompt`

这些方式的关键差异在于：

- 指令什么时候加载进上下文
- 长会话压缩时会不会保留
- 指令权重有多高
- token 成本是多少
- 行为是否确定性执行

## 七种方法速查

| 方法 | 成本 | 加载时机 | 压缩行为 | 适合场景 |
| --- | --- | --- | --- | --- |
| 根目录 `CLAUDE.md` | 高 | 会话开始时加载，全程保留 | 压缩后重新读取 | 构建命令、目录结构、编码规范、团队约定 |
| 子目录 `CLAUDE.md` | 低 | 读取对应子目录文件时按需加载 | 压缩后丢失，直到再次访问该子目录 | 特定子目录规范 |
| Rules | 中等 | 用户级规则会话开始加载；路径限定规则在匹配文件被访问时加载 | 压缩后重新注入 | 特定约束或规范 |
| Skills | 低 | 启动时仅加载名称和描述，调用时加载全文 | 已调用 Skills 共享预算重新注入，先进先出 | 部署检查表、发布流程、代码审查流程 |
| Subagents | 低 | 启动时加载名称和描述，通过 Agent 工具调用时加载正文 | 中间结果不进入主上下文，仅最终摘要返回 | 深度搜索、日志分析、依赖审计等隔离副任务 |
| Hooks | 低 | 生命周期事件触发时执行 | 绕过压缩，配置在主上下文之外 | 自动跑 linter、发通知、拦截命令 |
| Output Styles / System Prompt | 高或中等 | 会话开始时注入系统提示词 | 永不压缩 | 角色、语气、格式偏好 |

## CLAUDE.md

`CLAUDE.md` 是项目中的 Markdown 指令文件，适合记录 Claude Code 需要长期知道的项目事实，例如：

- 构建命令
- 目录结构
- monorepo 布局
- 编码规范
- 团队约定

它有两类加载方式。

根目录 `CLAUDE.md` 会在会话启动时加载，并在整个会话中保留。执行压缩时，Claude Code 会重新读取这些文件。

子目录 `CLAUDE.md` 会按需加载。例如 `app/api/CLAUDE.md` 只会在 Claude 读取 `app/api/` 下的文件时加载；压缩后会丢失，直到再次访问该子目录。

### 使用建议

不要让 `CLAUDE.md` 变成公共垃圾场。它的每一行都会进入每个工程师的每次会话，即使当前任务并不需要这些信息。

更合适的做法是：

- 将根目录 `CLAUDE.md` 控制在 200 行以内
- 指定 owner，像审代码一样审它的改动
- 把它当作代码库概览或索引
- 团队级路径规范放到 Rules
- 流程型内容放到 Skills
- monorepo 中给每个团队目录配置自己的子目录 `CLAUDE.md`

对于必须在组织所有仓库统一执行的安全策略或合规要求，可以通过 MDM 或配置管理工具集中部署。

## Rules

Rules 是 `.claude/rules/` 目录下的 Markdown 文件，用于给 Claude 设定特定约束或规范。

没有路径限定的 Rules 和根目录 `CLAUDE.md` 行为类似：会话启动时加载，压缩后重新注入。因此它会持续消耗上下文。

路径限定的 Rules 更适合多数工程约束。通过 `paths` 字段控制加载时机，只有当 Claude 访问匹配文件时，规则才会进入上下文。

示例：

```yaml
---
paths:
  - "src/api/**"
  - "**/*.handler.ts"
---
All API handlers must validate input with Zod before processing.
```

### 使用建议

文件级约束适合放在路径限定 Rule 中，例如：

- migration 只能追加，不能修改历史迁移
- API handler 必须做输入校验
- 特定目录必须遵循指定错误处理方式

当一条指令跨多个目录，但又不是全局适用时，路径限定 Rule 通常比子目录 `CLAUDE.md` 更合适。

## Skills

Skills 存放在 `.claude/skills/` 目录下。每个 Skill 是一个文件夹，包含 `SKILL.md`，也可以包含脚本和资源。

会话启动时，Claude 只加载 Skill 的名称和描述。完整正文只在 Skill 被调用时加载。调用方式包括：

- 斜杠命令，例如 `/code-review`
- 根据任务描述自动匹配触发

压缩时，Claude Code 会在共享预算内重新注入已调用的 Skills。如果一个会话调用了很多 Skills，最早调用的会先被丢弃。

### 使用建议

流程化指令应该放在 Skill 中，而不是放进 `CLAUDE.md`。

适合做成 Skill 的内容包括：

- 发布检查表
- 部署工作流
- 代码审查流程
- 安全审查步骤
- 文档生成流程

## Subagents

Subagents 是 `.claude/agents/` 目录下的 Markdown 文件，用于定义特定副任务的隔离助手。

每个 Subagent 文件通常包含：

- YAML frontmatter
- 名称
- 描述
- 可选模型配置
- 可选工具权限
- 作为该 Subagent 系统提示词的正文

与 Skills 类似，会话启动时只加载名称、描述和工具列表，正文不会自动加载。Claude 通过 Agent 工具调用 Subagent，并传入 prompt。

关键点是：Subagent 的正文不会进入主对话。Subagent 在自己的全新上下文窗口中运行，主会话只接收最终消息和元数据。

### 使用建议

当副任务会产生大量中间信息，且这些中间信息之后不需要继续引用时，使用 Subagent。

适合 Subagent 的任务包括：

- 深度搜索
- 日志分析
- 依赖审计
- 多文件并行调查
- 大规模代码库局部扫描

如果希望流程在主线程中展开，方便用户逐步观察和介入，则更适合使用 Skill。

## Hooks

Hooks 是在 Claude 生命周期事件上触发的用户定义处理器，可以是：

- command
- HTTP endpoint
- MCP tool
- prompt
- agent

可触发事件包括文件编辑、工具调用、会话启动等。

Hooks 可以注册在：

- `settings.json`
- 托管策略设置
- Skill 或 Agent 的 frontmatter

所有 Hooks 的触发条件都是确定性的。`command`、HTTP、`mcp_tool` 的执行也是确定性的；`prompt` 和 `agent` 类型虽然使用模型生成输出，但触发条件仍然确定。

Hooks 的上下文成本很低，因为配置或指令在主上下文窗口之外。部分 Hook 输出会进入主上下文，例如阻断型 Hook 的 stderr 会保存到上下文中，让 Claude 知道工具调用为什么被拒绝。

### 使用建议

任何应该确定性发生的事情，都应该用 Hook，而不是只写进 `CLAUDE.md`。

适合 Hook 的事情包括：

- 编辑后自动跑 linter
- 完成后发 Slack 通知
- 执行前拦截特定命令
- 备份聊天记录
- 阻止危险工具调用

如果某个动作必须发生，不要依赖模型“记得做”，应该把它做成确定性机制。

## Output Styles

Output Styles 存放在 `.claude/output-styles/` 目录下，会注入系统提示词。

它们不会被压缩，每次会话启动时都会加载，首次请求后缓存。由于处于系统提示词层级，Output Styles 的指令遵循权重很高。

修改 Output Style 会替换默认 Output Style，除非在 frontmatter 中设置：

```yaml
keep-coding-instructions: true
```

如果没有保留默认编码指令，Claude Code 可能会丢失原本的软件工程助手行为，例如：

- 如何控制改动范围
- 什么时候添加注释
- 什么时候省略解释
- 如何处理安全问题
- 完成前是否运行测试

### 使用建议

自定义 Output Style 前，应先查看内置样式。常见需求通常已经由内置样式覆盖，例如：

- Proactive
- Explanatory
- Learning

只有在确实需要改变角色、语气或输出模式时，才考虑自定义 Output Style。

## append-system-prompt

`append-system-prompt` 是命令行参数。它不会替换原始系统提示词，而是在原始系统提示词基础上追加内容。

它只对当次调用生效，不会作为文件跨会话持久化。

它适合临时加入：

- 特定编码标准
- 输出格式要求
- 领域知识
- 当前任务的额外约束

追加内容会增加输入 token。如果追加指令要求更冗长的回答，输出 token 也会增加。

### 使用建议

追加指令越多，Claude 对它们的遵循度越容易下降，尤其是指令之间存在冲突时。

因此 `append-system-prompt` 更适合一次性、短期、低冲突的补充要求。

## 实用避坑指南

### 不要在 CLAUDE.md 里写“每次 X 都做 Y”

如果某个行为应该可靠发生，例如每次编辑后跑 prettier，应该使用 Hook。

### 不要只在 CLAUDE.md 里写“绝对不要做这个”

模型指令不是安全护栏。在长会话、模糊场景、高压上下文或存在 prompt 注入时，模型仍可能违反规则。

真正的护栏应使用：

- Hooks
- Permissions
- Managed Settings

### 不要在 CLAUDE.md 里写长流程

`CLAUDE.md` 适合放 Claude 全程需要知道的事实。部署手册、安全审查清单、发布流程等长流程应该放进 Skills。

### 不要写没有路径限定的局部 Rule

如果 API 相关 Rule 没有限定路径，它就会像全局 `CLAUDE.md` 一样始终加载。

应通过 `paths` 限定适用范围。

### 不要把个人偏好写进项目级 CLAUDE.md

个人偏好应放在本地用户级文件中，不应污染团队共享配置。

## 决策表

| 需求 | 推荐机制 |
| --- | --- |
| 让 Claude 知道项目结构、构建命令、团队规范 | 根目录 `CLAUDE.md` |
| 给某个目录补充局部上下文 | 子目录 `CLAUDE.md` |
| 给某类文件设置硬约束 | 路径限定 Rules |
| 沉淀可重复流程 | Skills |
| 隔离执行大量中间分析 | Subagents |
| 确保某个动作必然发生 | Hooks |
| 临时追加一次性格式或领域要求 | `append-system-prompt` |
| 改变助手输出风格或角色 | Output Styles |

## 核心结论

不要把所有指令都塞进一个巨大的 `CLAUDE.md` 或 system prompt。

更好的做法是把 agent 指令当成工程系统来设计：

- 常驻事实放 `CLAUDE.md`
- 局部约束放 Rules
- 流程放 Skills
- 隔离副任务交给 Subagents
- 必须发生的事用 Hooks
- 输出风格谨慎放 Output Styles
- 临时补充用 `append-system-prompt`

这篇文章的真正价值在于：它把“提示词工程”推进到了“上下文工程”和“行为控制架构”。
