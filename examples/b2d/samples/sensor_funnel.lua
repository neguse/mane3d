-- sensor_funnel.lua - Box2D official Sensor Funnel sample
-- Demonstrates sensor events with bodies falling through a funnel.
local b2d = require("b2d")
local draw = require("examples.b2d.draw")

local M = {}

M.camera = {
    center_x = 0,
    center_y = 0,
    zoom = 33,
}

local ground_id = nil
local sensor_shape_id = nil
local body_ids = {}
local sensor_overlapping = {}  -- Bodies currently overlapping sensor

local max_bodies = 32
local spawn_timer = 0

function M.create_scene(world)
    body_ids = {}
    sensor_overlapping = {}
    spawn_timer = 0

    -- Ground with funnel shape
    local body_def = b2d.default_body_def()
    ground_id = b2d.create_body(world, body_def)

    local shape_def = b2d.default_shape_def()

    -- Funnel walls
    local segment = b2d.Segment({point1 = {-20, -20}, point2 = {-8, 0}})
    b2d.create_segment_shape(ground_id, shape_def, segment)

    segment = b2d.Segment({point1 = {8, 0}, point2 = {20, -20}})
    b2d.create_segment_shape(ground_id, shape_def, segment)

    -- Bottom
    segment = b2d.Segment({point1 = {-20, -20}, point2 = {20, -20}})
    b2d.create_segment_shape(ground_id, shape_def, segment)

    -- Sensor at funnel opening
    shape_def = b2d.default_shape_def()
    shape_def.isSensor = true
    shape_def.enableSensorEvents = true

    local box = b2d.make_box(4, 1)
    sensor_shape_id = b2d.create_polygon_shape(ground_id, shape_def, box)
end

local function spawn_body(world)
    if #body_ids >= max_bodies then return end

    local body_def = b2d.default_body_def()
    body_def.type = b2d.BodyType.DYNAMICBODY
    body_def.position = {math.random() * 10 - 5, 15 + math.random() * 5}

    local body_id = b2d.create_body(world, body_def)

    local shape_def = b2d.default_shape_def()
    shape_def.enableSensorEvents = true

    -- Random shape type
    local shape_type = math.random(1, 3)
    if shape_type == 1 then
        local circle = b2d.Circle({center = {0, 0}, radius = 0.5})
        b2d.create_circle_shape(body_id, shape_def, circle)
    elseif shape_type == 2 then
        local capsule = b2d.Capsule({center1 = {0, -0.3}, center2 = {0, 0.3}, radius = 0.2})
        b2d.create_capsule_shape(body_id, shape_def, capsule)
    else
        local box = b2d.make_box(0.4, 0.4)
        b2d.create_polygon_shape(body_id, shape_def, box)
    end

    table.insert(body_ids, body_id)
end

function M.update(world, dt)
    -- Spawn bodies periodically
    spawn_timer = spawn_timer + dt
    if spawn_timer > 0.2 then
        spawn_body(world)
        spawn_timer = 0
    end

    -- Process sensor events
    local sensor_events = b2d.world_get_sensor_events(world)

    if sensor_events then
        -- Begin events
        if sensor_events.beginEvents then
            for _, event in ipairs(sensor_events.beginEvents) do
                local visitor_body = b2d.shape_get_body(event.visitorShapeId)
                sensor_overlapping[tostring(visitor_body)] = true
            end
        end

        -- End events
        if sensor_events.endEvents then
            for _, event in ipairs(sensor_events.endEvents) do
                local visitor_body = b2d.shape_get_body(event.visitorShapeId)
                sensor_overlapping[tostring(visitor_body)] = nil
            end
        end
    end
end

function M.render(camera, world)
    -- Draw funnel walls
    draw.line(-20, -20, -8, 0, draw.colors.static)
    draw.line(8, 0, 20, -20, draw.colors.static)
    draw.line(-20, -20, 20, -20, draw.colors.static)

    -- Draw sensor zone
    draw.box(0, 0, 4, 1, 0, {0.3, 0.8, 0.3, 0.5})

    -- Draw bodies
    for _, body_id in ipairs(body_ids) do
        if b2d.body_is_valid(body_id) then
            local pos = b2d.body_get_position(body_id)

            -- Check if in sensor
            local in_sensor = sensor_overlapping[tostring(body_id)]
            local color = in_sensor and {0.9, 0.3, 0.3, 1} or draw.colors.dynamic

            draw.solid_circle(pos[1], pos[2], 0.5, color)
            draw.circle(pos[1], pos[2], 0.5, {0, 0, 0, 1})
        end
    end

    -- Draw count
    draw.point(-18, 18, 3, {1, 1, 1, 1})
end

function M.cleanup()
    ground_id = nil
    sensor_shape_id = nil
    body_ids = {}
    sensor_overlapping = {}
end

return M
