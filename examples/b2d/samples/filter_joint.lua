-- filter_joint.lua - Box2D official Filter Joint sample
-- Demonstrates using filter joints to prevent collision between specific bodies.
local b2d = require("b2d")
local draw = require("examples.b2d.draw")

local M = {}

M.camera = {
    center_x = 0,
    center_y = 7,
    zoom = 25 * 0.4,
}

local ground_id = nil
local body_id1 = nil
local body_id2 = nil

function M.create_scene(world)
    -- Ground
    local body_def = b2d.default_body_def()
    ground_id = b2d.create_body(world, body_def)

    local shape_def = b2d.default_shape_def()
    local segment = b2d.Segment({point1 = {-20, 0}, point2 = {20, 0}})
    b2d.create_segment_shape(ground_id, shape_def, segment)

    -- First body
    body_def = b2d.default_body_def()
    body_def.type = b2d.BodyType.DYNAMICBODY
    body_def.position = {-4.0, 2.0}
    body_id1 = b2d.create_body(world, body_def)

    local box = b2d.make_square(2.0)
    shape_def = b2d.default_shape_def()
    b2d.create_polygon_shape(body_id1, shape_def, box)

    -- Second body
    body_def.position = {4.0, 2.0}
    body_id2 = b2d.create_body(world, body_def)
    b2d.create_polygon_shape(body_id2, shape_def, box)

    -- Filter joint prevents collision between these two bodies
    local filter_def = b2d.default_filter_joint_def()
    filter_def.bodyIdA = body_id1
    filter_def.bodyIdB = body_id2
    b2d.create_filter_joint(world, filter_def)
end

function M.render(camera, world)
    -- Ground
    draw.line(-20, 0, 20, 0, draw.colors.static)

    -- Draw first body
    local pos1 = b2d.body_get_position(body_id1)
    local rot1 = b2d.body_get_rotation(body_id1)
    local angle1 = b2d.rot_get_angle(rot1)
    local color1 = b2d.body_is_awake(body_id1) and draw.colors.dynamic or draw.colors.sleeping
    draw.solid_box(pos1[1], pos1[2], 2.0, 2.0, angle1, color1)
    draw.box(pos1[1], pos1[2], 2.0, 2.0, angle1, {0, 0, 0, 1})

    -- Draw second body
    local pos2 = b2d.body_get_position(body_id2)
    local rot2 = b2d.body_get_rotation(body_id2)
    local angle2 = b2d.rot_get_angle(rot2)
    local color2 = b2d.body_is_awake(body_id2) and draw.colors.dynamic or draw.colors.sleeping
    draw.solid_box(pos2[1], pos2[2], 2.0, 2.0, angle2, color2)
    draw.box(pos2[1], pos2[2], 2.0, 2.0, angle2, {0, 0, 0, 1})
end

function M.cleanup()
    ground_id = nil
    body_id1 = nil
    body_id2 = nil
end

return M
