-- motor_joint.lua - Box2D official Motor Joint sample
-- Motor joints are used to control the relative motion between two bodies.
-- Unlike other joints, motor joints directly apply forces and torques.
local b2d = require("b2d")
local draw = require("examples.b2d.draw")
local imgui = require("imgui")

local M = {}

M.camera = {
    center_x = 0,
    center_y = 7,
    zoom = 25 * 0.4,
}

local ground_id = nil
local target_id = nil
local body_id = nil
local joint_id = nil
local spring_body_id = nil

local transform_p = {0, 8}
local transform_q = {1, 0}  -- identity rotation
local time = 0
local speed = 1.0
local max_force = 5000.0
local max_torque = 500.0

function M.create_scene(world)
    time = 0

    -- Ground
    local body_def = b2d.default_body_def()
    ground_id = b2d.create_body(world, body_def)

    local shape_def = b2d.default_shape_def()
    local segment = b2d.Segment({point1 = {-20, 0}, point2 = {20, 0}})
    b2d.create_segment_shape(ground_id, shape_def, segment)

    -- Kinematic target body
    body_def = b2d.default_body_def()
    body_def.type = b2d.BodyType.KINEMATICBODY
    body_def.position = {0, 8}
    target_id = b2d.create_body(world, body_def)

    -- Dynamic motorized body
    body_def = b2d.default_body_def()
    body_def.type = b2d.BodyType.DYNAMICBODY
    body_def.position = {0, 8}
    body_id = b2d.create_body(world, body_def)

    local box = b2d.make_box(2, 0.5)
    shape_def = b2d.default_shape_def()
    b2d.create_polygon_shape(body_id, shape_def, box)

    -- Motor joint between target and body
    local joint_def = b2d.default_motor_joint_def()
    joint_def.bodyIdA = target_id
    joint_def.bodyIdB = body_id
    joint_def.linearHertz = 4.0
    joint_def.linearDampingRatio = 0.7
    joint_def.angularHertz = 4.0
    joint_def.angularDampingRatio = 0.7
    joint_def.maxSpringForce = max_force
    joint_def.maxSpringTorque = max_torque

    joint_id = b2d.create_motor_joint(world, joint_def)

    -- Spring body (small square connected to ground)
    body_def = b2d.default_body_def()
    body_def.type = b2d.BodyType.DYNAMICBODY
    body_def.position = {-2, 2}
    spring_body_id = b2d.create_body(world, body_def)

    local square = b2d.make_square(0.5)
    shape_def = b2d.default_shape_def()
    b2d.create_polygon_shape(spring_body_id, shape_def, square)

    -- Motor joint for spring body
    joint_def = b2d.default_motor_joint_def()
    joint_def.bodyIdA = ground_id
    joint_def.bodyIdB = spring_body_id
    joint_def.localFrameA = b2d.Transform({p = {-2 + 0.25, 2 + 0.25}, q = {1, 0}})
    joint_def.localFrameB = b2d.Transform({p = {0.25, 0.25}, q = {1, 0}})
    joint_def.linearHertz = 7.5
    joint_def.linearDampingRatio = 0.7
    joint_def.angularHertz = 7.5
    joint_def.angularDampingRatio = 0.7
    joint_def.maxSpringForce = 500.0
    joint_def.maxSpringTorque = 10.0

    b2d.create_motor_joint(world, joint_def)
end

function M.update(world, dt)
    if dt > 0 then
        time = time + speed * dt

        -- Figure-8 path
        local x = 6 * math.sin(2 * time)
        local y = 8 + 4 * math.sin(time)
        local angle = 2 * time

        transform_p = {x, y}
        transform_q = b2d.make_rot(angle)

        -- Move kinematic target (transform as table: {{p.x, p.y}, {q.c, q.s}})
        local transform = {transform_p, {transform_q[1], transform_q[2]}}
        b2d.body_set_target_transform(target_id, transform, dt, true)
    end
end

function M.update_gui(world)
    imgui.begin_window("Motor Joint")

    local changed
    changed, speed = imgui.slider_float("Speed", speed, -5, 5)

    changed, max_force = imgui.slider_float("Max Force", max_force, 0, 10000)
    if changed then
        b2d.motor_joint_set_max_spring_force(joint_id, max_force)
    end

    changed, max_torque = imgui.slider_float("Max Torque", max_torque, 0, 10000)
    if changed then
        b2d.motor_joint_set_max_spring_torque(joint_id, max_torque)
    end

    if imgui.button("Apply Impulse") then
        b2d.body_apply_linear_impulse_to_center(body_id, {100, 0}, true)
    end

    imgui.separator()
    local force = b2d.joint_get_constraint_force(joint_id)
    local torque = b2d.joint_get_constraint_torque(joint_id)
    imgui.text(string.format("force = {%.0f, %.0f}", force[1], force[2]))
    imgui.text(string.format("torque = %.0f", torque))

    imgui.end_window()
end

function M.render(camera, world)
    -- Ground line
    draw.line(-20, 0, 20, 0, draw.colors.static)

    -- Draw target transform (crosshair)
    local scale = 1.0
    local c, s = transform_q[1], transform_q[2]
    local px, py = transform_p[1], transform_p[2]
    -- X axis (red)
    draw.line(px, py, px + c * scale, py + s * scale, {1, 0, 0, 1})
    -- Y axis (green)
    draw.line(px, py, px - s * scale, py + c * scale, {0, 1, 0, 1})

    -- Draw motorized body
    local pos = b2d.body_get_position(body_id)
    local rot = b2d.body_get_rotation(body_id)
    local angle = b2d.rot_get_angle(rot)
    local color = b2d.body_is_awake(body_id) and draw.colors.dynamic or draw.colors.sleeping
    draw.solid_box(pos[1], pos[2], 2, 0.5, angle, color)
    draw.box(pos[1], pos[2], 2, 0.5, angle, {0, 0, 0, 1})

    -- Draw spring body
    local spring_pos = b2d.body_get_position(spring_body_id)
    local spring_rot = b2d.body_get_rotation(spring_body_id)
    local spring_angle = b2d.rot_get_angle(spring_rot)
    local spring_color = b2d.body_is_awake(spring_body_id) and draw.colors.dynamic or draw.colors.sleeping
    draw.solid_box(spring_pos[1], spring_pos[2], 0.5, 0.5, spring_angle, spring_color)
    draw.box(spring_pos[1], spring_pos[2], 0.5, 0.5, spring_angle, {0, 0, 0, 1})

    -- Draw anchor point for spring body
    draw.solid_circle(-2 + 0.25, 2 + 0.25, 0.1, {1, 1, 0, 1})
end

function M.cleanup()
    ground_id = nil
    target_id = nil
    body_id = nil
    joint_id = nil
    spring_body_id = nil
end

return M
