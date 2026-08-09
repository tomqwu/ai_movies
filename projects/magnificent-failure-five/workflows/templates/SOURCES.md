# Vendored Workflow Templates — Sources

All files in this directory are **pristine, unmodified** copies fetched from the official
`Comfy-Org/workflow_templates` GitHub repository (`main` branch). They are vendored as a
base for later tasks to copy and patch — never edit these in place.

Fetch date: **2026-08-09**

## Discovery notes

The repo's `templates/` directory currently contains **1382 files** (per the git trees API,
`git/trees/main?recursive=1`, `truncated: false`). The GitHub Contents API
(`GET /repos/Comfy-Org/workflow_templates/contents/templates`) silently caps its response at
**1000 entries** with no `Link` pagination header, so an alphabetical listing via the Contents
API alone misses everything sorted after roughly the `u`/`v` prefixes — including all
`video_*` templates. This is exactly where the MiniMax H3 native-node templates live, so the
Contents API alone (as suggested by the brief's Step 1 snippet) undercounts and would have
missed them. The git trees API was used as the authoritative fallback and found them.

The repo ships **two families** of MiniMax H3 templates:
- `api_minimax_h3_*.json` — API/cloud-service wrapper templates (call MiniMax's hosted API,
  same pattern as `api_bfl_*`, `api_kling_*`, `api_luma_*`, etc.)
- `video_minimax_h3_*.json` — native local ComfyUI node templates (run the open-weights model
  locally via `UNETLoader`/`CLIPLoader` + a dedicated `MiniMaxH3...` sampler node)

Per the task context (H3 has native, open-weights ComfyUI support since v0.30.0), the
**`video_minimax_h3_*` family is correct** and was used. These filenames also matched the
brief's guessed names exactly (`video_minimax_h3_r2v.json`, `video_minimax_h3_i2v.json`) —
both a t2v (`video_minimax_h3_t2v.json`) and an flf2v variant also exist upstream but were not
needed for this task.

## Files

### `video_minimax_h3_r2v.json`
- **Upstream URL:** https://raw.githubusercontent.com/Comfy-Org/workflow_templates/main/templates/video_minimax_h3_r2v.json
- **Fetched:** 2026-08-09
- **Upstream template name:** "Reference to Video (MiniMax H3)"
- **H3 node types observed:** `MiniMaxH3ReferenceToVideo`
- **Other nodes (top-level, single-graph — no subgraph nesting):**
  `SaveVideo`, `ResolutionSelector`, `VAELoader` (x2 — video + audio VAE), `VAEDecodeAudio`,
  `VAEDecode`, `KSamplerSelect`, `BasicScheduler`, `SamplerCustomAdvanced`, `BasicGuider`,
  `UNETLoader`, `CLIPLoader`, `RandomNoise`, `CreateVideo`, `ComfyMathExpression`,
  `PrimitiveFloat`, `LoadImage` (x2 — reference images), `PrimitiveStringMultiline`,
  `MarkdownNote` (x2)

### `video_minimax_h3_i2v.json`
- **Upstream URL:** https://raw.githubusercontent.com/Comfy-Org/workflow_templates/main/templates/video_minimax_h3_i2v.json
- **Fetched:** 2026-08-09
- **Upstream template name:** "Image to Video (MiniMax H3)" (nested as a subgraph node —
  the sampler/model chain lives under `.definitions.subgraphs[]`, not `.nodes[]`, in this file)
- **H3 node types observed:** `MiniMaxH3ImageToVideo`
- **Other nodes (subgraph "Image to Video (MiniMax H3)"):**
  `VAELoader` (x2), `VAEDecodeAudio`, `VAEDecode`, `KSamplerSelect`, `BasicScheduler`,
  `SamplerCustomAdvanced`, `BasicGuider`, `UNETLoader`, `CLIPLoader`, `RandomNoise`,
  `CreateVideo`, `ComfyMathExpression`, `PrimitiveFloat`
- **Other nodes (top-level):** `SaveVideo`, `LoadImage`, `ResolutionSelector`,
  `ImageScaleToTotalPixels`, `GetImageSize`, `MarkdownNote` (x3)

### `flux_t2i.json`
- **Source filename upstream:** `flux_dev_full_text_to_image.json`
- **Upstream URL:** https://raw.githubusercontent.com/Comfy-Org/workflow_templates/main/templates/flux_dev_full_text_to_image.json
- **Fetched:** 2026-08-09
- **Upstream template name:** "Text to Image (Flux.1 Dev)" — dev variant, as preferred by the brief
- **Node types (subgraph "Text to Image (Flux.1 Dev)"):** `VAELoader`, `UNETLoader`,
  `DualCLIPLoader`, `EmptySD3LatentImage`, `CLIPTextEncode`, `KSampler`, `VAEDecode`,
  `ConditioningZeroOut`
- **Other nodes (top-level):** `SaveImage`, `MarkdownNote`

### `qwen_image_edit.json`
- **Source filename upstream:** `image_qwen_image_edit_2511.json`
- **Upstream URL:** https://raw.githubusercontent.com/Comfy-Org/workflow_templates/main/templates/image_qwen_image_edit_2511.json
- **Fetched:** 2026-08-09
- **Upstream template name:** "Image Edit (Qwen-Image 2511)" — newest variant available
  (2511 supersedes the also-present 2509 variant; a `2511_int8` quantized variant and a
  `2509_relight` specialized variant also exist upstream but were not used)
- **Node types (subgraph "Image Edit (Qwen-Image 2511)"):** `ModelSamplingAuraFlow`,
  `VAELoader`, `FluxKontextMultiReferenceLatentMethod` (x2), `TextEncodeQwenImageEditPlus` (x2),
  `Note`, `CFGNorm`, `LoraLoaderModelOnly`, `PrimitiveFloat` (x2), `VAEEncode`, `UNETLoader`,
  `CLIPLoader`, `ComfySwitchNode` (x3), `PrimitiveInt` (x2), `PrimitiveBoolean`, `KSampler`,
  `VAEDecode`, `FluxKontextImageScale`
- **Other nodes (top-level):** `LoadImage` (x2), `SaveImage`, `MarkdownNote` (x2)

## Format note

These templates use the modern ComfyUI frontend workflow format, where the main model/sampler
chain is frequently packaged as a **subgraph** node (a single `.nodes[]` entry whose `type` is
a UUID pointing into `.definitions.subgraphs[]`, which contains the real node list). Only
`video_minimax_h3_r2v.json` keeps its full graph flat at the top level; the other three nest
their core nodes inside a subgraph. Downstream tasks patching these files should account for
this when editing node parameters.
