# gemini-mcp — Claude 调用 Gemini（走 Google AI Pro 订阅）

让 mini 上所有 Claude Code session 能把「Gemini 更擅长 / 更省」的活交给 Gemini。底层是 Google 官方
**Antigravity CLI（`agy`）**：Gemini CLI 自 2026-06-18 起不再服务个人和 AI Pro 用户，`agy` 是它的接班人。
额度来自 Google AI Pro 订阅（5 小时刷新 + 周上限），不按 token 计费。

## 工具（MCP 名 `gemini`，共享 HTTP：`127.0.0.1:8772/mcp`）
| 工具 | 用途 | 默认模型 |
|---|---|---|
| `gemini_ask` | 一般问答；读大文件 / 长日志 / 整个目录，只回结论 | fast |
| `gemini_media` | 图片、PDF、录音、视频（画面+声音）理解 | fast |
| `gemini_research` | 用 Google 搜索回答最新问题，附来源 | balanced |
| `gemini_second_opinion` | 独立审查方案 / 代码 / 结论，返回结构化 JSON（verdict、issues、confidence…） | strong |
| `gemini_generate_image` | 文生图（Nano Banana），存到指定路径或 `out/` | fast |
| `gemini_job_start` / `gemini_job_result` | 后台长任务 | balanced |
| `gemini_status` | agy 版本、模型别名、近 5 小时 / 7 天调用次数 | — |

模型别名：`fast` = gemini-4-hydrogen-low，`balanced` = hydrogen-medium，`strong` = gemini-4-neon-high，
`code` = gemini-4-carbon-high，`max` = neon-xhigh；也可直接填 `agy models` 里的型号。
（Gemini 3.8 Flash 和 Gemini 4 Argon 于 2026-11-30 下架，没用。）

## 设计 / 优化
- **只读**：每次调用在空的临时工作区里跑，只把指定文件软链进去；用 agy 权限规则禁止写文件、改文件、执行命令、
  浏览器、调用其他 MCP、发消息、定时任务（已实测：写入和编辑都被拦下）。联网只在 `gemini_research` 打开，
  生成图片只在 `gemini_generate_image` 打开。
- **缓存**：同样的请求（提示词 + 模型 + 文件大小/修改时间）7 天内直接返回（`~/.cache/gemini-mcp/cache.db`）；
  联网和生成不缓存。
- **限流**：最多同时 3 个 agy 进程；单次默认超时 10 分钟（后台任务 1 小时）。
- **精简回传**：只给 Claude 答案 + 模型、用时、token；`max_chars` 截断。
- **用量日志**：`~/.cache/gemini-mcp/usage.jsonl`。
- 文件路径必须是绝对路径（服务的工作目录不是调用方的）。

## 实测（2026-11-24，AI Pro）
问答约 3–5 s；图片 / PDF 约 6–8 s；录音约 4 s；视频约 6 s；联网约 12–23 s；第二意见（Neon high）约 45 s；
生成图片约 30–45 s；缓存命中 0 s。

## 运维
- 服务：launchd `com.desmond.gemini-mcp`（plist 副本在本目录），日志 `~/Library/Logs/gemini-mcp.log`。
  改代码后：`launchctl kickstart -k gui/$(id -u)/com.desmond.gemini-mcp`
- 注册：`claude mcp add --transport http -s user gemini http://127.0.0.1:8772/mcp`
- agy：`~/.local/bin/agy`（自动更新），登录凭据在系统钥匙串。掉登录时报 "authentication required"：
  在 pty 里跑 `agy`，选 Google OAuth，把打印出的链接给用户登录，把授权码粘回去（mini 没有屏幕）。
- 安装 venv：`uv venv .venv --python 3.12 && uv pip install --python .venv/bin/python -r requirements.txt`
