-- test_scissor_lift.lua - Headless Scissor Lift test
local b2d = require("b2d")

print("Scissor Lift Headless Test")
print("==========================")

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

-- Create scissor links
body_def = b2d.default_body_def()
body_def.type = b2d.BodyType.DYNAMICBODY
body_def.sleepThreshold = 0.01
shape_def = b2d.default_shape_def()
local capsule = b2d.Capsule({center1 = {-2.5, 0}, center2 = {2.5, 0}, radius = 0.15})

local body_ids = {}
local base_id1, base_id2 = ground_id, ground_id
local base_anchor1 = {-2.5, 0.2}
local base_anchor2 = {2.5, 0.2}
local y = 0.5
local N = 3
local link_id1 = nil

for i = 0, N - 1 do
    body_def.position = {0, y}
    body_def.rotation = b2d.make_rot(0.15)
    local body1 = b2d.create_body(world, body_def)
    b2d.create_capsule_shape(body1, shape_def, capsule)
    table.insert(body_ids, body1)

    body_def.position = {0, y}
    body_def.rotation = b2d.make_rot(-0.15)
    local body2 = b2d.create_body(world, body_def)
    b2d.create_capsule_shape(body2, shape_def, capsule)
    table.insert(body_ids, body2)

    if i == 1 then link_id1 = body2 end

    local revolute_def = b2d.default_revolute_joint_def()
    revolute_def.bodyIdA = base_id1
    revolute_def.bodyIdB = body1
    revolute_def.localFrameA = b2d.Transform({p = base_anchor1, q = {1, 0}})
    revolute_def.localFrameB = b2d.Transform({p = {-2.5, 0}, q = {1, 0}})
    b2d.create_revolute_joint(world, revolute_def)

    if i == 0 then
        local wheel_def = b2d.default_wheel_joint_def()
        wheel_def.bodyIdA = base_id2
        wheel_def.bodyIdB = body2
        wheel_def.localFrameA = b2d.Transform({p = base_anchor2, q = {1, 0}})
        wheel_def.localFrameB = b2d.Transform({p = {2.5, 0}, q = {1, 0}})
        wheel_def.enableSpring = false
        b2d.create_wheel_joint(world, wheel_def)
    else
        revolute_def.bodyIdA = base_id2
        revolute_def.bodyIdB = body2
        revolute_def.localFrameA = b2d.Transform({p = base_anchor2, q = {1, 0}})
        revolute_def.localFrameB = b2d.Transform({p = {2.5, 0}, q = {1, 0}})
        b2d.create_revolute_joint(world, revolute_def)
    end

    revolute_def.bodyIdA = body1
    revolute_def.bodyIdB = body2
    revolute_def.localFrameA = b2d.Transform({p = {0, 0}, q = {1, 0}})
    revolute_def.localFrameB = b2d.Transform({p = {0, 0}, q = {1, 0}})
    b2d.create_revolute_joint(world, revolute_def)

    base_id1, base_id2 = body2, body1
    base_anchor1 = {-2.5, 0}
    base_anchor2 = {2.5, 0}
    y = y + 1.0
end
print("Created " .. #body_ids .. " scissor links")

-- Platform
body_def.position = {0, y}
body_def.rotation = b2d.make_rot(0)
local platform_id = b2d.create_body(world, body_def)
local box = b2d.make_box(3.0, 0.2)
b2d.create_polygon_shape(platform_id, shape_def, box)
print("Platform created")

-- Platform connections
local revolute_def = b2d.default_revolute_joint_def()
revolute_def.bodyIdA = platform_id
revolute_def.bodyIdB = base_id1
revolute_def.localFrameA = b2d.Transform({p = {-2.5, -0.4}, q = {1, 0}})
revolute_def.localFrameB = b2d.Transform({p = base_anchor1, q = {1, 0}})
b2d.create_revolute_joint(world, revolute_def)

local wheel_def = b2d.default_wheel_joint_def()
wheel_def.bodyIdA = platform_id
wheel_def.bodyIdB = base_id2
wheel_def.localFrameA = b2d.Transform({p = {2.5, -0.4}, q = {1, 0}})
wheel_def.localFrameB = b2d.Transform({p = base_anchor2, q = {1, 0}})
wheel_def.enableSpring = false
b2d.create_wheel_joint(world, wheel_def)

-- Distance joint for lift
local distance_def = b2d.default_distance_joint_def()
distance_def.bodyIdA = ground_id
distance_def.bodyIdB = link_id1
distance_def.localFrameA = b2d.Transform({p = {-2.5, 0.2}, q = {1, 0}})
distance_def.localFrameB = b2d.Transform({p = {0.5, 0}, q = {1, 0}})
distance_def.enableSpring = true
distance_def.minLength = 0.2
distance_def.maxLength = 5.5
distance_def.enableLimit = true
distance_def.enableMotor = true
distance_def.motorSpeed = 0.25
distance_def.maxMotorForce = 2000.0
local lift_joint = b2d.create_distance_joint(world, distance_def)
print("Lift joint created")

-- Simulate
print("\nSimulating...")
for i = 1, 180 do  -- 3 seconds
    b2d.world_step(world, 1.0/60.0, 8)  -- 8 substeps for smoother operation
end

local plat_pos = b2d.body_get_position(platform_id)
print("Platform position after 3s: x =", plat_pos[1], "y =", plat_pos[2])

-- Cleanup
b2d.destroy_world(world)
print("\n==========================")
print("Scissor Lift Test OK!")
