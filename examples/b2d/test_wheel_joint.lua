-- test_wheel_joint.lua - Headless Wheel Joint test
local b2d = require("b2d")

print("Wheel Joint Headless Test")
print("=========================")

-- Create world
local def = b2d.default_world_def()
def.gravity = {0, -10}
local world = b2d.create_world(def)
print("World created")

-- Ground
local body_def = b2d.default_body_def()
local ground_id = b2d.create_body(world, body_def)
print("Ground created")

-- Dynamic body with capsule
body_def = b2d.default_body_def()
body_def.type = b2d.BodyType.DYNAMICBODY
body_def.position = {0, 10.25}
local body_id = b2d.create_body(world, body_def)
local shape_def = b2d.default_shape_def()
local capsule = b2d.Capsule({center1 = {0, -0.5}, center2 = {0, 0.5}, radius = 0.5})
b2d.create_capsule_shape(body_id, shape_def, capsule)
print("Dynamic body with capsule created")

-- Wheel joint
local pivot = {0, 10}
local axis_len = math.sqrt(2)
local axis = {1/axis_len, 1/axis_len}

local joint_def = b2d.default_wheel_joint_def()
joint_def.bodyIdA = ground_id
joint_def.bodyIdB = body_id

local rot = b2d.make_rot_from_unit_vector(axis)
local anchorA = b2d.body_get_local_point(ground_id, pivot)
local anchorB = b2d.body_get_local_point(body_id, pivot)
joint_def.localFrameA = b2d.Transform({p = anchorA, q = rot})
joint_def.localFrameB = b2d.Transform({p = anchorB, q = {1, 0}})

joint_def.motorSpeed = 2.0
joint_def.maxMotorTorque = 5.0
joint_def.enableMotor = true
joint_def.lowerTranslation = -3
joint_def.upperTranslation = 3
joint_def.enableLimit = true
joint_def.hertz = 1.0
joint_def.dampingRatio = 0.7
joint_def.enableSpring = true

local joint_id = b2d.create_wheel_joint(world, joint_def)
print("Wheel joint created:", joint_id)

-- Simulate
print("\nSimulating...")
for i = 1, 120 do
    b2d.world_step(world, 1.0/60.0, 4)
end

local pos = b2d.body_get_position(body_id)
print("Body position after 2s: x =", pos[1], "y =", pos[2])

local torque = b2d.wheel_joint_get_motor_torque(joint_id)
print("Motor torque:", torque)

-- Cleanup
b2d.destroy_world(world)
print("\n=========================")
print("Wheel Joint Test OK!")
