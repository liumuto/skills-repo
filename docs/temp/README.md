# docs/temp —— 临时文档区

只用于**临时放置**草稿、过程记录、调试笔记等未定型内容。

## 重要：不入库

本目录除了这份 `README.md`，**其余文件都被 `.gitignore` 忽略，不会进入 git 工作区**。

对应的 `.gitignore` 规则：

```gitignore
docs/temp/*
!docs/temp/README.md
```

## 放这里

- 临时草稿、思路速记、一次性分析
- 尚未决定归属的文档

## 注意

- 这里的内容**不纳入版本管理**，换机器/换人即丢失，不要把唯一副本长期留在这里。
- 文档一旦定型，**移入** `plan/` / `architecture/` / `tech/` / `guide/` 对应子区，使其入库。
