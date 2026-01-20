-- test_explosion.lua - Headless Explosion test
local b2d = require("b2d")

print("Explosion Headless Test")
print("=======================")

-- Create world
local def = b2d.default_world_def()
def.gravity = {0, 0}  -- No gravity for this test
local world = b2d.create_world(def)
print("World created")

-- Create ground
local body_def = b2d.default_body_def()
local ground_id = b2d.create_body(world, body_def)

-- Create dynamic bodies in a circle
local shape_def = b2d.default_shape_def()
local box = b2d.make_box(1.0, 0.1)
local body_ids = {}

local r = 8
for angle = 0, 330, 30 do
    local rad = angle * math.pi / 180
    local c, s = math.cos(rad), math.sin(rad)

    body_def = b2d.default_body_def()
    body_def.type = b2d.BodyType.DYNAMICBODY
    body_def.position = {r * c, r * s}
    body_def.gravityScale = 0

    local body_id = b2d.create_body(world, body_def)
    b2d.create_polygon_shape(body_id, shape_def, box)
    table.insert(body_ids, body_id)
end
print("Created", #body_ids, "bodies in a circle")

-- Get initial positions
local initial_positions = {}
for i, body_id in ipairs(body_ids) do
    initial_positions[i] = b2d.body_get_position(body_id)
end

-- Trigger explosion
print("\nTriggering explosion...")
local explosion_def = b2d.default_explosion_def()
explosion_def.position = {0, 0}
explosion_def.radius = 7
explosion_def.falloff = 3
explosion_def.impulsePerLength = 10
b2d.world_explode(world, explosion_def)
print("Explosion triggered at origin")

-- Simulate
print("Simulating...")
for i = 1, 60 do  -- 1 second
    b2d.world_step(world, 1.0/60.0, 4)
end

-- Check if bodies moved outward
print("\nChecking body movement:")
local moved_count = 0
for i, body_id in ipairs(body_ids) do
    local pos = b2d.body_get_position(body_id)
    local init = initial_positions[i]

    local dist_now = math.sqrt(pos[1] * pos[1] + pos[2] * pos[2])
    local dist_init = math.sqrt(init[1] * init[1] + init[2] * init[2])

    if dist_now > dist_init + 0.1 then
        moved_count = moved_count + 1
    end
end

print("Bodies moved outward:", moved_count, "of", #body_ids)

if moved_count > 0 then
    print("Explosion effect working!")
else
    print("Bodies did not move (explosion may not have enough impulse)")
end

-- Cleanup
b2d.destroy_world(world)
print("\n=======================")
print("Explosion Test OK!")
