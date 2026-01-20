-- test_motor_joint.lua - Headless Motor Joint test
local b2d = require("b2d")

print("Motor Joint Headless Test")
print("=========================")

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

-- Kinematic target body
body_def = b2d.default_body_def()
body_def.type = b2d.BodyType.KINEMATICBODY
body_def.position = {0, 8}
local target_id = b2d.create_body(world, body_def)
print("Target body created (kinematic)")

-- Dynamic motorized body
body_def = b2d.default_body_def()
body_def.type = b2d.BodyType.DYNAMICBODY
body_def.position = {0, 8}
local body_id = b2d.create_body(world, body_def)
local box = b2d.make_box(2, 0.5)
shape_def = b2d.default_shape_def()
b2d.create_polygon_shape(body_id, shape_def, box)
print("Dynamic body created")

-- Motor joint
local joint_def = b2d.default_motor_joint_def()
joint_def.bodyIdA = target_id
joint_def.bodyIdB = body_id
joint_def.linearHertz = 4.0
joint_def.linearDampingRatio = 0.7
joint_def.angularHertz = 4.0
joint_def.angularDampingRatio = 0.7
joint_def.maxSpringForce = 5000.0
joint_def.maxSpringTorque = 500.0
local joint_id = b2d.create_motor_joint(world, joint_def)
print("Motor joint created:", joint_id)

-- Simulate
print("\nSimulating...")
local time = 0
for i = 1, 120 do  -- 2 seconds
    local dt = 1.0 / 60.0
    time = time + dt

    -- Move target in figure-8
    local x = 6 * math.sin(2 * time)
    local y = 8 + 4 * math.sin(time)
    local angle = 2 * time
    local rot = b2d.make_rot(angle)
    -- Transform as table: {{p.x, p.y}, {q.c, q.s}}
    local transform = {{x, y}, {rot[1], rot[2]}}
    b2d.body_set_target_transform(target_id, transform, dt, true)

    b2d.world_step(world, dt, 4)
end

local pos = b2d.body_get_position(body_id)
print("Body position after 2s: x =", pos[1], "y =", pos[2])

local force = b2d.joint_get_constraint_force(joint_id)
local torque = b2d.joint_get_constraint_torque(joint_id)
print("Constraint force:", force[1], force[2])
print("Constraint torque:", torque)

-- Cleanup
b2d.destroy_world(world)
print("\n=========================")
print("Motor Joint Test OK!")
