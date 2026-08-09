#!/usr/bin/env python3
"""Patch widget values in a ComfyUI workflow JSON (UI export format).

Usage: patch_workflow.py IN OUT NODE_TYPE INDEX VALUE [NODE_TYPE INDEX VALUE ...]
VALUE is parsed as JSON when possible (numbers/bools), else kept as string.

Node discovery — both locations:
    Vendored Comfy-Org workflow templates are inconsistent about where their
    real node list lives. Some templates (e.g. video_minimax_h3_r2v.json)
    keep every node flat at the top level in `wf["nodes"]`. Others (i2v,
    flux, qwen) package their core model/sampler chain as a *subgraph*: the
    top-level `wf["nodes"]` entry for that chain is just a stub whose `type`
    is a subgraph UUID, and the actual nodes live in
    `wf["definitions"]["subgraphs"][i]["nodes"]` for each subgraph i.

    To make NODE_TYPE matching work regardless of which layout a given
    template uses, this script collects candidate nodes from BOTH locations
    before filtering by type:
      1. every entry in top-level `wf["nodes"]` (if present), and
      2. every entry in `nodes` for each subgraph under
         `wf["definitions"]["subgraphs"][]` (if present).
    A node type that appears in either location is patched in place (the
    dict objects are mutated directly, so writing back `wf` as a whole
    preserves the edit regardless of which container the node came from).
"""
import json
import pathlib
import sys


def parse(v: str):
    try:
        return json.loads(v)
    except ValueError:
        return v


def collect_nodes(wf: dict) -> list:
    """Return every node dict reachable from top-level `nodes` plus every
    subgraph's `nodes` under `definitions.subgraphs[]`."""
    nodes = list(wf.get("nodes") or [])
    subgraphs = (wf.get("definitions") or {}).get("subgraphs") or []
    for sg in subgraphs:
        nodes.extend(sg.get("nodes") or [])
    return nodes


def main() -> None:
    src, dst = pathlib.Path(sys.argv[1]), pathlib.Path(sys.argv[2])
    wf = json.loads(src.read_text())
    patches = sys.argv[3:]
    assert patches and len(patches) % 3 == 0, "patches come in NODE_TYPE INDEX VALUE triples"
    all_nodes = collect_nodes(wf)
    for i in range(0, len(patches), 3):
        ntype, idx, val = patches[i], int(patches[i + 1]), parse(patches[i + 2])
        hits = [n for n in all_nodes if n.get("type") == ntype]
        if not hits:
            sys.exit(f"error: no node of type {ntype} in {src}")
        for n in hits:
            n["widgets_values"][idx] = val
            print(f"node {n['id']} ({ntype}): widgets_values[{idx}] = {val!r}")
    dst.write_text(json.dumps(wf, indent=2))
    print(f"wrote {dst}")


if __name__ == "__main__":
    main()
