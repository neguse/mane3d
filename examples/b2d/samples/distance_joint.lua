-- distance_joint.lua - Distance joint demo (pendulum chain)
local b2d = require("b2d")
local draw = require("examples.b2d.draw")

local M = {}

M.camera = {
    center_x = 3,
    center_y = 12,
    zoom = 9,
}

local ground_id = nil
local bodies = {}
local joints = {}

local COUNT = 5
local LENGTH = 1

function M.create_scene(world)
    bodies = {}
    joints = {}

    -- Ground (thin box instead of segment)
    local body_def = b2d.default_body_def()
    body_def.position = {0, -0.1}
    ground_id = b2d.create_body(world, body_def)

    local shape_def = b2d.default_shape_def()
    local ground_box = b2d.make_box(20, 0.1)
    b2d.create_polygon_shape(ground_id, shape_def, ground_box)

    -- Create chain of circles connected by distance joints
    local circle = b2d.Circle({center = {x = 0, y = 0}, radius = 0.25})
    shape_def = b2d.default_shape_def()
    shape_def.density = 20

    local y_offset = 15

    local prev_body = ground_id
    for i = 1, COUNT do
        body_def = b2d.default_body_def()
        body_def.type = b2d.BodyType.DYNAMICBODY
        body_def.position = {LENGTH * i, y_offset}
        body_def.angularDamping = 1

        local body_id = b2d.create_body(world, body_def)
        b2d.create_circle_shape(body_id, shape_def, circle)
        table.insert(bodies, body_id)

        -- Create distance joint
        local joint_def = b2d.default_distance_joint_def()
        local anchorA = b2d.body_get_local_point(prev_body, {LENGTH * (i - 1), y_offset})
        local anchorB = b2d.body_get_local_point(body_id, {LENGTH * i, y_offset})
        -- Use flattened accessors to directly set base fields
        joint_def.bodyIdA = prev_body
        joint_def.bodyIdB = body_id
        joint_def.localFrameA = b2d.Transform({ p = anchorA, q = {c = 1, s = 0} })
        joint_def.localFrameB = b2d.Transform({ p = anchorB, q = {c = 1, s = 0} })
        joint_def.length = LENGTH
        joint_def.enableSpring = true
        joint_def.hertz = 5
        joint_def.dampingRatio = 0.5

        local joint_id = b2d.create_distance_joint(world, joint_def)
        table.insert(joints, joint_id)

        prev_body = body_id
    end
end

function M.render(camera, world)
    -- Ground
    draw.solid_box(0, -0.1, 20, 0.1, 0, draw.colors.static)

    -- Draw joints (lines between anchor points)
    local anchor_pos = {0, 15}  -- Ground anchor
    for i, joint_id in ipairs(joints) do
        local body_pos = b2d.body_get_position(bodies[i])
        draw.line(anchor_pos[1], anchor_pos[2], body_pos[1], body_pos[2], {0.5, 0.5, 0.5, 1})
        anchor_pos = body_pos
    end

    -- Draw bodies
    for _, body_id in ipairs(bodies) do
        local pos = b2d.body_get_position(body_id)
        local rot = b2d.body_get_rotation(body_id)
        local color = b2d.body_is_awake(body_id) and draw.colors.dynamic or draw.colors.sleeping
        draw.solid_circle_axis(pos[1], pos[2], 0.25, rot, color)
    end
end

function M.cleanup()
    ground_id = nil
    bodies = {}
    joints = {}
end

return M
