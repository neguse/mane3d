-- tumbler.lua - Box2D official Tumbler Benchmark sample
-- A rotating container that tumbles boxes around.
local b2d = require("b2d")
local draw = require("examples.b2d.draw")

local M = {}

M.camera = {
    center_x = 0,
    center_y = 10,
    zoom = 30,
}

local ground_id = nil
local tumbler_id = nil
local motor_joint_id = nil
local box_ids = {}
local spawn_timer = 0
local max_boxes = 100

function M.create_scene(world)
    box_ids = {}
    spawn_timer = 0

    -- Ground
    local body_def = b2d.default_body_def()
    ground_id = b2d.create_body(world, body_def)

    -- Tumbler (rotating container)
    body_def = b2d.default_body_def()
    body_def.type = b2d.BodyType.DYNAMICBODY
    body_def.position = {0, 10}
    body_def.enableSleep = false
    tumbler_id = b2d.create_body(world, body_def)

    local shape_def = b2d.default_shape_def()
    shape_def.density = 5

    -- Create walls of the tumbler
    local wall_thickness = 0.5
    local wall_length = 10

    -- Top
    local box = b2d.make_offset_box(wall_length, wall_thickness, {0, wall_length}, {1, 0})
    b2d.create_polygon_shape(tumbler_id, shape_def, box)

    -- Bottom
    box = b2d.make_offset_box(wall_length, wall_thickness, {0, -wall_length}, {1, 0})
    b2d.create_polygon_shape(tumbler_id, shape_def, box)

    -- Left
    box = b2d.make_offset_box(wall_thickness, wall_length, {-wall_length, 0}, {1, 0})
    b2d.create_polygon_shape(tumbler_id, shape_def, box)

    -- Right
    box = b2d.make_offset_box(wall_thickness, wall_length, {wall_length, 0}, {1, 0})
    b2d.create_polygon_shape(tumbler_id, shape_def, box)

    -- Motor joint to rotate tumbler
    local motor_def = b2d.default_revolute_joint_def()
    motor_def.bodyIdA = ground_id
    motor_def.bodyIdB = tumbler_id
    local frame_a = b2d.Transform()
    frame_a.p = {0, 10}
    frame_a.q = {c = 1, s = 0}
    motor_def.localFrameA = frame_a
    local frame_b = b2d.Transform()
    frame_b.p = {0, 0}
    frame_b.q = {c = 1, s = 0}
    motor_def.localFrameB = frame_b
    motor_def.enableMotor = true
    motor_def.motorSpeed = 0.5
    motor_def.maxMotorTorque = 100000
    motor_joint_id = b2d.create_revolute_joint(world, motor_def)
end

local function spawn_box(world)
    if #box_ids >= max_boxes then return end

    local body_def = b2d.default_body_def()
    body_def.type = b2d.BodyType.DYNAMICBODY
    body_def.position = {0, 10}
    local box_id = b2d.create_body(world, body_def)

    local shape_def = b2d.default_shape_def()
    local box = b2d.make_box(0.5, 0.5)
    b2d.create_polygon_shape(box_id, shape_def, box)

    table.insert(box_ids, box_id)
end

function M.update(world, dt)
    spawn_timer = spawn_timer + dt
    if spawn_timer > 0.1 then
        spawn_box(world)
        spawn_timer = 0
    end
end

function M.render(camera, world)
    -- Draw tumbler
    if tumbler_id and b2d.body_is_valid(tumbler_id) then
        local pos = b2d.body_get_position(tumbler_id)
        local rot = b2d.body_get_rotation(tumbler_id)
        local angle = b2d.rot_get_angle(rot)

        local c, s = math.cos(angle), math.sin(angle)
        local wall_length = 10
        local wall_thickness = 0.5

        -- Draw walls (rotate around center)
        local walls = {
            {0, wall_length, wall_length, wall_thickness},  -- Top
            {0, -wall_length, wall_length, wall_thickness}, -- Bottom
            {-wall_length, 0, wall_thickness, wall_length}, -- Left
            {wall_length, 0, wall_thickness, wall_length},  -- Right
        }

        for _, wall in ipairs(walls) do
            local ox, oy = wall[1], wall[2]
            local wx = pos[1] + c * ox - s * oy
            local wy = pos[2] + s * ox + c * oy
            draw.solid_box(wx, wy, wall[3], wall[4], angle, draw.colors.kinematic)
            draw.box(wx, wy, wall[3], wall[4], angle, {0, 0, 0, 1})
        end
    end

    -- Draw boxes
    for _, box_id in ipairs(box_ids) do
        if b2d.body_is_valid(box_id) then
            local pos = b2d.body_get_position(box_id)
            local rot = b2d.body_get_rotation(box_id)
            local angle = b2d.rot_get_angle(rot)
            local color = b2d.body_is_awake(box_id) and draw.colors.dynamic or draw.colors.sleeping
            draw.solid_box(pos[1], pos[2], 0.5, 0.5, angle, color)
            draw.box(pos[1], pos[2], 0.5, 0.5, angle, {0, 0, 0, 1})
        end
    end

    -- Draw box count
    draw.point(-25, 25, 3, {1, 1, 1, 1})
end

function M.cleanup()
    ground_id = nil
    tumbler_id = nil
    motor_joint_id = nil
    box_ids = {}
end

return M
