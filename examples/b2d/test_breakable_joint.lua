-- test_breakable_joint.lua - Headless Breakable Joint test
local b2d = require("b2d")

print("Breakable Joint Headless Test")
print("==============================")

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

-- Create body with distance joint
body_def = b2d.default_body_def()
body_def.type = b2d.BodyType.DYNAMICBODY
body_def.position = {0, 10}
body_def.enableSleep = false
local body1 = b2d.create_body(world, body_def)

local box = b2d.make_box(1.0, 1.0)
b2d.create_polygon_shape(body1, shape_def, box)
print("Dynamic body created")

local length = 2.0
local pivot1 = {0, 10 + 1.0 + length}
local distance_def = b2d.default_distance_joint_def()
distance_def.bodyIdA = ground_id
distance_def.bodyIdB = body1
distance_def.localFrameA = b2d.Transform({p = pivot1, q = {1, 0}})
distance_def.localFrameB = b2d.Transform({p = {0, 1.0}, q = {1, 0}})
distance_def.length = length
local joint_id = b2d.create_distance_joint(world, distance_def)
print("Distance joint created")

-- Simulate and check joint force
print("\nSimulating with normal gravity...")
local break_force = 500.0
local joint_broken = false

for i = 1, 120 do  -- 2 seconds
    b2d.world_step(world, 1.0/60.0, 4)

    if b2d.joint_is_valid(joint_id) then
        local force = b2d.joint_get_constraint_force(joint_id)
        local force_mag = math.sqrt(force[1] * force[1] + force[2] * force[2])

        if force_mag > break_force then
            print("Joint force exceeded threshold:", force_mag)
            b2d.destroy_joint(joint_id)
            joint_broken = true
            break
        end
    end
end

if not joint_broken then
    print("Joint intact under normal gravity")

    -- Increase gravity to break joint
    print("\nIncreasing gravity to break joint...")
    b2d.world_set_gravity(world, {0, -100})

    for i = 1, 60 do  -- 1 second
        b2d.world_step(world, 1.0/60.0, 4)

        if b2d.joint_is_valid(joint_id) then
            local force = b2d.joint_get_constraint_force(joint_id)
            local force_mag = math.sqrt(force[1] * force[1] + force[2] * force[2])

            if force_mag > break_force then
                print("Joint broken! Force was:", force_mag)
                b2d.destroy_joint(joint_id)
                joint_broken = true
                break
            end
        end
    end
end

local body_pos = b2d.body_get_position(body1)
print("Final body position: y =", body_pos[2])

-- Cleanup
b2d.destroy_world(world)
print("\n==============================")
print("Breakable Joint Test OK!")
