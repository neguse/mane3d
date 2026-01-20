-- test_driving.lua - Headless Driving test
local b2d = require("b2d")

print("Driving Headless Test")
print("=====================")

-- Create world
local def = b2d.default_world_def()
def.gravity = {0, -10}
local world = b2d.create_world(def)
print("World created")

-- Ground
local body_def = b2d.default_body_def()
local ground_id = b2d.create_body(world, body_def)
local shape_def = b2d.default_shape_def()
local segment = b2d.Segment({point1 = {-50, 0}, point2 = {200, 0}})
b2d.create_segment_shape(ground_id, shape_def, segment)
print("Ground created")

-- Create car chassis
body_def = b2d.default_body_def()
body_def.type = b2d.BodyType.DYNAMICBODY
body_def.position = {0, 1}
local chassis_id = b2d.create_body(world, body_def)

local chassis_box = b2d.make_box(2.0, 0.5)
shape_def = b2d.default_shape_def()
shape_def.density = 1.0
b2d.create_polygon_shape(chassis_id, shape_def, chassis_box)
print("Chassis created")

-- Front wheel
body_def.position = {1.5, 0.5}
local wheel_front_id = b2d.create_body(world, body_def)

local circle = b2d.Circle({center = {0, 0}, radius = 0.4})
shape_def = b2d.default_shape_def()
shape_def.density = 1.0
shape_def.material = b2d.SurfaceMaterial({friction = 0.9})
b2d.create_circle_shape(wheel_front_id, shape_def, circle)

-- Rear wheel
body_def.position = {-1.5, 0.5}
local wheel_rear_id = b2d.create_body(world, body_def)
b2d.create_circle_shape(wheel_rear_id, shape_def, circle)
print("Wheels created")

-- Front wheel joint
local wheel_def = b2d.default_wheel_joint_def()
wheel_def.bodyIdA = chassis_id
wheel_def.bodyIdB = wheel_front_id
wheel_def.localFrameA = b2d.Transform({p = {1.5, -0.5}, q = {1, 0}})
wheel_def.localFrameB = b2d.Transform({p = {0, 0}, q = {1, 0}})
wheel_def.enableSpring = true
wheel_def.hertz = 5.0
wheel_def.dampingRatio = 0.7
wheel_def.lowerTranslation = -0.25
wheel_def.upperTranslation = 0.25
wheel_def.enableLimit = true
wheel_def.enableMotor = true
wheel_def.maxMotorTorque = 5.0
wheel_def.motorSpeed = 0
local joint_front_id = b2d.create_wheel_joint(world, wheel_def)

-- Rear wheel joint
wheel_def.bodyIdA = chassis_id
wheel_def.bodyIdB = wheel_rear_id
wheel_def.localFrameA = b2d.Transform({p = {-1.5, -0.5}, q = {1, 0}})
wheel_def.localFrameB = b2d.Transform({p = {0, 0}, q = {1, 0}})
local joint_rear_id = b2d.create_wheel_joint(world, wheel_def)
print("Wheel joints created")

-- Let car settle
print("\nSettling...")
for i = 1, 60 do
    b2d.world_step(world, 1.0/60.0, 4)
end

local init_pos = b2d.body_get_position(chassis_id)
print("Initial position: x =", init_pos[1])

-- Drive forward
print("Driving forward...")
b2d.wheel_joint_set_motor_speed(joint_front_id, 30)
b2d.wheel_joint_set_motor_speed(joint_rear_id, 30)
b2d.joint_wake_bodies(joint_front_id)
b2d.joint_wake_bodies(joint_rear_id)

for i = 1, 180 do  -- 3 seconds
    b2d.world_step(world, 1.0/60.0, 4)
end

local final_pos = b2d.body_get_position(chassis_id)
local vel = b2d.body_get_linear_velocity(chassis_id)
print("Final position: x =", final_pos[1])
print("Velocity: x =", vel[1], "y =", vel[2])
print("Distance traveled:", final_pos[1] - init_pos[1])

-- Cleanup
b2d.destroy_world(world)
print("\n=====================")
print("Driving Test OK!")
