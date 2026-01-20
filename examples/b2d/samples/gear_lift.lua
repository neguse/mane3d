-- gear_lift.lua - Box2D official Gear Lift sample (simplified)
-- Two meshing gears that drive a chain lifting a door.
local b2d = require("b2d")
local draw = require("examples.b2d.draw")
local imgui = require("imgui")

local M = {}

M.camera = {
    center_x = 0,
    center_y = 6,
    zoom = 7,
}

local ground_id = nil
local driver_gear_id = nil
local follower_gear_id = nil
local link_ids = {}
local door_id = nil
local driver_joint_id = nil

local motor_torque = 80.0
local motor_speed = 0.0
local enable_motor = true

local gear_radius = 1.0
local tooth_count = 16
local tooth_half_width = 0.09
local tooth_half_height = 0.06
local link_half_length = 0.07
local link_radius = 0.05
local link_count = 40
local door_half_height = 1.5

local gear_position1 = {-4.25, 9.75}
local gear_position2 = {-2.25, 10.75}  -- gear_position1 + {2.0, 1.0}

local function create_gear(world, position, is_driver)
    local body_def = b2d.default_body_def()
    body_def.type = b2d.BodyType.DYNAMICBODY
    body_def.position = position

    local gear_id = b2d.create_body(world, body_def)

    local shape_def = b2d.default_shape_def()
    shape_def.friction = 0.1

    -- Main gear circle
    local circle = b2d.Circle({center = {0, 0}, radius = gear_radius})
    b2d.create_circle_shape(gear_id, shape_def, circle)

    -- Teeth around the gear
    local delta_angle = 2.0 * math.pi / tooth_count
    for i = 0, tooth_count - 1 do
        local angle = i * delta_angle
        local c, s = math.cos(angle), math.sin(angle)
        local center_x = (gear_radius + tooth_half_height) * c
        local center_y = (gear_radius + tooth_half_height) * s
        local rot = b2d.make_rot(angle)
        local tooth = b2d.make_offset_rounded_box(tooth_half_width, tooth_half_height, {center_x, center_y}, rot, 0.03)
        b2d.create_polygon_shape(gear_id, shape_def, tooth)
    end

    return gear_id
end

function M.create_scene(world)
    link_ids = {}

    -- Ground
    local body_def = b2d.default_body_def()
    ground_id = b2d.create_body(world, body_def)

    -- Ground segment
    local shape_def = b2d.default_shape_def()
    local segment = b2d.Segment({point1 = {-10, 0}, point2 = {10, 0}})
    b2d.create_segment_shape(ground_id, shape_def, segment)

    -- Driver gear
    driver_gear_id = create_gear(world, gear_position1, true)

    -- Revolute joint for driver gear
    local revolute_def = b2d.default_revolute_joint_def()
    revolute_def.bodyIdA = ground_id
    revolute_def.bodyIdB = driver_gear_id
    revolute_def.localFrameA = b2d.Transform({p = gear_position1, q = {1, 0}})
    revolute_def.localFrameB = b2d.Transform({p = {0, 0}, q = {1, 0}})
    revolute_def.enableMotor = enable_motor
    revolute_def.maxMotorTorque = motor_torque
    revolute_def.motorSpeed = motor_speed
    driver_joint_id = b2d.create_revolute_joint(world, revolute_def)

    -- Follower gear
    follower_gear_id = create_gear(world, gear_position2, false)

    -- Revolute joint for follower gear with limits
    local half_pi = 0.5 * math.pi
    revolute_def = b2d.default_revolute_joint_def()
    revolute_def.bodyIdA = ground_id
    revolute_def.bodyIdB = follower_gear_id
    local rot_q = b2d.make_rot(0.25 * math.pi)
    revolute_def.localFrameA = b2d.Transform({p = gear_position2, q = rot_q})
    revolute_def.localFrameB = b2d.Transform({p = {0, 0}, q = {1, 0}})
    revolute_def.enableMotor = true
    revolute_def.maxMotorTorque = 0.5
    revolute_def.lowerAngle = -0.3 * math.pi
    revolute_def.upperAngle = 0.8 * math.pi
    revolute_def.enableLimit = true
    b2d.create_revolute_joint(world, revolute_def)

    -- Chain links
    local link_attach_x = gear_position2[1] + gear_radius + 2 * tooth_half_width + 0.03
    local link_attach_y = gear_position2[2]
    local position_x = link_attach_x
    local position_y = link_attach_y - link_half_length

    local capsule = b2d.Capsule({
        center1 = {0, -link_half_length},
        center2 = {0, link_half_length},
        radius = link_radius
    })

    shape_def = b2d.default_shape_def()
    shape_def.density = 2.0

    local prev_body_id = follower_gear_id
    for i = 1, link_count do
        body_def = b2d.default_body_def()
        body_def.type = b2d.BodyType.DYNAMICBODY
        body_def.position = {position_x, position_y}

        local link_id = b2d.create_body(world, body_def)
        b2d.create_capsule_shape(link_id, shape_def, capsule)
        table.insert(link_ids, link_id)

        -- Revolute joint connecting links
        local pivot = {position_x, position_y + link_half_length}
        local joint_def = b2d.default_revolute_joint_def()
        joint_def.bodyIdA = prev_body_id
        joint_def.bodyIdB = link_id
        joint_def.localFrameA = b2d.Transform({p = b2d.body_get_local_point(prev_body_id, pivot), q = {1, 0}})
        joint_def.localFrameB = b2d.Transform({p = {0, link_half_length}, q = {1, 0}})
        joint_def.enableMotor = true
        joint_def.maxMotorTorque = 0.05
        b2d.create_revolute_joint(world, joint_def)

        position_y = position_y - 2 * link_half_length
        prev_body_id = link_id
    end

    local last_link_id = prev_body_id

    -- Door
    local door_position = {link_attach_x, position_y + link_half_length - door_half_height}
    body_def = b2d.default_body_def()
    body_def.type = b2d.BodyType.DYNAMICBODY
    body_def.position = door_position
    door_id = b2d.create_body(world, body_def)

    local box = b2d.make_box(0.15, door_half_height)
    shape_def = b2d.default_shape_def()
    shape_def.friction = 0.1
    b2d.create_polygon_shape(door_id, shape_def, box)

    -- Connect door to last link
    local pivot = {door_position[1], door_position[2] + door_half_height}
    revolute_def = b2d.default_revolute_joint_def()
    revolute_def.bodyIdA = last_link_id
    revolute_def.bodyIdB = door_id
    revolute_def.localFrameA = b2d.Transform({p = b2d.body_get_local_point(last_link_id, pivot), q = {1, 0}})
    revolute_def.localFrameB = b2d.Transform({p = {0, door_half_height}, q = {1, 0}})
    revolute_def.enableMotor = true
    revolute_def.maxMotorTorque = 0.05
    b2d.create_revolute_joint(world, revolute_def)

    -- Prismatic joint for door (vertical guide)
    local prismatic_def = b2d.default_prismatic_joint_def()
    prismatic_def.bodyIdA = ground_id
    prismatic_def.bodyIdB = door_id
    local up_rot = b2d.make_rot(0.5 * math.pi)  -- vertical axis
    prismatic_def.localFrameA = b2d.Transform({p = door_position, q = up_rot})
    prismatic_def.localFrameB = b2d.Transform({p = {0, 0}, q = up_rot})
    prismatic_def.maxMotorForce = 0.2
    prismatic_def.enableMotor = true
    prismatic_def.collideConnected = true
    b2d.create_prismatic_joint(world, prismatic_def)
end

function M.update_gui(world)
    imgui.begin_window("Gear Lift")

    local changed
    changed, enable_motor = imgui.checkbox("Motor", enable_motor)
    if changed then
        b2d.revolute_joint_enable_motor(driver_joint_id, enable_motor)
        b2d.joint_wake_bodies(driver_joint_id)
    end

    changed, motor_torque = imgui.slider_float("Max Torque", motor_torque, 0, 100)
    if changed then
        b2d.revolute_joint_set_max_motor_torque(driver_joint_id, motor_torque)
        b2d.joint_wake_bodies(driver_joint_id)
    end

    changed, motor_speed = imgui.slider_float("Speed", motor_speed, -0.3, 0.3)
    if changed then
        b2d.revolute_joint_set_motor_speed(driver_joint_id, motor_speed)
        b2d.joint_wake_bodies(driver_joint_id)
    end

    imgui.text_unformatted("A/D: Control speed")

    imgui.end_window()
end

M.controls = "A: Decrease speed, D: Increase speed"

function M.on_key(key, world)
    local app = require("sokol.app")
    if key == app.Keycode.A then
        motor_speed = math.max(-0.3, motor_speed - 0.01)
        b2d.revolute_joint_set_motor_speed(driver_joint_id, motor_speed)
        b2d.joint_wake_bodies(driver_joint_id)
    elseif key == app.Keycode.D then
        motor_speed = math.min(0.3, motor_speed + 0.01)
        b2d.revolute_joint_set_motor_speed(driver_joint_id, motor_speed)
        b2d.joint_wake_bodies(driver_joint_id)
    end
end

function M.render(camera, world)
    -- Ground
    draw.line(-10, 0, 10, 0, draw.colors.static)

    -- Draw gears (simplified as circles with radiating lines for teeth)
    local function draw_gear(gear_id)
        local pos = b2d.body_get_position(gear_id)
        local rot = b2d.body_get_rotation(gear_id)
        local angle = b2d.rot_get_angle(rot)
        local color = b2d.body_is_awake(gear_id) and draw.colors.dynamic or draw.colors.sleeping

        -- Main circle
        draw.solid_circle(pos[1], pos[2], gear_radius, color)
        draw.circle(pos[1], pos[2], gear_radius, {0, 0, 0, 1})

        -- Teeth indicators
        local delta_angle = 2.0 * math.pi / tooth_count
        for i = 0, tooth_count - 1 do
            local tooth_angle = angle + i * delta_angle
            local c, s = math.cos(tooth_angle), math.sin(tooth_angle)
            local inner_r = gear_radius
            local outer_r = gear_radius + 2 * tooth_half_height
            draw.line(
                pos[1] + inner_r * c, pos[2] + inner_r * s,
                pos[1] + outer_r * c, pos[2] + outer_r * s,
                {0.5, 0.5, 0.5, 1}
            )
        end
    end

    draw_gear(driver_gear_id)
    draw_gear(follower_gear_id)

    -- Draw links
    for _, link_id in ipairs(link_ids) do
        local pos = b2d.body_get_position(link_id)
        local rot = b2d.body_get_rotation(link_id)
        local angle = b2d.rot_get_angle(rot)
        local color = b2d.body_is_awake(link_id) and draw.colors.dynamic or draw.colors.sleeping

        local c, s = math.cos(angle), math.sin(angle)
        local c1x = pos[1] + (-link_half_length) * (-s)
        local c1y = pos[2] + (-link_half_length) * c
        local c2x = pos[1] + link_half_length * (-s)
        local c2y = pos[2] + link_half_length * c
        draw.solid_capsule(c1x, c1y, c2x, c2y, link_radius, color)
        draw.capsule(c1x, c1y, c2x, c2y, link_radius, {0, 0, 0, 1})
    end

    -- Draw door
    local door_pos = b2d.body_get_position(door_id)
    local door_rot = b2d.body_get_rotation(door_id)
    local door_angle = b2d.rot_get_angle(door_rot)
    local door_color = b2d.body_is_awake(door_id) and draw.colors.dynamic or draw.colors.sleeping
    draw.solid_box(door_pos[1], door_pos[2], 0.15, door_half_height, door_angle, door_color)
    draw.box(door_pos[1], door_pos[2], 0.15, door_half_height, door_angle, {0, 0, 0, 1})
end

function M.cleanup()
    ground_id = nil
    driver_gear_id = nil
    follower_gear_id = nil
    link_ids = {}
    door_id = nil
    driver_joint_id = nil
end

return M
