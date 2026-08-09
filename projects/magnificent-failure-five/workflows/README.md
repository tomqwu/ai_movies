# Workflows (Comfy Cloud-importable)

Drag any JSON into cloud.comfy.org to import. `wf2_shot_r2v.json` uses **only core ComfyUI
nodes** — built into every ComfyUI/Comfy Cloud install, no community pack required. Comfy Cloud
separately preinstalls the VHS/VideoHelperSuite, KJNodes, and Frame-Interpolation packs
(https://comfy.org/cloud/supported-nodes/) for workflows that need them, but none of their nodes
appear in this workflow. See "Node provenance" below for how each node type's core status was
verified.

| file | purpose | key settings |
|---|---|---|
| wf1_cast_sheet.json | character reference stills (FLUX) | 832×1216 default (individual refs); group shot switches to 1344×768 in-editor; seed per cast-sheet-prompts.md |
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
sockets, plus **one spare unconnected socket, `ref_image_2`** (confirmed directly in node 136's
`inputs` array: `ref_image_0`/`link` and `ref_image_1`/`link` are non-null, `ref_image_2`/`link`
is `null`, and there is no `ref_image_3`…`ref_image_8` entry in the JSON at all — the array
simply stops at index 2). `ref_images` is a dynamic ("autogrow") input list: ComfyUI grows it by
one more socket each time the current last socket gets connected, so sockets beyond what's
already wired don't exist in the static JSON — they only appear once you connect the previous
one, in the live editor. The template's own vendor documentation (node 105's `MarkdownNote`,
"About this workflow") states the node accepts **up to 9** reference images in total; that's a
runtime ceiling on the dynamic list, not a count of sockets you'll see sitting empty in the JSON.
For our 5 reference stills per shot, the operator duplicates the `LoadImage` node in the Comfy
Cloud editor and wires each new copy to the next `ref_images.ref_image_N` socket as it
materializes — takes ~30 s per extra ref in the editor; the runbook covers it.

Shots shorter than 5 s (sh02–sh05, sh07 are 4 s): set the `PrimitiveFloat` "Float (Duration)"
widget to 4 before queueing, per the shot's prompt card.

## Node provenance

Every node type in `wf2_shot_r2v.json` is core ComfyUI — none require a community pack. Full
inventory (`jq -r '[.nodes[].type] | unique | .[]' wf2_shot_r2v.json`): `BasicGuider`,
`BasicScheduler`, `CLIPLoader`, `ComfyMathExpression`, `CreateVideo`, `KSamplerSelect`,
`LoadImage`, `MarkdownNote`, `MiniMaxH3ReferenceToVideo`, `PrimitiveFloat`,
`PrimitiveStringMultiline`, `RandomNoise`, `ResolutionSelector`, `SamplerCustomAdvanced`,
`SaveVideo`, `UNETLoader`, `VAEDecode`, `VAEDecodeAudio`, `VAELoader`.

The two whose core status isn't obvious from the name alone were checked directly against the
`Comfy-Org/ComfyUI` core source on GitHub (checked 2026-08-09):

- **`ComfyMathExpression`** — defined in
  [`comfy_extras/nodes_math.py`](https://github.com/Comfy-Org/ComfyUI/blob/master/comfy_extras/nodes_math.py)
  as class `MathExpressionNode`, registered with node ID `"ComfyMathExpression"` (display name
  "Math Expression", category `utilities`) via `MathExtension.get_node_list()`. Corroborated by
  a live issue in the core repo's own tracker,
  [Comfy-Org/ComfyUI#12690](https://github.com/Comfy-Org/ComfyUI/issues/12690) ("Math Expression
  node: allow mixing INT and FLOAT inputs"), which only makes sense if the node ships in that
  repo.
- **`ResolutionSelector`** — defined in
  [`comfy_extras/nodes_resolution.py`](https://github.com/Comfy-Org/ComfyUI/blob/master/comfy_extras/nodes_resolution.py)
  as class `ResolutionSelector`, registered with node ID `"ResolutionSelector"` (display name
  "Resolution Selector", category `utilities`) via `ResolutionExtension.get_node_list()`.
  Corroborated by merged core-repo PR
  [Comfy-Org/ComfyUI#14309](https://github.com/Comfy-Org/ComfyUI/pull/14309) ("Improve
  ResolutionSelector").
- **`MiniMaxH3ReferenceToVideo`** — added to core ComfyUI via
  [Comfy-Org/ComfyUI#15224](https://github.com/Comfy-Org/ComfyUI/pull/15224).
- The remaining 16 types (`LoadImage`, `CLIPLoader`, `UNETLoader`, `VAELoader`, `VAEDecode`,
  `VAEDecodeAudio`, `CreateVideo`, `SaveVideo`, `KSamplerSelect`, `BasicScheduler`,
  `SamplerCustomAdvanced`, `BasicGuider`, `RandomNoise`, `PrimitiveFloat`,
  `PrimitiveStringMultiline`, `MarkdownNote`) are long-standing ComfyUI core node types present
  in every install.

None of VHS/VideoHelperSuite, KJNodes, or Frame-Interpolation (the community packs Comfy Cloud
preinstalls at https://comfy.org/cloud/supported-nodes/) are used by this workflow — H3 renders
video+audio natively in one pass, so no helper/interpolation nodes are needed.
