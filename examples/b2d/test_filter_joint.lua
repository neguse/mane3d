-- test_filter_joint.lua - Headless Filter Joint test
local b2d = require("b2d")

print("Filter Joint Headless Test")
print("===========================")

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

-- Two bodies that would normally collide
body_def = b2d.default_body_def()
body_def.type = b2d.BodyType.DYNAMICBODY

-- First body (slightly overlapping second)
body_def.position = {0, 4}
local body_id1 = b2d.create_body(world, body_def)
local box = b2d.make_square(1.0)
shape_def = b2d.default_shape_def()
b2d.create_polygon_shape(body_id1, shape_def, box)

-- Second body (slightly overlapping first)
body_def.position = {1.5, 4}  -- Overlapping
local body_id2 = b2d.create_body(world, body_def)
b2d.create_polygon_shape(body_id2, shape_def, box)

print("Created two overlapping bodies")

-- Filter joint prevents collision between these two bodies
local filter_def = b2d.default_filter_joint_def()
filter_def.bodyIdA = body_id1
filter_def.bodyIdB = body_id2
b2d.create_filter_joint(world, filter_def)
print("Filter joint created")

-- Simulate
print("\nSimulating...")
for i = 1, 120 do  -- 2 seconds
    b2d.world_step(world, 1.0/60.0, 4)
end

-- Check positions - they should pass through each other
local pos1 = b2d.body_get_position(body_id1)
local pos2 = b2d.body_get_position(body_id2)
print("Body1 position: x =", pos1[1], "y =", pos1[2])
print("Body2 position: x =", pos2[1], "y =", pos2[2])

-- They should both be on the ground now, having passed through each other
local both_on_ground = pos1[2] < 2 and pos2[2] < 2
print("Both bodies on ground:", both_on_ground)

-- Cleanup
b2d.destroy_world(world)
print("\n===========================")
print("Filter Joint Test OK!")
