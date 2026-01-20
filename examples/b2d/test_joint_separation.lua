-- test_joint_separation.lua - Headless Joint Separation test
local b2d = require("b2d")

print("Joint Separation Headless Test")
print("===============================")

-- Create world
local def = b2d.default_world_def()
def.gravity = {0, -10}
local world = b2d.create_world(def)
print("World created")

-- Ground
local body_def = b2d.default_body_def()
local ground_id = b2d.create_body(world, body_def)

local shape_def = b2d.default_shape_def()
local segment = b2d.Segment({point1 = {-40, 0}, point2 = {40, 0}})
b2d.create_segment_shape(ground_id, shape_def, segment)
print("Ground created")

-- Create body with revolute joint
body_def = b2d.default_body_def()
body_def.type = b2d.BodyType.DYNAMICBODY
body_def.position = {0, 10}
body_def.enableSleep = false
local body1 = b2d.create_body(world, body_def)

local box = b2d.make_box(1.0, 1.0)
b2d.create_polygon_shape(body1, shape_def, box)
print("Dynamic body created")

-- Revolute joint
local pivot = {-1.0, 10}
local revolute_def = b2d.default_revolute_joint_def()
revolute_def.bodyIdA = ground_id
revolute_def.bodyIdB = body1
revolute_def.localFrameA = b2d.Transform({p = pivot, q = {1, 0}})
revolute_def.localFrameB = b2d.Transform({p = {-1.0, 0}, q = {1, 0}})
local joint_id = b2d.create_revolute_joint(world, revolute_def)
print("Revolute joint created")

-- Simulate a few steps
print("\nSimulating...")
for i = 1, 60 do  -- 1 second
    b2d.world_step(world, 1.0/60.0, 4)
end

-- Get separation values
local linear_sep = b2d.joint_get_linear_separation(joint_id)
local angular_sep = b2d.joint_get_angular_separation(joint_id)
print("Linear separation:", linear_sep)
print("Angular separation:", angular_sep, "radians")

-- Apply strong impulse to stress the joint
print("\nApplying strong impulse...")
local p = b2d.body_get_world_point(body1, {1.0, 1.0})
b2d.body_apply_linear_impulse(body1, {500, -500}, p, true)

-- Simulate more
for i = 1, 30 do
    b2d.world_step(world, 1.0/60.0, 4)
end

linear_sep = b2d.joint_get_linear_separation(joint_id)
angular_sep = b2d.joint_get_angular_separation(joint_id)
print("After impulse - Linear separation:", linear_sep)
print("After impulse - Angular separation:", angular_sep, "radians")

-- Cleanup
b2d.destroy_world(world)
print("\n===============================")
print("Joint Separation Test OK!")
