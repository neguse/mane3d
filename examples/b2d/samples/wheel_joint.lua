-- wheel_joint.lua - Box2D official Wheel Joint sample
-- Wheel joints provide 2D suspension by constraining a point on one body
-- to a line on another body while providing a spring-damper system.
local b2d = require("b2d")
local draw = require("examples.b2d.draw")
local imgui = require("imgui")

local M = {}

M.camera = {
    center_x = 0,
    center_y = 10,
    zoom = 25 * 0.15,
}

local ground_id = nil
local body_id = nil
local joint_id = nil

local enable_spring = true
local enable_limit = true
local enable_motor = true
local motor_speed = 2.0
local motor_torque = 5.0
local hertz = 1.0
local damping_ratio = 0.7

function M.create_scene(world)
    -- Ground (empty body for joint anchor)
    local body_def = b2d.default_body_def()
    ground_id = b2d.create_body(world, body_def)

    -- Dynamic body with capsule shape
    body_def = b2d.default_body_def()
    body_def.type = b2d.BodyType.DYNAMICBODY
    body_def.position = {0, 10.25}
    body_id = b2d.create_body(world, body_def)

    local shape_def = b2d.default_shape_def()
    local capsule = b2d.Capsule({center1 = {0, -0.5}, center2 = {0, 0.5}, radius = 0.5})
    b2d.create_capsule_shape(body_id, shape_def, capsule)

    -- Wheel joint
    local pivot = {0, 10}
    -- Axis: normalized {1, 1} -> diagonal
    local axis_len = math.sqrt(2)
    local axis = {1/axis_len, 1/axis_len}

    local joint_def = b2d.default_wheel_joint_def()
    joint_def.bodyIdA = ground_id
    joint_def.bodyIdB = body_id

    -- localFrameA with rotation from axis
    local rot = b2d.make_rot_from_unit_vector(axis)
    local anchorA = b2d.body_get_local_point(ground_id, pivot)
    local anchorB = b2d.body_get_local_point(body_id, pivot)
    joint_def.localFrameA = b2d.Transform({p = anchorA, q = rot})
    joint_def.localFrameB = b2d.Transform({p = anchorB, q = {1, 0}})  -- identity rotation

    joint_def.motorSpeed = motor_speed
    joint_def.maxMotorTorque = motor_torque
    joint_def.enableMotor = enable_motor
    joint_def.lowerTranslation = -3
    joint_def.upperTranslation = 3
    joint_def.enableLimit = enable_limit
    joint_def.hertz = hertz
    joint_def.dampingRatio = damping_ratio
    joint_def.enableSpring = enable_spring

    joint_id = b2d.create_wheel_joint(world, joint_def)
end

function M.update_gui(world)
    imgui.begin_window("Wheel Joint")

    local changed
    changed, enable_limit = imgui.checkbox("Limit", enable_limit)
    if changed then
        b2d.wheel_joint_enable_limit(joint_id, enable_limit)
    end

    changed, enable_motor = imgui.checkbox("Motor", enable_motor)
    if changed then
        b2d.wheel_joint_enable_motor(joint_id, enable_motor)
    end

    if enable_motor then
        changed, motor_torque = imgui.slider_float("Torque", motor_torque, 0, 20)
        if changed then
            b2d.wheel_joint_set_max_motor_torque(joint_id, motor_torque)
        end

        changed, motor_speed = imgui.slider_float("Speed", motor_speed, -20, 20)
        if changed then
            b2d.wheel_joint_set_motor_speed(joint_id, motor_speed)
        end
    end

    changed, enable_spring = imgui.checkbox("Spring", enable_spring)
    if changed then
        b2d.wheel_joint_enable_spring(joint_id, enable_spring)
    end

    if enable_spring then
        changed, hertz = imgui.slider_float("Hertz", hertz, 0, 10)
        if changed then
            b2d.wheel_joint_set_spring_hertz(joint_id, hertz)
        end

        changed, damping_ratio = imgui.slider_float("Damping", damping_ratio, 0, 2)
        if changed then
            b2d.wheel_joint_set_spring_damping_ratio(joint_id, damping_ratio)
        end
    end

    imgui.separator()
    local torque = b2d.wheel_joint_get_motor_torque(joint_id)
    imgui.text(string.format("Motor Torque = %.1f", torque))

    imgui.end_window()
end

function M.render(camera, world)
    -- Draw pivot point and axis
    local pivot = {0, 10}
    local axis_len_draw = 3
    local axis_x, axis_y = 1/math.sqrt(2), 1/math.sqrt(2)
    draw.line(pivot[1] - axis_x * axis_len_draw, pivot[2] - axis_y * axis_len_draw,
              pivot[1] + axis_x * axis_len_draw, pivot[2] + axis_y * axis_len_draw,
              {0.5, 0.5, 0.5, 1})
    draw.solid_circle(pivot[1], pivot[2], 0.1, {1, 1, 0, 1})

    -- Draw body (capsule)
    local pos = b2d.body_get_position(body_id)
    local rot = b2d.body_get_rotation(body_id)
    local angle = b2d.rot_get_angle(rot)
    local color = b2d.body_is_awake(body_id) and draw.colors.dynamic or draw.colors.sleeping

    -- Capsule: center1={0,-0.5}, center2={0,0.5}, radius=0.5
    local c, s = math.cos(angle), math.sin(angle)
    local c1x, c1y = pos[1] + 0 * c - (-0.5) * s, pos[2] + 0 * s + (-0.5) * c
    local c2x, c2y = pos[1] + 0 * c - (0.5) * s, pos[2] + 0 * s + (0.5) * c
    draw.solid_capsule(c1x, c1y, c2x, c2y, 0.5, color)
    draw.capsule(c1x, c1y, c2x, c2y, 0.5, {0, 0, 0, 1})
end

function M.cleanup()
    ground_id = nil
    body_id = nil
    joint_id = nil
end

return M
