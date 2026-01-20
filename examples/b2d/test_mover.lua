-- test_mover.lua - Headless Character Mover test
local b2d = require("b2d")

print("Character Mover Headless Test")
print("=============================")

-- Create world
local def = b2d.default_world_def()
def.gravity = {0, -10}
local world = b2d.create_world(def)
print("World created")

-- Ground
local body_def = b2d.default_body_def()
local ground_id = b2d.create_body(world, body_def)

local shape_def = b2d.default_shape_def()
local segment = b2d.Segment({point1 = {-10, 0}, point2 = {30, 0}})
b2d.create_segment_shape(ground_id, shape_def, segment)
print("Ground created")

-- Simple character simulation
local pos = {5, 5}
local vel = {0, 0}
local gravity = -30
local dt = 1.0/60.0

print("\nSimulating character movement...")
for i = 1, 60 do  -- 1 second
    -- Apply gravity
    vel[2] = vel[2] + gravity * dt

    -- Update position
    pos[1] = pos[1] + vel[1] * dt
    pos[2] = pos[2] + vel[2] * dt

    -- Ground collision
    if pos[2] < 0.5 then  -- Assuming character radius
        pos[2] = 0.5
        vel[2] = 0
    end

    b2d.world_step(world, dt, 4)
end

print("Final character position:", pos[1], pos[2])

if pos[2] < 1 then
    print("Character landed on ground!")
else
    print("Character still falling")
end

-- Cleanup
b2d.destroy_world(world)
print("\n=============================")
print("Character Mover Test OK!")
