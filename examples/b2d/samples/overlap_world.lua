-- overlap_world.lua - Box2D official Overlap World sample
-- Demonstrates AABB and shape overlap queries.
local b2d = require("b2d")
local draw = require("examples.b2d.draw")

local M = {}

M.camera = {
    center_x = 0,
    center_y = 5,
    zoom = 20,
}

local ground_id = nil
local body_ids = {}
local query_aabb = {lower = {-5, 2}, upper = {5, 8}}
local overlapping = {}

function M.create_scene(world)
    body_ids = {}
    overlapping = {}

    -- Ground
    local body_def = b2d.default_body_def()
    ground_id = b2d.create_body(world, body_def)

    local shape_def = b2d.default_shape_def()
    local segment = b2d.Segment({point1 = {-20, 0}, point2 = {20, 0}})
    b2d.create_segment_shape(ground_id, shape_def, segment)

    -- Create random shapes
    math.randomseed(42)

    for i = 1, 20 do
        body_def = b2d.default_body_def()
        body_def.type = b2d.BodyType.DYNAMICBODY
        body_def.position = {math.random() * 30 - 15, math.random() * 10 + 2}
        local body_id = b2d.create_body(world, body_def)

        shape_def = b2d.default_shape_def()

        if math.random() > 0.5 then
            local circle = b2d.Circle({center = {0, 0}, radius = 0.5 + math.random() * 0.5})
            b2d.create_circle_shape(body_id, shape_def, circle)
        else
            local box = b2d.make_box(0.3 + math.random() * 0.5, 0.3 + math.random() * 0.5)
            b2d.create_polygon_shape(body_id, shape_def, box)
        end

        table.insert(body_ids, body_id)
    end
end

M.controls = "Arrow keys: Move query AABB"

function M.update(world, dt)
    overlapping = {}

    -- Perform overlap query
    local aabb = b2d.AABB({
        lowerBound = query_aabb.lower,
        upperBound = query_aabb.upper
    })

    local results = b2d.world_overlap_aabb(world, aabb, b2d.default_query_filter())

    if results then
        for _, shape_id in ipairs(results) do
            local body_id = b2d.shape_get_body(shape_id)
            overlapping[tostring(body_id)] = true
        end
    end
end

function M.on_key(key, world)
    local app = require("sokol.app")
    local speed = 0.5

    if key == app.Keycode.LEFT then
        query_aabb.lower[1] = query_aabb.lower[1] - speed
        query_aabb.upper[1] = query_aabb.upper[1] - speed
    elseif key == app.Keycode.RIGHT then
        query_aabb.lower[1] = query_aabb.lower[1] + speed
        query_aabb.upper[1] = query_aabb.upper[1] + speed
    elseif key == app.Keycode.UP then
        query_aabb.lower[2] = query_aabb.lower[2] + speed
        query_aabb.upper[2] = query_aabb.upper[2] + speed
    elseif key == app.Keycode.DOWN then
        query_aabb.lower[2] = query_aabb.lower[2] - speed
        query_aabb.upper[2] = query_aabb.upper[2] - speed
    end
end

function M.render(camera, world)
    -- Draw ground
    draw.line(-20, 0, 20, 0, draw.colors.static)

    -- Draw query AABB
    local lx, ly = query_aabb.lower[1], query_aabb.lower[2]
    local ux, uy = query_aabb.upper[1], query_aabb.upper[2]
    draw.line(lx, ly, ux, ly, {0, 1, 0, 0.7})
    draw.line(ux, ly, ux, uy, {0, 1, 0, 0.7})
    draw.line(ux, uy, lx, uy, {0, 1, 0, 0.7})
    draw.line(lx, uy, lx, ly, {0, 1, 0, 0.7})

    -- Draw bodies
    for _, body_id in ipairs(body_ids) do
        if b2d.body_is_valid(body_id) then
            local pos = b2d.body_get_position(body_id)
            local rot = b2d.body_get_rotation(body_id)
            local angle = b2d.rot_get_angle(rot)

            local is_overlapping = overlapping[tostring(body_id)]
            local color = is_overlapping and {1, 0.3, 0.3, 1} or draw.colors.dynamic

            draw.solid_circle(pos[1], pos[2], 0.5, color)
            draw.circle(pos[1], pos[2], 0.5, {0, 0, 0, 1})
        end
    end
end

function M.cleanup()
    ground_id = nil
    body_ids = {}
    overlapping = {}
end

return M
