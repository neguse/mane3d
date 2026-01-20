-- test_motion_locks.lua - Headless Motion Locks test
local b2d = require("b2d")

print("Motion Locks Headless Test")
print("==========================")

-- Create world
local def = b2d.default_world_def()
def.gravity = {0, -10}
local world = b2d.create_world(def)
print("World created")

-- Ground
local body_def = b2d.default_body_def()
local ground_id = b2d.create_body(world, body_def)
print("Ground created")

-- Motion locks: lock angular Z
local motion_locks = b2d.MotionLocks()
motion_locks.linearX = false
motion_locks.linearY = false
motion_locks.angularZ = true

local position_x = -12.5
local position_y = 10.0

body_def = b2d.default_body_def()
body_def.type = b2d.BodyType.DYNAMICBODY
body_def.motionLocks = motion_locks

local box = b2d.make_box(1.0, 1.0)
local shape_def = b2d.default_shape_def()

-- 1. Distance joint
body_def.position = {position_x, position_y}
local body1 = b2d.create_body(world, body_def)
b2d.create_polygon_shape(body1, shape_def, box)

local length = 2.0
local pivot1 = {position_x, position_y + 1.0 + length}
local distance_def = b2d.default_distance_joint_def()
distance_def.bodyIdA = ground_id
distance_def.bodyIdB = body1
distance_def.localFrameA = b2d.Transform({p = pivot1, q = {1, 0}})
distance_def.localFrameB = b2d.Transform({p = {0, 1.0}, q = {1, 0}})
distance_def.length = length
b2d.create_distance_joint(world, distance_def)
print("Created body with distance joint")

position_x = position_x + 5.0

-- 2. Revolute joint
body_def.position = {position_x, position_y}
local body2 = b2d.create_body(world, body_def)
b2d.create_polygon_shape(body2, shape_def, box)

local pivot = {position_x - 1.0, position_y}
local revolute_def = b2d.default_revolute_joint_def()
revolute_def.bodyIdA = ground_id
revolute_def.bodyIdB = body2
revolute_def.localFrameA = b2d.Transform({p = pivot, q = {1, 0}})
revolute_def.localFrameB = b2d.Transform({p = {-1.0, 0}, q = {1, 0}})
b2d.create_revolute_joint(world, revolute_def)
print("Created body with revolute joint")

position_x = position_x + 5.0

-- 3. Weld joint
body_def.position = {position_x, position_y}
local body3 = b2d.create_body(world, body_def)
b2d.create_polygon_shape(body3, shape_def, box)

pivot = {position_x - 1.0, position_y}
local weld_def = b2d.default_weld_joint_def()
weld_def.bodyIdA = ground_id
weld_def.bodyIdB = body3
weld_def.localFrameA = b2d.Transform({p = pivot, q = {1, 0}})
weld_def.localFrameB = b2d.Transform({p = {-1.0, 0}, q = {1, 0}})
weld_def.angularHertz = 1.0
weld_def.angularDampingRatio = 0.5
weld_def.linearHertz = 1.0
weld_def.linearDampingRatio = 0.5
b2d.create_weld_joint(world, weld_def)
print("Created body with weld joint")

-- Simulate
print("\nSimulating...")
for i = 1, 180 do  -- 3 seconds
    b2d.world_step(world, 1.0/60.0, 4)
end

-- Check rotations (should be 0 due to angular lock)
local rot1 = b2d.body_get_rotation(body1)
local angle1 = b2d.rot_get_angle(rot1)
local rot2 = b2d.body_get_rotation(body2)
local angle2 = b2d.rot_get_angle(rot2)
print("Body1 angle (should be ~0):", angle1)
print("Body2 angle (should be ~0):", angle2)

-- Test unlocking
print("\nUnlocking angular Z...")
motion_locks.angularZ = false
b2d.body_set_motion_locks(body2, motion_locks)
b2d.body_set_awake(body2, true)

-- Simulate more
for i = 1, 120 do  -- 2 seconds
    b2d.world_step(world, 1.0/60.0, 4)
end

rot2 = b2d.body_get_rotation(body2)
angle2 = b2d.rot_get_angle(rot2)
print("Body2 angle after unlock:", angle2)

-- Cleanup
b2d.destroy_world(world)
print("\n==========================")
print("Motion Locks Test OK!")
