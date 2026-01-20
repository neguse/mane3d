-- top_down_friction.lua - Box2D official Top Down Friction sample
-- Demonstrates using motor joints to simulate top-down friction.
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
local body_ids = {}

function M.create_scene(world)
    body_ids = {}

    -- Ground (walls forming a box)
    local body_def = b2d.default_body_def()
    ground_id = b2d.create_body(world, body_def)

    local shape_def = b2d.default_shape_def()

    -- Bottom
    local segment = b2d.Segment({point1 = {-10, 0}, point2 = {10, 0}})
    b2d.create_segment_shape(ground_id, shape_def, segment)

    -- Left
    segment = b2d.Segment({point1 = {-10, 0}, point2 = {-10, 20}})
    b2d.create_segment_shape(ground_id, shape_def, segment)

    -- Right
    segment = b2d.Segment({point1 = {10, 0}, point2 = {10, 20}})
    b2d.create_segment_shape(ground_id, shape_def, segment)

    -- Top
    segment = b2d.Segment({point1 = {-10, 20}, point2 = {10, 20}})
    b2d.create_segment_shape(ground_id, shape_def, segment)

    -- Motor joint definition (shared for friction)
    local joint_def = b2d.default_motor_joint_def()
    joint_def.bodyIdA = ground_id
    joint_def.collideConnected = true
    joint_def.maxVelocityForce = 10.0
    joint_def.maxVelocityTorque = 10.0

    -- Shape definitions
    local capsule = b2d.Capsule({center1 = {-0.25, 0}, center2 = {0.25, 0}, radius = 0.25})
    local circle = b2d.Circle({center = {0, 0}, radius = 0.35})
    local square = b2d.make_square(0.35)

    body_def = b2d.default_body_def()
    body_def.type = b2d.BodyType.DYNAMICBODY
    body_def.gravityScale = 0.0  -- Top-down view, no gravity

    shape_def = b2d.default_shape_def()
    shape_def.restitution = 0.8

    local n = 10
    local x, y = -5.0, 15.0

    for i = 0, n - 1 do
        for j = 0, n - 1 do
            body_def.position = {x, y}
            local body_id = b2d.create_body(world, body_def)
            table.insert(body_ids, body_id)

            local remainder = (n * i + j) % 3  -- Simplified to 3 shapes
            if remainder == 0 then
                b2d.create_capsule_shape(body_id, shape_def, capsule)
            elseif remainder == 1 then
                b2d.create_circle_shape(body_id, shape_def, circle)
            else
                b2d.create_polygon_shape(body_id, shape_def, square)
            end

            -- Add motor joint for friction
            joint_def.bodyIdB = body_id
            joint_def.localFrameA = b2d.Transform({p = {x, y}, q = {1, 0}})
            b2d.create_motor_joint(world, joint_def)

            x = x + 1.0
        end

        x = -5.0
        y = y - 1.0
    end
end

function M.update_gui(world)
    imgui.begin_window("Top Down Friction")

    if imgui.button("Explode") then
        local explosion_def = b2d.default_explosion_def()
        explosion_def.position = {0, 10}
        explosion_def.radius = 10.0
        explosion_def.falloff = 5.0
        explosion_def.impulsePerLength = 10.0
        b2d.world_explode(world, explosion_def)
    end

    imgui.end_window()
end

function M.render(camera, world)
    -- Draw walls
    draw.line(-10, 0, 10, 0, draw.colors.static)
    draw.line(-10, 0, -10, 20, draw.colors.static)
    draw.line(10, 0, 10, 20, draw.colors.static)
    draw.line(-10, 20, 10, 20, draw.colors.static)

    -- Draw bodies
    for _, body_id in ipairs(body_ids) do
        local pos = b2d.body_get_position(body_id)
        local rot = b2d.body_get_rotation(body_id)
        local angle = b2d.rot_get_angle(rot)
        local color = b2d.body_is_awake(body_id) and draw.colors.dynamic or draw.colors.sleeping

        -- Draw as circle for simplicity
        draw.solid_circle(pos[1], pos[2], 0.3, color)
        draw.circle(pos[1], pos[2], 0.3, {0, 0, 0, 1})
    end
end

function M.cleanup()
    ground_id = nil
    body_ids = {}
end

return M
