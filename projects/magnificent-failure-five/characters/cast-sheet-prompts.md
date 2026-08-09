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
