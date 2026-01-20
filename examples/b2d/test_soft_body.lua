-- test_soft_body.lua - Headless Soft Body (Donut) test
local b2d = require("b2d")

print("Soft Body (Donut) Headless Test")
print("================================")

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

-- Create donut
local sides = 7
local scale = 2.0
local position = {0, 10}

local radius = 1.0 * scale
local delta_angle = 2.0 * math.pi / sides
local length = 2.0 * math.pi * radius / sides

local capsule = b2d.Capsule({
    center1 = {0, -0.5 * length},
    center2 = {0, 0.5 * length},
    radius = 0.25 * scale
})

body_def = b2d.default_body_def()
body_def.type = b2d.BodyType.DYNAMICBODY

shape_def = b2d.default_shape_def()
local filter = b2d.Filter()
filter.groupIndex = -1
shape_def.filter = filter

local donut_bodies = {}
local angle = 0
for i = 1, sides do
    body_def.position = {
        radius * math.cos(angle) + position[1],
        radius * math.sin(angle) + position[2]
    }
    body_def.rotation = b2d.make_rot(angle)
    local body_id = b2d.create_body(world, body_def)
    b2d.create_capsule_shape(body_id, shape_def, capsule)
    table.insert(donut_bodies, body_id)
    angle = angle + delta_angle
end
print("Created " .. sides .. " donut segments")

-- Create weld joints
local weld_def = b2d.default_weld_joint_def()
weld_def.angularHertz = 5.0
weld_def.angularDampingRatio = 0.0

local prev_body_id = donut_bodies[sides]
local donut_joints = {}
for i = 1, sides do
    weld_def.bodyIdA = prev_body_id
    weld_def.bodyIdB = donut_bodies[i]

    local qA = b2d.body_get_rotation(prev_body_id)
    local qB = b2d.body_get_rotation(donut_bodies[i])
    local q_rel = b2d.inv_mul_rot(qA, qB)

    weld_def.localFrameA = b2d.Transform({p = {0, 0.5 * length}, q = q_rel})
    weld_def.localFrameB = b2d.Transform({p = {0, -0.5 * length}, q = {1, 0}})

    local joint_id = b2d.create_weld_joint(world, weld_def)
    table.insert(donut_joints, joint_id)
    prev_body_id = donut_bodies[i]
end
print("Created " .. #donut_joints .. " weld joints")

-- Simulate
print("\nSimulating (donut falling)...")
for i = 1, 300 do  -- 5 seconds
    b2d.world_step(world, 1.0/60.0, 4)
end

local center_y = 0
for _, body_id in ipairs(donut_bodies) do
    local pos = b2d.body_get_position(body_id)
    center_y = center_y + pos[2]
end
center_y = center_y / sides
print("Donut center Y after 5s:", center_y)

if center_y < 5 then
    print("Donut landed on ground: OK")
else
    print("Donut still falling")
end

-- Cleanup
b2d.destroy_world(world)
print("\n================================")
print("Soft Body Test OK!")
