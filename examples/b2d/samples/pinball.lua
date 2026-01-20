-- pinball.lua - Box2D official Pinball sample
-- Demonstrates a pinball machine with flippers and spinners.
local b2d = require("b2d")
local draw = require("examples.b2d.draw")

local M = {}

M.camera = {
    center_x = 0,
    center_y = 9,
    zoom = 12.5,
}

local ground_id = nil
local ball_id = nil
local left_flipper_id = nil
local right_flipper_id = nil
local left_joint_id = nil
local right_joint_id = nil
local spinner_ids = {}
local left_pressed = false
local right_pressed = false

local function create_ball(world)
    if ball_id and b2d.body_is_valid(ball_id) then
        b2d.destroy_body(ball_id)
    end

    local body_def = b2d.default_body_def()
    body_def.type = b2d.BodyType.DYNAMICBODY
    body_def.position = {0, 15}
    body_def.isBullet = true

    ball_id = b2d.create_body(world, body_def)

    local shape_def = b2d.default_shape_def()
    shape_def.material = b2d.SurfaceMaterial({restitution = 0.3})
    local circle = b2d.Circle({center = {0, 0}, radius = 0.4})
    b2d.create_circle_shape(ball_id, shape_def, circle)
end

function M.create_scene(world)
    spinner_ids = {}
    left_pressed = false
    right_pressed = false

    -- Ground body with chain walls
    local body_def = b2d.default_body_def()
    ground_id = b2d.create_body(world, body_def)

    local points = {{-8, 6}, {-8, 20}, {8, 20}, {8, 6}, {0, -2}}
    local chain_def = b2d.default_chain_def()
    chain_def.points = points
    chain_def.count = #points
    chain_def.isLoop = true
    b2d.create_chain(ground_id, chain_def)

    -- Flippers
    local p1 = {-2, 0}
    local p2 = {2, 0}

    body_def = b2d.default_body_def()
    body_def.type = b2d.BodyType.DYNAMICBODY
    body_def.enableSleep = false

    body_def.position = p1
    left_flipper_id = b2d.create_body(world, body_def)

    body_def.position = p2
    right_flipper_id = b2d.create_body(world, body_def)

    local box = b2d.make_box(1.75, 0.2)
    local shape_def = b2d.default_shape_def()

    b2d.create_polygon_shape(left_flipper_id, shape_def, box)
    b2d.create_polygon_shape(right_flipper_id, shape_def, box)

    -- Flipper joints
    local joint_def = b2d.default_revolute_joint_def()
    joint_def.bodyIdA = ground_id
    local frame_b = b2d.Transform()
    frame_b.p = {0, 0}
    frame_b.q = {c = 1, s = 0}
    joint_def.localFrameB = frame_b
    joint_def.enableMotor = true
    joint_def.maxMotorTorque = 1000
    joint_def.enableLimit = true

    joint_def.motorSpeed = 0
    local frame_a = b2d.Transform()
    frame_a.p = p1
    frame_a.q = {c = 1, s = 0}
    joint_def.localFrameA = frame_a
    joint_def.bodyIdB = left_flipper_id
    joint_def.lowerAngle = -30 * math.pi / 180
    joint_def.upperAngle = 5 * math.pi / 180
    left_joint_id = b2d.create_revolute_joint(world, joint_def)

    joint_def.motorSpeed = 0
    frame_a = b2d.Transform()
    frame_a.p = p2
    frame_a.q = {c = 1, s = 0}
    joint_def.localFrameA = frame_a
    joint_def.bodyIdB = right_flipper_id
    joint_def.lowerAngle = -5 * math.pi / 180
    joint_def.upperAngle = 30 * math.pi / 180
    right_joint_id = b2d.create_revolute_joint(world, joint_def)

    -- Spinners
    local spinner_positions = {{-4, 17}, {4, 8}}

    for _, pos in ipairs(spinner_positions) do
        body_def = b2d.default_body_def()
        body_def.type = b2d.BodyType.DYNAMICBODY
        body_def.position = pos

        local spinner_id = b2d.create_body(world, body_def)

        local box1 = b2d.make_box(1.5, 0.125)
        local box2 = b2d.make_box(0.125, 1.5)

        b2d.create_polygon_shape(spinner_id, shape_def, box1)
        b2d.create_polygon_shape(spinner_id, shape_def, box2)

        joint_def = b2d.default_revolute_joint_def()
        joint_def.bodyIdA = ground_id
        joint_def.bodyIdB = spinner_id
        local spinner_frame_a = b2d.Transform()
        spinner_frame_a.p = pos
        spinner_frame_a.q = {c = 1, s = 0}
        joint_def.localFrameA = spinner_frame_a
        local spinner_frame_b = b2d.Transform()
        spinner_frame_b.p = {0, 0}
        spinner_frame_b.q = {c = 1, s = 0}
        joint_def.localFrameB = spinner_frame_b
        joint_def.enableMotor = true
        joint_def.maxMotorTorque = 0.1
        b2d.create_revolute_joint(world, joint_def)

        table.insert(spinner_ids, spinner_id)
    end

    -- Ball
    create_ball(world)
end

M.controls = "A/D or Left/Right: Flippers, Space: New ball"

function M.update(world, dt)
    -- Update flipper motors
    local left_speed = left_pressed and 20 or -10
    local right_speed = right_pressed and -20 or 10

    if left_joint_id and b2d.joint_is_valid(left_joint_id) then
        b2d.revolute_joint_set_motor_speed(left_joint_id, left_speed)
    end
    if right_joint_id and b2d.joint_is_valid(right_joint_id) then
        b2d.revolute_joint_set_motor_speed(right_joint_id, right_speed)
    end
end

function M.on_key(key, world)
    local app = require("sokol.app")

    if key == app.Keycode.A or key == app.Keycode.LEFT then
        left_pressed = true
    elseif key == app.Keycode.D or key == app.Keycode.RIGHT then
        right_pressed = true
    elseif key == app.Keycode.SPACE then
        create_ball(world)
    end
end

-- Key release handler (called from sample_event if available)
function M.on_key_up(key, world)
    local app = require("sokol.app")

    if key == app.Keycode.A or key == app.Keycode.LEFT then
        left_pressed = false
    elseif key == app.Keycode.D or key == app.Keycode.RIGHT then
        right_pressed = false
    end
end

function M.render(camera, world)
    -- Draw walls
    local walls = {{-8, 6}, {-8, 20}, {8, 20}, {8, 6}, {0, -2}, {-8, 6}}
    for i = 1, #walls - 1 do
        draw.line(walls[i][1], walls[i][2], walls[i+1][1], walls[i+1][2], draw.colors.static)
    end

    -- Draw flippers
    for _, flipper in ipairs({left_flipper_id, right_flipper_id}) do
        if flipper and b2d.body_is_valid(flipper) then
            local pos = b2d.body_get_position(flipper)
            local rot = b2d.body_get_rotation(flipper)
            local angle = b2d.rot_get_angle(rot)

            draw.solid_box(pos[1], pos[2], 1.75, 0.2, angle, draw.colors.dynamic)
            draw.box(pos[1], pos[2], 1.75, 0.2, angle, {0, 0, 0, 1})
        end
    end

    -- Draw spinners
    for _, spinner_id in ipairs(spinner_ids) do
        if b2d.body_is_valid(spinner_id) then
            local pos = b2d.body_get_position(spinner_id)
            local rot = b2d.body_get_rotation(spinner_id)
            local angle = b2d.rot_get_angle(rot)

            draw.solid_box(pos[1], pos[2], 1.5, 0.125, angle, draw.colors.kinematic)
            draw.solid_box(pos[1], pos[2], 0.125, 1.5, angle, draw.colors.kinematic)
            draw.box(pos[1], pos[2], 1.5, 0.125, angle, {0, 0, 0, 1})
            draw.box(pos[1], pos[2], 0.125, 1.5, angle, {0, 0, 0, 1})
        end
    end

    -- Draw ball
    if ball_id and b2d.body_is_valid(ball_id) then
        local pos = b2d.body_get_position(ball_id)
        local color = b2d.body_is_awake(ball_id) and {0.8, 0.3, 0.3, 1} or draw.colors.sleeping

        draw.solid_circle(pos[1], pos[2], 0.4, color)
        draw.circle(pos[1], pos[2], 0.4, {0, 0, 0, 1})
    end
end

function M.cleanup()
    ground_id = nil
    ball_id = nil
    left_flipper_id = nil
    right_flipper_id = nil
    left_joint_id = nil
    right_joint_id = nil
    spinner_ids = {}
    left_pressed = false
    right_pressed = false
end

return M
