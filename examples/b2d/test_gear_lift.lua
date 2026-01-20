-- test_gear_lift.lua - Headless Gear Lift test
local b2d = require("b2d")

print("Gear Lift Headless Test")
print("=======================")

-- Create world
local def = b2d.default_world_def()
def.gravity = {0, -10}
local world = b2d.create_world(def)
print("World created")

-- Parameters
local gear_radius = 1.0
local tooth_count = 16
local tooth_half_width = 0.09
local tooth_half_height = 0.06
local link_half_length = 0.07
local link_radius = 0.05
local link_count = 20  -- Fewer links for test
local door_half_height = 1.5

local gear_position1 = {-4.25, 9.75}
local gear_position2 = {-2.25, 10.75}

-- Ground
local body_def = b2d.default_body_def()
local ground_id = b2d.create_body(world, body_def)
local shape_def = b2d.default_shape_def()
local segment = b2d.Segment({point1 = {-10, 0}, point2 = {10, 0}})
b2d.create_segment_shape(ground_id, shape_def, segment)
print("Ground created")

-- Driver gear
body_def = b2d.default_body_def()
body_def.type = b2d.BodyType.DYNAMICBODY
body_def.position = gear_position1
local driver_gear_id = b2d.create_body(world, body_def)

shape_def = b2d.default_shape_def()
shape_def.material = b2d.SurfaceMaterial({friction = 0.1})
local circle = b2d.Circle({center = {0, 0}, radius = gear_radius})
b2d.create_circle_shape(driver_gear_id, shape_def, circle)

-- Teeth
local delta_angle = 2.0 * math.pi / tooth_count
for i = 0, tooth_count - 1 do
    local angle = i * delta_angle
    local c, s = math.cos(angle), math.sin(angle)
    local center_x = (gear_radius + tooth_half_height) * c
    local center_y = (gear_radius + tooth_half_height) * s
    local rot = b2d.make_rot(angle)
    local tooth = b2d.make_offset_rounded_box(tooth_half_width, tooth_half_height, {center_x, center_y}, rot, 0.03)
    b2d.create_polygon_shape(driver_gear_id, shape_def, tooth)
end
print("Driver gear created with " .. tooth_count .. " teeth")

-- Driver joint with motor
local revolute_def = b2d.default_revolute_joint_def()
revolute_def.bodyIdA = ground_id
revolute_def.bodyIdB = driver_gear_id
revolute_def.localFrameA = b2d.Transform({p = gear_position1, q = {1, 0}})
revolute_def.localFrameB = b2d.Transform({p = {0, 0}, q = {1, 0}})
revolute_def.enableMotor = true
revolute_def.maxMotorTorque = 80.0
revolute_def.motorSpeed = 0.2
local driver_joint_id = b2d.create_revolute_joint(world, revolute_def)
print("Driver joint created")

-- Follower gear
body_def = b2d.default_body_def()
body_def.type = b2d.BodyType.DYNAMICBODY
body_def.position = gear_position2
local follower_gear_id = b2d.create_body(world, body_def)

b2d.create_circle_shape(follower_gear_id, shape_def, circle)

for i = 0, tooth_count - 1 do
    local angle = i * delta_angle
    local c, s = math.cos(angle), math.sin(angle)
    local center_x = (gear_radius + tooth_half_height) * c
    local center_y = (gear_radius + tooth_half_height) * s
    local rot = b2d.make_rot(angle)
    local tooth = b2d.make_offset_rounded_box(tooth_half_width, tooth_half_height, {center_x, center_y}, rot, 0.03)
    b2d.create_polygon_shape(follower_gear_id, shape_def, tooth)
end
print("Follower gear created")

-- Follower joint
local rot_q = b2d.make_rot(0.25 * math.pi)
revolute_def = b2d.default_revolute_joint_def()
revolute_def.bodyIdA = ground_id
revolute_def.bodyIdB = follower_gear_id
revolute_def.localFrameA = b2d.Transform({p = gear_position2, q = rot_q})
revolute_def.localFrameB = b2d.Transform({p = {0, 0}, q = {1, 0}})
revolute_def.enableMotor = true
revolute_def.maxMotorTorque = 0.5
b2d.create_revolute_joint(world, revolute_def)

-- Chain links
local link_attach_x = gear_position2[1] + gear_radius + 2 * tooth_half_width + 0.03
local position_y = gear_position2[2] - link_half_length

local capsule = b2d.Capsule({
    center1 = {0, -link_half_length},
    center2 = {0, link_half_length},
    radius = link_radius
})

shape_def = b2d.default_shape_def()
shape_def.density = 2.0

local prev_body_id = follower_gear_id
local link_ids = {}
for i = 1, link_count do
    body_def = b2d.default_body_def()
    body_def.type = b2d.BodyType.DYNAMICBODY
    body_def.position = {link_attach_x, position_y}

    local link_id = b2d.create_body(world, body_def)
    b2d.create_capsule_shape(link_id, shape_def, capsule)
    table.insert(link_ids, link_id)

    local pivot = {link_attach_x, position_y + link_half_length}
    local joint_def = b2d.default_revolute_joint_def()
    joint_def.bodyIdA = prev_body_id
    joint_def.bodyIdB = link_id
    joint_def.localFrameA = b2d.Transform({p = b2d.body_get_local_point(prev_body_id, pivot), q = {1, 0}})
    joint_def.localFrameB = b2d.Transform({p = {0, link_half_length}, q = {1, 0}})
    joint_def.enableMotor = true
    joint_def.maxMotorTorque = 0.05
    b2d.create_revolute_joint(world, joint_def)

    position_y = position_y - 2 * link_half_length
    prev_body_id = link_id
end
print("Created " .. link_count .. " chain links")

-- Door
local door_position = {link_attach_x, position_y + link_half_length - door_half_height}
body_def = b2d.default_body_def()
body_def.type = b2d.BodyType.DYNAMICBODY
body_def.position = door_position
local door_id = b2d.create_body(world, body_def)

local box = b2d.make_box(0.15, door_half_height)
shape_def = b2d.default_shape_def()
shape_def.material = b2d.SurfaceMaterial({friction = 0.1})
b2d.create_polygon_shape(door_id, shape_def, box)
print("Door created")

-- Simulate
print("\nSimulating...")
for i = 1, 180 do  -- 3 seconds
    b2d.world_step(world, 1.0/60.0, 4)
end

local door_pos = b2d.body_get_position(door_id)
local driver_rot = b2d.body_get_rotation(driver_gear_id)
local driver_angle = b2d.rot_get_angle(driver_rot)
print("Door position after 3s: y =", door_pos[2])
print("Driver gear angle:", driver_angle, "radians")

-- Cleanup
b2d.destroy_world(world)
print("\n=======================")
print("Gear Lift Test OK!")
