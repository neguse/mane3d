-- wedge.lua - Box2D official Wedge sample
-- Demonstrates continuous physics with acute angle wedge
local b2d = require("b2d")
local draw = require("examples.b2d.draw")

local M = {}

M.camera = {
    center_x = 0,
    center_y = 5.5,
    zoom = 6,
}

local ground_id = nil
local ball_id = nil

function M.create_scene(world)
    -- Ground wedge shape
    local body_def = b2d.default_body_def()
    ground_id = b2d.create_body(world, body_def)

    local shape_def = b2d.default_shape_def()

    -- Left diagonal wall
    local segment = b2d.Segment({point1 = {-4, 8}, point2 = {0, 0}})
    b2d.create_segment_shape(ground_id, shape_def, segment)

    -- Vertical wall
    segment = b2d.Segment({point1 = {0, 0}, point2 = {0, 8}})
    b2d.create_segment_shape(ground_id, shape_def, segment)

    -- Fast falling ball
    body_def = b2d.default_body_def()
    body_def.type = b2d.BodyType.DYNAMICBODY
    body_def.position = {-0.45, 10.75}
    body_def.linearVelocity = {0, -200}
    ball_id = b2d.create_body(world, body_def)

    shape_def = b2d.default_shape_def()
    shape_def.friction = 0.2
    local circle = b2d.Circle({center = {0, 0}, radius = 0.3})
    b2d.create_circle_shape(ball_id, shape_def, circle)
end

function M.render(camera, world)
    -- Draw wedge
    draw.line(-4, 8, 0, 0, draw.colors.static)
    draw.line(0, 0, 0, 8, draw.colors.static)

    -- Draw ball
    if ball_id and b2d.body_is_valid(ball_id) then
        local pos = b2d.body_get_position(ball_id)
        local color = b2d.body_is_awake(ball_id) and draw.colors.dynamic or draw.colors.sleeping
        draw.solid_circle(pos[1], pos[2], 0.3, color)
        draw.circle(pos[1], pos[2], 0.3, {0, 0, 0, 1})
    end
end

function M.cleanup()
    ground_id = nil
    ball_id = nil
end

return M
