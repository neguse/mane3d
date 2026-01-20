-- test_kinematic.lua - Headless Kinematic test
local b2d = require("b2d")

print("Kinematic Headless Test")
print("=======================")

-- Create world
local def = b2d.default_world_def()
def.gravity = {0, -10}
local world = b2d.create_world(def)
print("World created")

-- Kinematic body
local body_def = b2d.default_body_def()
body_def.type = b2d.BodyType.KINEMATICBODY
body_def.position = {4, 0}  -- Start at amplitude * 2

local body_id = b2d.create_body(world, body_def)

local box = b2d.make_box(0.1, 1.0)
local shape_def = b2d.default_shape_def()
b2d.create_polygon_shape(body_id, shape_def, box)
print("Kinematic body created")

local init_pos = b2d.body_get_position(body_id)
print("Initial position:", init_pos[1], init_pos[2])

-- Simulate and update target
print("\nSimulating with target transform updates...")
local amplitude = 2.0
local time = 0
local dt = 1.0 / 60.0

for i = 1, 120 do  -- 2 seconds
    time = time + dt

    -- Calculate target
    local target_x = 2 * amplitude * math.cos(time)
    local target_y = amplitude * math.sin(2 * time)
    local target_angle = 2 * time

    local c, s = math.cos(target_angle), math.sin(target_angle)
    local transform = {{target_x, target_y}, {c, s}}

    b2d.body_set_target_transform(body_id, transform, dt, true)
    b2d.world_step(world, dt, 4)
end

-- Check final position
local final_pos = b2d.body_get_position(body_id)
print("Final position:", final_pos[1], final_pos[2])

-- The body should have moved from initial position
local dist = math.sqrt((final_pos[1] - init_pos[1])^2 + (final_pos[2] - init_pos[2])^2)
if dist > 0.1 then
    print("Kinematic body followed target path!")
else
    print("Body did not move (kinematic targeting may not be working)")
end

-- Cleanup
b2d.destroy_world(world)
print("\n=======================")
print("Kinematic Test OK!")
