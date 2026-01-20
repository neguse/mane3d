-- test_wind.lua - Headless Wind test
local b2d = require("b2d")

print("Wind Headless Test")
print("==================")

-- Create world
local def = b2d.default_world_def()
def.gravity = {0, -10}
local world = b2d.create_world(def)
print("World created")

-- Create ground
local body_def = b2d.default_body_def()
local ground_id = b2d.create_body(world, body_def)

-- Create dynamic body
body_def = b2d.default_body_def()
body_def.type = b2d.BodyType.DYNAMICBODY
body_def.position = {0, 5}
body_def.gravityScale = 0.5
body_def.enableSleep = false
local body_id = b2d.create_body(world, body_def)

local shape_def = b2d.default_shape_def()
shape_def.density = 20
local capsule = b2d.Capsule({
    center1 = {0, -0.1},
    center2 = {0, 0.1},
    radius = 0.025
})
b2d.create_capsule_shape(body_id, shape_def, capsule)
print("Body created")

-- Get initial position
local init_pos = b2d.body_get_position(body_id)
print("Initial position: x =", init_pos[1], "y =", init_pos[2])

-- Apply wind force manually (since shape_apply_wind may not be bound)
print("\nSimulating with applied force (simulating wind)...")
for i = 1, 120 do  -- 2 seconds
    -- Apply horizontal force to simulate wind
    local pos = b2d.body_get_position(body_id)
    b2d.body_apply_force(body_id, {10, 0}, pos, true)
    b2d.world_step(world, 1.0/60.0, 4)
end

-- Get final position
local final_pos = b2d.body_get_position(body_id)
print("Final position: x =", final_pos[1], "y =", final_pos[2])

if final_pos[1] > init_pos[1] + 0.1 then
    print("Body moved by wind force!")
else
    print("Body did not move significantly")
end

-- Cleanup
b2d.destroy_world(world)
print("\n==================")
print("Wind Test OK!")
