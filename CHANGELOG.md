# Changelog

## v1.1.0 — 2026-11-24
- `gemini_generate_image` takes `reference_images` (absolute paths): the images are exposed read-only
  to agy and passed to its image tool, so you can keep people's likeness, copy a style, or edit a
  picture. Say in the prompt how to use them. Expect ~70 s instead of ~40 s.

## v1.0.0 — 2026-11-24
First public release.
- MCP server over Antigravity CLI (`agy`) on a Google AI Pro/Ultra subscription; shared streamable-HTTP
  process for all Claude Code sessions (launchd template + `install.sh`).
- Tools: `gemini_ask`, `gemini_media` (image/PDF/audio/video), `gemini_research` (Google Search),
  `gemini_second_opinion` (structured JSON review), `gemini_generate_image`, `gemini_followup`,
  `gemini_job_start`/`gemini_job_result`, `gemini_status`.
- Read-only scratch workspaces with agy deny rules and an empty allow list; 7-day cache; concurrency
  limit; fail-fast on quota (429) and auth by watching agy's log; model-name validation; ask-first
  instructions (`GEMINI_MCP_ASK_FIRST`).
