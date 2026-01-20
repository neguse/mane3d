-- test_pivot.lua - Headless Pivot test
local b2d = require("b2d")

print("Pivot Headless Test")
print("===================")

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

-- Dynamic body with initial velocity
local v = {5, 0}
local lever = 3.0

body_def = b2d.default_body_def()
body_def.type = b2d.BodyType.DYNAMICBODY
body_def.position = {0, 3}
body_def.linearVelocity = v

local body_id = b2d.create_body(world, body_def)

-- Calculate initial angular velocity
local r = {0, -lever}
local cross_vr = v[1] * r[2] - v[2] * r[1]
local dot_rr = r[1] * r[1] + r[2] * r[2]
local omega = cross_vr / dot_rr

b2d.body_set_angular_velocity(body_id, omega)

local box = b2d.make_box(0.1, lever)
b2d.create_polygon_shape(body_id, shape_def, box)
print("Body created with initial velocity and angular velocity")
print("Linear velocity:", v[1], v[2])
print("Angular velocity:", omega)

-- Simulate
print("\nSimulating...")
for i = 1, 60 do  -- 1 second
    b2d.world_step(world, 1.0/60.0, 4)
end

-- Check state
local pos = b2d.body_get_position(body_id)
local final_v = b2d.body_get_linear_velocity(body_id)
local final_omega = b2d.body_get_angular_velocity(body_id)

print("Final position:", pos[1], pos[2])
print("Final linear velocity:", final_v[1], final_v[2])
print("Final angular velocity:", final_omega)

-- Cleanup
b2d.destroy_world(world)
print("\n===================")
print("Pivot Test OK!")
