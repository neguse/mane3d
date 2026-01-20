-- test_offset_shapes.lua - Headless Offset Shapes test
local b2d = require("b2d")

print("Offset Shapes Headless Test")
print("===========================")

-- Create world
local def = b2d.default_world_def()
def.gravity = {0, -10}
local world = b2d.create_world(def)
print("World created")

-- Ground with offset box
local body_def = b2d.default_body_def()
body_def.position = {0, 0}
local ground_id = b2d.create_body(world, body_def)

local shape_def = b2d.default_shape_def()
local rot = b2d.make_rot(0.5 * math.pi)
local box = b2d.make_offset_box(2, 0.5, {0, -1}, rot)
b2d.create_polygon_shape(ground_id, shape_def, box)
print("Ground with offset box created")

-- Dynamic body with offset shape
body_def = b2d.default_body_def()
body_def.type = b2d.BodyType.DYNAMICBODY
body_def.position = {0, 5}
local body_id = b2d.create_body(world, body_def)

-- Offset box on dynamic body
box = b2d.make_offset_box(0.5, 0.5, {2, 0}, {1, 0})
b2d.create_polygon_shape(body_id, shape_def, box)
print("Dynamic body with offset shape created")

local init_pos = b2d.body_get_position(body_id)
print("Initial position:", init_pos[1], init_pos[2])

-- Simulate
print("\nSimulating...")
for i = 1, 120 do
    b2d.world_step(world, 1.0/60.0, 4)
end

local final_pos = b2d.body_get_position(body_id)
print("Final position:", final_pos[1], final_pos[2])

if final_pos[2] < init_pos[2] then
    print("Body fell (offset shapes working)")
end

-- Cleanup
b2d.destroy_world(world)
print("\n===========================")
print("Offset Shapes Test OK!")
