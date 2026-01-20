-- scissor_lift.lua - Box2D official Scissor Lift sample
-- A scissor mechanism that can lift a platform using a distance joint motor.
local b2d = require("b2d")
local draw = require("examples.b2d.draw")
local imgui = require("imgui")

local M = {}

M.camera = {
    center_x = 0,
    center_y = 9,
    zoom = 25 * 0.4,
}

local ground_id = nil
local body_ids = {}
local platform_id = nil
local lift_joint_id = nil
local link_id1 = nil  -- For distance joint attachment

local enable_motor = false
local motor_speed = 0.25
local motor_force = 2000.0

function M.create_scene(world)
    body_ids = {}

    -- Ground
    local body_def = b2d.default_body_def()
    ground_id = b2d.create_body(world, body_def)
    local shape_def = b2d.default_shape_def()
    local segment = b2d.Segment({point1 = {-20, 0}, point2 = {20, 0}})
    b2d.create_segment_shape(ground_id, shape_def, segment)

    -- Scissor links (capsules)
    body_def = b2d.default_body_def()
    body_def.type = b2d.BodyType.DYNAMICBODY
    body_def.sleepThreshold = 0.01
    shape_def = b2d.default_shape_def()
    local capsule = b2d.Capsule({center1 = {-2.5, 0}, center2 = {2.5, 0}, radius = 0.15})

    local base_id1 = ground_id
    local base_id2 = ground_id
    local base_anchor1 = {-2.5, 0.2}
    local base_anchor2 = {2.5, 0.2}
    local y = 0.5
    local N = 3

    local constraint_damping_ratio = 20.0
    local constraint_hertz = 240.0

    for i = 0, N - 1 do
        -- Left link (tilted positive)
        body_def.position = {0, y}
        body_def.rotation = b2d.make_rot(0.15)
        local body1 = b2d.create_body(world, body_def)
        b2d.create_capsule_shape(body1, shape_def, capsule)
        table.insert(body_ids, body1)

        -- Right link (tilted negative)
        body_def.position = {0, y}
        body_def.rotation = b2d.make_rot(-0.15)
        local body2 = b2d.create_body(world, body_def)
        b2d.create_capsule_shape(body2, shape_def, capsule)
        table.insert(body_ids, body2)

        if i == 1 then
            link_id1 = body2  -- Save for distance joint
        end

        local revolute_def = b2d.default_revolute_joint_def()

        -- Left pin
        revolute_def.bodyIdA = base_id1
        revolute_def.bodyIdB = body1
        revolute_def.localFrameA = b2d.Transform({p = base_anchor1, q = {1, 0}})
        revolute_def.localFrameB = b2d.Transform({p = {-2.5, 0}, q = {1, 0}})
        revolute_def.collideConnected = (i == 0)
        b2d.create_revolute_joint(world, revolute_def)

        -- Right pin
        if i == 0 then
            -- Use wheel joint for sliding base
            local wheel_def = b2d.default_wheel_joint_def()
            wheel_def.bodyIdA = base_id2
            wheel_def.bodyIdB = body2
            wheel_def.localFrameA = b2d.Transform({p = base_anchor2, q = {1, 0}})
            wheel_def.localFrameB = b2d.Transform({p = {2.5, 0}, q = {1, 0}})
            wheel_def.enableSpring = false
            wheel_def.collideConnected = true
            b2d.create_wheel_joint(world, wheel_def)
        else
            revolute_def.bodyIdA = base_id2
            revolute_def.bodyIdB = body2
            revolute_def.localFrameA = b2d.Transform({p = base_anchor2, q = {1, 0}})
            revolute_def.localFrameB = b2d.Transform({p = {2.5, 0}, q = {1, 0}})
            revolute_def.collideConnected = false
            b2d.create_revolute_joint(world, revolute_def)
        end

        -- Middle pin (X crossing)
        revolute_def.bodyIdA = body1
        revolute_def.bodyIdB = body2
        revolute_def.localFrameA = b2d.Transform({p = {0, 0}, q = {1, 0}})
        revolute_def.localFrameB = b2d.Transform({p = {0, 0}, q = {1, 0}})
        revolute_def.collideConnected = false
        b2d.create_revolute_joint(world, revolute_def)

        -- Swap for next level
        base_id1 = body2
        base_id2 = body1
        base_anchor1 = {-2.5, 0}
        base_anchor2 = {2.5, 0}
        y = y + 1.0
    end

    -- Platform on top
    body_def.position = {0, y}
    body_def.rotation = b2d.make_rot(0)
    platform_id = b2d.create_body(world, body_def)
    local box = b2d.make_box(3.0, 0.2)
    b2d.create_polygon_shape(platform_id, shape_def, box)

    -- Connect platform to top links
    local revolute_def = b2d.default_revolute_joint_def()
    revolute_def.bodyIdA = platform_id
    revolute_def.bodyIdB = base_id1
    revolute_def.localFrameA = b2d.Transform({p = {-2.5, -0.4}, q = {1, 0}})
    revolute_def.localFrameB = b2d.Transform({p = base_anchor1, q = {1, 0}})
    revolute_def.collideConnected = true
    b2d.create_revolute_joint(world, revolute_def)

    -- Wheel joint for sliding platform connection
    local wheel_def = b2d.default_wheel_joint_def()
    wheel_def.bodyIdA = platform_id
    wheel_def.bodyIdB = base_id2
    wheel_def.localFrameA = b2d.Transform({p = {2.5, -0.4}, q = {1, 0}})
    wheel_def.localFrameB = b2d.Transform({p = base_anchor2, q = {1, 0}})
    wheel_def.enableSpring = false
    wheel_def.collideConnected = true
    b2d.create_wheel_joint(world, wheel_def)

    -- Distance joint for lift motor
    local distance_def = b2d.default_distance_joint_def()
    distance_def.bodyIdA = ground_id
    distance_def.bodyIdB = link_id1
    distance_def.localFrameA = b2d.Transform({p = {-2.5, 0.2}, q = {1, 0}})
    distance_def.localFrameB = b2d.Transform({p = {0.5, 0}, q = {1, 0}})
    distance_def.enableSpring = true
    distance_def.minLength = 0.2
    distance_def.maxLength = 5.5
    distance_def.enableLimit = true
    distance_def.enableMotor = enable_motor
    distance_def.motorSpeed = motor_speed
    distance_def.maxMotorForce = motor_force
    lift_joint_id = b2d.create_distance_joint(world, distance_def)
end

function M.update_gui(world)
    imgui.begin_window("Scissor Lift")

    local changed
    changed, enable_motor = imgui.checkbox("Motor", enable_motor)
    if changed then
        b2d.distance_joint_enable_motor(lift_joint_id, enable_motor)
        b2d.joint_wake_bodies(lift_joint_id)
    end

    changed, motor_force = imgui.slider_float("Max Force", motor_force, 0, 3000)
    if changed then
        b2d.distance_joint_set_max_motor_force(lift_joint_id, motor_force)
        b2d.joint_wake_bodies(lift_joint_id)
    end

    changed, motor_speed = imgui.slider_float("Speed", motor_speed, -0.3, 0.3)
    if changed then
        b2d.distance_joint_set_motor_speed(lift_joint_id, motor_speed)
        b2d.joint_wake_bodies(lift_joint_id)
    end

    imgui.end_window()
end

function M.render(camera, world)
    -- Ground
    draw.line(-20, 0, 20, 0, draw.colors.static)

    -- Draw scissor links (capsules)
    for _, body_id in ipairs(body_ids) do
        local pos = b2d.body_get_position(body_id)
        local rot = b2d.body_get_rotation(body_id)
        local angle = b2d.rot_get_angle(rot)
        local color = b2d.body_is_awake(body_id) and draw.colors.dynamic or draw.colors.sleeping

        local c, s = math.cos(angle), math.sin(angle)
        local c1x = pos[1] + (-2.5) * c
        local c1y = pos[2] + (-2.5) * s
        local c2x = pos[1] + (2.5) * c
        local c2y = pos[2] + (2.5) * s
        draw.solid_capsule(c1x, c1y, c2x, c2y, 0.15, color)
        draw.capsule(c1x, c1y, c2x, c2y, 0.15, {0, 0, 0, 1})
    end

    -- Draw platform
    local plat_pos = b2d.body_get_position(platform_id)
    local plat_rot = b2d.body_get_rotation(platform_id)
    local plat_angle = b2d.rot_get_angle(plat_rot)
    local plat_color = b2d.body_is_awake(platform_id) and draw.colors.dynamic or draw.colors.sleeping
    draw.solid_box(plat_pos[1], plat_pos[2], 3.0, 0.2, plat_angle, plat_color)
    draw.box(plat_pos[1], plat_pos[2], 3.0, 0.2, plat_angle, {0, 0, 0, 1})
end

function M.cleanup()
    ground_id = nil
    body_ids = {}
    platform_id = nil
    lift_joint_id = nil
    link_id1 = nil
end

return M
