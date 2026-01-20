-- kinematic_benchmark.lua - Box2D official Kinematic Benchmark sample
-- Kinematic bodies interacting with dynamic bodies
local b2d = require("b2d")
local draw = require("examples.b2d.draw")

local M = {}

M.camera = {
    center_x = 0,
    center_y = 10,
    zoom = 25,
}

local ground_id = nil
local kinematic_bodies = {}
local dynamic_bodies = {}
local time = 0

function M.create_scene(world)
    kinematic_bodies = {}
    dynamic_bodies = {}
    time = 0

    -- Ground
    local body_def = b2d.default_body_def()
    ground_id = b2d.create_body(world, body_def)

    local shape_def = b2d.default_shape_def()
    local segment = b2d.Segment({point1 = {-20, 0}, point2 = {20, 0}})
    b2d.create_segment_shape(ground_id, shape_def, segment)

    -- Create moving kinematic platforms
    for i = -2, 2 do
        body_def = b2d.default_body_def()
        body_def.type = b2d.BodyType.KINEMATICBODY
        body_def.position = {i * 5, 5}
        local platform = b2d.create_body(world, body_def)

        local box = b2d.make_box(2, 0.2)
        b2d.create_polygon_shape(platform, shape_def, box)
        table.insert(kinematic_bodies, {body = platform, base_x = i * 5, phase = i * 0.5})
    end

    -- Create falling dynamic bodies
    local circle = b2d.Circle({center = {0, 0}, radius = 0.3})
    for i = 1, 50 do
        body_def = b2d.default_body_def()
        body_def.type = b2d.BodyType.DYNAMICBODY
        body_def.position = {
            math.random() * 20 - 10,
            15 + math.random() * 10
        }
        local body = b2d.create_body(world, body_def)
        b2d.create_circle_shape(body, shape_def, circle)
        table.insert(dynamic_bodies, body)
    end
end

function M.update(world, dt)
    time = time + dt

    -- Move kinematic platforms
    for _, k in ipairs(kinematic_bodies) do
        if b2d.body_is_valid(k.body) then
            local x = k.base_x + math.sin(time * 2 + k.phase) * 3
            local y = 5 + math.sin(time + k.phase * 2) * 2
            b2d.body_set_transform(k.body, {x, y}, {1, 0})
        end
    end
end

function M.render(camera, world)
    -- Draw ground
    draw.line(-20, 0, 20, 0, draw.colors.static)

    -- Draw kinematic platforms
    for _, k in ipairs(kinematic_bodies) do
        if b2d.body_is_valid(k.body) then
            local pos = b2d.body_get_position(k.body)
            draw.solid_box(pos[1], pos[2], 2, 0.2, 0, {0.4, 0.6, 0.8, 1})
            draw.box(pos[1], pos[2], 2, 0.2, 0, {0, 0, 0, 1})
        end
    end

    -- Draw dynamic bodies
    for _, body_id in ipairs(dynamic_bodies) do
        if b2d.body_is_valid(body_id) then
            local pos = b2d.body_get_position(body_id)
            local color = b2d.body_is_awake(body_id) and draw.colors.dynamic or draw.colors.sleeping
            draw.solid_circle(pos[1], pos[2], 0.3, color)
        end
    end
end

function M.cleanup()
    ground_id = nil
    kinematic_bodies = {}
    dynamic_bodies = {}
end

return M
