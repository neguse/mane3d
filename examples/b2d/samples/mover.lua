-- mover.lua - Box2D official Character Mover sample (simplified)
-- Demonstrates character controller using capsule collision queries.
local b2d = require("b2d")
local draw = require("examples.b2d.draw")

local M = {}

M.camera = {
    center_x = 10,
    center_y = 8,
    zoom = 15,
}

local ground_id = nil
local transform = {p = {2, 8}, q = {1, 0}}  -- Position and rotation
local velocity = {0, 0}
local capsule = {center1 = {0, -0.5}, center2 = {0, 0.5}, radius = 0.3}

local platforms = {}  -- Rotating platforms

local max_speed = 10
local gravity = -30
local jump_speed = 12
local can_jump = false

function M.create_scene(world)
    transform = {p = {2, 8}, q = {1, 0}}
    velocity = {0, 0}
    platforms = {}
    can_jump = false

    -- Ground with platforms
    local body_def = b2d.default_body_def()
    ground_id = b2d.create_body(world, body_def)

    local shape_def = b2d.default_shape_def()

    -- Floor
    local segment = b2d.Segment({point1 = {-5, 0}, point2 = {30, 0}})
    b2d.create_segment_shape(ground_id, shape_def, segment)

    -- Walls
    segment = b2d.Segment({point1 = {-5, 0}, point2 = {-5, 20}})
    b2d.create_segment_shape(ground_id, shape_def, segment)

    segment = b2d.Segment({point1 = {30, 0}, point2 = {30, 20}})
    b2d.create_segment_shape(ground_id, shape_def, segment)

    -- Static platforms (stairs)
    local stair_positions = {
        {5, 2}, {8, 4}, {11, 6}, {14, 8}, {17, 10}
    }
    for _, pos in ipairs(stair_positions) do
        local box = b2d.make_offset_box(1.5, 0.1, {pos[1], pos[2]}, {1, 0})
        b2d.create_polygon_shape(ground_id, shape_def, box)
    end

    -- Rotating platforms
    local platform_positions = {{20, 5}, {25, 8}}
    for _, pos in ipairs(platform_positions) do
        body_def = b2d.default_body_def()
        body_def.type = b2d.BodyType.KINEMATICBODY
        body_def.position = pos
        local platform_id = b2d.create_body(world, body_def)

        local box = b2d.make_box(1.5, 0.15)
        b2d.create_polygon_shape(platform_id, shape_def, box)

        -- Rotating joint
        local joint_def = b2d.default_revolute_joint_def()
        joint_def.bodyIdA = ground_id
        joint_def.bodyIdB = platform_id
        local frame_a = b2d.Transform()
        frame_a.p = pos
        frame_a.q = {c = 1, s = 0}
        joint_def.localFrameA = frame_a
        local frame_b = b2d.Transform()
        frame_b.p = {0, 0}
        frame_b.q = {c = 1, s = 0}
        joint_def.localFrameB = frame_b
        joint_def.enableMotor = true
        joint_def.maxMotorTorque = 50
        joint_def.motorSpeed = 1
        b2d.create_revolute_joint(world, joint_def)

        table.insert(platforms, platform_id)
    end
end

M.controls = "WASD/Arrows: Move, Space: Jump"

-- Store key state
local keys = {left = false, right = false, jump = false}

function M.update(world, dt)
    -- Apply gravity
    velocity[2] = velocity[2] + gravity * dt

    -- Horizontal movement
    local target_vx = 0
    if keys.left then target_vx = target_vx - max_speed end
    if keys.right then target_vx = target_vx + max_speed end

    -- Smooth acceleration
    velocity[1] = velocity[1] + (target_vx - velocity[1]) * 10 * dt

    -- Jump
    if keys.jump and can_jump then
        velocity[2] = jump_speed
        can_jump = false
        keys.jump = false
    end

    -- Move with collision
    local new_x = transform.p[1] + velocity[1] * dt
    local new_y = transform.p[2] + velocity[2] * dt

    -- Simple ground collision check
    local foot_y = new_y + capsule.center1[2] - capsule.radius
    if foot_y < 0 then
        new_y = capsule.radius - capsule.center1[2]
        velocity[2] = 0
        can_jump = true
    end

    -- Simple wall collision
    if new_x < -5 + capsule.radius then
        new_x = -5 + capsule.radius
        velocity[1] = 0
    end
    if new_x > 30 - capsule.radius then
        new_x = 30 - capsule.radius
        velocity[1] = 0
    end

    -- Platform collision (simplified - check if above platform)
    local stair_positions = {
        {5, 2}, {8, 4}, {11, 6}, {14, 8}, {17, 10}
    }
    for _, pos in ipairs(stair_positions) do
        local px, py = pos[1], pos[2]
        local hw, hh = 1.5, 0.1

        -- Check if character is above platform and falling
        if new_x > px - hw - capsule.radius and new_x < px + hw + capsule.radius then
            local platform_top = py + hh
            local char_bottom = new_y + capsule.center1[2] - capsule.radius

            if char_bottom < platform_top and char_bottom > platform_top - 0.5 and velocity[2] < 0 then
                new_y = platform_top + capsule.radius - capsule.center1[2]
                velocity[2] = 0
                can_jump = true
            end
        end
    end

    transform.p[1] = new_x
    transform.p[2] = new_y
end

function M.on_key(key, world)
    local app = require("sokol.app")

    if key == app.Keycode.A or key == app.Keycode.LEFT then
        keys.left = true
    elseif key == app.Keycode.D or key == app.Keycode.RIGHT then
        keys.right = true
    elseif key == app.Keycode.W or key == app.Keycode.UP or key == app.Keycode.SPACE then
        keys.jump = true
    end
end

function M.on_key_up(key, world)
    local app = require("sokol.app")

    if key == app.Keycode.A or key == app.Keycode.LEFT then
        keys.left = false
    elseif key == app.Keycode.D or key == app.Keycode.RIGHT then
        keys.right = false
    end
end

function M.render(camera, world)
    -- Draw floor and walls
    draw.line(-5, 0, 30, 0, draw.colors.static)
    draw.line(-5, 0, -5, 20, draw.colors.static)
    draw.line(30, 0, 30, 20, draw.colors.static)

    -- Draw stairs
    local stair_positions = {
        {5, 2}, {8, 4}, {11, 6}, {14, 8}, {17, 10}
    }
    for _, pos in ipairs(stair_positions) do
        draw.solid_box(pos[1], pos[2], 1.5, 0.1, 0, draw.colors.static)
        draw.box(pos[1], pos[2], 1.5, 0.1, 0, {0, 0, 0, 1})
    end

    -- Draw rotating platforms
    for _, platform_id in ipairs(platforms) do
        if b2d.body_is_valid(platform_id) then
            local pos = b2d.body_get_position(platform_id)
            local rot = b2d.body_get_rotation(platform_id)
            local angle = b2d.rot_get_angle(rot)

            draw.solid_box(pos[1], pos[2], 1.5, 0.15, angle, draw.colors.kinematic)
            draw.box(pos[1], pos[2], 1.5, 0.15, angle, {0, 0, 0, 1})
        end
    end

    -- Draw character (capsule approximated as two circles and a box)
    local cx, cy = transform.p[1], transform.p[2]
    local r = capsule.radius
    local half_len = 0.5

    -- Body
    draw.solid_box(cx, cy, r, half_len, 0, {0.2, 0.6, 0.2, 1})

    -- Top circle
    draw.solid_circle(cx, cy + half_len, r, {0.2, 0.6, 0.2, 1})
    draw.circle(cx, cy + half_len, r, {0, 0, 0, 1})

    -- Bottom circle
    draw.solid_circle(cx, cy - half_len, r, {0.2, 0.6, 0.2, 1})
    draw.circle(cx, cy - half_len, r, {0, 0, 0, 1})

    -- Jump indicator
    if can_jump then
        draw.point(cx, cy - half_len - r - 0.1, 3, {0, 1, 0, 1})
    end
end

function M.cleanup()
    ground_id = nil
    transform = {p = {2, 8}, q = {1, 0}}
    velocity = {0, 0}
    platforms = {}
    keys = {left = false, right = false, jump = false}
end

return M
