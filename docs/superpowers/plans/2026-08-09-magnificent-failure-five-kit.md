# Magnificent Failure Five — Production Kit Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build the complete production kit for the 30-second superhero trailer-parody "The Magnificent Failure Five": screenplay, character system, generated prompt cards, Comfy Cloud-importable workflow JSONs, local assembly scripts, and a guided-run runbook.

**Architecture:** Content lives in `projects/magnificent-failure-five/`; shared scripts at repo root. Character DNA blocks are single-sourced in `characters/` and compiled into copy-paste-ready per-shot prompt cards by a generator script (DRY — editing a DNA block regenerates every card). Video workflows start from official Comfy-Org templates fetched into the repo, then patched programmatically. Assembly is a tested ffmpeg bash script.

**Tech Stack:** Markdown content, ComfyUI workflow JSON (Comfy Cloud), Python 3 stdlib (no pip deps), bash + ffmpeg + jq, git.

**Spec:** `docs/superpowers/specs/2026-08-09-comfy-movie-workflow-design.md` (approved).

## Global Constraints

- Workflows may reference **only nodes available on Comfy Cloud**: ComfyUI core (incl. `MiniMaxH3ReferenceToVideo`, `MiniMaxH3ImageToVideo`, `EmptyMiniMaxH3LatentAV`, `MiniMaxH3SigmaShift`), VideoHelperSuite, KJNodes, ComfyUI-Frame-Interpolation.
- Video: 16:9, **1344×768**, 24 fps, clips 4–5 s; 7 shots totaling ~30 s (5+4+4+4+4+5+4).
- Character DNA blocks: **50–80 words each**, pasted verbatim into every generation.
- Seeds: cast refs 100–105; shot take seeds = `1000*shot_number + take_number` (sh03 take 2 → 3002).
- Keeper clips are named `sh01.mp4`…`sh07.mp4` under `assets/clips/keepers/`; raw takes `shNN_takeNN_seedNNNN.mp4` under `assets/clips/`.
- Narrator line files `n01.wav`…`n07.wav` under `assets/audio/narrator/`; music at `assets/audio/music.mp3`.
- All generated media dirs are gitignored (already configured in `.gitignore`).
- Work directly on `main`; **commit AND push at the end of every task** (user preference: always land on main).
- macOS host; scripts must run with system bash/zsh + `ffmpeg` + `jq` + `python3` (stdlib only).
- Commit messages end with `Co-Authored-By: Claude Fable 5 <noreply@anthropic.com>`.

## Execution note

Tasks 1–10 build the kit (this plan). The **guided run** (executing workflows on Comfy Cloud with the user, cherry-picking takes, generating music/VO, final assembly) is interactive and follows the runbook produced in Task 9 — it is not scripted as plan tasks.

---

### Task 1: Project scaffold + README

**Files:**
- Create: `README.md`, `projects/magnificent-failure-five/` folder tree with `.gitkeep` files

**Interfaces:**
- Produces: the directory layout every later task writes into (paths exactly as below).

- [ ] **Step 1: Create the tree**

```bash
cd /Users/tomwu/Projects/ai_movies
mkdir -p projects/magnificent-failure-five/{screenplay,characters,prompts,workflows/templates,assets/{refs,keyframes,clips/keepers,audio/narrator},output} scripts
touch projects/magnificent-failure-five/assets/{refs,keyframes,clips/keepers,audio/narrator}/.gitkeep projects/magnificent-failure-five/output/.gitkeep
```

- [ ] **Step 2: Write `README.md`**

```markdown
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
```

- [ ] **Step 3: Verify tree**

Run: `find projects scripts -type d | sort`
Expected: all directories listed above exist.

- [ ] **Step 4: Commit and push**

```bash
git add -A && git commit -m "feat: scaffold multi-project layout and README

Co-Authored-By: Claude Fable 5 <noreply@anthropic.com>" && git push
```

---

### Task 2: Character package (style block + 5 DNA blocks + cast-sheet prompts)

**Files:**
- Create: `projects/magnificent-failure-five/characters/style-block.md`
- Create: `projects/magnificent-failure-five/characters/captain-obvious.md`, `stretch.md`, `tank.md`, `flex.md`, `jitters.md`
- Create: `projects/magnificent-failure-five/characters/cast-sheet-prompts.md`

**Interfaces:**
- Produces: each character file contains exactly one ` ```prompt ` fenced block (the DNA). `build_prompts.py` (Task 4) extracts the **last** ` ```prompt ` block from each file. `style-block.md` same convention. Filenames (kebab-case) are the character IDs used in `shots.json`.

- [ ] **Step 1: Write `characters/style-block.md`**

````markdown
# Global style block

Prepended verbatim to every video prompt (NOT to cast-sheet ref stills, which use neutral studio styling so identity transfers cleanly).

```prompt
Epic live-action cinematic movie-trailer style, photorealistic, anamorphic widescreen, dramatic golden-hour rim lighting with volumetric haze and lens flares, desaturated teal-and-orange color grade, shallow depth of field, subtle 35mm film grain, modern city setting.
```
````

- [ ] **Step 2: Write the five character files**

`characters/captain-obvious.md`:

````markdown
# CAPTAIN OBVIOUS — the leader (royal blue)

Signature: blue thrift-store armor, plastic chest plate, unearned confidence. Silhouette: average.

```prompt
CAPTAIN OBVIOUS: a 35-year-old man, average height and build, square overconfident jaw, short brown hair, thick eyebrows. Wears a royal-blue spandex suit with a scuffed white plastic chest plate strapped on with silver duct tape, a blue cape, yellow rubber dish gloves, and black winter boots. A hand-drawn letter C is marker-scrawled on the chest plate. Stands chin raised, fists on hips, radiating unearned confidence.
```
````

`characters/stretch.md`:

````markdown
# STRETCH — the tall one (crimson red)

Signature: cape two sizes too long (load-bearing trip hazard). Silhouette: very tall, lanky.

```prompt
STRETCH: a 28-year-old man, extremely tall and lanky, long thin limbs, narrow face, prominent Adam's apple, messy black hair. Wears a wrinkled crimson-red spandex suit one size too small with his ankles exposed, and a huge red satin cape two sizes too long that drags on the ground and tangles around his feet. White sneakers and a red sweatband on his forehead.
```
````

`characters/tank.md`:

````markdown
# TANK — the sturdy one (bright yellow)

Signature: colander helmet, towel cape. Silhouette: short, stocky, barrel-chested.

```prompt
TANK: a 40-year-old man, short and stocky, barrel chest, thick neck, ruddy cheeks, bushy ginger beard. Wears a bright-yellow spandex suit stretched over his round belly, a steel kitchen colander strapped to his head as a helmet with a leather chin strap, brown work gloves, a yellow bath towel tied as a cape, and steel-toe work boots.
```
````

`characters/flex.md`:

````markdown
# FLEX — the muscle (forest green)

Signature: tiny domino mask on a huge frame. Silhouette: enormous bodybuilder.

```prompt
FLEX: a 32-year-old man with an enormous bodybuilder physique, massive shoulders, bulging arms, shaved head, heavy jaw. Wears a stretched forest-green tank top with the word FLEX in crooked iron-on letters, green compression shorts over white gym leggings, a comically tiny black domino mask that barely covers his eyes, and white athletic tape on his wrists and knuckles.
```
````

`characters/jitters.md`:

````markdown
# JITTERS — the nervous one (purple)

Signature: hood up, oversized ski goggles, paper lightning bolt. Silhouette: skinny, hunched.

```prompt
JITTERS: a 24-year-old man, very skinny with a hunched anxious posture, pale face, wide darting eyes, curly blond hair sticking out in tufts. Wears a purple zip-up hoodie with the hood up, oversized silver ski goggles pushed onto his forehead, purple sweatpants tucked into mismatched socks, fingerless gloves, and a small backpack with a taped-on paper lightning bolt.
```
````

- [ ] **Step 3: Write `characters/cast-sheet-prompts.md`**

````markdown
# Cast-sheet prompts (wf1_cast_sheet.json)

Reference stills use NEUTRAL studio styling (identity transfers; scene style comes from the video prompt). Run wf1 once per row: paste the prompt, set the seed and resolution, queue.

**Individual refs** — resolution **832×1216** (portrait), seeds below, save as `assets/refs/<id>.png`:

| id | seed | prompt |
|---|---|---|
| captain-obvious | 101 | Full-body studio character reference photo, head-to-toe visible, standing facing camera, neutral pose, plain dark gray seamless backdrop, even soft lighting, photorealistic. <paste captain-obvious DNA block> |
| stretch | 102 | (same framing text) <paste stretch DNA block> |
| tank | 103 | (same framing text) <paste tank DNA block> |
| flex | 104 | (same framing text) <paste flex DNA block> |
| jitters | 105 | (same framing text) <paste jitters DNA block> |

**Group shot** — resolution **1344×768**, seed **100**, save as `assets/refs/group.png`:

> Full-body studio group photo of five costumed amateur superheroes standing side by side by height, all head-to-toe visible, facing camera, plain dark gray seamless backdrop, even soft lighting, photorealistic. Left to right: <paste all five DNA blocks in order stretch, flex, captain-obvious, jitters, tank>

**Acceptance (cast gate):** five clearly distinct silhouettes and costume colors; costumes readable at thumbnail size; no blended faces. Review together before ANY video credits are spent.
````

- [ ] **Step 4: Validate DNA word counts (50–80 words)**

```bash
cd projects/magnificent-failure-five/characters
for f in captain-obvious stretch tank flex jitters; do
  n=$(awk '/^```prompt$/{flag=1;next}/^```$/{flag=0}flag' "$f.md" | wc -w | tr -d ' ')
  echo "$f: $n words"
done
```

Expected: every count between 50 and 80. If any is outside the range, edit that DNA block (trim adjectives or add costume detail) until it passes.

- [ ] **Step 5: Commit and push**

```bash
git add projects/magnificent-failure-five/characters && git commit -m "feat(mf5): character system — style block, 5 DNA blocks, cast-sheet prompts

Co-Authored-By: Claude Fable 5 <noreply@anthropic.com>" && git push
```

---

### Task 3: Screenplay package

**Files:**
- Create: `projects/magnificent-failure-five/screenplay/screenplay.md`
- Create: `projects/magnificent-failure-five/screenplay/shotlist.md`
- Create: `projects/magnificent-failure-five/screenplay/narrator.md`

**Interfaces:**
- Consumes: character names from Task 2.
- Produces: shot IDs `sh01`–`sh07` with lengths 5,4,4,4,4,5,4 — the authoritative creative reference the shots.json (Task 4) must match.

- [ ] **Step 1: Write `screenplay/screenplay.md`**

```markdown
# THE MAGNIFICENT FAILURE FIVE
### a 30-second trailer for a movie that should not exist

FADE IN FROM BLACK. Epic orchestral swell.

**EXT. CITY PLAZA — GOLDEN HOUR (SLOW MOTION)** — sh01, 5s
Smoke drifts. FIVE COSTUMED HEROES walk abreast toward camera, capes billowing:
CAPTAIN OBVIOUS (blue, plastic chest plate), STRETCH (red, cape far too long),
TANK (yellow, colander helmet), FLEX (green, tiny mask), JITTERS (purple, hood up).
> NARRATOR (V.O.): In a world…
STRETCH steps on his own cape and takes TANK down with him. The others keep striding, oblivious.

**EXT. ROOFTOP — GOLDEN HOUR** — sh02, 4s
CAPTAIN OBVIOUS drops into frame, nails a three-point superhero landing — on an AC unit,
which crumples and swallows him whole.
> NARRATOR (V.O.): …that cried out for heroes…

**EXT. BRICK ALLEY — DUSK** — sh03, 4s
JITTERS sprints at a wall for a heroic wall-run. Two steps up. Stalls. Slides down
flat against the bricks, palms squeaking all the way to the pavement.
> NARRATOR (V.O.): …destiny answered.

**EXT. SUBURBAN OAK TREE — DAY** — sh04, 4s
TANK inches along a branch toward a supremely calm TABBY CAT. The branch snaps.
TANK crashes through the foliage. The cat steps off, lands gracefully — on his chest.
> NARRATOR (V.O.): Five men. One mission.

**EXT. BETWEEN ROOFTOPS — DUSK** — sh05, 4s
FLEX swings on a grappling rope in a majestic arc… and pendulums face-first into a
billboard. He sticks for a beat, then slides down slowly.
> NARRATOR (V.O.): No fear.

**EXT. GLASS STOREFRONT — NIGHT** — sh06, 5s
All five charge the entrance, battle cries, shoulder to shoulder. The automatic door
does not open. Five-man pileup against the glass. The door wobbles. Then opens.
> NARRATOR (V.O.): No limits.

**EXT. CITY PLAZA — NIGHT, SMOKE** — sh07, 4s
The five hold a dramatic tiered team pose. STRETCH wobbles first. Domino collapse
into a groaning heap. TITLE SLAMS over the wreckage:
> **COMING SOON.** *unfortunately.*

SMASH TO BLACK.
```

- [ ] **Step 2: Write `screenplay/shotlist.md`**

```markdown
# Shot list

Total: 30 s. Workflow: wf2 (R2V) default; wf3a+wf3b keyframe fallback per retry policy (3 failed takes → fix the input, not the seed).

| id | len | framing | characters | setup | payoff | seed base |
|---|---|---|---|---|---|---|
| sh01 | 5s | wide, low-angle dolly back, slow-mo | all five | epic group walk through smoke | Stretch trips on cape, takes Tank down | 1000 |
| sh02 | 4s | high-angle crane, push-in | captain-obvious | heroic three-point rooftop landing | AC unit crumples, swallows him | 2000 |
| sh03 | 4s | side tracking shot | jitters | sprint into wall-run | stalls, squeaky slide to pavement | 3000 |
| sh04 | 4s | medium, slight low angle | tank | branch-crawl toward calm cat | branch snaps; cat lands on his chest | 4000 |
| sh05 | 4s | wide between rooftops | flex | grappling-hook swing, cape flying | pendulums flat into billboard, slides down | 5000 |
| sh06 | 5s | steadicam front view | all five | full-team charge, battle cries | automatic door doesn't open; glass pileup | 6000 |
| sh07 | 4s | slow push-in through smoke | all five | tiered team title pose | domino collapse; title card overlays in post | 7000 |

Framing discipline (consistency research): full-five shots are wide (faces small); solo shots carry the close-up identity load. Title text is added in post (`assemble.sh` drawtext) — never ask the video model to render text.
```

- [ ] **Step 3: Write `screenplay/narrator.md`**

```markdown
# Narrator VO

Voice: classic deep American movie-trailer narrator. Delivery: absolute sincerity — the comedy is in the picture, never in the read. Generate one file per line (ElevenLabs free tier is sufficient; ~0.8–1.5 s each). Settings that work: stability ~35–40%, similarity ~75%, slight style exaggeration.

| file | line | plays over |
|---|---|---|
| n01.wav | "In a world…" | sh01 |
| n02.wav | "…that cried out for heroes…" | sh02 |
| n03.wav | "…destiny answered." | sh03 |
| n04.wav | "Five men. One mission." | sh04 |
| n05.wav | "No fear." | sh05 |
| n06.wav | "No limits." | sh06 |
| n07.wav | "Coming soon. Unfortunately." | sh07 (title) |

Save to `assets/audio/narrator/`. Each line starts ~0.3 s after its shot begins (assemble.sh handles timing automatically).

# Music

One continuous 30 s epic trailer cue → `assets/audio/music.mp3`. Suno/Udio if available, else local ACE-Step (free). Prompt:

> Epic cinematic trailer orchestra, 30 seconds, slow build with braams and taiko hits, heroic brass theme that keeps almost resolving, big final stinger around 26 seconds, no vocals.
```

- [ ] **Step 4: Validate shot lengths sum to 30**

```bash
awk -F'|' '/^\| sh0/{gsub(/[^0-9]/,"",$3); s+=$3} END{print s}' projects/magnificent-failure-five/screenplay/shotlist.md
```

Expected output: `30`

- [ ] **Step 5: Commit and push**

```bash
git add projects/magnificent-failure-five/screenplay && git commit -m "feat(mf5): screenplay, shot list, narrator/music package

Co-Authored-By: Claude Fable 5 <noreply@anthropic.com>" && git push
```

---

### Task 4: Prompt-card generator + generated cards + take log

**Files:**
- Create: `scripts/build_prompts.py`
- Create: `projects/magnificent-failure-five/prompts/shots.json`
- Create: `projects/magnificent-failure-five/prompts/take-log.md`
- Generated: `projects/magnificent-failure-five/prompts/sh01.md` … `sh07.md` (committed; regenerated whenever DNA/shots change)

**Interfaces:**
- Consumes: ` ```prompt ` blocks from `characters/*.md` (Task 2).
- Produces: `sh0N.md` cards whose "Copy-paste prompt" section is the final assembled generation prompt. `build_prompts.py <project-dir>` is re-runnable and idempotent.

- [ ] **Step 1: Write `prompts/shots.json`**

```json
{
  "style": "style-block",
  "shots": [
    {"id": "sh01", "title": "Group walk & trip", "len": 5, "framing": "wide, low-angle dolly back, slow motion",
     "chars": ["captain-obvious", "stretch", "tank", "flex", "jitters"], "seed_base": 1000,
     "motion": "Slow-motion low-angle dolly back: five costumed heroes walk abreast through drifting smoke, capes billowing, confident stride; the tall red hero trips on his own dragging cape and stumbles sideways into the short yellow hero, both lurching out of formation while the other three keep striding, oblivious.",
     "audio": "epic orchestral swell, slow-motion whoosh, a stumble thud, muffled yelp",
     "narrator": "In a world…"},
    {"id": "sh02", "title": "Superhero landing fail", "len": 4, "framing": "high-angle crane, push-in",
     "chars": ["captain-obvious"], "seed_base": 2000,
     "motion": "High-angle crane shot pushing in: the blue-armored hero drops onto a rooftop AC unit in a three-point superhero landing; the sheet-metal unit crumples and collapses under him and he flails as he sinks into it, dust bursting outward.",
     "audio": "dramatic bass hit, sheet metal crumpling, clattering, a startled grunt",
     "narrator": "…that cried out for heroes…"},
    {"id": "sh03", "title": "Wall-run slide", "len": 4, "framing": "side tracking shot",
     "chars": ["jitters"], "seed_base": 3000,
     "motion": "Side tracking shot in a narrow brick alley at dusk: the purple-hoodied skinny hero sprints at the wall, takes two running steps up the bricks, stalls mid-stride, and slowly slides down flat against the wall to the pavement, palms dragging.",
     "audio": "running footsteps, long sneaker squeak against brick, soft body flop, pigeons flapping",
     "narrator": "…destiny answered."},
    {"id": "sh04", "title": "Cat rescue backfire", "len": 4, "framing": "medium, slight low angle",
     "chars": ["tank"], "seed_base": 4000,
     "motion": "Medium shot up into an oak tree: the stocky yellow hero in a colander helmet inches along a branch reaching toward a calm tabby cat; the branch cracks and snaps, he crashes down through foliage onto the grass, and the cat hops down gracefully onto his chest.",
     "audio": "creaking wood, a sharp crack, rustling leaves, heavy thump, soft meow",
     "narrator": "Five men. One mission."},
    {"id": "sh05", "title": "Billboard swing", "len": 4, "framing": "wide between rooftops",
     "chars": ["flex"], "seed_base": 5000,
     "motion": "Wide shot between rooftops at dusk: the huge green-clad bodybuilder hero swings across on a grappling rope in a heroic arc, then pendulums straight into a large billboard, smacking flat against it and sliding down slowly out of frame.",
     "audio": "rope whoosh, rushing wind, a loud hollow boom on impact, slow squeak of sliding",
     "narrator": "No fear."},
    {"id": "sh06", "title": "Glass door pileup", "len": 5, "framing": "steadicam front view",
     "chars": ["captain-obvious", "stretch", "tank", "flex", "jitters"], "seed_base": 6000,
     "motion": "Steadicam front view at night: all five heroes charge shoulder-to-shoulder toward a glass storefront, screaming battle cries; the automatic sliding door fails to open and they pile into the glass one after another, squashed faces and capes, the door wobbling.",
     "audio": "battle cries, pounding footsteps, repeated dull thumps on glass, overlapping groans",
     "narrator": "No limits."},
    {"id": "sh07", "title": "Title pose collapse", "len": 4, "framing": "slow push-in through smoke",
     "chars": ["captain-obvious", "stretch", "tank", "flex", "jitters"], "seed_base": 7000,
     "motion": "Slow push-in through swirling smoke at night: the five heroes hold a dramatic tiered team pose; the tall red hero wobbles first and they collapse onto each other in a domino chain, ending in a groaning heap as the smoke drifts across.",
     "audio": "final orchestral stinger, a wobble, cascading thuds, a weak group groan",
     "narrator": "Coming soon. Unfortunately."}
  ]
}
```

- [ ] **Step 2: Write `scripts/build_prompts.py`**

```python
#!/usr/bin/env python3
"""Assemble per-shot prompt cards from character DNA blocks + shots.json.

Usage: python3 scripts/build_prompts.py projects/magnificent-failure-five

Reads  <proj>/characters/*.md   (last ```prompt fenced block per file)
       <proj>/prompts/shots.json
Writes <proj>/prompts/<shot_id>.md  (overwrites; cards are generated artifacts)
"""
import json
import pathlib
import re
import sys

FENCE = re.compile(r"```prompt\n(.*?)```", re.S)


def load_block(path: pathlib.Path) -> str:
    blocks = FENCE.findall(path.read_text())
    if not blocks:
        sys.exit(f"error: no ```prompt block in {path}")
    return blocks[-1].strip()


def main() -> None:
    proj = pathlib.Path(sys.argv[1])
    chars_dir = proj / "characters"
    data = json.loads((proj / "prompts" / "shots.json").read_text())
    style = load_block(chars_dir / f"{data['style']}.md")

    total = sum(s["len"] for s in data["shots"])
    if not 28 <= total <= 32:
        sys.exit(f"error: shot lengths sum to {total}s, expected ~30s")

    for shot in data["shots"]:
        dna = [load_block(chars_dir / f"{c}.md") for c in shot["chars"]]
        refs = "all five" if len(shot["chars"]) == 5 else ", ".join(shot["chars"])
        card = f"""# {shot['id']} — {shot['title']} ({shot['len']}s, {shot['framing']})

> GENERATED by scripts/build_prompts.py — edit characters/*.md or prompts/shots.json, not this file.

**Workflow:** `wf2_shot_r2v.json` · **refs:** {refs} · **length:** {shot['len']}s
**Seed:** take N → {shot['seed_base']} + N (log every take in `take-log.md`)
**Narrator (post):** {shot['narrator']}
**Fallback:** 3 failed takes → `wf3a_keyframe.json` + `wf3b_i2v.json` (fix the input, not the seed)

## Copy-paste prompt

{style}

Characters:
{chr(10).join(f'- {d}' for d in dna)}

Action: {shot['motion']}

Audio: {shot['audio']}
"""
        (proj / "prompts" / f"{shot['id']}.md").write_text(card)
        print(f"wrote prompts/{shot['id']}.md ({len(shot['chars'])} chars)")


if __name__ == "__main__":
    main()
```

- [ ] **Step 3: Run the generator and verify failure-then-success behavior**

First verify it fails loudly on a missing block: temporarily run against a bogus project dir.

```bash
python3 scripts/build_prompts.py /tmp/nonexistent 2>&1; echo "exit: $?"
```

Expected: a Python error/exit (no silent success). Then run for real:

```bash
python3 scripts/build_prompts.py projects/magnificent-failure-five
```

Expected: `wrote prompts/sh01.md (5 chars)` … `wrote prompts/sh07.md (5 chars)` — seven lines.

- [ ] **Step 4: Validate generated cards**

```bash
p=projects/magnificent-failure-five/prompts
grep -L "CAPTAIN OBVIOUS" $p/sh01.md $p/sh06.md $p/sh07.md   # expect no output (all contain him)
grep -c "STRETCH" $p/sh01.md                                  # expect >= 1
for f in $p/sh0*.md; do
  n=$(sed -n 's/^Action: //p' "$f" | wc -w | tr -d ' ')
  echo "$f motion: $n words"
done
```

Expected: no file listed by `grep -L`; every motion prompt 25–55 words.

- [ ] **Step 5: Write `prompts/take-log.md`**

```markdown
# Take log

Hand-edited during the guided run. Every take gets a row the moment it's queued; mark the keeper.

| shot | take | seed | workflow | verdict | notes |
|---|---|---|---|---|---|
| sh01 | 1 | 1001 | wf2 | — | |
```

- [ ] **Step 6: Commit and push**

```bash
git add scripts/build_prompts.py projects/magnificent-failure-five/prompts && git commit -m "feat(mf5): prompt-card generator, shots.json, generated cards, take log

Co-Authored-By: Claude Fable 5 <noreply@anthropic.com>" && git push
```

---

### Task 5: Fetch official workflow templates

**Files:**
- Create: `projects/magnificent-failure-five/workflows/templates/` — official Comfy-Org template JSONs (H3 r2v + i2v, FLUX, Qwen-Image-Edit) + `SOURCES.md`

**Interfaces:**
- Produces: pristine upstream templates that Tasks 6–8 copy and patch. Never edited in place.

- [ ] **Step 1: Discover exact template filenames**

```bash
curl -fsSL "https://api.github.com/repos/Comfy-Org/workflow_templates/contents/templates" \
  | jq -r '.[].name' | grep -iE 'minimax|flux|qwen' | grep -v '\.webp'
```

Expected: names like `video_minimax_h3_t2v.json`, `video_minimax_h3_i2v.json`, `video_minimax_h3_r2v.json`, a FLUX text-to-image template (e.g. `image_flux_dev*.json` or newer flux2), and Qwen image-edit templates. If the API rate-limits, browse https://github.com/Comfy-Org/workflow_templates/tree/main/templates instead.

- [ ] **Step 2: Download the four needed templates**

```bash
T=projects/magnificent-failure-five/workflows/templates
base=https://raw.githubusercontent.com/Comfy-Org/workflow_templates/main/templates
curl -fsSL "$base/video_minimax_h3_r2v.json" -o "$T/video_minimax_h3_r2v.json"
curl -fsSL "$base/video_minimax_h3_i2v.json" -o "$T/video_minimax_h3_i2v.json"
# substitute the exact FLUX + Qwen edit filenames found in Step 1:
curl -fsSL "$base/<flux_t2i_template>.json" -o "$T/flux_t2i.json"
curl -fsSL "$base/<qwen_image_edit_template>.json" -o "$T/qwen_image_edit.json"
```

(The `<...>` substitutions are resolved from Step 1's real listing at execution time — record the exact URLs used in `SOURCES.md`.)

- [ ] **Step 3: Validate and inspect**

```bash
for f in projects/magnificent-failure-five/workflows/templates/*.json; do
  jq empty "$f" && echo "OK $f"
done
jq -r '.nodes[] | "\(.id)\t\(.type)"' projects/magnificent-failure-five/workflows/templates/video_minimax_h3_r2v.json
```

Expected: `OK` for every file; the R2V node list includes `MiniMaxH3ReferenceToVideo` (or the actual H3 node types shipped — record what they are). Write `SOURCES.md` listing each file's upstream URL and fetch date.

- [ ] **Step 4: Commit and push**

```bash
git add projects/magnificent-failure-five/workflows/templates && git commit -m "feat(mf5): vendor official Comfy-Org workflow templates (H3 r2v/i2v, FLUX, Qwen edit)

Co-Authored-By: Claude Fable 5 <noreply@anthropic.com>" && git push
```

---

### Task 6: `wf2_shot_r2v.json` — the workhorse shot workflow

**Files:**
- Create: `scripts/patch_workflow.py`
- Create: `projects/magnificent-failure-five/workflows/wf2_shot_r2v.json`
- Create: `projects/magnificent-failure-five/workflows/README.md`

**Interfaces:**
- Consumes: `templates/video_minimax_h3_r2v.json` (Task 5).
- Produces: `patch_workflow.py IN OUT NODE_TYPE INDEX VALUE [NODE_TYPE INDEX VALUE ...]` — sets `widgets_values[INDEX]` on every node of `NODE_TYPE`; used again by Tasks 7–8. `wf2_shot_r2v.json` importable on Comfy Cloud: 1344×768, 5 s, audio on.

- [ ] **Step 1: Write `scripts/patch_workflow.py`**

```python
#!/usr/bin/env python3
"""Patch widget values in a ComfyUI workflow JSON (UI export format).

Usage: patch_workflow.py IN OUT NODE_TYPE INDEX VALUE [NODE_TYPE INDEX VALUE ...]
VALUE is parsed as JSON when possible (numbers/bools), else kept as string.
"""
import json
import pathlib
import sys


def parse(v: str):
    try:
        return json.loads(v)
    except ValueError:
        return v


def main() -> None:
    src, dst = pathlib.Path(sys.argv[1]), pathlib.Path(sys.argv[2])
    wf = json.loads(src.read_text())
    patches = sys.argv[3:]
    assert patches and len(patches) % 3 == 0, "patches come in NODE_TYPE INDEX VALUE triples"
    for i in range(0, len(patches), 3):
        ntype, idx, val = patches[i], int(patches[i + 1]), parse(patches[i + 2])
        hits = [n for n in wf["nodes"] if n.get("type") == ntype]
        if not hits:
            sys.exit(f"error: no node of type {ntype} in {src}")
        for n in hits:
            n["widgets_values"][idx] = val
            print(f"node {n['id']} ({ntype}): widgets_values[{idx}] = {val!r}")
    dst.write_text(json.dumps(wf, indent=2))
    print(f"wrote {dst}")


if __name__ == "__main__":
    main()
```

- [ ] **Step 2: Identify the H3 latent/size widgets in the template**

```bash
jq -r '.nodes[] | select(.type|test("MiniMaxH3|EmptyMiniMax")) | {id, type, widgets_values}' \
  projects/magnificent-failure-five/workflows/templates/video_minimax_h3_r2v.json
```

Identify by value signature: the node carrying width/height (e.g. defaults like 1280/720) and the duration/frames widget (e.g. 5, or 121 @ 24 fps). Record the node type + indices found — they are the arguments for Step 3.

- [ ] **Step 3: Patch to 1344×768, 5 s**

```bash
python3 scripts/patch_workflow.py \
  projects/magnificent-failure-five/workflows/templates/video_minimax_h3_r2v.json \
  projects/magnificent-failure-five/workflows/wf2_shot_r2v.json \
  <LATENT_NODE_TYPE> <WIDTH_IDX> 1344 \
  <LATENT_NODE_TYPE> <HEIGHT_IDX> 768 \
  <LATENT_NODE_TYPE> <DURATION_IDX> <5-or-121-per-template-unit>
```

(Arguments filled from Step 2's inspection. If the template already defaults to the target values, copy it unchanged: `cp templates/video_minimax_h3_r2v.json wf2_shot_r2v.json`.)

- [ ] **Step 4: Verify the patched workflow**

```bash
W=projects/magnificent-failure-five/workflows/wf2_shot_r2v.json
jq empty "$W" && echo "valid JSON"
jq -r '.nodes[] | select(.widgets_values != null) | select((.widgets_values|tostring)|test("1344")) | .type' "$W"
jq -r '[.nodes[].type] | unique | .[]' "$W"
```

Expected: valid JSON; at least one node carries 1344; node-type list contains only core/H3/VHS/KJNodes/Frame-Interpolation types (Global Constraints). Any unexpected type = stop and re-check against https://comfy.org/cloud/supported-nodes/.

- [ ] **Step 5: Write `workflows/README.md`**

```markdown
# Workflows (Comfy Cloud-importable)

Drag any JSON into cloud.comfy.org to import. All node types are on the Comfy Cloud allowlist.

| file | purpose | key settings |
|---|---|---|
| wf1_cast_sheet.json | character reference stills (FLUX) | seed + resolution per cast-sheet-prompts.md |
| wf2_shot_r2v.json | per-shot video: H3 Reference-to-Video | 1344×768, 5 s, native audio; load 5 refs from assets/refs/; paste prompt from prompts/shNN.md; seed from take-log convention |
| wf3a_keyframe.json | fallback stage 1: Qwen-Image-Edit keyframe from refs | 1344×768 out |
| wf3b_i2v.json | fallback stage 2: H3 Image-to-Video from keyframe | 1344×768, shot length |
| templates/ | pristine upstream templates (never edit) | see SOURCES.md |

Reference-image count: if the template ships fewer image inputs than 5, duplicate the LoadImage node in the Comfy Cloud editor and connect it to the reference input chain (H3 R2V accepts up to 9) — takes ~30 s in the editor; the runbook covers it.

Shots shorter than 5 s (sh02–sh05, sh07 are 4 s): set the duration widget to 4 before queueing, per the shot's prompt card.
```

- [ ] **Step 6: Commit and push**

```bash
git add scripts/patch_workflow.py projects/magnificent-failure-five/workflows && git commit -m "feat(mf5): wf2 shot R2V workflow + patch tool + workflows README

Co-Authored-By: Claude Fable 5 <noreply@anthropic.com>" && git push
```

---

### Task 7: `wf1_cast_sheet.json` — character stills

**Files:**
- Create: `projects/magnificent-failure-five/workflows/wf1_cast_sheet.json`

**Interfaces:**
- Consumes: `templates/flux_t2i.json` (Task 5), `patch_workflow.py` (Task 6).
- Produces: importable stills workflow; prompt/seed/resolution are set per run from `characters/cast-sheet-prompts.md`.

- [ ] **Step 1: Inspect the FLUX template's size + seed widgets**

```bash
jq -r '.nodes[] | {id, type, widgets_values}' \
  projects/magnificent-failure-five/workflows/templates/flux_t2i.json
```

Locate the empty-latent node (width/height) and sampler seed widget.

- [ ] **Step 2: Patch defaults to the individual-ref preset (832×1216, seed 101)**

```bash
python3 scripts/patch_workflow.py \
  projects/magnificent-failure-five/workflows/templates/flux_t2i.json \
  projects/magnificent-failure-five/workflows/wf1_cast_sheet.json \
  <LATENT_NODE_TYPE> <WIDTH_IDX> 832 \
  <LATENT_NODE_TYPE> <HEIGHT_IDX> 1216
```

(Group-shot runs switch to 1344×768 in the editor per cast-sheet-prompts.md. Seed is set per character in the editor — fixed seeds 100–105.)

- [ ] **Step 3: Validate**

```bash
W=projects/magnificent-failure-five/workflows/wf1_cast_sheet.json
jq empty "$W" && jq -r '[.nodes[].type] | unique | .[]' "$W"
```

Expected: valid JSON; only core FLUX/sampler/loader node types.

- [ ] **Step 4: Commit and push**

```bash
git add projects/magnificent-failure-five/workflows/wf1_cast_sheet.json && git commit -m "feat(mf5): wf1 cast-sheet stills workflow

Co-Authored-By: Claude Fable 5 <noreply@anthropic.com>" && git push
```

---

### Task 8: `wf3a_keyframe.json` + `wf3b_i2v.json` — the fallback pair

**Files:**
- Create: `projects/magnificent-failure-five/workflows/wf3a_keyframe.json`
- Create: `projects/magnificent-failure-five/workflows/wf3b_i2v.json`

**Interfaces:**
- Consumes: `templates/qwen_image_edit.json`, `templates/video_minimax_h3_i2v.json`, `patch_workflow.py`.
- Produces: two-stage fallback. Split into two files deliberately (spec §4.1 "fallback pair"): the keyframe is reviewed (cast-gate style) before video credits are spent.

- [ ] **Step 1: Build wf3a from the Qwen edit template**

```bash
jq -r '.nodes[] | {id, type, widgets_values}' \
  projects/magnificent-failure-five/workflows/templates/qwen_image_edit.json
python3 scripts/patch_workflow.py \
  projects/magnificent-failure-five/workflows/templates/qwen_image_edit.json \
  projects/magnificent-failure-five/workflows/wf3a_keyframe.json \
  <LATENT_OR_RESIZE_NODE_TYPE> <WIDTH_IDX> 1344 \
  <LATENT_OR_RESIZE_NODE_TYPE> <HEIGHT_IDX> 768
```

(If the Qwen edit template derives output size from the input image rather than a widget, copy unchanged and note in workflows/README.md that the reference input must be resized to 1344×768 — KJNodes Resize is on the allowlist.)

- [ ] **Step 2: Build wf3b from the H3 I2V template**

```bash
python3 scripts/patch_workflow.py \
  projects/magnificent-failure-five/workflows/templates/video_minimax_h3_i2v.json \
  projects/magnificent-failure-five/workflows/wf3b_i2v.json \
  <LATENT_NODE_TYPE> <WIDTH_IDX> 1344 \
  <LATENT_NODE_TYPE> <HEIGHT_IDX> 768 \
  <LATENT_NODE_TYPE> <DURATION_IDX> <5-or-121-per-template-unit>
```

- [ ] **Step 3: Validate both**

```bash
for W in projects/magnificent-failure-five/workflows/wf3a_keyframe.json projects/magnificent-failure-five/workflows/wf3b_i2v.json; do
  jq empty "$W" && echo "OK $W" && jq -r '[.nodes[].type] | unique | .[]' "$W"
done
```

Expected: both valid; only allowlisted node types.

- [ ] **Step 4: Commit and push**

```bash
git add projects/magnificent-failure-five/workflows/wf3a_keyframe.json projects/magnificent-failure-five/workflows/wf3b_i2v.json && git commit -m "feat(mf5): wf3 keyframe+I2V fallback pair

Co-Authored-By: Claude Fable 5 <noreply@anthropic.com>" && git push
```

---

### Task 9: `assemble.sh` + `test_assemble.sh` — local assembly with a real test

**Files:**
- Create: `scripts/assemble.sh`
- Create: `scripts/test_assemble.sh`

**Interfaces:**
- Consumes: keeper/audio naming conventions (Global Constraints).
- Produces: `scripts/assemble.sh <project-dir>` → `<project-dir>/output/final_1080p.mp4` (1920×1080, 24 fps, ~30 s, mixed audio, title overlay).

- [ ] **Step 1: Check ffmpeg availability**

Run: `which ffmpeg ffprobe jq || brew install ffmpeg jq`
Expected: paths for ffmpeg + ffprobe + jq.

- [ ] **Step 2: Write the test first — `scripts/test_assemble.sh`**

```bash
#!/usr/bin/env bash
# Synthetic end-to-end test for assemble.sh: builds fake keepers/audio, asserts output.
set -euo pipefail
cd "$(dirname "$0")/.."

PROJ="$(mktemp -d)/proj"
mkdir -p "$PROJ/assets/clips/keepers" "$PROJ/assets/audio/narrator"

lens=(5 4 4 4 4 5 4)
for i in 1 2 3 4 5 6 7; do
  d=${lens[$((i - 1))]}
  ffmpeg -y -v error -f lavfi -i "testsrc2=duration=$d:size=1344x768:rate=24" \
    -f lavfi -i "sine=frequency=$((300 + i * 50)):duration=$d" \
    -c:v libx264 -c:a aac -shortest "$PROJ/assets/clips/keepers/sh0$i.mp4"
  ffmpeg -y -v error -f lavfi -i "sine=frequency=880:duration=0.8" \
    "$PROJ/assets/audio/narrator/n0$i.wav"
done
ffmpeg -y -v error -f lavfi -i "sine=frequency=220:duration=30" -c:a libmp3lame \
  "$PROJ/assets/audio/music.mp3"

scripts/assemble.sh "$PROJ"

OUT="$PROJ/output/final_1080p.mp4"
DUR=$(ffprobe -v error -show_entries format=duration -of csv=p=0 "$OUT")
W=$(ffprobe -v error -select_streams v:0 -show_entries stream=width -of csv=p=0 "$OUT")
A=$(ffprobe -v error -select_streams a:0 -show_entries stream=codec_type -of csv=p=0 "$OUT")

python3 -c "d=float('$DUR'); assert 28 <= d <= 32, f'duration {d} out of range'"
[ "$W" = "1920" ] || { echo "FAIL: width $W != 1920"; exit 1; }
[ "$A" = "audio" ] || { echo "FAIL: no audio stream"; exit 1; }
echo "PASS: $OUT (${DUR}s, ${W}px wide, audio ok)"
```

- [ ] **Step 3: Run the test — verify it fails (assemble.sh missing)**

Run: `chmod +x scripts/test_assemble.sh && scripts/test_assemble.sh`
Expected: FAIL — `scripts/assemble.sh: No such file or directory`.

- [ ] **Step 4: Write `scripts/assemble.sh`**

```bash
#!/usr/bin/env bash
# Assemble the final trailer: keeper clips + music bed + narrator VO + title overlay.
# Usage: scripts/assemble.sh <project-dir>
set -euo pipefail

PROJ="${1:?usage: assemble.sh <project-dir>}"
CLIPS="$PROJ/assets/clips/keepers"
AUDIO="$PROJ/assets/audio"
OUT="$PROJ/output"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT
mkdir -p "$OUT"

SHOTS=(sh01 sh02 sh03 sh04 sh05 sh06 sh07)

# 1) Normalize every keeper: 1920x1080 (lanczos + light sharpen), 24fps, uniform codecs.
for s in "${SHOTS[@]}"; do
  in="$CLIPS/$s.mp4"
  [ -f "$in" ] || { echo "missing keeper: $in" >&2; exit 1; }
  ffmpeg -y -v error -i "$in" \
    -vf "scale=1920:1080:flags=lanczos,fps=24,unsharp=5:5:0.4" \
    -af "aresample=48000" -ac 2 \
    -c:v libx264 -preset medium -crf 18 -c:a aac -b:a 192k \
    "$TMP/$s.mp4"
done

# 2) Concat into one timeline.
: > "$TMP/list.txt"
for s in "${SHOTS[@]}"; do printf "file '%s/%s.mp4'\n" "$TMP" "$s" >> "$TMP/list.txt"; done
ffmpeg -y -v error -f concat -safe 0 -i "$TMP/list.txt" -c copy "$TMP/timeline.mp4"
TOTAL=$(ffprobe -v error -show_entries format=duration -of csv=p=0 "$TMP/timeline.mp4")

# 3) Narrator offsets: each line starts 0.3s into its shot.
offsets=()
t=0
for s in "${SHOTS[@]}"; do
  offsets+=("$(python3 -c "print(int(($t + 0.3) * 1000))")")
  d=$(ffprobe -v error -show_entries format=duration -of csv=p=0 "$TMP/$s.mp4")
  t=$(python3 -c "print($t + $d)")
done

# 4) Audio mix: native clip audio (0.5) + music bed (0.30, faded out) + narrator (1.0).
[ -f "$AUDIO/music.mp3" ] || { echo "missing $AUDIO/music.mp3" >&2; exit 1; }
FADE_ST=$(python3 -c "print(max(0, float('$TOTAL') - 1.5))")
inputs=(-i "$TMP/timeline.mp4" -i "$AUDIO/music.mp3")
filter="[0:a]volume=0.5[native];[1:a]volume=0.30,afade=t=out:st=$FADE_ST:d=1.5[music];"
mix="[native][music]"
n=2
for i in "${!SHOTS[@]}"; do
  f="$AUDIO/narrator/n0$((i + 1)).wav"
  [ -f "$f" ] || { echo "missing narrator line: $f" >&2; exit 1; }
  inputs+=(-i "$f")
  filter+="[$n:a]adelay=${offsets[$i]}|${offsets[$i]}[v$n];"
  mix+="[v$n]"
  n=$((n + 1))
done
filter+="${mix}amix=inputs=$n:normalize=0,loudnorm=I=-14:TP=-1.5:LRA=11[aout]"

# 5) Title overlay over the last 2.5s, then render.
FONT="/System/Library/Fonts/Supplemental/Impact.ttf"
[ -f "$FONT" ] || FONT="/System/Library/Fonts/Helvetica.ttc"
T1=$(python3 -c "print(max(0, float('$TOTAL') - 2.5))")
T2=$(python3 -c "print(max(0, float('$TOTAL') - 1.9))")
filter+=";[0:v]drawtext=fontfile=$FONT:text='COMING SOON.':fontsize=110:fontcolor=white:borderw=3:bordercolor=black@0.6:x=(w-text_w)/2:y=(h/2)-90:enable='gte(t\,$T1)',drawtext=fontfile=$FONT:text='unfortunately.':fontsize=54:fontcolor=white@0.9:borderw=2:bordercolor=black@0.6:x=(w-text_w)/2:y=(h/2)+30:enable='gte(t\,$T2)'[vout]"

ffmpeg -y -v error "${inputs[@]}" \
  -filter_complex "$filter" \
  -map "[vout]" -map "[aout]" \
  -c:v libx264 -preset slow -crf 17 -c:a aac -b:a 256k -movflags +faststart \
  "$OUT/final_1080p.mp4"

echo "Done: $OUT/final_1080p.mp4 (timeline ${TOTAL}s)"
```

- [ ] **Step 5: Run the test — verify it passes**

Run: `chmod +x scripts/assemble.sh && scripts/test_assemble.sh`
Expected: `PASS: .../output/final_1080p.mp4 (30.xs, 1920px wide, audio ok)`. Debug filter-graph errors here, on synthetic media — not during the real run.

- [ ] **Step 6: Commit and push**

```bash
git add scripts/assemble.sh scripts/test_assemble.sh && git commit -m "feat: ffmpeg assembly pipeline with synthetic end-to-end test

Co-Authored-By: Claude Fable 5 <noreply@anthropic.com>" && git push
```

---

### Task 10: Runbook

**Files:**
- Create: `projects/magnificent-failure-five/runbook.md`

**Interfaces:**
- Consumes: everything above. This is the document the guided run follows.

- [ ] **Step 1: Write `runbook.md`**

```markdown
# Runbook — The Magnificent Failure Five

Production happens in five gates. Never advance past a gate without the review it names.
Log every queued take in `prompts/take-log.md` immediately.

## Gate 0 — Setup (once)
1. Log in at https://cloud.comfy.org (free tier: 400 credits/mo; Standard removes retry pressure).
2. Drag `workflows/wf1_cast_sheet.json` into the editor; confirm it loads with no missing-node errors.
3. Budget expectation: ~15–50 credits per video clip; full film with retries ≈ 250–800 credits.

## Gate 1 — Cast (stills only, cheap)
1. Run wf1 six times per `characters/cast-sheet-prompts.md` (5 singles @832×1216 seeds 101–105, group @1344×768 seed 100).
2. Download to `assets/refs/` as `captain-obvious.png`, `stretch.png`, `tank.png`, `flex.png`, `jitters.png`, `group.png`.
3. REVIEW TOGETHER (acceptance in cast-sheet-prompts.md). Iterate seeds/DNA until the cast is right.
   If a DNA block changes: re-run `python3 scripts/build_prompts.py projects/magnificent-failure-five` and commit.
4. No video credits before this gate passes.

## Gate 2 — Shots (the credit spend)
Per shot sh01 → sh07:
1. Open `workflows/wf2_shot_r2v.json`. Upload the 5 ref images to its LoadImage nodes
   (duplicate LoadImage nodes in-editor if the template ships fewer than 5 — H3 R2V accepts up to 9).
2. Paste the FULL "Copy-paste prompt" from `prompts/shNN.md`. Set duration per the card (4 or 5 s).
3. Set seed = seed_base + take number (sh03 take 2 → 3002). Queue. Log the take.
4. Two takes per shot; keep the better → download as `assets/clips/keepers/shNN.mp4`.
5. Three failed takes → STOP re-rolling. Fallback: `wf3a_keyframe.json` (compose the keyframe
   from refs; review the still) → `wf3b_i2v.json` (animate it). Log `wf3` in the take log.
6. Watch for: face blending (regenerate; if persistent, recompose wider), wardrobe drift
   (check signature colors), physics nonsense (simplify the Action line to ONE clear event).

## Gate 3 — Audio (local, ~free)
1. Music: 30 s cue per `screenplay/narrator.md` prompt → `assets/audio/music.mp3`.
2. Narrator: 7 lines per `screenplay/narrator.md` table → `assets/audio/narrator/n01.wav`…`n07.wav`.

## Gate 4 — Assembly + final review (local)
1. `scripts/assemble.sh projects/magnificent-failure-five`
2. Review `output/final_1080p.mp4` against the spec checklist: 28–32 s total; narrator audible
   over music (music sits −12 dB under VO by construction); no dead air; title lands on the
   final beat; every gag reads in one viewing.
3. Fix list → regenerate only the offending shot (its seed + workflow are in the take log), re-run assembly.
4. Ship. Commit the take log and push.
```

- [ ] **Step 2: Verify runbook references resolve**

```bash
cd projects/magnificent-failure-five
for p in workflows/wf1_cast_sheet.json workflows/wf2_shot_r2v.json workflows/wf3a_keyframe.json workflows/wf3b_i2v.json characters/cast-sheet-prompts.md prompts/sh01.md prompts/take-log.md screenplay/narrator.md; do
  [ -f "$p" ] && echo "OK $p" || echo "MISSING $p"
done
```

Expected: all `OK`.

- [ ] **Step 3: Commit and push**

```bash
git add projects/magnificent-failure-five/runbook.md && git commit -m "docs(mf5): production runbook with five gates

Co-Authored-By: Claude Fable 5 <noreply@anthropic.com>" && git push
```

---

### Task 11: Final validation sweep

**Files:**
- Modify: anything the sweep flags.

- [ ] **Step 1: Re-run every validation**

```bash
python3 scripts/build_prompts.py projects/magnificent-failure-five && git diff --exit-code projects/magnificent-failure-five/prompts
scripts/test_assemble.sh
for W in projects/magnificent-failure-five/workflows/wf*.json; do jq empty "$W" && echo "OK $W"; done
awk -F'|' '/^\| sh0/{gsub(/[^0-9]/,"",$3); s+=$3} END{print "total:", s}' projects/magnificent-failure-five/screenplay/shotlist.md
```

Expected: prompts regenerate with no diff (idempotent); assembly test PASS; all workflows valid; total 30.

- [ ] **Step 2: Spec-coverage check**

Walk spec §3–§5 and confirm: 7 shots ✓ cast of 5 ✓ DNA blocks ✓ 4 workflow files (wf1, wf2, wf3a+wf3b — noting the pair split) ✓ retry policy in runbook ✓ audio plan ✓ assembly + acceptance checklist ✓. Fix any gap found.

- [ ] **Step 3: Commit and push any fixes**

```bash
git add -A && git commit -m "chore(mf5): final kit validation sweep

Co-Authored-By: Claude Fable 5 <noreply@anthropic.com>" && git push
```

(Skip the commit if the sweep found nothing to fix.)

---

## Plan self-review notes

- **Spec coverage:** spec §3.1 shots → Tasks 3–4; §3.2 cast → Task 2; §4.1 stages → Tasks 5–9; §4.2 workflow constraints → Tasks 6–8 validations; §4.3 retry policy → runbook Gate 2; §4.4 layout → Task 1; §5 acceptance → runbook Gates 1/2/4; §6 risks → framing discipline (shotlist), fallback pair, budget note (runbook Gate 0). wf4 (optional interpolation) is intentionally deferred to the guided run per spec §4.2/§6 — 24 fps native is the trailer look; if wanted, it's built in-editor and exported back.
- **Known unknowns, handled explicitly:** exact template filenames and widget indices are discovered at execution time (Task 5 Step 1, Task 6 Step 2) with concrete inspection commands and acceptance assertions — not placeholders, but documented discovery procedures with verifiable outcomes.
- **Type consistency:** `build_prompts.py <project-dir>` and `patch_workflow.py IN OUT TYPE IDX VALUE...` signatures are used identically across Tasks 4/6/7/8/11; keeper and narrator naming identical across Tasks 4/9/10.
