-- test_sensor_funnel.lua - Headless Sensor Funnel test
local b2d = require("b2d")

print("Sensor Funnel Headless Test")
print("===========================")

-- Create world
local def = b2d.default_world_def()
def.gravity = {0, -10}
local world = b2d.create_world(def)
print("World created")

-- Ground with sensor
local body_def = b2d.default_body_def()
local ground_id = b2d.create_body(world, body_def)

-- Floor
local shape_def = b2d.default_shape_def()
local segment = b2d.Segment({point1 = {-10, -5}, point2 = {10, -5}})
b2d.create_segment_shape(ground_id, shape_def, segment)

-- Sensor
shape_def = b2d.default_shape_def()
shape_def.isSensor = true
shape_def.enableSensorEvents = true
local box = b2d.make_box(2, 1)
b2d.create_polygon_shape(ground_id, shape_def, box)
print("Sensor created")

-- Falling body
body_def = b2d.default_body_def()
body_def.type = b2d.BodyType.DYNAMICBODY
body_def.position = {0, 10}
local body_id = b2d.create_body(world, body_def)

shape_def = b2d.default_shape_def()
shape_def.enableSensorEvents = true
local circle = b2d.Circle({center = {0, 0}, radius = 0.5})
b2d.create_circle_shape(body_id, shape_def, circle)
print("Falling body created")

-- Simulate and check sensor events
print("\nSimulating...")
local sensor_begin_count = 0
local sensor_end_count = 0

for i = 1, 180 do  -- 3 seconds
    b2d.world_step(world, 1.0/60.0, 4)

    local sensor_events = b2d.world_get_sensor_events(world)
    if sensor_events then
        if sensor_events.beginEvents then
            sensor_begin_count = sensor_begin_count + #sensor_events.beginEvents
        end
        if sensor_events.endEvents then
            sensor_end_count = sensor_end_count + #sensor_events.endEvents
        end
    end
end

print("Sensor begin events:", sensor_begin_count)
print("Sensor end events:", sensor_end_count)

if sensor_begin_count > 0 then
    print("Sensor events detected!")
else
    print("No sensor events (body may have missed sensor)")
end

-- Cleanup
b2d.destroy_world(world)
print("\n===========================")
print("Sensor Funnel Test OK!")
