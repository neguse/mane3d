-- test_ball_and_chain.lua - Headless Ball and Chain test
local b2d = require("b2d")

print("Ball and Chain Headless Test")
print("============================")

-- Create world
local def = b2d.default_world_def()
def.gravity = {0, -10}
local world = b2d.create_world(def)
print("World created")

-- Ground
local body_def = b2d.default_body_def()
local ground_id = b2d.create_body(world, body_def)
print("Ground created")

local link_count = 30
local hx = 0.5
local capsule = b2d.Capsule({center1 = {-hx, 0}, center2 = {hx, 0}, radius = 0.125})

local shape_def = b2d.default_shape_def()
shape_def.density = 20.0
local filter1 = b2d.Filter()
filter1.categoryBits = 0x1
filter1.maskBits = 0x2
shape_def.filter = filter1

local joint_def = b2d.default_revolute_joint_def()
local prev_body_id = ground_id
local body_ids = {}
local joint_ids = {}

-- Create chain links
for i = 0, link_count - 1 do
    body_def = b2d.default_body_def()
    body_def.type = b2d.BodyType.DYNAMICBODY
    body_def.position = {(1.0 + 2.0 * i) * hx, link_count * hx}
    local body_id = b2d.create_body(world, body_def)
    b2d.create_capsule_shape(body_id, shape_def, capsule)
    table.insert(body_ids, body_id)

    local pivot = {(2.0 * i) * hx, link_count * hx}
    joint_def.bodyIdA = prev_body_id
    joint_def.bodyIdB = body_id
    local anchorA = b2d.body_get_local_point(prev_body_id, pivot)
    local anchorB = b2d.body_get_local_point(body_id, pivot)
    joint_def.localFrameA = b2d.Transform({p = anchorA, q = {1, 0}})
    joint_def.localFrameB = b2d.Transform({p = anchorB, q = {1, 0}})
    joint_def.enableMotor = true
    joint_def.maxMotorTorque = 100.0
    joint_def.enableSpring = (i > 0)
    joint_def.hertz = 4.0

    local joint_id = b2d.create_revolute_joint(world, joint_def)
    table.insert(joint_ids, joint_id)

    prev_body_id = body_id
end
print("Created " .. link_count .. " chain links")

-- Create ball
local circle = b2d.Circle({center = {0, 0}, radius = 4.0})
body_def = b2d.default_body_def()
body_def.type = b2d.BodyType.DYNAMICBODY
body_def.position = {(1.0 + 2.0 * link_count) * hx + 4.0 - hx, link_count * hx}
local ball_id = b2d.create_body(world, body_def)
local filter2 = b2d.Filter()
filter2.categoryBits = 0x2
filter2.maskBits = 0x1
shape_def.filter = filter2
b2d.create_circle_shape(ball_id, shape_def, circle)

-- Connect ball to chain
local pivot = {(2.0 * link_count) * hx, link_count * hx}
joint_def.bodyIdA = prev_body_id
joint_def.bodyIdB = ball_id
local anchorA = b2d.body_get_local_point(prev_body_id, pivot)
local anchorB = b2d.body_get_local_point(ball_id, pivot)
joint_def.localFrameA = b2d.Transform({p = anchorA, q = {1, 0}})
joint_def.localFrameB = b2d.Transform({p = anchorB, q = {1, 0}})
joint_def.enableMotor = true
joint_def.maxMotorTorque = 100.0
joint_def.enableSpring = true
joint_def.hertz = 4.0
local ball_joint = b2d.create_revolute_joint(world, joint_def)
table.insert(joint_ids, ball_joint)
print("Created ball and connected to chain")
print("Total joints:", #joint_ids)

-- Simulate
print("\nSimulating...")
for i = 1, 180 do  -- 3 seconds
    b2d.world_step(world, 1.0/60.0, 4)
end

local ball_pos = b2d.body_get_position(ball_id)
print("Ball position after 3s: x =", ball_pos[1], "y =", ball_pos[2])

local first_link_pos = b2d.body_get_position(body_ids[1])
print("First link position: x =", first_link_pos[1], "y =", first_link_pos[2])

-- Cleanup
b2d.destroy_world(world)
print("\n============================")
print("Ball and Chain Test OK!")
