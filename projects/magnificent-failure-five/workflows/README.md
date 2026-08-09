# Workflows (Comfy Cloud-importable)

Drag any JSON into cloud.comfy.org to import. All node types used across these workflows are
either core ComfyUI nodes (built into every ComfyUI/Comfy Cloud install, including the
`MiniMaxH3*` family added in [ComfyUI#15224](https://github.com/Comfy-Org/ComfyUI/pull/15224))
or ship in the preinstalled community packs Comfy Cloud lists at
https://comfy.org/cloud/supported-nodes/ (VHS/VideoHelperSuite, KJNodes, Frame-Interpolation).

| file | purpose | key settings |
|---|---|---|
| wf1_cast_sheet.json | character reference stills (FLUX) | seed + resolution per cast-sheet-prompts.md |
| wf2_shot_r2v.json | per-shot video: H3 Reference-to-Video | 1344×768, 5 s, native audio; load refs from assets/refs/; paste prompt from prompts/shNN.md; seed from take-log convention |
| wf3a_keyframe.json | fallback stage 1: Qwen-Image-Edit keyframe from refs | 1344×768 out |
| wf3b_i2v.json | fallback stage 2: H3 Image-to-Video from keyframe | 1344×768, shot length |
| templates/ | pristine upstream templates (never edit) | see SOURCES.md |

## wf2_shot_r2v.json — how the 1344×768 / 5 s patch works

The `video_minimax_h3_r2v.json` template does **not** expose width/height as a directly
editable widget on the `MiniMaxH3ReferenceToVideo` node (id 136) — that node's `width`/
`height`/`length` widgets are all converted to *linked inputs*, so whatever value sits in
their `widgets_values` slots is cosmetic only and is overridden at run time by the upstream
node the link comes from. Tracing the graph:

- **Resolution** is produced by the `ResolutionSelector` node (id 115) — `widgets_values =
  ["16:9 (Widescreen)", megapixels, 32]` — and fed into node 136's `width`/`height` inputs.
  The template ships its own `MarkdownNote` lookup table (node 140) mapping `megapixels` →
  output size at `multiple=32`; the row `0.98 → 1344 x 768` is an exact match for the goal
  resolution, so `patch_workflow.py` sets **`ResolutionSelector` index 1 → `0.98`**.
- **Duration** is produced by a `PrimitiveFloat` node titled "Float (Duration)" (id 132),
  in **seconds**, which a `ComfyMathExpression` node (id 131) converts to a valid frame
  `length` (rounds to 24 fps and pads to satisfy an internal frame-count constraint). The
  template's own default is already `5`, so `patch_workflow.py` re-asserts **`PrimitiveFloat`
  index 0 → `5`** (idempotent — see below).
- For display consistency, node 136's own (functionally inert) `width`/`height` widget slots
  are also set to `1344`/`768` so the JSON doesn't show stale values next to the node that
  visually owns them.

Exact command used:

```bash
python3 scripts/patch_workflow.py \
  projects/magnificent-failure-five/workflows/templates/video_minimax_h3_r2v.json \
  projects/magnificent-failure-five/workflows/wf2_shot_r2v.json \
  ResolutionSelector 1 0.98 \
  MiniMaxH3ReferenceToVideo 1 1344 \
  MiniMaxH3ReferenceToVideo 2 768 \
  PrimitiveFloat 0 5
```

Audio needs no separate toggle: `CreateVideo` (id 130) has its `audio` input permanently
wired from `VAEDecodeAudio`, so every render from this template carries H3's native joint
audio track.

## Reference-image inputs

The vendored `video_minimax_h3_r2v.json` template ships with **2 `LoadImage` nodes**
(ids 137, 139) pre-wired into `MiniMaxH3ReferenceToVideo`'s `ref_image_0` and `ref_image_1`
sockets. The node exposes room for up to **9** reference images total (`ref_image_2`
through `ref_image_8` are present as unconnected input sockets). If a shot needs more than 2
reference stills, duplicate the `LoadImage` node in the Comfy Cloud editor and wire it to the
next open `ref_images.ref_image_N` socket — takes ~30 s in the editor; the runbook covers it.

Shots shorter than 5 s (sh02–sh05, sh07 are 4 s): set the `PrimitiveFloat` "Float (Duration)"
widget to 4 before queueing, per the shot's prompt card.
