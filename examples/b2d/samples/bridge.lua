-- bridge.lua - Bridge using revolute joints
local b2d = require("b2d")
local draw = require("examples.b2d.draw")

local M = {}

M.camera = {
    center_x = 0,
    center_y = 10,
    zoom = 25,
}

local ground_id = nil
local planks = {}
local weights = {}

local PLANK_COUNT = 20
local PLANK_WIDTH = 0.5
local PLANK_HEIGHT = 0.1

function M.create_scene(world)
    planks = {}
    weights = {}

    -- Ground (thin box instead of segment)
    local body_def = b2d.default_body_def()
    body_def.position = {0, -0.1}
    ground_id = b2d.create_body(world, body_def)

    local shape_def = b2d.default_shape_def()
    local ground_box = b2d.make_box(20, 0.1)
    b2d.create_polygon_shape(ground_id, shape_def, ground_box)

    -- Create bridge planks
    local x_base = -PLANK_COUNT * PLANK_WIDTH * 0.5
    local y = 10
    local box = b2d.make_box(PLANK_WIDTH, PLANK_HEIGHT)

    shape_def = b2d.default_shape_def()
    shape_def.density = 20

    local prev_body = ground_id
    for i = 1, PLANK_COUNT do
        body_def = b2d.default_body_def()
        body_def.type = b2d.BodyType.DYNAMICBODY
        body_def.position = {x_base + PLANK_WIDTH * 0.5 + (i - 1) * PLANK_WIDTH * 2, y}
        body_def.linearDamping = 0.1
        body_def.angularDamping = 0.1

        local plank_id = b2d.create_body(world, body_def)
        b2d.create_polygon_shape(plank_id, shape_def, box)
        table.insert(planks, plank_id)

        -- Create revolute joint
        local pivot_x = x_base + (i - 1) * PLANK_WIDTH * 2
        local joint_def = b2d.default_revolute_joint_def()
        local anchorA = b2d.body_get_local_point(prev_body, {pivot_x, y})
        local anchorB = b2d.body_get_local_point(plank_id, {pivot_x, y})
        -- Use flattened accessors to directly set base fields
        joint_def.bodyIdA = prev_body
        joint_def.bodyIdB = plank_id
        joint_def.localFrameA = b2d.Transform({ p = anchorA, q = {c = 1, s = 0} })
        joint_def.localFrameB = b2d.Transform({ p = anchorB, q = {c = 1, s = 0} })
        joint_def.enableMotor = true
        joint_def.maxMotorTorque = 100  -- Friction
        joint_def.enableSpring = true
        joint_def.hertz = 2
        joint_def.dampingRatio = 0.7

        b2d.create_revolute_joint(world, joint_def)
        prev_body = plank_id
    end

    -- Final anchor to ground
    local final_pivot_x = x_base + PLANK_COUNT * PLANK_WIDTH * 2
    joint_def = b2d.default_revolute_joint_def()
    local anchorA2 = b2d.body_get_local_point(prev_body, {final_pivot_x, y})
    local anchorB2 = b2d.body_get_local_point(ground_id, {final_pivot_x, y})
    joint_def.bodyIdA = prev_body
    joint_def.bodyIdB = ground_id
    joint_def.localFrameA = b2d.Transform({ p = anchorA2, q = {c = 1, s = 0} })
    joint_def.localFrameB = b2d.Transform({ p = anchorB2, q = {c = 1, s = 0} })
    joint_def.enableMotor = true
    joint_def.maxMotorTorque = 100
    b2d.create_revolute_joint(world, joint_def)

    -- Add some weights on the bridge
    local circle = b2d.Circle({center = {x = 0, y = 0}, radius = 0.3})
    shape_def = b2d.default_shape_def()
    shape_def.density = 30

    for i = 1, 3 do
        body_def = b2d.default_body_def()
        body_def.type = b2d.BodyType.DYNAMICBODY
        body_def.position = {-4 + (i-1) * 4, y + 3}

        local weight_id = b2d.create_body(world, body_def)
        b2d.create_circle_shape(weight_id, shape_def, circle)
        table.insert(weights, weight_id)
    end
end

function M.render(camera, world)
    -- Ground
    draw.solid_box(0, -0.1, 20, 0.1, 0, draw.colors.static)

    -- Draw anchors
    local x_base = -PLANK_COUNT * PLANK_WIDTH * 0.5
    draw.solid_circle(x_base, 10, 0.15, draw.colors.static)
    draw.solid_circle(x_base + PLANK_COUNT * PLANK_WIDTH * 2, 10, 0.15, draw.colors.static)

    -- Draw planks
    for _, plank_id in ipairs(planks) do
        local pos = b2d.body_get_position(plank_id)
        local rot = b2d.body_get_rotation(plank_id)
        local angle = b2d.rot_get_angle(rot)
        local color = b2d.body_is_awake(plank_id) and {0.6, 0.4, 0.2, 1} or {0.4, 0.3, 0.2, 1}
        draw.solid_box(pos[1], pos[2], PLANK_WIDTH, PLANK_HEIGHT, angle, color)
        draw.box(pos[1], pos[2], PLANK_WIDTH, PLANK_HEIGHT, angle, {0, 0, 0, 1})
    end

    -- Draw weights
    for _, weight_id in ipairs(weights) do
        local pos = b2d.body_get_position(weight_id)
        local rot = b2d.body_get_rotation(weight_id)
        local color = b2d.body_is_awake(weight_id) and draw.colors.dynamic or draw.colors.sleeping
        draw.solid_circle_axis(pos[1], pos[2], 0.3, rot, color)
    end
end

function M.cleanup()
    ground_id = nil
    planks = {}
    weights = {}
end

return M
