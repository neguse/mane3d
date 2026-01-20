-- prismatic_joint.lua - Box2D official Prismatic Joint sample
-- Prismatic joints constrain two bodies to move relative to each other
-- along a specified axis.
local b2d = require("b2d")
local draw = require("examples.b2d.draw")
local imgui = require("imgui")

local M = {}

M.camera = {
    center_x = 0,
    center_y = 8,
    zoom = 25 * 0.5,
}

local ground_id = nil
local body_id = nil
local joint_id = nil

local enable_spring = false
local enable_limit = true
local enable_motor = false
local motor_speed = 2.0
local motor_force = 25.0
local hertz = 1.0
local damping_ratio = 0.5
local translation = 0.0

function M.create_scene(world)
    -- Ground (empty body for joint anchor)
    local body_def = b2d.default_body_def()
    ground_id = b2d.create_body(world, body_def)

    -- Dynamic body
    body_def = b2d.default_body_def()
    body_def.type = b2d.BodyType.DYNAMICBODY
    body_def.position = {0, 10}
    body_id = b2d.create_body(world, body_def)

    local shape_def = b2d.default_shape_def()
    local box = b2d.make_box(0.5, 2)
    b2d.create_polygon_shape(body_id, shape_def, box)

    -- Prismatic joint
    local pivot = {0, 9}
    -- Axis: normalized {1, 1} -> diagonal
    local axis_len = math.sqrt(2)
    local axis = {1/axis_len, 1/axis_len}

    local joint_def = b2d.default_prismatic_joint_def()
    joint_def.bodyIdA = ground_id
    joint_def.bodyIdB = body_id
    local anchorA = b2d.body_get_local_point(ground_id, pivot)
    local anchorB = b2d.body_get_local_point(body_id, pivot)
    -- localFrameA/B with rotation from axis
    local rot = b2d.make_rot_from_unit_vector(axis)
    joint_def.localFrameA = b2d.Transform({p = anchorA, q = rot})
    joint_def.localFrameB = b2d.Transform({p = anchorB, q = rot})
    joint_def.motorSpeed = motor_speed
    joint_def.maxMotorForce = motor_force
    joint_def.enableMotor = enable_motor
    joint_def.lowerTranslation = -10
    joint_def.upperTranslation = 10
    joint_def.enableLimit = enable_limit
    joint_def.enableSpring = enable_spring
    joint_def.hertz = hertz
    joint_def.dampingRatio = damping_ratio

    joint_id = b2d.create_prismatic_joint(world, joint_def)
end

function M.update_gui(world)
    imgui.begin_window("Prismatic Joint")

    local changed
    changed, enable_limit = imgui.checkbox("Limit", enable_limit)
    if changed then
        b2d.prismatic_joint_enable_limit(joint_id, enable_limit)
        b2d.joint_wake_bodies(joint_id)
    end

    changed, enable_motor = imgui.checkbox("Motor", enable_motor)
    if changed then
        b2d.prismatic_joint_enable_motor(joint_id, enable_motor)
        b2d.joint_wake_bodies(joint_id)
    end

    if enable_motor then
        changed, motor_force = imgui.slider_float("Max Force", motor_force, 0, 200)
        if changed then
            b2d.prismatic_joint_set_max_motor_force(joint_id, motor_force)
            b2d.joint_wake_bodies(joint_id)
        end

        changed, motor_speed = imgui.slider_float("Speed", motor_speed, -40, 40)
        if changed then
            b2d.prismatic_joint_set_motor_speed(joint_id, motor_speed)
            b2d.joint_wake_bodies(joint_id)
        end
    end

    changed, enable_spring = imgui.checkbox("Spring", enable_spring)
    if changed then
        b2d.prismatic_joint_enable_spring(joint_id, enable_spring)
        b2d.joint_wake_bodies(joint_id)
    end

    if enable_spring then
        changed, hertz = imgui.slider_float("Hertz", hertz, 0, 10)
        if changed then
            b2d.prismatic_joint_set_spring_hertz(joint_id, hertz)
            b2d.joint_wake_bodies(joint_id)
        end

        changed, damping_ratio = imgui.slider_float("Damping", damping_ratio, 0, 2)
        if changed then
            b2d.prismatic_joint_set_spring_damping_ratio(joint_id, damping_ratio)
            b2d.joint_wake_bodies(joint_id)
        end

        changed, translation = imgui.slider_float("Translation", translation, -15, 15)
        if changed then
            b2d.prismatic_joint_set_target_translation(joint_id, translation)
            b2d.joint_wake_bodies(joint_id)
        end
    end

    imgui.separator()
    local force = b2d.prismatic_joint_get_motor_force(joint_id)
    imgui.text(string.format("Motor Force = %.1f", force))

    local trans = b2d.prismatic_joint_get_translation(joint_id)
    imgui.text(string.format("Translation = %.1f", trans))

    local speed = b2d.prismatic_joint_get_speed(joint_id)
    imgui.text(string.format("Speed = %.4f", speed))

    imgui.end_window()
end

function M.render(camera, world)
    -- Draw pivot point and axis
    local pivot = {0, 9}
    local axis_len_draw = 5
    local axis_x, axis_y = 1/math.sqrt(2), 1/math.sqrt(2)
    draw.line(pivot[1] - axis_x * axis_len_draw, pivot[2] - axis_y * axis_len_draw,
              pivot[1] + axis_x * axis_len_draw, pivot[2] + axis_y * axis_len_draw,
              {0.5, 0.5, 0.5, 1})
    draw.solid_circle(pivot[1], pivot[2], 0.15, {1, 1, 0, 1})

    -- Draw body
    local pos = b2d.body_get_position(body_id)
    local rot = b2d.body_get_rotation(body_id)
    local angle = b2d.rot_get_angle(rot)
    local color = b2d.body_is_awake(body_id) and draw.colors.dynamic or draw.colors.sleeping
    draw.solid_box(pos[1], pos[2], 0.5, 2, angle, color)
    draw.box(pos[1], pos[2], 0.5, 2, angle, {0, 0, 0, 1})
end

function M.cleanup()
    ground_id = nil
    body_id = nil
    joint_id = nil
end

return M
