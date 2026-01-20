-- ghost_bumps.lua - Box2D official Ghost Bumps sample
-- Demonstrates ghost collision prevention
local b2d = require("b2d")
local draw = require("examples.b2d.draw")

local M = {}

M.camera = {
    center_x = 0,
    center_y = 3,
    zoom = 10,
}

local ground_id = nil
local body_ids = {}

function M.create_scene(world)
    body_ids = {}

    -- Ground made of multiple segments (potential ghost collision areas)
    local body_def = b2d.default_body_def()
    ground_id = b2d.create_body(world, body_def)

    local shape_def = b2d.default_shape_def()

    -- Create a series of connected segments
    local points = {
        {-10, 0},
        {-5, 0},
        {-3, 0.5},
        {0, 0},
        {3, -0.5},
        {5, 0},
        {10, 0},
    }

    for i = 1, #points - 1 do
        local segment = b2d.Segment({point1 = points[i], point2 = points[i+1]})
        b2d.create_segment_shape(ground_id, shape_def, segment)
    end

    -- Create fast moving ball
    body_def = b2d.default_body_def()
    body_def.type = b2d.BodyType.DYNAMICBODY
    body_def.position = {-8, 2}
    body_def.linearVelocity = {20, 0}
    local ball = b2d.create_body(world, body_def)

    local circle = b2d.Circle({center = {0, 0}, radius = 0.5})
    b2d.create_circle_shape(ball, shape_def, circle)
    table.insert(body_ids, ball)

    -- Create another ball
    body_def.position = {-6, 2}
    body_def.linearVelocity = {15, 0}
    ball = b2d.create_body(world, body_def)
    b2d.create_circle_shape(ball, shape_def, circle)
    table.insert(body_ids, ball)
end

function M.render(camera, world)
    -- Draw ground segments
    local points = {
        {-10, 0},
        {-5, 0},
        {-3, 0.5},
        {0, 0},
        {3, -0.5},
        {5, 0},
        {10, 0},
    }

    for i = 1, #points - 1 do
        draw.line(points[i][1], points[i][2], points[i+1][1], points[i+1][2], draw.colors.static)
    end

    -- Mark joint points (potential ghost collision locations)
    for i = 2, #points - 1 do
        draw.point(points[i][1], points[i][2], 6, {1, 1, 0, 1})
    end

    -- Draw balls
    for _, body_id in ipairs(body_ids) do
        if b2d.body_is_valid(body_id) then
            local pos = b2d.body_get_position(body_id)
            local color = b2d.body_is_awake(body_id) and draw.colors.dynamic or draw.colors.sleeping
            draw.solid_circle(pos[1], pos[2], 0.5, color)
            draw.circle(pos[1], pos[2], 0.5, {0, 0, 0, 1})
        end
    end
end

function M.cleanup()
    ground_id = nil
    body_ids = {}
end

return M
