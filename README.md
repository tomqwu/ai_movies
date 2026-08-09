# ai_movies

AI-generated short films, produced end-to-end with ComfyUI on [Comfy Cloud](https://cloud.comfy.org).

Each film lives in its own folder under `projects/`. Shared tooling lives in `scripts/`.

| Project | Status | Description |
|---|---|---|
| [magnificent-failure-five](projects/magnificent-failure-five/) | in production | 30s live-action trailer parody: five amateur superheroes, zero successes |

## How a project works

1. **Design spec** in `docs/superpowers/specs/` — creative + technical decisions.
2. **Characters** — locked "DNA" prompt blocks + reference images (generated once, reused everywhere).
3. **Prompt cards** in `prompts/` — copy-paste-ready per-shot prompts, generated from the DNA blocks by `scripts/build_prompts.py`.
4. **Workflows** in `workflows/` — importable ComfyUI JSONs (Comfy Cloud drag-and-drop).
5. **Runbook** — step-by-step generation + assembly instructions (`projects/<name>/runbook.md`).
6. **Assembly** — `scripts/assemble.sh <project-dir>` cuts keeper clips + music + narrator into the final MP4 locally with ffmpeg.

Generated media (refs, takes, audio, finals) is gitignored; every keeper is reproducible from its workflow + seed, logged in `prompts/take-log.md`.
