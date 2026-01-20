-- ball_and_chain.lua - Box2D official Ball and Chain sample
-- A chain of capsules with a large ball at the end, demonstrating revolute joints with friction.
local b2d = require("b2d")
local draw = require("examples.b2d.draw")
local imgui = require("imgui")

local M = {}

M.camera = {
    center_x = 0,
    center_y = -8,
    zoom = 27.5,
}

local ground_id = nil
local body_ids = {}
local joint_ids = {}
local ball_id = nil

local link_count = 30
local friction_torque = 100.0

function M.create_scene(world)
    body_ids = {}
    joint_ids = {}

    -- Ground (empty body for joint anchor)
    local body_def = b2d.default_body_def()
    ground_id = b2d.create_body(world, body_def)

    local hx = 0.5
    local capsule = b2d.Capsule({center1 = {-hx, 0}, center2 = {hx, 0}, radius = 0.125})

    local shape_def = b2d.default_shape_def()
    shape_def.density = 20.0
    local filter1 = b2d.Filter()
    filter1.categoryBits = 0x1
    filter1.maskBits = 0x2
    shape_def.filter = filter1

    local joint_def = b2d.default_revolute_joint_def()

    local prev_body_id = ground_id

    -- Create chain links
    for i = 0, link_count - 1 do
        body_def = b2d.default_body_def()
        body_def.type = b2d.BodyType.DYNAMICBODY
        body_def.position = {(1.0 + 2.0 * i) * hx, link_count * hx}
        local body_id = b2d.create_body(world, body_def)
        b2d.create_capsule_shape(body_id, shape_def, capsule)
        table.insert(body_ids, body_id)

        local pivot = {(2.0 * i) * hx, link_count * hx}
        joint_def.bodyIdA = prev_body_id
        joint_def.bodyIdB = body_id
        local anchorA = b2d.body_get_local_point(prev_body_id, pivot)
        local anchorB = b2d.body_get_local_point(body_id, pivot)
        joint_def.localFrameA = b2d.Transform({p = anchorA, q = {1, 0}})
        joint_def.localFrameB = b2d.Transform({p = anchorB, q = {1, 0}})
        joint_def.enableMotor = true
        joint_def.maxMotorTorque = friction_torque
        joint_def.enableSpring = (i > 0)
        joint_def.hertz = 4.0

        local joint_id = b2d.create_revolute_joint(world, joint_def)
        table.insert(joint_ids, joint_id)

        prev_body_id = body_id
    end

    -- Create ball at the end
    local circle = b2d.Circle({center = {0, 0}, radius = 4.0})
    body_def = b2d.default_body_def()
    body_def.type = b2d.BodyType.DYNAMICBODY
    body_def.position = {(1.0 + 2.0 * link_count) * hx + 4.0 - hx, link_count * hx}
    ball_id = b2d.create_body(world, body_def)

    local filter2 = b2d.Filter()
    filter2.categoryBits = 0x2
    filter2.maskBits = 0x1
    shape_def.filter = filter2
    b2d.create_circle_shape(ball_id, shape_def, circle)

    -- Connect ball to chain
    local pivot = {(2.0 * link_count) * hx, link_count * hx}
    joint_def.bodyIdA = prev_body_id
    joint_def.bodyIdB = ball_id
    local anchorA = b2d.body_get_local_point(prev_body_id, pivot)
    local anchorB = b2d.body_get_local_point(ball_id, pivot)
    joint_def.localFrameA = b2d.Transform({p = anchorA, q = {1, 0}})
    joint_def.localFrameB = b2d.Transform({p = anchorB, q = {1, 0}})
    joint_def.enableMotor = true
    joint_def.maxMotorTorque = friction_torque
    joint_def.enableSpring = true
    joint_def.hertz = 4.0

    local joint_id = b2d.create_revolute_joint(world, joint_def)
    table.insert(joint_ids, joint_id)
end

function M.update_gui(world)
    imgui.begin_window("Ball and Chain")

    local changed, new_friction = imgui.slider_float("Joint Friction", friction_torque, 0, 1000)
    if changed then
        friction_torque = new_friction
        for _, joint_id in ipairs(joint_ids) do
            b2d.revolute_joint_set_max_motor_torque(joint_id, friction_torque)
        end
    end

    imgui.end_window()
end

function M.render(camera, world)
    -- Draw chain links (capsules)
    for _, body_id in ipairs(body_ids) do
        local pos = b2d.body_get_position(body_id)
        local rot = b2d.body_get_rotation(body_id)
        local angle = b2d.rot_get_angle(rot)
        local color = b2d.body_is_awake(body_id) and draw.colors.dynamic or draw.colors.sleeping

        -- Capsule: center1={-0.5, 0}, center2={0.5, 0}, radius=0.125
        local c, s = math.cos(angle), math.sin(angle)
        local hx = 0.5
        local c1x = pos[1] + (-hx) * c - 0 * s
        local c1y = pos[2] + (-hx) * s + 0 * c
        local c2x = pos[1] + hx * c - 0 * s
        local c2y = pos[2] + hx * s + 0 * c
        draw.solid_capsule(c1x, c1y, c2x, c2y, 0.125, color)
        draw.capsule(c1x, c1y, c2x, c2y, 0.125, {0, 0, 0, 1})
    end

    -- Draw ball
    local ball_pos = b2d.body_get_position(ball_id)
    local ball_color = b2d.body_is_awake(ball_id) and draw.colors.dynamic or draw.colors.sleeping
    draw.solid_circle(ball_pos[1], ball_pos[2], 4.0, ball_color)
    draw.circle(ball_pos[1], ball_pos[2], 4.0, {0, 0, 0, 1})

    -- Draw anchor point
    draw.solid_circle(0, link_count * 0.5, 0.2, {1, 1, 0, 1})
end

function M.cleanup()
    ground_id = nil
    body_ids = {}
    joint_ids = {}
    ball_id = nil
end

return M
