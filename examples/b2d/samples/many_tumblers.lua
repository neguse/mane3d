-- many_tumblers.lua - Box2D official Many Tumblers Benchmark sample
-- Multiple rotating tumblers benchmark
local b2d = require("b2d")
local draw = require("examples.b2d.draw")

local M = {}

M.camera = {
    center_x = 0,
    center_y = 10,
    zoom = 30,
}

local ground_id = nil
local tumbler_bodies = {}
local ball_bodies = {}
local joint_ids = {}

function M.create_scene(world)
    tumbler_bodies = {}
    ball_bodies = {}
    joint_ids = {}

    -- Ground
    local body_def = b2d.default_body_def()
    ground_id = b2d.create_body(world, body_def)

    local shape_def = b2d.default_shape_def()
    local segment = b2d.Segment({point1 = {-30, 0}, point2 = {30, 0}})
    b2d.create_segment_shape(ground_id, shape_def, segment)

    -- Create multiple tumblers
    local tumbler_count = 3
    local tumbler_size = 5

    for t = -1, 1 do
        local center_x = t * 15
        local center_y = tumbler_size + 2

        -- Tumbler body
        body_def = b2d.default_body_def()
        body_def.type = b2d.BodyType.DYNAMICBODY
        body_def.position = {center_x, center_y}
        body_def.enableSleep = false
        local tumbler = b2d.create_body(world, body_def)

        -- Tumbler walls
        local wall_thickness = 0.3
        local boxes = {
            b2d.make_offset_box(tumbler_size, wall_thickness, {0, -tumbler_size}, {1, 0}),
            b2d.make_offset_box(tumbler_size, wall_thickness, {0, tumbler_size}, {1, 0}),
            b2d.make_offset_box(wall_thickness, tumbler_size, {-tumbler_size, 0}, {1, 0}),
            b2d.make_offset_box(wall_thickness, tumbler_size, {tumbler_size, 0}, {1, 0}),
        }

        for _, box in ipairs(boxes) do
            b2d.create_polygon_shape(tumbler, shape_def, box)
        end

        table.insert(tumbler_bodies, {body = tumbler, center = {center_x, center_y}})

        -- Motor joint
        local joint_def = b2d.default_revolute_joint_def()
        joint_def.bodyIdA = ground_id
        joint_def.bodyIdB = tumbler
        local frame_a = b2d.Transform()
        frame_a.p = {center_x, center_y}
        frame_a.q = {c = 1, s = 0}
        joint_def.localFrameA = frame_a
        local frame_b = b2d.Transform()
        frame_b.p = {0, 0}
        frame_b.q = {c = 1, s = 0}
        joint_def.localFrameB = frame_b
        joint_def.enableMotor = true
        joint_def.motorSpeed = 1 + t * 0.5
        joint_def.maxMotorTorque = 100000
        local joint = b2d.create_revolute_joint(world, joint_def)
        table.insert(joint_ids, joint)

        -- Add balls inside each tumbler
        local circle = b2d.Circle({center = {0, 0}, radius = 0.3})
        for i = 1, 20 do
            body_def = b2d.default_body_def()
            body_def.type = b2d.BodyType.DYNAMICBODY
            body_def.position = {
                center_x + math.random() * 6 - 3,
                center_y + math.random() * 6 - 3
            }
            local ball = b2d.create_body(world, body_def)
            b2d.create_circle_shape(ball, shape_def, circle)
            table.insert(ball_bodies, ball)
        end
    end
end

function M.render(camera, world)
    -- Draw ground
    draw.line(-30, 0, 30, 0, draw.colors.static)

    -- Draw tumblers
    for _, t in ipairs(tumbler_bodies) do
        if b2d.body_is_valid(t.body) then
            local pos = b2d.body_get_position(t.body)
            local rot = b2d.body_get_rotation(t.body)
            local angle = b2d.rot_get_angle(rot)

            -- Draw tumbler walls (simplified)
            local c = math.cos(angle)
            local s = math.sin(angle)
            local size = 5

            -- Draw rotated box outline
            local corners = {
                {-size, -size}, {size, -size}, {size, size}, {-size, size}
            }
            for i = 1, 4 do
                local j = i % 4 + 1
                local x1 = pos[1] + corners[i][1] * c - corners[i][2] * s
                local y1 = pos[2] + corners[i][1] * s + corners[i][2] * c
                local x2 = pos[1] + corners[j][1] * c - corners[j][2] * s
                local y2 = pos[2] + corners[j][1] * s + corners[j][2] * c
                draw.line(x1, y1, x2, y2, {0.6, 0.4, 0.2, 1})
            end
        end
    end

    -- Draw balls
    for _, body_id in ipairs(ball_bodies) do
        if b2d.body_is_valid(body_id) then
            local pos = b2d.body_get_position(body_id)
            local color = b2d.body_is_awake(body_id) and draw.colors.dynamic or draw.colors.sleeping
            draw.solid_circle(pos[1], pos[2], 0.3, color)
        end
    end
end

function M.cleanup()
    ground_id = nil
    tumbler_bodies = {}
    ball_bodies = {}
    joint_ids = {}
end

return M
