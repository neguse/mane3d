-- revolute_joint.lua - Box2D official Revolute Joint sample
local b2d = require("b2d")
local draw = require("examples.b2d.draw")
local imgui = require("imgui")

local M = {}

M.camera = {
    center_x = 0,
    center_y = 15.5,
    zoom = 25 * 0.7,
}

local ground_id = nil
local ball_id = nil
local joint_id1 = nil
local joint_id2 = nil
local body_id1 = nil
local body_id2 = nil

-- Settings
local enable_spring = false
local enable_limit = false
local enable_motor = false
local hertz = 2.0
local damping_ratio = 0.5
local target_degrees = 45.0
local motor_speed = 1.0
local motor_torque = 1000.0

function M.create_scene(world)
    -- Ground
    local body_def = b2d.default_body_def()
    body_def.position = {0, -1}
    ground_id = b2d.create_body(world, body_def)

    local box = b2d.make_box(40, 1)
    local shape_def = b2d.default_shape_def()
    b2d.create_polygon_shape(ground_id, shape_def, box)

    -- First body: capsule
    body_def = b2d.default_body_def()
    body_def.type = b2d.BodyType.DYNAMICBODY
    body_def.position = {-10, 20}
    body_id1 = b2d.create_body(world, body_def)

    shape_def = b2d.default_shape_def()
    shape_def.density = 1.0
    local capsule = b2d.Capsule({center1 = {0, -1}, center2 = {0, 6}, radius = 0.5})
    b2d.create_capsule_shape(body_id1, shape_def, capsule)

    -- Revolute joint 1
    local pivot1 = {-10, 20.5}
    local joint_def = b2d.default_revolute_joint_def()
    joint_def.bodyIdA = ground_id
    joint_def.bodyIdB = body_id1
    local anchorA = b2d.body_get_local_point(ground_id, pivot1)
    local anchorB = b2d.body_get_local_point(body_id1, pivot1)
    joint_def.localFrameA = b2d.Transform({p = anchorA, q = b2d.make_rot(math.pi * 0.5)})
    joint_def.localFrameB = b2d.Transform({p = anchorB, q = {1, 0}})
    joint_def.targetAngle = math.pi * target_degrees / 180
    joint_def.enableSpring = enable_spring
    joint_def.hertz = hertz
    joint_def.dampingRatio = damping_ratio
    joint_def.motorSpeed = motor_speed
    joint_def.maxMotorTorque = motor_torque
    joint_def.enableMotor = enable_motor
    joint_def.lowerAngle = -0.5 * math.pi
    joint_def.upperAngle = 0.05 * math.pi
    joint_def.enableLimit = enable_limit

    joint_id1 = b2d.create_revolute_joint(world, joint_def)

    -- Ball
    body_def = b2d.default_body_def()
    body_def.type = b2d.BodyType.DYNAMICBODY
    body_def.position = {5, 30}
    ball_id = b2d.create_body(world, body_def)

    shape_def = b2d.default_shape_def()
    shape_def.density = 1.0
    local circle = b2d.Circle({center = {0, 0}, radius = 2})
    b2d.create_circle_shape(ball_id, shape_def, circle)

    -- Second body: offset box (plank)
    body_def = b2d.default_body_def()
    body_def.type = b2d.BodyType.DYNAMICBODY
    body_def.position = {20, 10}
    body_id2 = b2d.create_body(world, body_def)

    shape_def = b2d.default_shape_def()
    shape_def.density = 1.0
    local offset_box = b2d.make_offset_box(10, 0.5, {-10, 0}, {1, 0})
    b2d.create_polygon_shape(body_id2, shape_def, offset_box)

    -- Revolute joint 2
    local pivot2 = {19, 10}
    joint_def = b2d.default_revolute_joint_def()
    joint_def.bodyIdA = ground_id
    joint_def.bodyIdB = body_id2
    anchorA = b2d.body_get_local_point(ground_id, pivot2)
    anchorB = b2d.body_get_local_point(body_id2, pivot2)
    joint_def.localFrameA = b2d.Transform({p = anchorA, q = {1, 0}})
    joint_def.localFrameB = b2d.Transform({p = anchorB, q = {1, 0}})
    joint_def.lowerAngle = -0.25 * math.pi
    joint_def.upperAngle = 0
    joint_def.enableLimit = true
    joint_def.enableMotor = true
    joint_def.motorSpeed = 0
    joint_def.maxMotorTorque = motor_torque

    joint_id2 = b2d.create_revolute_joint(world, joint_def)
end

function M.update_gui(world)
    imgui.begin_window("Revolute Joint")

    local changed
    changed, enable_limit = imgui.checkbox("Limit", enable_limit)
    if changed then
        b2d.revolute_joint_enable_limit(joint_id1, enable_limit)
        b2d.joint_wake_bodies(joint_id1)
    end

    changed, enable_motor = imgui.checkbox("Motor", enable_motor)
    if changed then
        b2d.revolute_joint_enable_motor(joint_id1, enable_motor)
        b2d.joint_wake_bodies(joint_id1)
    end

    if enable_motor then
        changed, motor_torque = imgui.slider_float("Max Torque", motor_torque, 0, 5000)
        if changed then
            b2d.revolute_joint_set_max_motor_torque(joint_id1, motor_torque)
            b2d.joint_wake_bodies(joint_id1)
        end

        changed, motor_speed = imgui.slider_float("Speed", motor_speed, -20, 20)
        if changed then
            b2d.revolute_joint_set_motor_speed(joint_id1, motor_speed)
            b2d.joint_wake_bodies(joint_id1)
        end
    end

    changed, enable_spring = imgui.checkbox("Spring", enable_spring)
    if changed then
        b2d.revolute_joint_enable_spring(joint_id1, enable_spring)
        b2d.joint_wake_bodies(joint_id1)
    end

    if enable_spring then
        changed, hertz = imgui.slider_float("Hertz", hertz, 0, 30)
        if changed then
            b2d.revolute_joint_set_spring_hertz(joint_id1, hertz)
            b2d.joint_wake_bodies(joint_id1)
        end

        changed, damping_ratio = imgui.slider_float("Damping", damping_ratio, 0, 2)
        if changed then
            b2d.revolute_joint_set_spring_damping_ratio(joint_id1, damping_ratio)
            b2d.joint_wake_bodies(joint_id1)
        end

        changed, target_degrees = imgui.slider_float("Degrees", target_degrees, -180, 180)
        if changed then
            b2d.revolute_joint_set_target_angle(joint_id1, math.pi * target_degrees / 180)
            b2d.joint_wake_bodies(joint_id1)
        end
    end

    imgui.separator()
    local angle1 = b2d.revolute_joint_get_angle(joint_id1)
    imgui.text(string.format("Angle (Deg) 1 = %.1f", angle1 * 180 / math.pi))

    local torque1 = b2d.revolute_joint_get_motor_torque(joint_id1)
    imgui.text(string.format("Motor Torque 1 = %.1f", torque1))

    local torque2 = b2d.revolute_joint_get_motor_torque(joint_id2)
    imgui.text(string.format("Motor Torque 2 = %.1f", torque2))

    imgui.end_window()
end

function M.render(camera, world)
    -- Ground
    draw.solid_box(0, -1, 40, 1, 0, draw.colors.static)

    -- Body 1 (capsule) - local coords: {0, -1} to {0, 6}
    local pos1 = b2d.body_get_position(body_id1)
    local rot1 = b2d.body_get_rotation(body_id1)
    local angle1 = b2d.rot_get_angle(rot1)
    local color1 = b2d.body_is_awake(body_id1) and draw.colors.dynamic or draw.colors.sleeping
    -- Transform local capsule endpoints to world
    local cos_a1, sin_a1 = math.cos(angle1), math.sin(angle1)
    local p1_x = pos1[1] + 0 * cos_a1 - (-1) * sin_a1
    local p1_y = pos1[2] + 0 * sin_a1 + (-1) * cos_a1
    local p2_x = pos1[1] + 0 * cos_a1 - 6 * sin_a1
    local p2_y = pos1[2] + 0 * sin_a1 + 6 * cos_a1
    draw.solid_capsule({p1_x, p1_y}, {p2_x, p2_y}, 0.5, color1)

    -- Ball
    local ball_pos = b2d.body_get_position(ball_id)
    local ball_rot = b2d.body_get_rotation(ball_id)
    local ball_color = b2d.body_is_awake(ball_id) and draw.colors.dynamic or draw.colors.sleeping
    draw.solid_circle_axis(ball_pos[1], ball_pos[2], 2, ball_rot, ball_color)

    -- Body 2 (offset box/plank)
    local pos2 = b2d.body_get_position(body_id2)
    local rot2 = b2d.body_get_rotation(body_id2)
    local angle2 = b2d.rot_get_angle(rot2)
    local color2 = b2d.body_is_awake(body_id2) and draw.colors.dynamic or draw.colors.sleeping
    -- The box is offset by {-10, 0} from body center
    local cos_a2, sin_a2 = math.cos(angle2), math.sin(angle2)
    local offset_x = -10 * cos_a2
    local offset_y = -10 * sin_a2
    draw.solid_box(pos2[1] + offset_x, pos2[2] + offset_y, 10, 0.5, angle2, color2)
    draw.box(pos2[1] + offset_x, pos2[2] + offset_y, 10, 0.5, angle2, {0, 0, 0, 1})

    -- Pivot points
    draw.solid_circle(-10, 20.5, 0.2, {1, 1, 0, 1})
    draw.solid_circle(19, 10, 0.2, {1, 1, 0, 1})
end

function M.cleanup()
    ground_id = nil
    ball_id = nil
    joint_id1 = nil
    joint_id2 = nil
    body_id1 = nil
    body_id2 = nil
end

return M
