-- test_rolling_resistance.lua - Headless Rolling Resistance test
local b2d = require("b2d")

print("Rolling Resistance Headless Test")
print("================================")

-- Create world
local def = b2d.default_world_def()
def.gravity = {0, -10}
local world = b2d.create_world(def)
print("World created")

-- Create slope and circles
local resist_scale = 0.02
local circle = b2d.Circle({center = {0, 0}, radius = 0.5})

-- Create 5 slopes with different rolling resistances
for i = 0, 4 do
    -- Ground segment
    local body_def = b2d.default_body_def()
    local ground_id = b2d.create_body(world, body_def)

    local shape_def = b2d.default_shape_def()
    local segment = b2d.Segment({
        point1 = {-10, 2 * i},
        point2 = {10, 2 * i}  -- Flat
    })
    b2d.create_segment_shape(ground_id, shape_def, segment)

    -- Rolling circle
    body_def = b2d.default_body_def()
    body_def.type = b2d.BodyType.DYNAMICBODY
    body_def.position = {-9, 2 * i + 0.75}
    body_def.angularVelocity = -10
    body_def.linearVelocity = {5, 0}

    local body_id = b2d.create_body(world, body_def)

    shape_def = b2d.default_shape_def()
    shape_def.material = b2d.SurfaceMaterial({rollingResistance = resist_scale * i})
    b2d.create_circle_shape(body_id, shape_def, circle)

    print("Circle", i, "created with rolling resistance:", resist_scale * i)
end

-- Simulate
print("\nSimulating...")
for i = 1, 120 do  -- 2 seconds
    b2d.world_step(world, 1.0/60.0, 4)
end

print("Simulation completed")

-- Cleanup
b2d.destroy_world(world)
print("\n================================")
print("Rolling Resistance Test OK!")
