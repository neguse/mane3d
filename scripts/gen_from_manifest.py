#!/usr/bin/env python3
"""Generate bindings based on v0 manifests.

This is a thin dispatcher that calls existing generators. It is intentionally
minimal and does not attempt to reinterpret binding rules yet.
"""
import argparse
import glob
import os
import sys
import subprocess


def load_yaml(path):
    try:
        import yaml  # type: ignore
    except Exception as exc:
        print("Error: PyYAML is required to read manifests.")
        print("Install with: pip install pyyaml")
        print(f"Details: {exc}")
        sys.exit(1)
    with open(path, "r", encoding="utf-8") as f:
        return yaml.safe_load(f) or {}


def is_sokol(module_name):
    return isinstance(module_name, str) and module_name.startswith("sokol.")


def call(cmd, cwd):
    print("+", " ".join(cmd))
    subprocess.check_call(cmd, cwd=cwd)


def main():
    parser = argparse.ArgumentParser(description="Generate bindings from manifests")
    parser.add_argument(
        "--manifest",
        action="append",
        default=[],
        help="Manifest file (can be repeated). Defaults to manifests/*.yaml",
    )
    args = parser.parse_args()

    script_dir = os.path.dirname(os.path.abspath(__file__))
    root_dir = os.path.abspath(os.path.join(script_dir, ".."))

    manifest_paths = args.manifest
    if not manifest_paths:
        manifest_paths = sorted(glob.glob(os.path.join(root_dir, "manifests", "*.yaml")))

    if not manifest_paths:
        print("No manifests found.")
        sys.exit(1)

    manifests = []
    for path in manifest_paths:
        manifest = load_yaml(path)
        manifest["__path"] = path
        manifests.append(manifest)

    # Run sokol generator once if any sokol manifests are present.
    if any(is_sokol(m.get("module")) for m in manifests):
        call([sys.executable, os.path.join("scripts", "gen_lua.py")], cwd=root_dir)

    for m in manifests:
        module = m.get("module")
        if is_sokol(module):
            continue

        if module == "imgui":
            header = m.get("headers", [None])[0]
            if not header:
                print(f"[imgui] Missing header in {m['__path']}")
                continue
            out = None
            output = m.get("output") or {}
            out = output.get("c_binding")
            cmd = [sys.executable, os.path.join("scripts", "gen_imgui.py"), header]
            if out:
                cmd.append(out)
            call(cmd, cwd=root_dir)
            continue

        if module == "b2d":
            header = m.get("headers", [None])[0]
            if not header:
                print(f"[b2d] Missing header in {m['__path']}")
                continue
            cmd = [sys.executable, os.path.join("scripts", "gen_box2d.py"), header]
            call(cmd, cwd=root_dir)
            continue

        # Manual-only or unsupported module.
        manual = (m.get("overrides") or {}).get("manual_shim")
        if manual:
            print(f"[skip] {module}: manual shim only ({len(manual)} entries)")
        else:
            print(f"[skip] {module}: no generator mapped")


if __name__ == "__main__":
    main()
