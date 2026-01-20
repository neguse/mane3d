-- driving.lua - Box2D official Driving sample (simplified)
-- A simple car with wheel joints that can be driven on terrain.
local b2d = require("b2d")
local draw = require("examples.b2d.draw")
local imgui = require("imgui")

local M = {}

M.camera = {
    center_x = 0,
    center_y = 5,
    zoom = 25 * 0.4,
}

local ground_id = nil
local chassis_id = nil
local wheel_front_id = nil
local wheel_rear_id = nil
local joint_front_id = nil
local joint_rear_id = nil

local throttle = 0.0
local speed = 35.0
local torque = 5.0
local hertz = 5.0
local damping_ratio = 0.7

function M.create_scene(world)
    -- Ground
    local body_def = b2d.default_body_def()
    ground_id = b2d.create_body(world, body_def)

    local shape_def = b2d.default_shape_def()

    -- Flat ground with hills
    local segments = {
        {{-20, 0}, {20, 0}},
        {{20, 0}, {25, 0.25}},
        {{25, 0.25}, {30, 1}},
        {{30, 1}, {35, 4}},
        {{35, 4}, {40, 0}},
        {{40, 0}, {50, 0}},
        {{50, 0}, {55, -1}},
        {{55, -1}, {60, -2}},
        {{60, -2}, {70, -2}},
        {{70, -2}, {80, -1.25}},
        {{80, -1.25}, {90, 0}},
        {{90, 0}, {100, 0}},
        -- Jump ramp
        {{100, 0}, {110, 5}},
        {{110, 5}, {120, 5}},
        {{120, 5}, {130, 0}},
        {{130, 0}, {150, 0}},
    }

    for _, seg in ipairs(segments) do
        local segment = b2d.Segment({point1 = seg[1], point2 = seg[2]})
        b2d.create_segment_shape(ground_id, shape_def, segment)
    end

    -- Create car chassis
    body_def = b2d.default_body_def()
    body_def.type = b2d.BodyType.DYNAMICBODY
    body_def.position = {0, 1}
    chassis_id = b2d.create_body(world, body_def)

    local chassis_box = b2d.make_box(2.0, 0.5)
    shape_def = b2d.default_shape_def()
    shape_def.density = 1.0
    b2d.create_polygon_shape(chassis_id, shape_def, chassis_box)

    -- Front wheel
    body_def.position = {1.5, 0.5}
    wheel_front_id = b2d.create_body(world, body_def)

    local circle = b2d.Circle({center = {0, 0}, radius = 0.4})
    shape_def = b2d.default_shape_def()
    shape_def.density = 1.0
    shape_def.friction = 0.9
    b2d.create_circle_shape(wheel_front_id, shape_def, circle)

    -- Rear wheel
    body_def.position = {-1.5, 0.5}
    wheel_rear_id = b2d.create_body(world, body_def)
    b2d.create_circle_shape(wheel_rear_id, shape_def, circle)

    -- Front wheel joint
    local wheel_def = b2d.default_wheel_joint_def()
    wheel_def.bodyIdA = chassis_id
    wheel_def.bodyIdB = wheel_front_id
    wheel_def.localFrameA = b2d.Transform({p = {1.5, -0.5}, q = {1, 0}})
    wheel_def.localFrameB = b2d.Transform({p = {0, 0}, q = {1, 0}})
    wheel_def.enableSpring = true
    wheel_def.hertz = hertz
    wheel_def.dampingRatio = damping_ratio
    wheel_def.lowerTranslation = -0.25
    wheel_def.upperTranslation = 0.25
    wheel_def.enableLimit = true
    wheel_def.enableMotor = true
    wheel_def.maxMotorTorque = torque
    wheel_def.motorSpeed = 0
    joint_front_id = b2d.create_wheel_joint(world, wheel_def)

    -- Rear wheel joint (driven wheel)
    wheel_def.bodyIdA = chassis_id
    wheel_def.bodyIdB = wheel_rear_id
    wheel_def.localFrameA = b2d.Transform({p = {-1.5, -0.5}, q = {1, 0}})
    wheel_def.localFrameB = b2d.Transform({p = {0, 0}, q = {1, 0}})
    joint_rear_id = b2d.create_wheel_joint(world, wheel_def)
end

function M.update(world, dt)
    -- Update camera to follow car
    local pos = b2d.body_get_position(chassis_id)
    M.camera.center_x = pos[1]
end

function M.update_gui(world)
    imgui.begin_window("Driving")

    local changed
    changed, hertz = imgui.slider_float("Spring Hertz", hertz, 0, 20)
    if changed then
        b2d.wheel_joint_set_spring_hertz(joint_front_id, hertz)
        b2d.wheel_joint_set_spring_hertz(joint_rear_id, hertz)
    end

    changed, damping_ratio = imgui.slider_float("Damping Ratio", damping_ratio, 0, 10)
    if changed then
        b2d.wheel_joint_set_spring_damping_ratio(joint_front_id, damping_ratio)
        b2d.wheel_joint_set_spring_damping_ratio(joint_rear_id, damping_ratio)
    end

    changed, speed = imgui.slider_float("Speed", speed, 0, 50)

    changed, torque = imgui.slider_float("Torque", torque, 0, 10)
    if changed then
        b2d.wheel_joint_set_max_motor_torque(joint_front_id, torque)
        b2d.wheel_joint_set_max_motor_torque(joint_rear_id, torque)
    end

    local vel = b2d.body_get_linear_velocity(chassis_id)
    local kph = vel[1] * 3.6
    imgui.text_unformatted(string.format("Speed: %.1f km/h", kph))
    imgui.text_unformatted("A: Left, S: Brake, D: Right")

    imgui.end_window()
end

M.controls = "A: Left, S: Brake, D: Right"

function M.on_key(key, world)
    local app = require("sokol.app")
    if key == app.Keycode.A then
        throttle = 1.0
        b2d.wheel_joint_set_motor_speed(joint_front_id, speed)
        b2d.wheel_joint_set_motor_speed(joint_rear_id, speed)
        b2d.joint_wake_bodies(joint_front_id)
        b2d.joint_wake_bodies(joint_rear_id)
    elseif key == app.Keycode.S then
        throttle = 0.0
        b2d.wheel_joint_set_motor_speed(joint_front_id, 0)
        b2d.wheel_joint_set_motor_speed(joint_rear_id, 0)
        b2d.joint_wake_bodies(joint_front_id)
        b2d.joint_wake_bodies(joint_rear_id)
    elseif key == app.Keycode.D then
        throttle = -1.0
        b2d.wheel_joint_set_motor_speed(joint_front_id, -speed)
        b2d.wheel_joint_set_motor_speed(joint_rear_id, -speed)
        b2d.joint_wake_bodies(joint_front_id)
        b2d.joint_wake_bodies(joint_rear_id)
    end
end

function M.render(camera, world)
    -- Draw ground
    local segments = {
        {{-20, 0}, {20, 0}},
        {{20, 0}, {25, 0.25}},
        {{25, 0.25}, {30, 1}},
        {{30, 1}, {35, 4}},
        {{35, 4}, {40, 0}},
        {{40, 0}, {50, 0}},
        {{50, 0}, {55, -1}},
        {{55, -1}, {60, -2}},
        {{60, -2}, {70, -2}},
        {{70, -2}, {80, -1.25}},
        {{80, -1.25}, {90, 0}},
        {{90, 0}, {100, 0}},
        {{100, 0}, {110, 5}},
        {{110, 5}, {120, 5}},
        {{120, 5}, {130, 0}},
        {{130, 0}, {150, 0}},
    }

    for _, seg in ipairs(segments) do
        draw.line(seg[1][1], seg[1][2], seg[2][1], seg[2][2], draw.colors.static)
    end

    -- Draw chassis
    local pos = b2d.body_get_position(chassis_id)
    local rot = b2d.body_get_rotation(chassis_id)
    local angle = b2d.rot_get_angle(rot)
    local color = b2d.body_is_awake(chassis_id) and draw.colors.dynamic or draw.colors.sleeping
    draw.solid_box(pos[1], pos[2], 2.0, 0.5, angle, color)
    draw.box(pos[1], pos[2], 2.0, 0.5, angle, {0, 0, 0, 1})

    -- Draw front wheel
    pos = b2d.body_get_position(wheel_front_id)
    color = b2d.body_is_awake(wheel_front_id) and draw.colors.dynamic or draw.colors.sleeping
    draw.solid_circle(pos[1], pos[2], 0.4, color)
    draw.circle(pos[1], pos[2], 0.4, {0, 0, 0, 1})

    -- Draw rear wheel
    pos = b2d.body_get_position(wheel_rear_id)
    color = b2d.body_is_awake(wheel_rear_id) and draw.colors.dynamic or draw.colors.sleeping
    draw.solid_circle(pos[1], pos[2], 0.4, color)
    draw.circle(pos[1], pos[2], 0.4, {0, 0, 0, 1})
end

function M.cleanup()
    ground_id = nil
    chassis_id = nil
    wheel_front_id = nil
    wheel_rear_id = nil
    joint_front_id = nil
    joint_rear_id = nil
end

return M
