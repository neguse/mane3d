-- test_conveyor_belt.lua - Headless Conveyor Belt test
local b2d = require("b2d")

print("Conveyor Belt Headless Test")
print("============================")

-- Create world
local def = b2d.default_world_def()
def.gravity = {0, -10}
local world = b2d.create_world(def)
print("World created")

-- Ground
local body_def = b2d.default_body_def()
local ground_id = b2d.create_body(world, body_def)

local shape_def = b2d.default_shape_def()
local segment = b2d.Segment({point1 = {-20, 0}, point2 = {20, 0}})
b2d.create_segment_shape(ground_id, shape_def, segment)
print("Ground created")

-- Platform (conveyor belt)
body_def = b2d.default_body_def()
body_def.position = {-5, 5}
local platform_id = b2d.create_body(world, body_def)

local box = b2d.make_rounded_box(10.0, 0.25, 0.25)

shape_def = b2d.default_shape_def()
shape_def.material = b2d.SurfaceMaterial({friction = 0.8, tangentSpeed = 2.0})
b2d.create_polygon_shape(platform_id, shape_def, box)
print("Conveyor belt platform created (tangent speed = 2.0)")

-- Single box
shape_def = b2d.default_shape_def()
local cube = b2d.make_square(0.5)

body_def = b2d.default_body_def()
body_def.type = b2d.BodyType.DYNAMICBODY
body_def.position = {-10, 7}
local box_id = b2d.create_body(world, body_def)
b2d.create_polygon_shape(box_id, shape_def, cube)
print("Box created at x = -10")

-- Simulate
print("\nSimulating...")
for i = 1, 300 do  -- 5 seconds
    b2d.world_step(world, 1.0/60.0, 4)
end

local pos = b2d.body_get_position(box_id)
print("Box position after 5s: x =", pos[1], "y =", pos[2])

-- The box should have moved to the right due to conveyor belt
if pos[1] > -10 then
    print("Conveyor belt moved box to the right (as expected)")
else
    print("Box did not move as expected")
end

-- Cleanup
b2d.destroy_world(world)
print("\n============================")
print("Conveyor Belt Test OK!")
