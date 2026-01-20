-- test_ragdoll.lua - Headless Ragdoll test
local b2d = require("b2d")

print("Ragdoll Headless Test")
print("=====================")

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

-- Simple ragdoll: just hip, torso, head
local bones = {}
local scale = 1.0
local px, py = 0, 25

body_def = b2d.default_body_def()
body_def.type = b2d.BodyType.DYNAMICBODY

shape_def = b2d.default_shape_def()
local filter = b2d.Filter()
filter.groupIndex = -1
filter.categoryBits = 2
filter.maskBits = 3
shape_def.filter = filter

-- Hip
body_def.position = {px, py + 0.95 * scale}
local hip_id = b2d.create_body(world, body_def)
local capsule = b2d.Capsule({center1 = {0, -0.02 * scale}, center2 = {0, 0.02 * scale}, radius = 0.095 * scale})
b2d.create_capsule_shape(hip_id, shape_def, capsule)
print("Hip created")

-- Torso
body_def.position = {px, py + 1.2 * scale}
local torso_id = b2d.create_body(world, body_def)
capsule = b2d.Capsule({center1 = {0, -0.135 * scale}, center2 = {0, 0.135 * scale}, radius = 0.09 * scale})
b2d.create_capsule_shape(torso_id, shape_def, capsule)

local pivot = {px, py + 1.0 * scale}
local joint_def = b2d.default_revolute_joint_def()
joint_def.bodyIdA = hip_id
joint_def.bodyIdB = torso_id
local anchorA = b2d.body_get_local_point(hip_id, pivot)
local anchorB = b2d.body_get_local_point(torso_id, pivot)
joint_def.localFrameA = b2d.Transform({p = anchorA, q = {1, 0}})
joint_def.localFrameB = b2d.Transform({p = anchorB, q = {1, 0}})
joint_def.enableLimit = true
joint_def.lowerAngle = -0.25 * math.pi
joint_def.upperAngle = 0
joint_def.enableMotor = true
joint_def.maxMotorTorque = 0.03
joint_def.enableSpring = true
joint_def.hertz = 5.0
joint_def.dampingRatio = 0.5
local hip_torso_joint = b2d.create_revolute_joint(world, joint_def)
print("Torso created with joint")

-- Head
body_def.position = {px, py + 1.475 * scale}
local head_id = b2d.create_body(world, body_def)
capsule = b2d.Capsule({center1 = {0, -0.038 * scale}, center2 = {0, 0.039 * scale}, radius = 0.075 * scale})
b2d.create_capsule_shape(head_id, shape_def, capsule)

pivot = {px, py + 1.4 * scale}
joint_def = b2d.default_revolute_joint_def()
joint_def.bodyIdA = torso_id
joint_def.bodyIdB = head_id
anchorA = b2d.body_get_local_point(torso_id, pivot)
anchorB = b2d.body_get_local_point(head_id, pivot)
joint_def.localFrameA = b2d.Transform({p = anchorA, q = {1, 0}})
joint_def.localFrameB = b2d.Transform({p = anchorB, q = {1, 0}})
joint_def.enableLimit = true
joint_def.lowerAngle = -0.3 * math.pi
joint_def.upperAngle = 0.1 * math.pi
joint_def.enableMotor = true
joint_def.maxMotorTorque = 0.01
joint_def.enableSpring = true
joint_def.hertz = 5.0
joint_def.dampingRatio = 0.5
local torso_head_joint = b2d.create_revolute_joint(world, joint_def)
print("Head created with joint")

-- Contact tuning
b2d.world_set_contact_tuning(world, 240.0, 0.0, 2.0)

-- Simulate
print("\nSimulating (ragdoll falling)...")
for i = 1, 300 do  -- 5 seconds
    b2d.world_step(world, 1.0/60.0, 4)
end

local hip_pos = b2d.body_get_position(hip_id)
local head_pos = b2d.body_get_position(head_id)
print("Hip position after 5s: x =", hip_pos[1], "y =", hip_pos[2])
print("Head position after 5s: x =", head_pos[1], "y =", head_pos[2])

-- Verify ragdoll landed on ground
if hip_pos[2] < 2 then
    print("Ragdoll landed on ground: OK")
else
    print("Ragdoll still falling: y =", hip_pos[2])
end

-- Cleanup
b2d.destroy_world(world)
print("\n=====================")
print("Ragdoll Test OK!")
