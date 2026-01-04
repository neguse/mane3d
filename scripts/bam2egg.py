#!/usr/bin/env python3
"""Convert .bam files from 3d-game-shaders-for-beginners to .egg format."""

import shutil
import subprocess
import sys
from pathlib import Path

SCRIPT_DIR = Path(__file__).parent
ROOT_DIR = SCRIPT_DIR.parent
DEMO_DIR = ROOT_DIR / "deps" / "3d-game-shaders-for-beginners" / "demonstration"
SOURCE_DIR = DEMO_DIR / "eggs"
OUTPUT_DIR = ROOT_DIR / "assets"


def find_bam2egg():
    """Find bam2egg executable in the same directory as the Python interpreter."""
    python_dir = Path(sys.executable).parent
    for name in ["bam2egg.exe", "bam2egg"]:
        candidate = python_dir / name
        if candidate.exists():
            return str(candidate)
    return "bam2egg"


def main():
    bam2egg_cmd = find_bam2egg()
    OUTPUT_DIR.mkdir(parents=True, exist_ok=True)

    bam_files = list(SOURCE_DIR.rglob("*.bam"))
    if not bam_files:
        print(f"No .bam files found in {SOURCE_DIR}")
        return 1

    print(f"Found {len(bam_files)} .bam files")

    for bam_file in bam_files:
        rel_path = bam_file.relative_to(SOURCE_DIR)
        out_dir = OUTPUT_DIR / rel_path.parent
        out_dir.mkdir(parents=True, exist_ok=True)
        out_file = out_dir / (bam_file.stem + ".egg")

        print(f"Converting: {rel_path} -> {out_file.relative_to(ROOT_DIR)}")

        try:
            subprocess.run(
                [bam2egg_cmd, "-o", str(out_file), str(bam_file)],
                check=True,
                capture_output=True,
                text=True,
            )
        except subprocess.CalledProcessError as e:
            print(f"  Error: {e.stderr}")
            continue
        except FileNotFoundError:
            print("Error: bam2egg not found. Install Panda3D and ensure it's in PATH.")
            return 1

    # Copy textures (model-specific)
    tex_dirs = list(SOURCE_DIR.rglob("tex"))
    for tex_dir in tex_dirs:
        if tex_dir.is_dir():
            rel_path = tex_dir.relative_to(SOURCE_DIR)
            out_tex_dir = OUTPUT_DIR / rel_path
            out_tex_dir.mkdir(parents=True, exist_ok=True)
            for tex_file in tex_dir.iterdir():
                if tex_file.is_file():
                    out_file = out_tex_dir / tex_file.name
                    print(f"Copying: {tex_file.relative_to(SOURCE_DIR)} -> {out_file.relative_to(ROOT_DIR)}")
                    shutil.copy2(tex_file, out_file)

    # Copy shared images (LUTs, noise, etc.)
    images_dir = DEMO_DIR / "images"
    if images_dir.is_dir():
        out_images_dir = OUTPUT_DIR / "images"
        out_images_dir.mkdir(parents=True, exist_ok=True)
        for img_file in images_dir.iterdir():
            if img_file.is_file():
                out_file = out_images_dir / img_file.name
                print(f"Copying: images/{img_file.name} -> {out_file.relative_to(ROOT_DIR)}")
                shutil.copy2(img_file, out_file)

    print("Done!")
    return 0


if __name__ == "__main__":
    sys.exit(main())
