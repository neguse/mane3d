-- spinner.lua - Box2D official Spinner Benchmark sample
-- Rotating spinner hitting many objects
local b2d = require("b2d")
local draw = require("examples.b2d.draw")

local M = {}

M.camera = {
    center_x = 0,
    center_y = 10,
    zoom = 25,
}

local ground_id = nil
local spinner_body = nil
local body_ids = {}
local joint_id = nil

function M.create_scene(world)
    body_ids = {}

    -- Ground
    local body_def = b2d.default_body_def()
    ground_id = b2d.create_body(world, body_def)

    local shape_def = b2d.default_shape_def()
    local segment = b2d.Segment({point1 = {-30, 0}, point2 = {30, 0}})
    b2d.create_segment_shape(ground_id, shape_def, segment)

    -- Walls
    segment = b2d.Segment({point1 = {-15, 0}, point2 = {-15, 25}})
    b2d.create_segment_shape(ground_id, shape_def, segment)
    segment = b2d.Segment({point1 = {15, 0}, point2 = {15, 25}})
    b2d.create_segment_shape(ground_id, shape_def, segment)
    segment = b2d.Segment({point1 = {-15, 25}, point2 = {15, 25}})
    b2d.create_segment_shape(ground_id, shape_def, segment)

    -- Spinner (rotating bar)
    body_def = b2d.default_body_def()
    body_def.type = b2d.BodyType.DYNAMICBODY
    body_def.position = {0, 12}
    body_def.enableSleep = false
    spinner_body = b2d.create_body(world, body_def)

    local box = b2d.make_box(10, 0.3)
    b2d.create_polygon_shape(spinner_body, shape_def, box)

    -- Motor joint to spin it
    local joint_def = b2d.default_revolute_joint_def()
    joint_def.bodyIdA = ground_id
    joint_def.bodyIdB = spinner_body
    local frame_a = b2d.Transform()
    frame_a.p = {0, 12}
    frame_a.q = {c = 1, s = 0}
    joint_def.localFrameA = frame_a
    local frame_b = b2d.Transform()
    frame_b.p = {0, 0}
    frame_b.q = {c = 1, s = 0}
    joint_def.localFrameB = frame_b
    joint_def.enableMotor = true
    joint_def.motorSpeed = 3  -- radians per second
    joint_def.maxMotorTorque = 10000
    joint_id = b2d.create_revolute_joint(world, joint_def)

    -- Create many small objects
    local circle = b2d.Circle({center = {0, 0}, radius = 0.3})
    for i = 1, 100 do
        body_def = b2d.default_body_def()
        body_def.type = b2d.BodyType.DYNAMICBODY
        body_def.position = {
            math.random() * 20 - 10,
            math.random() * 20 + 2
        }
        local body = b2d.create_body(world, body_def)
        b2d.create_circle_shape(body, shape_def, circle)
        table.insert(body_ids, body)
    end
end

function M.render(camera, world)
    -- Draw walls
    draw.line(-30, 0, 30, 0, draw.colors.static)
    draw.line(-15, 0, -15, 25, draw.colors.static)
    draw.line(15, 0, 15, 25, draw.colors.static)
    draw.line(-15, 25, 15, 25, draw.colors.static)

    -- Draw spinner
    if spinner_body and b2d.body_is_valid(spinner_body) then
        local pos = b2d.body_get_position(spinner_body)
        local rot = b2d.body_get_rotation(spinner_body)
        local angle = b2d.rot_get_angle(rot)
        draw.solid_box(pos[1], pos[2], 10, 0.3, angle, {0.6, 0.4, 0.2, 1})
        draw.box(pos[1], pos[2], 10, 0.3, angle, {0, 0, 0, 1})
    end

    -- Draw bodies
    for _, body_id in ipairs(body_ids) do
        if b2d.body_is_valid(body_id) then
            local pos = b2d.body_get_position(body_id)
            local color = b2d.body_is_awake(body_id) and draw.colors.dynamic or draw.colors.sleeping
            draw.solid_circle(pos[1], pos[2], 0.3, color)
        end
    end
end

function M.cleanup()
    ground_id = nil
    spinner_body = nil
    body_ids = {}
    joint_id = nil
end

return M
