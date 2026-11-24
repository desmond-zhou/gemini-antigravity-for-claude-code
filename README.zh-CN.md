# gemini-antigravity-for-claude-code（中文说明）

让 **Claude Code** 用你的 **Google AI Pro / Ultra 订阅**调用 **Google Gemini**，不需要按 token 计费的 API key。
底层是 Google 官方的 **Antigravity CLI（`agy`）**，它是 Gemini CLI 的接班人：从 2026-06-18 起，Gemini CLI 不再
服务免费、Google One 和 AI Pro/Ultra 用户。

[English](README.md) · 作者：**[Desmond Zhou](https://desmondzhou.com)**

## 工具

| 工具 | 用途 | 默认模型 |
|---|---|---|
| `gemini_ask` | 一般问答；读大文件、长日志、整个目录，只回传结论 | fast |
| `gemini_media` | 理解图片、PDF、录音、视频（画面和声音） | fast |
| `gemini_research` | 用 Google 搜索查最新信息，附来源 | balanced |
| `gemini_second_opinion` | 用另一家的模型独立审查方案、代码、结论，返回结构化 JSON | strong |
| `gemini_generate_image` | 文生图（Nano Banana），存到指定路径 | fast |
| `gemini_followup` | 接着上一轮对话追问，不必重发材料 | fast |
| `gemini_job_start` / `gemini_job_result` | 后台长任务 | balanced |
| `gemini_status` | agy 版本、模型别名、本机调用次数 | — |

模型别名：`fast` = gemini-4-hydrogen-low，`balanced` = hydrogen-medium，`strong` = gemini-4-neon-high，
`code` = gemini-4-carbon-high，`max` = neon-xhigh；也可以直接填 `agy models` 里列出的型号。

## 设计要点

- **只读**：每次调用都在空的临时目录里跑，只放进指定的文件；写文件、改文件、执行命令、操作浏览器、调用其他 MCP、发消息、定时任务一律禁止（实测拦得住）。联网只在 `gemini_research` 里打开，生成图片只在 `gemini_generate_image` 里打开。
- **缓存**：同样的请求 7 天内直接返回，文件一改动就失效；联网和生成图片不缓存。
- **额度用完快速失败**：agy 遇到 429 会默默重试到超时、最后返回空答案。本服务盯着 agy 的日志，一发现额度用完或未登录，几秒内就停止，并记下恢复时间，恢复前的调用秒回错误。
- **模型名校验**：agy 遇到不认识的模型名会悄悄改用默认模型，本服务直接报错。
- **限流和精简回传**：最多同时 3 个调用；只回传答案、用时和 token 数。
- **整台机器共用一个服务**：一个 HTTP 进程服务所有 Claude session。
- **默认先问**：Claude 把子任务交给 Gemini 之前先问你。设 `GEMINI_MCP_ASK_FIRST=0` 可关掉。

## 安装（macOS）

```bash
curl -fsSL https://antigravity.google/cli/install.sh | bash
agy                      # 选 Google OAuth，用 AI Pro/Ultra 账号登录（无屏幕的机器：把打印出的链接在任意设备打开，再把授权码粘回来）
git clone https://github.com/desmond-zhou/gemini-antigravity-for-claude-code
cd gemini-antigravity-for-claude-code && ./install.sh      # 加 --dry-run 只预览
```

装好后新开一个 Claude Code session，就能用 `gemini_*` 工具。文件路径一律用绝对路径。

## 署名与许可

作者 **Desmond Zhou**：[desmondzhou.com](https://desmondzhou.com)。用 Claude Code 开发。MIT 许可证。
非 Google 或 Anthropic 官方项目。
