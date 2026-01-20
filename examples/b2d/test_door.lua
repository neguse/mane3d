-- test_door.lua - Headless Door test
local b2d = require("b2d")

print("Door Headless Test")
print("==================")

-- Create world
local def = b2d.default_world_def()
def.gravity = {0, -10}
local world = b2d.create_world(def)
print("World created")

-- Ground
local body_def = b2d.default_body_def()
body_def.position = {0, 0}
local ground_id = b2d.create_body(world, body_def)
print("Ground created")

-- Door
body_def = b2d.default_body_def()
body_def.type = b2d.BodyType.DYNAMICBODY
body_def.position = {0, 1.5}
body_def.gravityScale = 0.0

local door_id = b2d.create_body(world, body_def)

local shape_def = b2d.default_shape_def()
shape_def.density = 1000.0

local box = b2d.make_box(0.1, 1.5)
b2d.create_polygon_shape(door_id, shape_def, box)
print("Door created")

-- Revolute joint with spring
local revolute_def = b2d.default_revolute_joint_def()
revolute_def.bodyIdA = ground_id
revolute_def.bodyIdB = door_id
revolute_def.localFrameA = b2d.Transform({p = {0, 0}, q = {1, 0}})
revolute_def.localFrameB = b2d.Transform({p = {0, -1.5}, q = {1, 0}})
revolute_def.targetAngle = 0
revolute_def.enableSpring = true
revolute_def.hertz = 1.0
revolute_def.dampingRatio = 0.5
revolute_def.lowerAngle = -0.5 * math.pi
revolute_def.upperAngle = 0.5 * math.pi
revolute_def.enableLimit = true

local joint_id = b2d.create_revolute_joint(world, revolute_def)
print("Revolute joint created")

-- Apply impulse to door
local p = b2d.body_get_world_point(door_id, {0, 1.5})
b2d.body_apply_linear_impulse(door_id, {50000, 0}, p, true)
print("Impulse applied")

-- Simulate
print("\nSimulating...")
for i = 1, 180 do  -- 3 seconds
    b2d.world_step(world, 1.0/60.0, 4)
end

local door_rot = b2d.body_get_rotation(door_id)
local door_angle = b2d.rot_get_angle(door_rot)
print("Door angle after 3s:", door_angle, "radians")

-- Cleanup
b2d.destroy_world(world)
print("\n==================")
print("Door Test OK!")
