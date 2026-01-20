-- set_velocity.lua - Box2D official Set Velocity sample
-- Demonstrates setting linear velocity every frame
local b2d = require("b2d")
local draw = require("examples.b2d.draw")

local M = {}

M.camera = {
    center_x = 0,
    center_y = 2.5,
    zoom = 3.5,
}

local ground_id = nil
local body_id = nil

function M.create_scene(world)
    -- Ground
    local body_def = b2d.default_body_def()
    body_def.position = {0, -0.25}
    ground_id = b2d.create_body(world, body_def)

    local shape_def = b2d.default_shape_def()
    local box = b2d.make_box(20, 0.25)
    b2d.create_polygon_shape(ground_id, shape_def, box)

    -- Dynamic body
    body_def = b2d.default_body_def()
    body_def.type = b2d.BodyType.DYNAMICBODY
    body_def.position = {0, 0.5}
    body_id = b2d.create_body(world, body_def)

    local small_box = b2d.make_box(0.5, 0.5)
    b2d.create_polygon_shape(body_id, shape_def, small_box)
end

function M.update(world, dt)
    -- Set velocity every frame - body will stay in place
    if body_id and b2d.body_is_valid(body_id) then
        b2d.body_set_linear_velocity(body_id, {0, -20})
    end
end

function M.render(camera, world)
    -- Draw ground
    draw.solid_box(0, -0.25, 20, 0.25, 0, draw.colors.static)
    draw.box(0, -0.25, 20, 0.25, 0, {0, 0, 0, 1})

    -- Draw body
    if body_id and b2d.body_is_valid(body_id) then
        local pos = b2d.body_get_position(body_id)
        local rot = b2d.body_get_rotation(body_id)
        local angle = b2d.rot_get_angle(rot)
        local color = b2d.body_is_awake(body_id) and draw.colors.dynamic or draw.colors.sleeping
        draw.solid_box(pos[1], pos[2], 0.5, 0.5, angle, color)
        draw.box(pos[1], pos[2], 0.5, 0.5, angle, {0, 0, 0, 1})
    end
end

function M.cleanup()
    ground_id = nil
    body_id = nil
end

return M
