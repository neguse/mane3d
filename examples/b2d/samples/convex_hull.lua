-- convex_hull.lua - Box2D official Convex Hull sample
-- Demonstrates computing convex hulls from random point sets.
local b2d = require("b2d")
local draw = require("examples.b2d.draw")

local M = {}

M.camera = {
    center_x = 0.5,
    center_y = 0,
    zoom = 7.5,
}

local max_points = 8  -- B2_MAX_POLYGON_VERTICES
local points = {}
local hull = nil
local generation = 0

local function generate()
    points = {}

    -- Generate random points within a clamped region
    local angle = math.pi * math.random()
    local c, s = math.cos(angle), math.sin(angle)

    for i = 1, max_points do
        local x = math.random() * 8 - 4  -- [-4, 4]
        local y = math.random() * 8 - 4

        -- Clamp to square to create collinearities
        x = math.max(-4, math.min(4, x))
        y = math.max(-4, math.min(4, y))

        -- Rotate
        local rx = c * x - s * y
        local ry = s * x + c * y

        points[i] = {rx, ry}
    end

    -- Compute convex hull
    hull = b2d.compute_hull(points)
    generation = generation + 1
end

function M.create_scene(world)
    generation = 0
    generate()
end

M.controls = "G: Generate new hull"

function M.on_key(key, world)
    local app = require("sokol.app")

    if key == app.Keycode.G then
        generate()
    end
end

function M.render(camera, world)
    -- Draw input points
    for i, pt in ipairs(points) do
        draw.point(pt[1], pt[2], 6, {0.5, 0.5, 0.9, 1})
    end

    -- Draw convex hull
    if hull and hull.count and hull.count > 0 then
        local hull_points = hull.points

        -- Draw hull edges
        if hull_points and #hull_points >= 2 then
            for i = 1, #hull_points do
                local j = (i % #hull_points) + 1
                local p1 = hull_points[i]
                local p2 = hull_points[j]

                draw.line(p1[1], p1[2], p2[1], p2[2], {0.3, 0.9, 0.3, 1})
            end

            -- Draw hull vertices
            for i, pt in ipairs(hull_points) do
                draw.point(pt[1], pt[2], 8, {0.9, 0.3, 0.3, 1})
            end
        end
    end

    -- Draw generation count indicator
    draw.point(-6, 5, 3, {1, 1, 1, 1})
end

function M.cleanup()
    points = {}
    hull = nil
    generation = 0
end

return M
