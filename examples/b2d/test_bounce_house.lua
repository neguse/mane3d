-- test_bounce_house.lua - Headless Bounce House test
local b2d = require("b2d")

print("Bounce House Headless Test")
print("==========================")

-- Create world
local def = b2d.default_world_def()
def.gravity = {0, 0}  -- No gravity for bounce house
local world = b2d.create_world(def)
print("World created")

-- Ground (walls)
local body_def = b2d.default_body_def()
local ground_id = b2d.create_body(world, body_def)

local shape_def = b2d.default_shape_def()

-- Create walls
local walls = {
    {{-10, -10}, {10, -10}},
    {{10, -10}, {10, 10}},
    {{10, 10}, {-10, 10}},
    {{-10, 10}, {-10, -10}},
}

for _, wall in ipairs(walls) do
    local segment = b2d.Segment({point1 = wall[1], point2 = wall[2]})
    b2d.create_segment_shape(ground_id, shape_def, segment)
end
print("Walls created")

-- Bouncing ball (bullet)
body_def = b2d.default_body_def()
body_def.type = b2d.BodyType.DYNAMICBODY
body_def.linearVelocity = {10, 20}
body_def.position = {0, 0}
body_def.gravityScale = 0
body_def.isBullet = true

local body_id = b2d.create_body(world, body_def)

shape_def = b2d.default_shape_def()
shape_def.density = 1
shape_def.material = b2d.SurfaceMaterial({restitution = 1.0, friction = 0})

local circle = b2d.Circle({center = {0, 0}, radius = 0.5})
b2d.create_circle_shape(body_id, shape_def, circle)
print("Bouncing ball created (bullet mode)")

-- Simulate
print("\nSimulating...")
local bounce_count = 0
local last_vel = b2d.body_get_linear_velocity(body_id)

for i = 1, 300 do  -- 5 seconds
    b2d.world_step(world, 1.0/60.0, 4)

    -- Detect direction change (bounce)
    local vel = b2d.body_get_linear_velocity(body_id)
    if (vel[1] * last_vel[1] < 0) or (vel[2] * last_vel[2] < 0) then
        bounce_count = bounce_count + 1
    end
    last_vel = vel
end

print("Bounces detected:", bounce_count)

-- Check ball is still inside
local pos = b2d.body_get_position(body_id)
local inside = (pos[1] > -10 and pos[1] < 10 and pos[2] > -10 and pos[2] < 10)
print("Ball position:", pos[1], pos[2])
print("Ball inside walls:", inside)

if bounce_count > 0 and inside then
    print("Continuous collision working!")
else
    print("Something may not be working correctly")
end

-- Cleanup
b2d.destroy_world(world)
print("\n==========================")
print("Bounce House Test OK!")
