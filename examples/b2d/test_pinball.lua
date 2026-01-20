-- test_pinball.lua - Headless Pinball test
local b2d = require("b2d")

print("Pinball Headless Test")
print("=====================")

-- Create world
local def = b2d.default_world_def()
def.gravity = {0, -10}
local world = b2d.create_world(def)
print("World created")

-- Ground with walls
local body_def = b2d.default_body_def()
local ground_id = b2d.create_body(world, body_def)

local points = {{-8, 6}, {-8, 20}, {8, 20}, {8, 6}, {0, -2}}
local chain_def = b2d.default_chain_def()
chain_def.points = points
chain_def.count = #points
chain_def.isLoop = true
b2d.create_chain(ground_id, chain_def)
print("Walls created")

-- Flippers
body_def = b2d.default_body_def()
body_def.type = b2d.BodyType.DYNAMICBODY
body_def.enableSleep = false
body_def.position = {-2, 0}
local left_flipper_id = b2d.create_body(world, body_def)

body_def.position = {2, 0}
local right_flipper_id = b2d.create_body(world, body_def)

local box = b2d.make_box(1.75, 0.2)
local shape_def = b2d.default_shape_def()

b2d.create_polygon_shape(left_flipper_id, shape_def, box)
b2d.create_polygon_shape(right_flipper_id, shape_def, box)

-- Flipper joints
local joint_def = b2d.default_revolute_joint_def()
joint_def.bodyIdA = ground_id
local frame_b = b2d.Transform()
frame_b.p = {0, 0}
frame_b.q = {c = 1, s = 0}
joint_def.localFrameB = frame_b
joint_def.enableMotor = true
joint_def.maxMotorTorque = 1000
joint_def.enableLimit = true

local frame_a = b2d.Transform()
frame_a.p = {-2, 0}
frame_a.q = {c = 1, s = 0}
joint_def.localFrameA = frame_a
joint_def.bodyIdB = left_flipper_id
joint_def.lowerAngle = -30 * math.pi / 180
joint_def.upperAngle = 5 * math.pi / 180
local left_joint_id = b2d.create_revolute_joint(world, joint_def)

frame_a = b2d.Transform()
frame_a.p = {2, 0}
frame_a.q = {c = 1, s = 0}
joint_def.localFrameA = frame_a
joint_def.bodyIdB = right_flipper_id
joint_def.lowerAngle = -5 * math.pi / 180
joint_def.upperAngle = 30 * math.pi / 180
local right_joint_id = b2d.create_revolute_joint(world, joint_def)
print("Flippers created with joints")

-- Ball
body_def = b2d.default_body_def()
body_def.type = b2d.BodyType.DYNAMICBODY
body_def.position = {0, 15}
body_def.isBullet = true
local ball_id = b2d.create_body(world, body_def)

shape_def = b2d.default_shape_def()
shape_def.material = b2d.SurfaceMaterial({restitution = 0.3})
local circle = b2d.Circle({center = {0, 0}, radius = 0.4})
b2d.create_circle_shape(ball_id, shape_def, circle)
print("Ball created")

-- Simulate with flipper activation
print("\nSimulating with flipper activation...")
for i = 1, 180 do  -- 3 seconds
    -- Activate flippers periodically
    local left_speed = (i % 60 < 30) and 20 or -10
    local right_speed = (i % 60 < 30) and -20 or 10

    b2d.revolute_joint_set_motor_speed(left_joint_id, left_speed)
    b2d.revolute_joint_set_motor_speed(right_joint_id, right_speed)

    b2d.world_step(world, 1.0/60.0, 4)
end

-- Check ball position
local ball_pos = b2d.body_get_position(ball_id)
print("Ball position:", ball_pos[1], ball_pos[2])

-- Check flipper positions
local left_rot = b2d.body_get_rotation(left_flipper_id)
local left_angle = b2d.rot_get_angle(left_rot)
print("Left flipper angle:", left_angle * 180 / math.pi, "degrees")

-- Cleanup
b2d.destroy_world(world)
print("\n=====================")
print("Pinball Test OK!")
