-- cart.lua - Box2D official Cart sample (Robustness)
-- High gravity and high mass ratio test
local b2d = require("b2d")
local draw = require("examples.b2d.draw")

local M = {}

M.camera = {
    center_x = 0,
    center_y = 1,
    zoom = 1.5,
}

local ground_id = nil
local cart_body = nil
local wheel_bodies = {}
local joint_ids = {}

function M.create_scene(world)
    wheel_bodies = {}
    joint_ids = {}

    -- Ground
    local body_def = b2d.default_body_def()
    body_def.position = {0, -1}
    ground_id = b2d.create_body(world, body_def)

    local shape_def = b2d.default_shape_def()
    local box = b2d.make_box(5, 1)
    b2d.create_polygon_shape(ground_id, shape_def, box)

    -- Cart body
    body_def = b2d.default_body_def()
    body_def.type = b2d.BodyType.DYNAMICBODY
    body_def.position = {0, 0.3}
    cart_body = b2d.create_body(world, body_def)

    shape_def = b2d.default_shape_def()
    shape_def.density = 100  -- Heavy
    box = b2d.make_box(0.4, 0.1)
    b2d.create_polygon_shape(cart_body, shape_def, box)

    -- Wheels
    local wheel_radius = 0.1
    local wheel_offset = 0.3

    for i = -1, 1, 2 do
        body_def = b2d.default_body_def()
        body_def.type = b2d.BodyType.DYNAMICBODY
        body_def.position = {i * wheel_offset, 0.1}
        local wheel = b2d.create_body(world, body_def)

        shape_def = b2d.default_shape_def()
        shape_def.density = 1
        local circle = b2d.Circle({center = {0, 0}, radius = wheel_radius})
        b2d.create_circle_shape(wheel, shape_def, circle)
        table.insert(wheel_bodies, wheel)

        -- Wheel joint
        local joint_def = b2d.default_wheel_joint_def()
        joint_def.bodyIdA = cart_body
        joint_def.bodyIdB = wheel
        local frame_a = b2d.Transform()
        frame_a.p = {i * wheel_offset, -0.2}
        frame_a.q = {c = 0, s = 1}  -- Axis pointing up (90 degrees)
        joint_def.localFrameA = frame_a
        local frame_b = b2d.Transform()
        frame_b.p = {0, 0}
        frame_b.q = {c = 1, s = 0}
        joint_def.localFrameB = frame_b
        joint_def.enableSpring = true
        joint_def.hertz = 5
        joint_def.dampingRatio = 0.7
        local joint = b2d.create_wheel_joint(world, joint_def)
        table.insert(joint_ids, joint)
    end
end

function M.render(camera, world)
    -- Draw ground
    draw.solid_box(0, -1, 5, 1, 0, draw.colors.static)
    draw.box(0, -1, 5, 1, 0, {0, 0, 0, 1})

    -- Draw cart body
    if cart_body and b2d.body_is_valid(cart_body) then
        local pos = b2d.body_get_position(cart_body)
        local rot = b2d.body_get_rotation(cart_body)
        local angle = b2d.rot_get_angle(rot)
        local color = b2d.body_is_awake(cart_body) and draw.colors.dynamic or draw.colors.sleeping
        draw.solid_box(pos[1], pos[2], 0.4, 0.1, angle, color)
        draw.box(pos[1], pos[2], 0.4, 0.1, angle, {0, 0, 0, 1})
    end

    -- Draw wheels
    for _, wheel in ipairs(wheel_bodies) do
        if b2d.body_is_valid(wheel) then
            local pos = b2d.body_get_position(wheel)
            local color = b2d.body_is_awake(wheel) and draw.colors.dynamic or draw.colors.sleeping
            draw.solid_circle(pos[1], pos[2], 0.1, color)
            draw.circle(pos[1], pos[2], 0.1, {0, 0, 0, 1})
        end
    end
end

function M.cleanup()
    ground_id = nil
    cart_body = nil
    wheel_bodies = {}
    joint_ids = {}
end

return M
