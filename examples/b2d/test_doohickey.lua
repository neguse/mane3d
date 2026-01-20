-- test_doohickey.lua - Headless Doohickey test
local b2d = require("b2d")

print("Doohickey Headless Test")
print("=======================")

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

-- Create one doohickey
local scale = 0.5
local position = {0, 4}

body_def = b2d.default_body_def()
body_def.type = b2d.BodyType.DYNAMICBODY
shape_def = b2d.default_shape_def()

local circle = b2d.Circle({center = {0, 0}, radius = 1.0 * scale})
local capsule = b2d.Capsule({
    center1 = {-3.5 * scale, 0},
    center2 = {3.5 * scale, 0},
    radius = 0.15 * scale
})

-- Wheel 1
body_def.position = {position[1] + scale * (-5), position[2] + scale * 3}
local wheel1 = b2d.create_body(world, body_def)
b2d.create_circle_shape(wheel1, shape_def, circle)

-- Wheel 2
body_def.position = {position[1] + scale * 5, position[2] + scale * 3}
local wheel2 = b2d.create_body(world, body_def)
b2d.create_circle_shape(wheel2, shape_def, circle)

-- Bar 1
body_def.position = {position[1] + scale * (-1.5), position[2] + scale * 3}
local bar1 = b2d.create_body(world, body_def)
b2d.create_capsule_shape(bar1, shape_def, capsule)

-- Bar 2
body_def.position = {position[1] + scale * 1.5, position[2] + scale * 3}
local bar2 = b2d.create_body(world, body_def)
b2d.create_capsule_shape(bar2, shape_def, capsule)
print("Created 2 wheels and 2 bars")

-- Revolute joints
local revolute_def = b2d.default_revolute_joint_def()
revolute_def.bodyIdA = wheel1
revolute_def.bodyIdB = bar1
revolute_def.localFrameA = b2d.Transform({p = {0, 0}, q = {1, 0}})
revolute_def.localFrameB = b2d.Transform({p = {-3.5 * scale, 0}, q = {1, 0}})
revolute_def.enableMotor = true
revolute_def.maxMotorTorque = 2.0 * scale
b2d.create_revolute_joint(world, revolute_def)

revolute_def.bodyIdA = wheel2
revolute_def.bodyIdB = bar2
revolute_def.localFrameA = b2d.Transform({p = {0, 0}, q = {1, 0}})
revolute_def.localFrameB = b2d.Transform({p = {3.5 * scale, 0}, q = {1, 0}})
b2d.create_revolute_joint(world, revolute_def)
print("Created 2 revolute joints")

-- Prismatic joint
local prismatic_def = b2d.default_prismatic_joint_def()
prismatic_def.bodyIdA = bar1
prismatic_def.bodyIdB = bar2
prismatic_def.localFrameA = b2d.Transform({p = {2.0 * scale, 0}, q = {1, 0}})
prismatic_def.localFrameB = b2d.Transform({p = {-2.0 * scale, 0}, q = {1, 0}})
prismatic_def.lowerTranslation = -2.0 * scale
prismatic_def.upperTranslation = 2.0 * scale
prismatic_def.enableLimit = true
prismatic_def.enableMotor = true
prismatic_def.maxMotorForce = 2.0 * scale
prismatic_def.enableSpring = true
prismatic_def.hertz = 1.0
prismatic_def.dampingRatio = 0.5
b2d.create_prismatic_joint(world, prismatic_def)
print("Created prismatic joint")

-- Simulate
print("\nSimulating...")
for i = 1, 180 do  -- 3 seconds
    b2d.world_step(world, 1.0/60.0, 4)
end

local w1_pos = b2d.body_get_position(wheel1)
local w2_pos = b2d.body_get_position(wheel2)
print("Wheel1 position after 3s: x =", w1_pos[1], "y =", w1_pos[2])
print("Wheel2 position after 3s: x =", w2_pos[1], "y =", w2_pos[2])

-- Cleanup
b2d.destroy_world(world)
print("\n=======================")
print("Doohickey Test OK!")
