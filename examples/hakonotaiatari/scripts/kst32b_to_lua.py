#!/usr/bin/env python3
"""
Convert KST32B.TXT (CSF1 vector font) to Lua table format.
Based on original csf1.py from hakonotaiatari.
"""

import sys
import os

def parse_command(c):
    """Parse a single CSF1 byte into a command."""
    command = None
    if c == 0x20:
        command = {"type": "TERMINATE", "arg": None}
    elif 0x21 <= c <= 0x26:
        x = c - 0x21
        command = {"type": "MOVE_X", "arg": x}
    elif 0x28 <= c <= 0x3f:
        x = c - 0x21 - 1
        command = {"type": "MOVE_X", "arg": x}
    elif 0x40 <= c <= 0x5b:
        nx = c - 0x40
        command = {"type": "DRAW_X", "arg": nx}
    elif 0x5e <= c <= 0x5f:
        nx = c - 0x40 - 2
        command = {"type": "DRAW_X", "arg": nx}
    elif 0x60 <= c <= 0x7d:
        nx = c - 0x60
        command = {"type": "NEXT_X", "arg": nx}
    elif c == 0x7e:
        y = 0
        command = {"type": "MOVE_Y", "arg": y}
    elif 0xa1 <= c <= 0xbf:
        y = c - 0xa0
        command = {"type": "MOVE_Y", "arg": y}
    elif 0xc0 <= c <= 0xdf:
        y = c - 0xc0
        command = {"type": "DRAW_Y", "arg": y}
    return command


def parse_commands(data):
    """Parse byte sequence into list of commands."""
    return [parse_command(c) for c in data]


def create_array(commands):
    """Convert commands to vertex buffer and index buffer."""
    vb = []
    ib = []
    x = 0
    y = 0
    next_x = None

    def draw(x2, y2):
        nonlocal x, y
        c1 = (x, y)
        c2 = (x2, y2)

        if c1 not in vb:
            vb.append(c1)
        if c2 not in vb:
            vb.append(c2)

        i1 = vb.index(c1)
        i2 = vb.index(c2)

        ib.append((i1, i2))
        x, y = x2, y2

    for c in commands:
        if c:
            t = c["type"]
            arg = c["arg"]
            if t == 'TERMINATE':
                break
            elif t == 'MOVE_X':
                x = arg
            elif t == 'MOVE_Y':
                y = arg
            elif t == 'DRAW_X':
                draw(arg, y)
            elif t == 'DRAW_Y':
                if next_x is None:
                    next_x = x
                draw(next_x, arg)
                next_x = None
            elif t == 'NEXT_X':
                next_x = arg

    return vb, ib


def to_unicode(code_bytes):
    """Convert KST32B character code to Unicode."""
    one = int(code_bytes[0:2], 16)
    two = int(code_bytes[2:4], 16)

    if one == 0x1a:
        return 0
    if one == 0:
        return two
    else:
        one += 0x80
        two += 0x80
        try:
            ch = bytes([one, two]).decode("euc-jp")
        except:
            return 0
        if len(ch) > 1:
            return 0
        else:
            return ord(ch)


def parse_file(path):
    """Parse KST32B.TXT file and return glyph data."""
    data = {}
    for line in open(path, 'rb'):
        if line[0] == ord('*'):
            continue
        code = to_unicode(line[0:4])
        if code != 0:
            commands = parse_commands(line[5:].strip())
            vb, ib = create_array(commands)
            if len(vb) > 0 and len(ib) > 0:
                data[code] = {'vertices': vb, 'lines': ib}
    return data


def normalize_vertex(vx, vy):
    """Normalize vertex from 30x32 grid to -0.5..0.5 range (centered)."""
    # Scale to -0.5..0.5 range so glyph is centered at origin
    nx = (vx / 30.0) - 0.5
    ny = (vy / 32.0) - 0.5  # Y increases downward in original, flip for OpenGL
    return nx, ny


def format_lua_key(char_code):
    """Format character code as Lua table key."""
    if 0x20 <= char_code <= 0x7E:
        char = chr(char_code)
        if char == '"':
            return '[\'"\']'
        elif char == '\\':
            return '["\\\\"]'
        elif char == "'":
            return "[\"'\"]"
        elif char == '[' or char == ']':
            return f'[{char_code}]'
        else:
            return f'["{char}"]'
    else:
        return f'[{char_code}]'


def generate_lua_file(glyphs, output_path):
    """Generate the complete Lua font file."""
    lua_content = '''-- hakonotaiatari font data
-- Auto-generated from KST32B.TXT
-- CSF1 vector font by Saka.N

local gl = require("sokol.gl")

local M = {}

-- Glyph definitions: vertices (normalized -1..1) and line indices (1-based)
local glyphs = {
'''

    # Sort by character code
    for char_code in sorted(glyphs.keys()):
        glyph = glyphs[char_code]
        vertices = glyph['vertices']
        lines = glyph['lines']

        key = format_lua_key(char_code)

        # Format vertices (normalized)
        vert_strs = []
        for vx, vy in vertices:
            nx, ny = normalize_vertex(vx, vy)
            vert_strs.append(f'{{{nx:.3f}, {ny:.3f}}}')

        # Format lines (1-based indices for Lua)
        line_strs = []
        for i1, i2 in lines:
            line_strs.append(f'{{{i1 + 1}, {i2 + 1}}}')

        lua_content += f'    {key} = {{\n'
        lua_content += f'        v = {{ {", ".join(vert_strs)} }},\n'
        lua_content += f'        l = {{ {", ".join(line_strs)} }},\n'
        lua_content += f'    }},\n'

    lua_content += '''}

-- Default glyph dimensions
local GLYPH_WIDTH = 0.8
local GLYPH_SPACING = 0.2

-- Initialize font (no-op)
function M.init()
end

-- Get glyph by character
local function get_glyph(char)
    if type(char) == "string" and #char >= 1 then
        -- Try direct lookup
        local g = glyphs[char]
        if g then return g end
        -- Try by byte code
        local code = string.byte(char)
        return glyphs[code]
    elseif type(char) == "number" then
        return glyphs[char]
    end
    return nil
end

-- Draw a single glyph at position (x, y) with scale and color (2D UI)
function M.draw_glyph(char, x, y, scale, r, g, b)
    local glyph = get_glyph(char)

    if not glyph or not glyph.v or #glyph.v == 0 then
        return GLYPH_WIDTH * scale
    end

    gl.begin_lines()
    for _, line in ipairs(glyph.l) do
        local v1 = glyph.v[line[1]]
        local v2 = glyph.v[line[2]]
        if v1 and v2 then
            gl.v3f_c3f(x + v1[1] * scale, y + v1[2] * scale, 0, r, g, b)
            gl.v3f_c3f(x + v2[1] * scale, y + v2[2] * scale, 0, r, g, b)
        end
    end
    gl["end"]()

    return GLYPH_WIDTH * scale
end

-- Draw text string at position (x, y) with scale and color
function M.draw_text(text, x, y, scale, r, g, b)
    local total_width = 0
    local char_width = (GLYPH_WIDTH + GLYPH_SPACING) * scale

    for i = 1, #text do
        local char = text:sub(i, i):upper()
        M.draw_glyph(char, x + total_width, y, scale, r, g, b)
        total_width = total_width + char_width
    end

    return total_width
end

-- Draw text centered at position
function M.draw_text_centered(text, x, y, scale, r, g, b)
    local char_width = (GLYPH_WIDTH + GLYPH_SPACING) * scale
    local total_width = #text * char_width
    return M.draw_text(text, x - total_width / 2, y, scale, r, g, b)
end

-- Draw number (simple, no leading zeros)
function M.draw_number(num, x, y, scale, r, g, b)
    local str = tostring(math.floor(num))
    return M.draw_text(str, x, y, scale, r, g, b)
end

-- Draw number centered
function M.draw_number_centered(num, x, y, scale, r, g, b)
    local str = tostring(math.floor(num))
    return M.draw_text_centered(str, x, y, scale, r, g, b)
end

-- Calculate text width
function M.text_width(text, scale)
    local char_width = (GLYPH_WIDTH + GLYPH_SPACING) * scale
    return #text * char_width
end

return M
'''

    with open(output_path, 'w', encoding='utf-8') as f:
        f.write(lua_content)

    print(f"Generated {output_path} with {len(glyphs)} glyphs")


def main():
    script_dir = os.path.dirname(os.path.abspath(__file__))
    input_path = os.path.join(script_dir, '..', 'deps', 'hakonotaiatari', 'src', 'KST32B.TXT')
    output_path = os.path.join(script_dir, '..', 'examples', 'hakonotaiatari', 'font.lua')

    if len(sys.argv) > 1:
        input_path = sys.argv[1]
    if len(sys.argv) > 2:
        output_path = sys.argv[2]

    print(f"Parsing {input_path}...")
    glyphs = parse_file(input_path)

    print(f"Found {len(glyphs)} glyphs")
    generate_lua_file(glyphs, output_path)


if __name__ == '__main__':
    main()
