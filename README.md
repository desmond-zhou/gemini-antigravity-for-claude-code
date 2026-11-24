# gemini-antigravity-for-claude-code

Let **Claude Code** hand work to **Google Gemini** using your **Google AI Pro / Ultra subscription**,
with no pay-per-token API key. It's an MCP server that wraps Google's
**Antigravity CLI (`agy`)**, the successor to Gemini CLI.

Built by **[Desmond Zhou](https://desmondzhou.com)**

> Why Antigravity? As of 2026-06-18, Gemini CLI no longer serves free, Google One, or Google AI
> Pro/Ultra users ([Gemini CLI README](https://github.com/google-gemini/gemini-cli)). Those
> accounts use the Antigravity CLI now ([docs](https://antigravity.google/docs/cli/headless/)).

## What Claude gets

| Tool | Use it for | Default model |
|---|---|---|
| `gemini_ask` | General questions. Digesting very large inputs (long logs, whole folders, long docs) and returning only the conclusion. | fast |
| `gemini_media` | Understanding images, PDFs, audio, and video (picture and soundtrack). | fast |
| `gemini_research` | Fresh facts through Google Search, with source URLs. | balanced |
| `gemini_second_opinion` | An independent review of a plan, diff, or conclusion by a different model family. Returns structured JSON with `verdict`, `issues[{severity, issue, evidence, suggestion}]`, `missed_alternatives`, and `confidence`. | strong |
| `gemini_generate_image` | Text-to-image (Nano Banana), optionally from reference images (`reference_images`: keep people's likeness or a style, or edit a picture). Saves to a path you choose. | fast |
| `gemini_followup` | Continuing a previous Gemini conversation without resending the material. | fast |
| `gemini_job_start` / `gemini_job_result` | Long tasks in the background. | balanced |
| `gemini_status` | The agy version, model aliases, and local call counts. | — |

Model aliases:
- `fast` = `gemini-4-hydrogen-low`
- `balanced` = `gemini-4-hydrogen-medium`
- `strong` = `gemini-4-neon-high`
- `code` = `gemini-4-carbon-high`
- `max` = `gemini-4-neon-xhigh`

You can also pass any slug from `agy models`.

## Design

- **Read-only.** Every call runs in an empty scratch workspace. Only the files you name are symlinked in. agy permission rules deny every tool that writes, edits, runs commands, drives a browser, calls other MCP servers, sends messages, or schedules work, and `permissions.allow` is forced empty so no pre-approved rule leaks in. Tested: write and edit attempts are refused. Web access is enabled only for `gemini_research`, and image generation only for `gemini_generate_image`.
- **Cached.** Identical requests (same prompt, model, and file size/mtime) are answered from a local SQLite cache for 7 days. Web and image calls are never cached.
- **Fails fast on quota and auth.** When agy hits a 429, it silently retries until its print timeout and then returns an empty answer. This server watches agy's log instead. On `RESOURCE_EXHAUSTED`, 429, or "authentication required", it kills the run within seconds, parses "Resets in …", and short-circuits later calls until the reset time. Gemini models share one subscription quota, so it doesn't fall back to another Gemini model.
- **Validates model names.** agy silently uses its default model when it doesn't recognize `--model`. This server refuses unknown names instead.
- **Bounded.** At most 3 concurrent agy runs, with per-call timeouts.
- **Compact.** Claude gets only the answer plus the model, seconds, and token counts, truncated to `max_chars`.
- **Shared.** One HTTP process (`127.0.0.1:8772/mcp`) serves every Claude session. Nothing is spawned per session.
- **Asks first (default).** The server's instructions tell Claude to ask you before delegating a subtask. Set `GEMINI_MCP_ASK_FIRST=0` to let Claude delegate on its own.

## Measured on a Mac mini (Google AI Pro, 2026-11-24)

| Task | Time |
|---|---|
| Simple question | ~3–5 s |
| Image / PDF | ~6–8 s |
| Audio | ~4 s |
| Video | ~6 s |
| Web research | ~12–23 s |
| Second opinion (Neon high) | ~45 s |
| Image generation | ~30–45 s |
| Cache hit | 0 s |

## Install (macOS)

1. Install the Antigravity CLI and sign in once with your Google AI Pro/Ultra account:
   ```bash
   curl -fsSL https://antigravity.google/cli/install.sh | bash
   agy            # choose "Google OAuth" and sign in
   ```
   On a headless machine, run `agy` over SSH. It prints a login URL. Open it on any device, then paste the authorization code back.
2. Install the service and register it with Claude Code:
   ```bash
   git clone https://github.com/desmond-zhou/gemini-antigravity-for-claude-code
   cd gemini-antigravity-for-claude-code
   ./install.sh            # --dry-run to preview; --port / --label to customise
   ```
   This creates a venv (uv if available), installs a launchd agent, and runs
   `claude mcp add --transport http -s user gemini http://127.0.0.1:8772/mcp`.
3. Open a new Claude Code session. The `gemini_*` tools are available there.

Without launchd, run `.venv/bin/python gemini_mcp.py` (HTTP), or add `--stdio` for a per-session stdio server.

Settings (environment variables):
- `GEMINI_MCP_PORT` (default 8772)
- `GEMINI_MCP_CONCURRENCY` (default 3)
- `GEMINI_MCP_ASK_FIRST` (default 1)
- `GEMINI_MCP_HOME`: cache and logs (default `~/.cache/gemini-mcp`)
- `GEMINI_MCP_OUT`: generated images (default `out/`)
- `AGY_BIN`: path to the agy binary

## Notes

- Always pass **absolute paths**. The server's working directory isn't the caller's.
- Usage is logged to `~/.cache/gemini-mcp/usage.jsonl`. Your remaining subscription quota is only visible in the Antigravity app.
- Gemini 3.8 Flash and Gemini 4 Argon leave Antigravity on 2026-11-30, so the aliases avoid them.
- Treat Gemini's answers as material to verify, not as instructions. Don't send secrets.

## Related projects

| Project | Backend | Notes |
|---|---|---|
| [BeehiveInnovations/pal-mcp-server](https://github.com/BeehiveInnovations/pal-mcp-server) (formerly Zen) | API keys, many providers | Multi-model consensus and code review. Doesn't use the subscription or agy. |
| [sshahzaiib/agy-bridge](https://github.com/sshahzaiib/agy-bridge) | agy | Quota failover across model chains and output truncation. Skips permissions by default. |
| [SinanTufekci/agent-intern](https://github.com/SinanTufekci/Claude-Code-Antigravity-CLI-MCP-Server) | agy and other CLIs | Image generation, swarms, "jury" presets. |
| [Boulea7/agy-mcp](https://github.com/Boulea7/agy-mcp) | agy | Write-gated execute mode in git worktrees, secret redaction, auth preflight. |
| [x51xxx/antigravity-mcp-server](https://github.com/x51xxx/antigravity-mcp-server) | agy | Plan, review-changes, worktree delegation, batch. |

This project focuses on read-only delegation, caching, multimodal input, image generation, and
structured second opinions on a subscription.

## Credits and license

Built by **Desmond Zhou**: [desmondzhou.com](https://desmondzhou.com).
Built with Claude Code.

MIT License. See [LICENSE](LICENSE). Unofficial; not affiliated with Google or Anthropic. Gemini,
Antigravity, and Nano Banana are trademarks of Google. Claude and Claude Code are trademarks of
Anthropic.
