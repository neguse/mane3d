-- test_prismatic_joint.lua - Headless Prismatic Joint test
local b2d = require("b2d")

print("Prismatic Joint Headless Test")
print("==============================")

-- Create world
local def = b2d.default_world_def()
def.gravity = {0, -10}
local world = b2d.create_world(def)
print("World created")

-- Ground
local body_def = b2d.default_body_def()
local ground_id = b2d.create_body(world, body_def)
print("Ground created")

-- Dynamic body
body_def = b2d.default_body_def()
body_def.type = b2d.BodyType.DYNAMICBODY
body_def.position = {0, 10}
local body_id = b2d.create_body(world, body_def)
local shape_def = b2d.default_shape_def()
local box = b2d.make_box(0.5, 2)
b2d.create_polygon_shape(body_id, shape_def, box)
print("Dynamic body created")

-- Prismatic joint
local pivot = {0, 9}
local axis_len = math.sqrt(2)
local axis = {1/axis_len, 1/axis_len}

local joint_def = b2d.default_prismatic_joint_def()
joint_def.bodyIdA = ground_id
joint_def.bodyIdB = body_id
local anchorA = b2d.body_get_local_point(ground_id, pivot)
local anchorB = b2d.body_get_local_point(body_id, pivot)
local rot = b2d.make_rot_from_unit_vector(axis)
joint_def.localFrameA = b2d.Transform({p = anchorA, q = rot})
joint_def.localFrameB = b2d.Transform({p = anchorB, q = rot})
joint_def.lowerTranslation = -10
joint_def.upperTranslation = 10
joint_def.enableLimit = true
joint_def.enableMotor = true
joint_def.motorSpeed = 5
joint_def.maxMotorForce = 100

local joint_id = b2d.create_prismatic_joint(world, joint_def)
print("Prismatic joint created:", joint_id)

-- Simulate
print("\nSimulating...")
for i = 1, 120 do
    b2d.world_step(world, 1.0/60.0, 4)
end

local pos = b2d.body_get_position(body_id)
print("Body position after 2s: x =", pos[1], "y =", pos[2])

local trans = b2d.prismatic_joint_get_translation(joint_id)
print("Joint translation:", trans)

local force = b2d.prismatic_joint_get_motor_force(joint_id)
print("Motor force:", force)

-- Cleanup
b2d.destroy_world(world)
print("\n==============================")
print("Prismatic Joint Test OK!")
