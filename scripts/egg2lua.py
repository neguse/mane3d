#!/usr/bin/env python3
"""
egg2lua.py - Convert Panda3D .egg files to Lua table format

Usage: python egg2lua.py input.egg output.lua
"""

import sys
import re
import os


class EggParser:
    """Parser for Panda3D .egg files"""

    def __init__(self):
        self.textures = {}  # name -> {path, wrap_u, wrap_v, filter, envtype}
        self.materials = {}  # name -> {diffuse, ambient, specular, emission, shininess}
        self.vertex_pools = {}  # name -> [{pos, uv, normal, rgba}]
        self.groups = []  # [{name, polygons: [{texture_refs, material_ref, vertices}]}]
        self.coordinate_system = "Z-Up"

    def parse(self, content):
        """Parse egg file content"""
        # Remove comments
        content = re.sub(r"//.*$", "", content, flags=re.MULTILINE)

        pos = 0
        while pos < len(content):
            pos = self._skip_whitespace(content, pos)
            if pos >= len(content):
                break

            # Parse top-level elements: <Tag> name { ... }
            if content[pos] == "<":
                end = content.find(">", pos)
                if end == -1:
                    break
                tag = content[pos + 1 : end].strip()
                pos = end + 1

                # Skip whitespace to get optional name
                pos = self._skip_whitespace(content, pos)

                # Get name (everything before {)
                name = ""
                name_start = pos
                while pos < len(content) and content[pos] not in "{\n":
                    pos += 1
                name = content[name_start:pos].strip()

                # Skip whitespace and find block
                pos = self._skip_whitespace(content, pos)
                if pos < len(content) and content[pos] == "{":
                    block_end = self._find_block_end(content, pos)
                    block_content = content[pos + 1 : block_end]

                    if tag == "CoordinateSystem":
                        self.coordinate_system = block_content.strip()
                    elif tag == "Texture":
                        self._parse_texture(name, block_content)
                    elif tag == "Material":
                        self._parse_material(name, block_content)
                    elif tag == "VertexPool":
                        self._parse_vertex_pool(name, block_content)
                    elif tag == "Group":
                        self._parse_group(name, block_content)

                    pos = block_end + 1
            else:
                pos += 1

    def _skip_whitespace(self, content, pos):
        while pos < len(content) and content[pos] in " \t\n\r":
            pos += 1
        return pos

    def _find_block_end(self, content, start):
        """Find matching closing brace"""
        depth = 0
        pos = start
        while pos < len(content):
            if content[pos] == "{":
                depth += 1
            elif content[pos] == "}":
                depth -= 1
                if depth == 0:
                    return pos
            pos += 1
        return len(content)

    def _parse_texture(self, name, content):
        """Parse texture block"""
        tex = {"path": "", "wrap_u": "repeat", "wrap_v": "repeat", "envtype": "modulate"}

        # First line is usually the path
        lines = content.strip().split("\n")
        for line in lines:
            line = line.strip()
            if line.startswith('"') and line.endswith('"'):
                tex["path"] = os.path.basename(line[1:-1])
            elif "<Scalar>" in line:
                m = re.search(r"<Scalar>\s*(\w+)\s*{\s*(\S+)\s*}", line)
                if m:
                    key, val = m.group(1), m.group(2)
                    if key == "wrapu":
                        tex["wrap_u"] = val
                    elif key == "wrapv":
                        tex["wrap_v"] = val
                    elif key == "envtype":
                        tex["envtype"] = val

        self.textures[name] = tex

    def _parse_material(self, name, content):
        """Parse material block"""
        mat = {
            "diffuse": [0.8, 0.8, 0.8],
            "ambient": [1, 1, 1],
            "specular": [0.5, 0.5, 0.5],
            "emission": [0, 0, 0],
            "shininess": 10,
        }

        for line in content.split("\n"):
            m = re.search(r"<Scalar>\s*(\w+)\s*{\s*([\d.+-]+)\s*}", line)
            if m:
                key, val = m.group(1), float(m.group(2))
                if key == "diffr":
                    mat["diffuse"][0] = val
                elif key == "diffg":
                    mat["diffuse"][1] = val
                elif key == "diffb":
                    mat["diffuse"][2] = val
                elif key == "ambr":
                    mat["ambient"][0] = val
                elif key == "ambg":
                    mat["ambient"][1] = val
                elif key == "ambb":
                    mat["ambient"][2] = val
                elif key == "specr":
                    mat["specular"][0] = val
                elif key == "specg":
                    mat["specular"][1] = val
                elif key == "specb":
                    mat["specular"][2] = val
                elif key == "emitr":
                    mat["emission"][0] = val
                elif key == "emitg":
                    mat["emission"][1] = val
                elif key == "emitb":
                    mat["emission"][2] = val
                elif key == "shininess":
                    mat["shininess"] = val

        self.materials[name] = mat

    def _parse_vertex_pool(self, name, content):
        """Parse vertex pool block"""
        vertices = []

        # Find all <Vertex> blocks
        pos = 0
        while True:
            m = re.search(r"<Vertex>\s*(\d+)\s*{", content[pos:])
            if not m:
                break

            idx = int(m.group(1))
            start = pos + m.end()
            end = self._find_block_end(content, start - 1)
            vertex_content = content[start:end]

            vertex = self._parse_vertex(vertex_content)

            # Expand list if needed
            while len(vertices) <= idx:
                vertices.append(None)
            vertices[idx] = vertex

            pos = end + 1

        self.vertex_pools[name] = vertices

    def _parse_vertex(self, content):
        """Parse single vertex data"""
        vertex = {
            "pos": [0, 0, 0],
            "uv": [0, 0],
            "normal": [0, 1, 0],
            "rgba": [1, 1, 1, 1],
        }

        lines = content.strip().split("\n")
        if lines:
            # First line is position
            parts = lines[0].strip().split()
            if len(parts) >= 3:
                vertex["pos"] = [float(parts[0]), float(parts[1]), float(parts[2])]

        # Parse sub-elements
        for line in lines[1:]:
            line = line.strip()
            m = re.search(r"<UV>\s*{\s*([\d.e+-]+)\s+([\d.e+-]+)\s*}", line)
            if m:
                vertex["uv"] = [float(m.group(1)), float(m.group(2))]
                continue

            m = re.search(
                r"<Normal>\s*{\s*([\d.e+-]+)\s+([\d.e+-]+)\s+([\d.e+-]+)\s*}", line
            )
            if m:
                # Normalize the normal
                nx, ny, nz = float(m.group(1)), float(m.group(2)), float(m.group(3))
                length = (nx * nx + ny * ny + nz * nz) ** 0.5
                if length > 0.0001:
                    vertex["normal"] = [nx / length, ny / length, nz / length]
                continue

            m = re.search(
                r"<RGBA>\s*{\s*([\d.e+-]+)\s+([\d.e+-]+)\s+([\d.e+-]+)\s+([\d.e+-]+)\s*}",
                line,
            )
            if m:
                vertex["rgba"] = [
                    float(m.group(1)),
                    float(m.group(2)),
                    float(m.group(3)),
                    float(m.group(4)),
                ]

        return vertex

    def _parse_group(self, name, content):
        """Parse group block (contains polygons)"""
        group = {"name": name, "polygons": []}

        # Find all <Polygon> blocks
        pos = 0
        while True:
            m = re.search(r"<Polygon>\s*{", content[pos:])
            if not m:
                break

            start = pos + m.end()
            end = self._find_block_end(content, start - 1)
            polygon_content = content[start:end]

            polygon = self._parse_polygon(polygon_content)
            group["polygons"].append(polygon)

            pos = end + 1

        # Also recursively parse nested groups
        pos = 0
        while True:
            m = re.search(r"<Group>\s*(\S+)\s*{", content[pos:])
            if not m:
                break

            nested_name = m.group(1)
            start = pos + m.end()
            end = self._find_block_end(content, start - 1)
            nested_content = content[start:end]

            self._parse_group(f"{name}/{nested_name}", nested_content)

            pos = end + 1

        if group["polygons"]:
            self.groups.append(group)

    def _parse_polygon(self, content):
        """Parse polygon block"""
        polygon = {"texture_refs": [], "material_ref": None, "vertex_refs": []}

        for line in content.split("\n"):
            line = line.strip()

            # Texture reference
            m = re.search(r"<TRef>\s*{\s*(\S+)\s*}", line)
            if m:
                polygon["texture_refs"].append(m.group(1))
                continue

            # Material reference
            m = re.search(r"<MRef>\s*{\s*(\S+)\s*}", line)
            if m:
                polygon["material_ref"] = m.group(1)
                continue

            # Vertex reference
            m = re.search(r"<VertexRef>\s*{([^}]+)}", line)
            if m:
                ref_content = m.group(1)
                # Extract vertex indices (before <Ref>)
                ref_m = re.search(r"<Ref>", ref_content)
                if ref_m:
                    indices_str = ref_content[: ref_m.start()]
                else:
                    indices_str = ref_content
                indices = [int(x) for x in indices_str.split() if x.isdigit()]
                polygon["vertex_refs"] = indices

        return polygon


def generate_lua(parser, output_path):
    """Generate Lua module from parsed egg data"""

    lines = []
    lines.append("-- Generated by egg2lua.py")
    lines.append("-- Coordinate system: " + parser.coordinate_system)
    lines.append("")
    lines.append("local M = {}")
    lines.append("")

    # Textures
    lines.append("-- Texture definitions")
    lines.append("M.textures = {")
    for name, tex in parser.textures.items():
        safe_name = name.replace("-", "_")
        lines.append(f'  ["{safe_name}"] = {{')
        lines.append(f'    path = "{tex["path"]}",')
        lines.append(f'    wrap_u = "{tex["wrap_u"]}",')
        lines.append(f'    wrap_v = "{tex["wrap_v"]}",')
        lines.append(f'    envtype = "{tex["envtype"]}",')
        lines.append("  },")
    lines.append("}")
    lines.append("")

    # Materials
    lines.append("-- Material definitions")
    lines.append("M.materials = {")
    for name, mat in parser.materials.items():
        safe_name = name.replace("-", "_")
        lines.append(f'  ["{safe_name}"] = {{')
        lines.append(f"    diffuse = {{{mat['diffuse'][0]}, {mat['diffuse'][1]}, {mat['diffuse'][2]}}},")
        lines.append(f"    ambient = {{{mat['ambient'][0]}, {mat['ambient'][1]}, {mat['ambient'][2]}}},")
        lines.append(f"    specular = {{{mat['specular'][0]}, {mat['specular'][1]}, {mat['specular'][2]}}},")
        lines.append(f"    emission = {{{mat['emission'][0]}, {mat['emission'][1]}, {mat['emission'][2]}}},")
        lines.append(f"    shininess = {mat['shininess']},")
        lines.append("  },")
    lines.append("}")
    lines.append("")

    # Build meshes by material
    # For each group, collect polygons by material
    meshes_by_material = {}

    for group in parser.groups:
        for polygon in group["polygons"]:
            mat_name = polygon["material_ref"] or "default"
            if mat_name not in meshes_by_material:
                meshes_by_material[mat_name] = {
                    "vertices": [],
                    "indices": [],
                    "textures": [],
                }
            mesh = meshes_by_material[mat_name]

            # Get vertex pool (use first one for now)
            pool_name = list(parser.vertex_pools.keys())[0] if parser.vertex_pools else None
            if not pool_name:
                continue
            pool = parser.vertex_pools[pool_name]

            # Store texture refs (use first polygon's textures)
            if not mesh["textures"] and polygon["texture_refs"]:
                mesh["textures"] = polygon["texture_refs"]

            # Add vertices (may have duplicates, but simpler)
            base_idx = len(mesh["vertices"])
            for vi in polygon["vertex_refs"]:
                if vi < len(pool) and pool[vi]:
                    mesh["vertices"].append(pool[vi])

            # Add triangle indices
            # Polygons with 3 vertices are triangles
            # Polygons with more vertices need triangulation
            n = len(polygon["vertex_refs"])
            for i in range(1, n - 1):
                mesh["indices"].extend([base_idx, base_idx + i, base_idx + i + 1])

    # Write meshes
    lines.append("-- Mesh data (by material)")
    lines.append("M.meshes = {")
    for mat_name, mesh in meshes_by_material.items():
        safe_name = mat_name.replace("-", "_")
        lines.append(f'  ["{safe_name}"] = {{')

        # Texture references
        tex_refs = ", ".join(f'"{t.replace("-", "_")}"' for t in mesh["textures"])
        lines.append(f"    textures = {{{tex_refs}}},")

        # Vertices - pack as flat array for sokol
        # Format: pos(3) + normal(3) + uv(2) = 8 floats per vertex
        lines.append("    -- Format: x, y, z, nx, ny, nz, u, v")
        lines.append("    vertices = {")
        for v in mesh["vertices"]:
            p = v["pos"]
            n = v["normal"]
            uv = v["uv"]
            lines.append(f"      {p[0]}, {p[1]}, {p[2]}, {n[0]}, {n[1]}, {n[2]}, {uv[0]}, {uv[1]},")
        lines.append("    },")

        # Indices
        lines.append("    indices = {")
        for i in range(0, len(mesh["indices"]), 12):
            chunk = mesh["indices"][i : i + 12]
            lines.append("      " + ", ".join(str(x) for x in chunk) + ",")
        lines.append("    },")

        lines.append(f'    material = "{safe_name}",')
        lines.append(f"    vertex_count = {len(mesh['vertices'])},")
        lines.append(f"    index_count = {len(mesh['indices'])},")
        lines.append("  },")
    lines.append("}")
    lines.append("")

    lines.append("return M")
    lines.append("")

    with open(output_path, "w", encoding="utf-8") as f:
        f.write("\n".join(lines))


def main():
    if len(sys.argv) < 3:
        print("Usage: python egg2lua.py input.egg output.lua")
        sys.exit(1)

    input_path = sys.argv[1]
    output_path = sys.argv[2]

    print(f"Parsing {input_path}...")

    with open(input_path, "r", encoding="utf-8", errors="replace") as f:
        content = f.read()

    parser = EggParser()
    parser.parse(content)

    print(f"  Textures: {len(parser.textures)}")
    print(f"  Materials: {len(parser.materials)}")
    print(f"  Vertex pools: {len(parser.vertex_pools)}")
    print(f"  Groups: {len(parser.groups)}")

    total_polys = sum(len(g["polygons"]) for g in parser.groups)
    print(f"  Total polygons: {total_polys}")

    print(f"Generating {output_path}...")
    generate_lua(parser, output_path)
    print("Done!")


if __name__ == "__main__":
    main()
