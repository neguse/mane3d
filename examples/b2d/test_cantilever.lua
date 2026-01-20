-- test_cantilever.lua - Headless Cantilever test
local b2d = require("b2d")

print("Cantilever Headless Test")
print("========================")

-- Create world
local def = b2d.default_world_def()
def.gravity = {0, -10}
local world = b2d.create_world(def)
print("World created")

-- Ground
local body_def = b2d.default_body_def()
local ground_id = b2d.create_body(world, body_def)
print("Ground created")

local link_count = 8
local hx = 0.5
local capsule = b2d.Capsule({center1 = {-hx, 0}, center2 = {hx, 0}, radius = 0.125})

local shape_def = b2d.default_shape_def()
shape_def.density = 20.0

local joint_def = b2d.default_weld_joint_def()
local prev_body_id = ground_id
local body_ids = {}
local joint_ids = {}

-- Create cantilever links
for i = 0, link_count - 1 do
    body_def = b2d.default_body_def()
    body_def.type = b2d.BodyType.DYNAMICBODY
    body_def.position = {(1.0 + 2.0 * i) * hx, 0}
    body_def.isAwake = false
    local body_id = b2d.create_body(world, body_def)
    b2d.create_capsule_shape(body_id, shape_def, capsule)
    table.insert(body_ids, body_id)

    local pivot = {(2.0 * i) * hx, 0}
    joint_def.bodyIdA = prev_body_id
    joint_def.bodyIdB = body_id
    local anchorA = b2d.body_get_local_point(prev_body_id, pivot)
    local anchorB = b2d.body_get_local_point(body_id, pivot)
    joint_def.localFrameA = b2d.Transform({p = anchorA, q = {1, 0}})
    joint_def.localFrameB = b2d.Transform({p = anchorB, q = {1, 0}})
    joint_def.linearHertz = 15.0
    joint_def.linearDampingRatio = 0.5
    joint_def.angularHertz = 5.0
    joint_def.angularDampingRatio = 0.5

    local joint_id = b2d.create_weld_joint(world, joint_def)
    table.insert(joint_ids, joint_id)

    -- Experimental tuning
    b2d.joint_set_constraint_tuning(joint_id, 120.0, 10.0)

    prev_body_id = body_id
end
print("Created " .. link_count .. " cantilever links")
print("Total joints:", #joint_ids)

local tip_id = body_ids[#body_ids]

-- Simulate
print("\nSimulating...")
for i = 1, 180 do  -- 3 seconds
    b2d.world_step(world, 1.0/60.0, 4)
end

local tip_pos = b2d.body_get_position(tip_id)
print("Tip position after 3s: x =", tip_pos[1], "y =", tip_pos[2])

local first_link_pos = b2d.body_get_position(body_ids[1])
print("First link position: x =", first_link_pos[1], "y =", first_link_pos[2])

-- Cleanup
b2d.destroy_world(world)
print("\n========================")
print("Cantilever Test OK!")
