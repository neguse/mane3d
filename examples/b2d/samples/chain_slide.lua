-- chain_slide.lua - Box2D official Chain Slide sample
-- Ball sliding at high speed along chain shape
local b2d = require("b2d")
local draw = require("examples.b2d.draw")

local M = {}

M.camera = {
    center_x = 0,
    center_y = 10,
    zoom = 25,
}

local ground_id = nil
local ball_id = nil

function M.create_scene(world)
    -- Ground with chain shape
    local body_def = b2d.default_body_def()
    ground_id = b2d.create_body(world, body_def)

    -- Create chain points
    local points = {}
    for i = 0, 40 do
        table.insert(points, {-20 + i, 0})
    end
    -- Add wall at end
    table.insert(points, {20, 10})

    local chain_def = b2d.default_chain_def()
    chain_def.points = points
    chain_def.count = #points
    chain_def.isLoop = false
    b2d.create_chain(ground_id, chain_def)

    -- Ball with high velocity
    body_def = b2d.default_body_def()
    body_def.type = b2d.BodyType.DYNAMICBODY
    body_def.linearVelocity = {100, 0}
    body_def.position = {-19.5, 0.5}
    ball_id = b2d.create_body(world, body_def)

    local shape_def = b2d.default_shape_def()
    shape_def.friction = 0
    local circle = b2d.Circle({center = {0, 0}, radius = 0.5})
    b2d.create_circle_shape(ball_id, shape_def, circle)
end

function M.render(camera, world)
    -- Draw chain
    for i = -20, 19 do
        draw.line(i, 0, i + 1, 0, draw.colors.static)
    end
    draw.line(20, 0, 20, 10, draw.colors.static)

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
