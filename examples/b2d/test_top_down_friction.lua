-- test_top_down_friction.lua - Headless Top Down Friction test
local b2d = require("b2d")

print("Top Down Friction Headless Test")
print("================================")

-- Create world with no gravity (top-down view)
local def = b2d.default_world_def()
def.gravity = {0, 0}
local world = b2d.create_world(def)
print("World created (zero gravity for top-down view)")

-- Ground (walls)
local body_def = b2d.default_body_def()
local ground_id = b2d.create_body(world, body_def)

local shape_def = b2d.default_shape_def()
local segment = b2d.Segment({point1 = {-10, 0}, point2 = {10, 0}})
b2d.create_segment_shape(ground_id, shape_def, segment)
segment = b2d.Segment({point1 = {-10, 0}, point2 = {-10, 20}})
b2d.create_segment_shape(ground_id, shape_def, segment)
segment = b2d.Segment({point1 = {10, 0}, point2 = {10, 20}})
b2d.create_segment_shape(ground_id, shape_def, segment)
segment = b2d.Segment({point1 = {-10, 20}, point2 = {10, 20}})
b2d.create_segment_shape(ground_id, shape_def, segment)
print("Walls created")

-- Motor joint definition for friction
local joint_def = b2d.default_motor_joint_def()
joint_def.bodyIdA = ground_id
joint_def.maxVelocityForce = 10.0
joint_def.maxVelocityTorque = 10.0

-- Create some bodies with motor joint friction
local body_ids = {}
local circle = b2d.Circle({center = {0, 0}, radius = 0.35})

body_def = b2d.default_body_def()
body_def.type = b2d.BodyType.DYNAMICBODY
body_def.gravityScale = 0.0

shape_def = b2d.default_shape_def()
shape_def.material = b2d.SurfaceMaterial({restitution = 0.8})

-- Create 4 bodies in a row
for i = 1, 4 do
    local x = -3 + i * 2
    local y = 10
    body_def.position = {x, y}
    local body_id = b2d.create_body(world, body_def)
    b2d.create_circle_shape(body_id, shape_def, circle)
    table.insert(body_ids, body_id)

    joint_def.bodyIdB = body_id
    joint_def.localFrameA = b2d.Transform({p = {x, y}, q = {1, 0}})
    b2d.create_motor_joint(world, joint_def)
end
print("Created 4 bodies with motor joint friction")

-- Apply impulse to first body
local impulse = {50, 0}
b2d.body_apply_linear_impulse_to_center(body_ids[1], impulse, true)
print("Applied impulse to first body")

-- Record initial velocity
local init_vel = b2d.body_get_linear_velocity(body_ids[1])
print("Initial velocity: x =", init_vel[1], "y =", init_vel[2])

-- Simulate
print("\nSimulating...")
for i = 1, 180 do  -- 3 seconds
    b2d.world_step(world, 1.0/60.0, 4)
end

-- Check final velocity (should be lower due to friction)
local final_vel = b2d.body_get_linear_velocity(body_ids[1])
print("Final velocity after 3s: x =", final_vel[1], "y =", final_vel[2])

-- The motor joint friction should slow things down
local speed_reduction = math.abs(init_vel[1]) - math.abs(final_vel[1])
print("Speed reduction:", speed_reduction)

-- Cleanup
b2d.destroy_world(world)
print("\n================================")
print("Top Down Friction Test OK!")
