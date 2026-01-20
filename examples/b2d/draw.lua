-- draw.lua - sokol.gl based 2D physics drawing utilities
local sgl = require("sokol.gl")

local M = {}

-- Colors
M.colors = {
    static = {0.5, 0.9, 0.5, 1.0},
    kinematic = {0.5, 0.5, 0.9, 1.0},
    dynamic = {0.9, 0.7, 0.7, 1.0},
    sleeping = {0.6, 0.6, 0.6, 1.0},
    joint = {0.0, 0.8, 0.8, 1.0},
    aabb = {0.9, 0.3, 0.9, 0.5},
    contact = {0.9, 0.9, 0.3, 1.0},
}

function M.setup()
    sgl.setup(sgl.Desc({
        max_vertices = 65536,
        max_commands = 16384,
    }))
end

function M.begin_frame(camera)
    sgl.defaults()
    sgl.matrix_mode_projection()
    local b = camera:get_bounds()
    sgl.ortho(b.left, b.right, b.bottom, b.top, -1, 1)
    sgl.matrix_mode_modelview()
    sgl.load_identity()
end

function M.set_color(c)
    sgl.c4f(c[1], c[2], c[3], c[4] or 1.0)
end

function M.point(x, y, size, color)
    M.set_color(color or {1, 1, 1, 1})
    local hs = size * 0.5
    sgl.begin_quads()
    sgl.v2f(x - hs, y - hs)
    sgl.v2f(x + hs, y - hs)
    sgl.v2f(x + hs, y + hs)
    sgl.v2f(x - hs, y + hs)
    sgl.end_()
end

function M.line(x1, y1, x2, y2, color)
    M.set_color(color or {1, 1, 1, 1})
    sgl.begin_lines()
    sgl.v2f(x1, y1)
    sgl.v2f(x2, y2)
    sgl.end_()
end

function M.circle(cx, cy, radius, color, segments)
    segments = segments or 32
    M.set_color(color or {1, 1, 1, 1})
    sgl.begin_line_strip()
    for i = 0, segments do
        local angle = (i / segments) * math.pi * 2
        local x = cx + math.cos(angle) * radius
        local y = cy + math.sin(angle) * radius
        sgl.v2f(x, y)
    end
    sgl.end_()
end

function M.solid_circle(cx, cy, radius, color, segments)
    segments = segments or 32
    M.set_color(color or {1, 1, 1, 1})
    sgl.begin_triangles()
    for i = 0, segments - 1 do
        local angle1 = (i / segments) * math.pi * 2
        local angle2 = ((i + 1) / segments) * math.pi * 2
        sgl.v2f(cx, cy)
        sgl.v2f(cx + math.cos(angle1) * radius, cy + math.sin(angle1) * radius)
        sgl.v2f(cx + math.cos(angle2) * radius, cy + math.sin(angle2) * radius)
    end
    sgl.end_()
end

-- Draw circle with rotation indicator
function M.solid_circle_axis(cx, cy, radius, rot, color, segments)
    segments = segments or 32
    M.solid_circle(cx, cy, radius, color, segments)
    -- Draw axis line
    local ax = cx + rot[1] * radius
    local ay = cy + rot[2] * radius
    M.line(cx, cy, ax, ay, {0, 0, 0, 1})
end

function M.box(cx, cy, hw, hh, angle, color)
    local c, s = math.cos(angle), math.sin(angle)
    local corners = {
        {-hw, -hh}, {hw, -hh}, {hw, hh}, {-hw, hh}
    }
    M.set_color(color or {1, 1, 1, 1})
    sgl.begin_line_strip()
    for i = 1, 5 do
        local idx = ((i - 1) % 4) + 1
        local lx, ly = corners[idx][1], corners[idx][2]
        local x = cx + lx * c - ly * s
        local y = cy + lx * s + ly * c
        sgl.v2f(x, y)
    end
    sgl.end_()
end

function M.solid_box(cx, cy, hw, hh, angle, color)
    local c, s = math.cos(angle), math.sin(angle)
    local corners = {
        {-hw, -hh}, {hw, -hh}, {hw, hh}, {-hw, hh}
    }
    M.set_color(color or {1, 1, 1, 1})
    sgl.begin_quads()
    for i = 1, 4 do
        local lx, ly = corners[i][1], corners[i][2]
        local x = cx + lx * c - ly * s
        local y = cy + lx * s + ly * c
        sgl.v2f(x, y)
    end
    sgl.end_()
end

-- Rounded box outline
function M.rounded_box(cx, cy, hw, hh, radius, angle, color, segments)
    segments = segments or 8
    local c, s = math.cos(angle), math.sin(angle)
    local function transform(lx, ly)
        return cx + lx * c - ly * s, cy + lx * s + ly * c
    end

    M.set_color(color or {1, 1, 1, 1})
    sgl.begin_line_strip()

    -- Inner box dimensions (without radius)
    local ihw, ihh = hw - radius, hh - radius

    -- Bottom-right corner arc
    for i = 0, segments do
        local a = -math.pi / 2 + (i / segments) * (math.pi / 2)
        local lx = ihw + math.cos(a) * radius
        local ly = -ihh + math.sin(a) * radius
        local x, y = transform(lx, ly)
        sgl.v2f(x, y)
    end
    -- Top-right corner arc
    for i = 0, segments do
        local a = 0 + (i / segments) * (math.pi / 2)
        local lx = ihw + math.cos(a) * radius
        local ly = ihh + math.sin(a) * radius
        local x, y = transform(lx, ly)
        sgl.v2f(x, y)
    end
    -- Top-left corner arc
    for i = 0, segments do
        local a = math.pi / 2 + (i / segments) * (math.pi / 2)
        local lx = -ihw + math.cos(a) * radius
        local ly = ihh + math.sin(a) * radius
        local x, y = transform(lx, ly)
        sgl.v2f(x, y)
    end
    -- Bottom-left corner arc
    for i = 0, segments do
        local a = math.pi + (i / segments) * (math.pi / 2)
        local lx = -ihw + math.cos(a) * radius
        local ly = -ihh + math.sin(a) * radius
        local x, y = transform(lx, ly)
        sgl.v2f(x, y)
    end
    -- Close: back to first vertex (Bottom-right arc start: a = -pi/2)
    local x, y = transform(ihw, -ihh - radius)
    sgl.v2f(x, y)

    sgl.end_()
end

-- Solid rounded box
function M.solid_rounded_box(cx, cy, hw, hh, radius, angle, color, segments)
    segments = segments or 8
    local c, s = math.cos(angle), math.sin(angle)
    local function transform(lx, ly)
        return cx + lx * c - ly * s, cy + lx * s + ly * c
    end

    M.set_color(color or {1, 1, 1, 1})

    -- Inner box dimensions
    local ihw, ihh = hw - radius, hh - radius

    -- Build outline vertices
    local verts = {}
    -- Bottom-right corner arc
    for i = 0, segments do
        local a = -math.pi / 2 + (i / segments) * (math.pi / 2)
        local lx = ihw + math.cos(a) * radius
        local ly = -ihh + math.sin(a) * radius
        table.insert(verts, {transform(lx, ly)})
    end
    -- Top-right corner arc
    for i = 0, segments do
        local a = 0 + (i / segments) * (math.pi / 2)
        local lx = ihw + math.cos(a) * radius
        local ly = ihh + math.sin(a) * radius
        table.insert(verts, {transform(lx, ly)})
    end
    -- Top-left corner arc
    for i = 0, segments do
        local a = math.pi / 2 + (i / segments) * (math.pi / 2)
        local lx = -ihw + math.cos(a) * radius
        local ly = ihh + math.sin(a) * radius
        table.insert(verts, {transform(lx, ly)})
    end
    -- Bottom-left corner arc
    for i = 0, segments do
        local a = math.pi + (i / segments) * (math.pi / 2)
        local lx = -ihw + math.cos(a) * radius
        local ly = -ihh + math.sin(a) * radius
        table.insert(verts, {transform(lx, ly)})
    end

    -- Draw as triangle fan from first vertex (no center point)
    sgl.begin_triangles()
    for i = 2, #verts - 1 do
        sgl.v2f(verts[1][1], verts[1][2])
        sgl.v2f(verts[i][1], verts[i][2])
        sgl.v2f(verts[i + 1][1], verts[i + 1][2])
    end
    sgl.end_()
end

-- Accepts either (p1, p2, radius, color) or (x1, y1, x2, y2, radius, color)
function M.capsule(p1_or_x1, p2_or_y1, radius_or_x2, color_or_y2, radius_opt, color_opt)
    local x1, y1, x2, y2, radius, color
    if type(p1_or_x1) == "table" then
        -- (p1, p2, radius, color) format
        x1, y1 = p1_or_x1[1], p1_or_x1[2]
        x2, y2 = p2_or_y1[1], p2_or_y1[2]
        radius = radius_or_x2
        color = color_or_y2
    else
        -- (x1, y1, x2, y2, radius, color) format
        x1, y1 = p1_or_x1, p2_or_y1
        x2, y2 = radius_or_x2, color_or_y2
        radius = radius_opt
        color = color_opt
    end

    local segments = 16
    M.set_color(color or {1, 1, 1, 1})

    local dx = x2 - x1
    local dy = y2 - y1
    local len = math.sqrt(dx * dx + dy * dy)
    if len < 1e-6 then
        M.circle(x1, y1, radius, color, segments * 2)
        return
    end
    local nx, ny = dx / len, dy / len
    local px, py = -ny, nx

    sgl.begin_line_strip()
    -- First semicircle
    for i = 0, segments do
        local angle = math.pi * 0.5 + (i / segments) * math.pi
        local ax = math.cos(angle) * nx - math.sin(angle) * px
        local ay = math.cos(angle) * ny - math.sin(angle) * py
        sgl.v2f(x1 + ax * radius, y1 + ay * radius)
    end
    -- Second semicircle
    for i = 0, segments do
        local angle = -math.pi * 0.5 + (i / segments) * math.pi
        local ax = math.cos(angle) * nx - math.sin(angle) * px
        local ay = math.cos(angle) * ny - math.sin(angle) * py
        sgl.v2f(x2 + ax * radius, y2 + ay * radius)
    end
    -- Close
    local angle = math.pi * 0.5
    local ax = math.cos(angle) * nx - math.sin(angle) * px
    local ay = math.cos(angle) * ny - math.sin(angle) * py
    sgl.v2f(x1 + ax * radius, y1 + ay * radius)
    sgl.end_()
end

-- Accepts either (p1, p2, radius, color) or (x1, y1, x2, y2, radius, color)
function M.solid_capsule(p1_or_x1, p2_or_y1, radius_or_x2, color_or_y2, radius_opt, color_opt)
    local x1, y1, x2, y2, radius, color
    if type(p1_or_x1) == "table" then
        -- (p1, p2, radius, color) format
        x1, y1 = p1_or_x1[1], p1_or_x1[2]
        x2, y2 = p2_or_y1[1], p2_or_y1[2]
        radius = radius_or_x2
        color = color_or_y2
    else
        -- (x1, y1, x2, y2, radius, color) format
        x1, y1 = p1_or_x1, p2_or_y1
        x2, y2 = radius_or_x2, color_or_y2
        radius = radius_opt
        color = color_opt
    end

    local segments = 16
    M.set_color(color or {1, 1, 1, 1})

    local dx = x2 - x1
    local dy = y2 - y1
    local len = math.sqrt(dx * dx + dy * dy)
    if len < 1e-6 then
        M.solid_circle(x1, y1, radius, color, segments * 2)
        return
    end
    local nx, ny = dx / len, dy / len
    local px, py = -ny, nx

    -- Build vertex list for capsule outline
    local verts = {}
    -- First semicircle
    for i = 0, segments do
        local angle = math.pi * 0.5 + (i / segments) * math.pi
        local ax = math.cos(angle) * nx - math.sin(angle) * px
        local ay = math.cos(angle) * ny - math.sin(angle) * py
        table.insert(verts, {x1 + ax * radius, y1 + ay * radius})
    end
    -- Second semicircle
    for i = 0, segments do
        local angle = -math.pi * 0.5 + (i / segments) * math.pi
        local ax = math.cos(angle) * nx - math.sin(angle) * px
        local ay = math.cos(angle) * ny - math.sin(angle) * py
        table.insert(verts, {x2 + ax * radius, y2 + ay * radius})
    end

    -- Draw as triangles from center
    local cx = (x1 + x2) * 0.5
    local cy = (y1 + y2) * 0.5
    sgl.begin_triangles()
    for i = 1, #verts - 1 do
        sgl.v2f(cx, cy)
        sgl.v2f(verts[i][1], verts[i][2])
        sgl.v2f(verts[i + 1][1], verts[i + 1][2])
    end
    -- Close
    sgl.v2f(cx, cy)
    sgl.v2f(verts[#verts][1], verts[#verts][2])
    sgl.v2f(verts[1][1], verts[1][2])
    sgl.end_()
end

function M.polygon(vertices, color)
    if #vertices < 2 then return end
    M.set_color(color or {1, 1, 1, 1})
    sgl.begin_line_strip()
    for i = 1, #vertices do
        sgl.v2f(vertices[i][1], vertices[i][2])
    end
    sgl.v2f(vertices[1][1], vertices[1][2])
    sgl.end_()
end

function M.solid_polygon(vertices, color)
    if #vertices < 3 then return end
    M.set_color(color or {1, 1, 1, 1})
    -- Draw as triangles (fan from first vertex)
    sgl.begin_triangles()
    for i = 2, #vertices - 1 do
        sgl.v2f(vertices[1][1], vertices[1][2])
        sgl.v2f(vertices[i][1], vertices[i][2])
        sgl.v2f(vertices[i + 1][1], vertices[i + 1][2])
    end
    sgl.end_()
end

-- Transform polygon vertices by b2Transform {{px, py}, {c, s}}
function M.transform_polygon(vertices, transform)
    local px, py = transform[1][1], transform[1][2]
    local c, s = transform[2][1], transform[2][2]
    local result = {}
    for i = 1, #vertices do
        local x, y = vertices[i][1], vertices[i][2]
        result[i] = {
            px + x * c - y * s,
            py + x * s + y * c
        }
    end
    return result
end

function M.segment(p1, p2, color)
    M.line(p1[1], p1[2], p2[1], p2[2], color)
end

function M.transform(tf, scale)
    scale = scale or 1.0
    local px, py = tf[1][1], tf[1][2]
    local c, s = tf[2][1], tf[2][2]
    -- X axis (red)
    M.line(px, py, px + c * scale, py + s * scale, {1, 0, 0, 1})
    -- Y axis (green)
    M.line(px, py, px - s * scale, py + c * scale, {0, 1, 0, 1})
end

function M.aabb(aabb, color)
    local lx, ly = aabb[1][1], aabb[1][2]
    local ux, uy = aabb[2][1], aabb[2][2]
    M.set_color(color or M.colors.aabb)
    sgl.begin_line_strip()
    sgl.v2f(lx, ly)
    sgl.v2f(ux, ly)
    sgl.v2f(ux, uy)
    sgl.v2f(lx, uy)
    sgl.v2f(lx, ly)
    sgl.end_()
end

function M.end_frame()
    sgl.draw()
end

function M.shutdown()
    sgl.shutdown()
end

return M
