-- segment_slide.lua - Box2D official Segment Slide sample
-- Ball sliding at high speed along segment shape
local b2d = require("b2d")
local draw = require("examples.b2d.draw")

local M = {}

M.camera = {
    center_x = 0,
    center_y = 10,
    zoom = 15,
}

local ground_id = nil
local ball_id = nil

function M.create_scene(world)
    -- Ground segment
    local body_def = b2d.default_body_def()
    ground_id = b2d.create_body(world, body_def)

    local shape_def = b2d.default_shape_def()

    -- Floor segment
    local segment = b2d.Segment({point1 = {-40, 0}, point2 = {40, 0}})
    b2d.create_segment_shape(ground_id, shape_def, segment)

    -- Wall at end
    segment = b2d.Segment({point1 = {40, 0}, point2 = {40, 10}})
    b2d.create_segment_shape(ground_id, shape_def, segment)

    -- Ball with high velocity
    body_def = b2d.default_body_def()
    body_def.type = b2d.BodyType.DYNAMICBODY
    body_def.linearVelocity = {100, 0}
    body_def.position = {-20, 0.7}
    ball_id = b2d.create_body(world, body_def)

    local circle = b2d.Circle({center = {0, 0}, radius = 0.5})
    b2d.create_circle_shape(ball_id, shape_def, circle)
end

function M.render(camera, world)
    -- Draw segments
    draw.line(-40, 0, 40, 0, draw.colors.static)
    draw.line(40, 0, 40, 10, draw.colors.static)

    -- Draw ball
    if ball_id and b2d.body_is_valid(ball_id) then
        local pos = b2d.body_get_position(ball_id)
        draw.solid_circle(pos[1], pos[2], 0.5, draw.colors.dynamic)
        draw.circle(pos[1], pos[2], 0.5, {0, 0, 0, 1})
    end
end

function M.cleanup()
    ground_id = nil
    ball_id = nil
end

return M
