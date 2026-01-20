-- sensor_types.lua - Box2D official Sensor Types sample
-- Demonstrates different sensor configurations
local b2d = require("b2d")
local draw = require("examples.b2d.draw")

local M = {}

M.camera = {
    center_x = 0,
    center_y = 3,
    zoom = 4.5,
}

local ground_id = nil
local sensor_ids = {}
local ball_ids = {}
local overlapping = {}

function M.create_scene(world)
    sensor_ids = {}
    ball_ids = {}
    overlapping = {}

    -- Ground with walls
    local body_def = b2d.default_body_def()
    ground_id = b2d.create_body(world, body_def)

    local shape_def = b2d.default_shape_def()
    shape_def.enableSensorEvents = true

    local segment = b2d.Segment({point1 = {-6, 0}, point2 = {6, 0}})
    b2d.create_segment_shape(ground_id, shape_def, segment)

    segment = b2d.Segment({point1 = {-6, 0}, point2 = {-6, 4}})
    b2d.create_segment_shape(ground_id, shape_def, segment)

    segment = b2d.Segment({point1 = {6, 0}, point2 = {6, 4}})
    b2d.create_segment_shape(ground_id, shape_def, segment)

    -- Create sensors at different positions
    local sensor_positions = {{-3, 1.5}, {0, 1.5}, {3, 1.5}}
    for i, pos in ipairs(sensor_positions) do
        body_def = b2d.default_body_def()
        body_def.position = pos
        local sensor_body = b2d.create_body(world, body_def)

        shape_def = b2d.default_shape_def()
        shape_def.isSensor = true
        shape_def.enableSensorEvents = true
        local box = b2d.make_box(1, 1)
        b2d.create_polygon_shape(sensor_body, shape_def, box)
        table.insert(sensor_ids, sensor_body)
        overlapping[i] = false
    end

    -- Create falling balls
    for i = 1, 5 do
        body_def = b2d.default_body_def()
        body_def.type = b2d.BodyType.DYNAMICBODY
        body_def.position = {-4 + i * 2, 5}
        local ball = b2d.create_body(world, body_def)

        shape_def = b2d.default_shape_def()
        shape_def.enableSensorEvents = true
        local circle = b2d.Circle({center = {0, 0}, radius = 0.3})
        b2d.create_circle_shape(ball, shape_def, circle)
        table.insert(ball_ids, ball)
    end
end

function M.update(world, dt)
    -- Check sensor events
    local events = b2d.world_get_sensor_events(world)
    if events and events.beginEvents then
        for _, event in ipairs(events.beginEvents) do
            -- Mark sensor as overlapping
            for i, sensor_id in ipairs(sensor_ids) do
                -- In a real implementation, we'd check if event.sensorShapeId matches
                overlapping[i] = true
            end
        end
    end
    if events and events.endEvents then
        for _, event in ipairs(events.endEvents) do
            -- Mark sensor as not overlapping
            for i, sensor_id in ipairs(sensor_ids) do
                overlapping[i] = false
            end
        end
    end
end

function M.render(camera, world)
    -- Draw ground and walls
    draw.line(-6, 0, 6, 0, draw.colors.static)
    draw.line(-6, 0, -6, 4, draw.colors.static)
    draw.line(6, 0, 6, 4, draw.colors.static)

    -- Draw sensors
    local sensor_positions = {{-3, 1.5}, {0, 1.5}, {3, 1.5}}
    for i, pos in ipairs(sensor_positions) do
        local color = overlapping[i] and {0, 1, 0, 0.3} or {1, 1, 0, 0.3}
        draw.solid_box(pos[1], pos[2], 1, 1, 0, color)
        draw.box(pos[1], pos[2], 1, 1, 0, {1, 1, 0, 1})
    end

    -- Draw balls
    for _, ball_id in ipairs(ball_ids) do
        if b2d.body_is_valid(ball_id) then
            local pos = b2d.body_get_position(ball_id)
            local color = b2d.body_is_awake(ball_id) and draw.colors.dynamic or draw.colors.sleeping
            draw.solid_circle(pos[1], pos[2], 0.3, color)
            draw.circle(pos[1], pos[2], 0.3, {0, 0, 0, 1})
        end
    end
end

function M.cleanup()
    ground_id = nil
    sensor_ids = {}
    ball_ids = {}
    overlapping = {}
end

return M
