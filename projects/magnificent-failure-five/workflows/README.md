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
| wf3a_keyframe.json | fallback stage 1: Qwen-Image-Edit keyframe from refs | template unchanged (no size widget); operator resizes the composed reference to 1344×768 before running |
| wf3b_i2v.json | fallback stage 2: H3 Image-to-Video from keyframe | 1344×768, 5 s default (adjust per shot), native audio |
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

## wf3a_keyframe.json — no size widget; template used unmodified

`templates/qwen_image_edit.json` (subgraph "Image Edit (Qwen-Image 2511)") has **no width,
height, or latent-size node anywhere in the file** — searched both the top-level `.nodes[]`
and the subgraph's `.nodes[]` (17 distinct node types: `ModelSamplingAuraFlow`, `VAELoader`,
`FluxKontextMultiReferenceLatentMethod` ×2, `TextEncodeQwenImageEditPlus` ×2, `Note`,
`CFGNorm`, `LoraLoaderModelOnly`, `PrimitiveFloat` ×2, `VAEEncode`, `UNETLoader`, `CLIPLoader`,
`ComfySwitchNode` ×3, `PrimitiveInt` ×2, `PrimitiveBoolean`, `KSampler`, `VAEDecode`,
`FluxKontextImageScale`) — none of them is an `EmptySD3LatentImage`/`ResolutionSelector`-style
size source. Instead, the edit chain runs entirely at the resolution of the input image: the
subgraph's `image1` input feeds directly into `FluxKontextImageScale` (node 160, confirmed via
its `widgets_values: []` — a parameterless node with only an `image` input) → `VAEEncode` →
`KSampler` → `VAEDecode` → `SaveImage`. There is no point in the graph where an explicit
width/height gets set; `FluxKontextImageScale` snaps whatever image it receives to Flux
Kontext's own nearest preferred-resolution bucket.

Per the brief's contingency for this exact case, `wf3a_keyframe.json` is a **byte-identical
copy** of `templates/qwen_image_edit.json` (verified: `diff <(jq -S . templates/qwen_image_edit.json) <(jq -S . wf3a_keyframe.json)`
is empty) — no `patch_workflow.py` run, nothing to patch. **Operator action:** resize the
composed reference/keyframe input image to 1344×768 *before* loading it into this workflow
(e.g. with the KJNodes "Resize Image" node added in-editor, or any equivalent pre-processing
step) so `FluxKontextImageScale`'s nearest-bucket snap lands on 1344×768 rather than some other
bucket. 1344×768 (~1.03 MP, 16:9) is a standard Flux/Kontext bucket size (it's the exact
`0.98 MP → 1344×768` row already used for wf2's `ResolutionSelector` table), so a pre-sized
1344×768 input should pass through effectively unchanged.

## wf3b_i2v.json — how the 1344×768 / 5 s patch works

`templates/video_minimax_h3_i2v.json` nests its core chain in the subgraph "Image to Video
(MiniMax H3)" (unlike the flat `r2v` template), which adds a second cosmetic layer to trace
through. Full chain, outermost to innermost:

- **Resolution** is genuinely driven by a top-level `ResolutionSelector` node (id 115) —
  linked (not cosmetic) into the subgraph-instance node's `width`/`height` inputs (top-level
  links 219/220). The template's own default is `["1:1 (Square)", 0.4, 32]` — **not** 16:9,
  unlike `wf2_shot_r2v.json`'s `r2v` template, whose `ResolutionSelector` already defaulted to
  `"16:9 (Widescreen)"`. So both `ResolutionSelector` widgets needed patching here:
  `widgets_values[0]` → `"16:9 (Widescreen)"` and `widgets_values[1]` → `0.98` (the same
  `0.98 → 1344×768 @ multiple=32` lookup-table row documented in node 118's `MarkdownNote`,
  identical table to wf2's).
- From there, `ResolutionSelector`'s output feeds the subgraph-instance node's `width`/`height`
  (converted-to-input, link-driven — cosmetic), which in turn feeds the subgraph's internal
  `MiniMaxH3ImageToVideo` node (id 104) `width`/`height` (also converted-to-input, also
  cosmetic). Both of these already showed `1344`/`768` in the pristine template — coincidental,
  not evidence they were the real source — so `patch_workflow.py` re-asserts them anyway for
  display consistency at both layers (idempotent, confirmed 0-diff at those lines).
- **Duration**: the subgraph-instance node's `value_1` ("duration") input has `"link": null` —
  unlike `width`/`height`, it is *not* wired from an external producer, so (per the same
  `-10`-boundary / proxy-widget reasoning established in Task 7 for `wf1`) its own
  `widgets_values[3]` **is** the true source, which the subgraph passes down to an internal
  `PrimitiveFloat`/`ComfyMathExpression` pair that converts seconds → a valid frame `length` on
  a 17-frame/24fps grid. The template's own default is already `5`, so `patch_workflow.py`
  re-asserts **index 3 → `5`** (idempotent).

Net effect: **the entire functional diff between `wf3b_i2v.json` and its template is 2 lines**
(`ResolutionSelector`'s aspect ratio and megapixels) — every other patch command ran against a
value the template already shipped correctly, confirmed via `diff <(jq -S . templates/video_minimax_h3_i2v.json) <(jq -S . wf3b_i2v.json)`.

Exact command used:

```bash
python3 scripts/patch_workflow.py \
  projects/magnificent-failure-five/workflows/templates/video_minimax_h3_i2v.json \
  projects/magnificent-failure-five/workflows/wf3b_i2v.json \
  ResolutionSelector 0 "16:9 (Widescreen)" \
  ResolutionSelector 1 0.98 \
  4c314f31-ecda-4b08-ae98-faaba1bf613f 1 1344 \
  4c314f31-ecda-4b08-ae98-faaba1bf613f 2 768 \
  4c314f31-ecda-4b08-ae98-faaba1bf613f 3 5 \
  MiniMaxH3ImageToVideo 1 1344 \
  MiniMaxH3ImageToVideo 2 768
```

(`4c314f31-ecda-4b08-ae98-faaba1bf613f` is the subgraph-instance node's `type` — the UUID
ComfyUI assigns to the top-level stub for the "Image to Video (MiniMax H3)" subgraph; it's the
only way to address that node's own promoted widgets by type.)

Audio needs no separate toggle here either: `CreateVideo` (id 91, inside the subgraph) has its
`audio` input wired from `VAEDecodeAudio`, same native-joint-audio pattern as `wf2`. The image
input path (`LoadImage` id 114 → `ResolutionSelector`-independent `first_frame` socket, link
218) is **not** pre-scaled by anything — the top-level `ImageScaleToTotalPixels`
(id 119) → `GetImageSize` (id 120) pair in this template is disconnected dead scaffolding
(`ImageScaleToTotalPixels`'s own `image` input has `"link": null`; `GetImageSize`'s outputs
feed nothing) — so H3 receives the raw loaded keyframe image and generates at the
`width`/`height` set above regardless of the input file's exact pixel dimensions.

## Reference-image inputs

The vendored `video_minimax_h3_r2v.json` template ships with **2 `LoadImage` nodes**
(ids 137, 139) pre-wired into `MiniMaxH3ReferenceToVideo`'s `ref_image_0` and `ref_image_1`
sockets, plus **one spare unconnected socket, `ref_image_2`** (confirmed directly in node 136's
`inputs` array: `ref_image_0`/`link` and `ref_image_1`/`link` are non-null, `ref_image_2`/`link`
is `null`, and there is no `ref_image_3`…`ref_image_8` entry in the JSON at all — the array
simply stops at index 2). `ref_images` is a dynamic ("autogrow") input list: ComfyUI grows it by
one more socket each time the current last socket gets connected, so sockets beyond what's
already wired don't exist in the static JSON — they only appear once you connect the previous
one, in the live editor. The template's own vendor documentation (node 116's `MarkdownNote`,
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

## Node provenance — wf3a / wf3b

`wf3a_keyframe.json` inventory (top-level: `LoadImage` ×2, `MarkdownNote` ×2, `SaveImage`,
plus the subgraph-instance stub; subgraph "Image Edit (Qwen-Image 2511)": `ModelSamplingAuraFlow`,
`VAELoader`, `FluxKontextMultiReferenceLatentMethod`, `TextEncodeQwenImageEditPlus`, `Note`,
`CFGNorm`, `LoraLoaderModelOnly`, `PrimitiveFloat`, `VAEEncode`, `UNETLoader`, `CLIPLoader`,
`ComfySwitchNode`, `PrimitiveInt`, `PrimitiveBoolean`, `KSampler`, `VAEDecode`,
`FluxKontextImageScale`) matches `templates/SOURCES.md` exactly. Every one of these subgraph
nodes **self-reports `"properties.cnr_id": "comfy-core"`** directly in the JSON (checked via
`jq`), except `Note` (`cnr_id: null` — an annotation-only node, same harmless status as
`MarkdownNote`), so no external lookup was needed for this file.

`wf3b_i2v.json` adds three node types beyond what wf2's provenance write-up above already covers:
`MiniMaxH3ImageToVideo`, `GetImageSize`, and `ImageScaleToTotalPixels` — each addressed below,
starting with `MiniMaxH3ImageToVideo`. Checked directly against `Comfy-Org/ComfyUI` core source (2026-08-09):
defined in the same file as the already-verified `MiniMaxH3ReferenceToVideo`,
[`comfy_extras/nodes_minimax_h3.py`](https://github.com/Comfy-Org/ComfyUI/blob/master/comfy_extras/nodes_minimax_h3.py)
(also defines `EmptyMiniMaxH3LatentAV` and `MiniMaxH3SigmaShift`, unused here), registered with
node ID `"MiniMaxH3ImageToVideo"`. `GetImageSize` was also checked directly — defined in
[`comfy_extras/nodes_images.py`](https://github.com/Comfy-Org/ComfyUI/blob/master/comfy_extras/nodes_images.py),
registered `node_id="GetImageSize"`. `ImageScaleToTotalPixels` (top-level node 119) appears in
`nodes.py`'s `NODE_DISPLAY_NAME_MAPPINGS` (`"ImageScaleToTotalPixels": "Scale Image to Total
Pixels"`) but the fetch tooling used couldn't confirm its class definition in the same pass
(the file is large); low-confidence but not a blocker, because — independent of core-status —
this node is **dead scaffolding in the pristine upstream template**: its `image` input has
`"link": null` (never wired to anything) and its own output feeds `GetImageSize`, whose outputs
in turn feed nothing. It has no effect on the workflow's behavior or Comfy Cloud eligibility
either way; noted here for completeness rather than as an open risk.
