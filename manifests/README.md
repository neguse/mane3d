Manifest files (v0)
===================

These manifests describe raw (near 1:1) bindings to be auto-generated.
They are allowlist-first: include patterns that are expected to be stable,
then add skip patterns for exceptions.

Notes
-----
- The schema is intentionally minimal and may evolve.
- Higher-level Lua APIs are expected to be manual when needed.
- Unknown / unsupported types should fail generation unless overridden.

Usage
-----
Run the dispatcher script (requires PyYAML):
  python3 scripts/gen_from_manifest.py

It will call the existing generators (sokol/imgui/box2d) based on manifests.
