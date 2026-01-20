-- sensor_bookend.lua - Box2D official Sensor Bookend sample
-- Demonstrates sensor begin/end event handling
local b2d = require("b2d")
local draw = require("examples.b2d.draw")

local M = {}

M.camera = {
    center_x = 0,
    center_y = 5,
    zoom = 15,
}

local ground_id = nil
local sensor_body = nil
local ball_ids = {}
local sensor_count = 0

function M.create_scene(world)
    ball_ids = {}
    sensor_count = 0

    -- Ground
    local body_def = b2d.default_body_def()
    ground_id = b2d.create_body(world, body_def)

    local shape_def = b2d.default_shape_def()
    local segment = b2d.Segment({point1 = {-20, 0}, point2 = {20, 0}})
    b2d.create_segment_shape(ground_id, shape_def, segment)

    -- Walls
    segment = b2d.Segment({point1 = {-10, 0}, point2 = {-10, 15}})
    b2d.create_segment_shape(ground_id, shape_def, segment)
    segment = b2d.Segment({point1 = {10, 0}, point2 = {10, 15}})
    b2d.create_segment_shape(ground_id, shape_def, segment)

    -- Sensor zone
    body_def = b2d.default_body_def()
    body_def.position = {0, 5}
    sensor_body = b2d.create_body(world, body_def)

    shape_def = b2d.default_shape_def()
    shape_def.isSensor = true
    shape_def.enableSensorEvents = true
    local box = b2d.make_box(5, 3)
    b2d.create_polygon_shape(sensor_body, shape_def, box)

    -- Falling balls
    body_def = b2d.default_body_def()
    body_def.type = b2d.BodyType.DYNAMICBODY

    for i = 1, 10 do
        body_def.position = {-8 + i * 1.5, 12 + math.random() * 3}
        local ball = b2d.create_body(world, body_def)

        shape_def = b2d.default_shape_def()
        shape_def.enableSensorEvents = true
        local circle = b2d.Circle({center = {0, 0}, radius = 0.4})
        b2d.create_circle_shape(ball, shape_def, circle)
        table.insert(ball_ids, ball)
    end
end

function M.update(world, dt)
    local events = b2d.world_get_sensor_events(world)
    if events then
        if events.beginEvents then
            for _, event in ipairs(events.beginEvents) do
                sensor_count = sensor_count + 1
            end
        end
        if events.endEvents then
            for _, event in ipairs(events.endEvents) do
                sensor_count = math.max(0, sensor_count - 1)
            end
        end
    end
end

function M.render(camera, world)
    -- Draw ground and walls
    draw.line(-20, 0, 20, 0, draw.colors.static)
    draw.line(-10, 0, -10, 15, draw.colors.static)
    draw.line(10, 0, 10, 15, draw.colors.static)

    -- Draw sensor zone (color based on count)
    local intensity = math.min(sensor_count / 10, 1)
    local color = {0.2 + intensity * 0.8, 1 - intensity * 0.5, 0.2, 0.4}
    draw.solid_box(0, 5, 5, 3, 0, color)
    draw.box(0, 5, 5, 3, 0, {1, 1, 0, 1})

    -- Draw balls
    for _, ball_id in ipairs(ball_ids) do
        if b2d.body_is_valid(ball_id) then
            local pos = b2d.body_get_position(ball_id)
            local color = b2d.body_is_awake(ball_id) and draw.colors.dynamic or draw.colors.sleeping
            draw.solid_circle(pos[1], pos[2], 0.4, color)
            draw.circle(pos[1], pos[2], 0.4, {0, 0, 0, 1})
        end
    end
end

function M.cleanup()
    ground_id = nil
    sensor_body = nil
    ball_ids = {}
    sensor_count = 0
end

return M
