-- motion_locks.lua - Box2D official Motion Locks sample
-- Demonstrates motion locks with different joint types.
local b2d = require("b2d")
local draw = require("examples.b2d.draw")
local imgui = require("imgui")

local M = {}

M.camera = {
    center_x = 0,
    center_y = 8,
    zoom = 25 * 0.7,
}

local ground_id = nil
local body_ids = {}
local lock_linear_x = false
local lock_linear_y = false
local lock_angular_z = true

function M.create_scene(world)
    body_ids = {}

    -- Ground
    local body_def = b2d.default_body_def()
    ground_id = b2d.create_body(world, body_def)

    local motion_locks = b2d.MotionLocks()
    motion_locks.linearX = lock_linear_x
    motion_locks.linearY = lock_linear_y
    motion_locks.angularZ = lock_angular_z

    local position_x = -12.5
    local position_y = 10.0

    body_def = b2d.default_body_def()
    body_def.type = b2d.BodyType.DYNAMICBODY
    body_def.motionLocks = motion_locks

    local box = b2d.make_box(1.0, 1.0)
    local shape_def = b2d.default_shape_def()

    -- 1. Distance joint
    body_def.position = {position_x, position_y}
    local body1 = b2d.create_body(world, body_def)
    b2d.create_polygon_shape(body1, shape_def, box)
    table.insert(body_ids, body1)

    local length = 2.0
    local pivot1 = {position_x, position_y + 1.0 + length}
    local pivot2 = {position_x, position_y + 1.0}
    local distance_def = b2d.default_distance_joint_def()
    distance_def.bodyIdA = ground_id
    distance_def.bodyIdB = body1
    distance_def.localFrameA = b2d.Transform({p = pivot1, q = {1, 0}})
    distance_def.localFrameB = b2d.Transform({p = {0, 1.0}, q = {1, 0}})
    distance_def.length = length
    b2d.create_distance_joint(world, distance_def)

    position_x = position_x + 5.0

    -- 2. Motor joint
    body_def.position = {position_x, position_y}
    local body2 = b2d.create_body(world, body_def)
    b2d.create_polygon_shape(body2, shape_def, box)
    table.insert(body_ids, body2)

    local motor_def = b2d.default_motor_joint_def()
    motor_def.bodyIdA = ground_id
    motor_def.bodyIdB = body2
    motor_def.localFrameA = b2d.Transform({p = {position_x, position_y}, q = {1, 0}})
    motor_def.maxVelocityForce = 200.0
    motor_def.maxVelocityTorque = 200.0
    b2d.create_motor_joint(world, motor_def)

    position_x = position_x + 5.0

    -- 3. Prismatic joint
    body_def.position = {position_x, position_y}
    local body3 = b2d.create_body(world, body_def)
    b2d.create_polygon_shape(body3, shape_def, box)
    table.insert(body_ids, body3)

    local pivot = {position_x - 1.0, position_y}
    local prismatic_def = b2d.default_prismatic_joint_def()
    prismatic_def.bodyIdA = ground_id
    prismatic_def.bodyIdB = body3
    prismatic_def.localFrameA = b2d.Transform({p = pivot, q = {1, 0}})
    prismatic_def.localFrameB = b2d.Transform({p = {-1.0, 0}, q = {1, 0}})
    b2d.create_prismatic_joint(world, prismatic_def)

    position_x = position_x + 5.0

    -- 4. Revolute joint
    body_def.position = {position_x, position_y}
    local body4 = b2d.create_body(world, body_def)
    b2d.create_polygon_shape(body4, shape_def, box)
    table.insert(body_ids, body4)

    pivot = {position_x - 1.0, position_y}
    local revolute_def = b2d.default_revolute_joint_def()
    revolute_def.bodyIdA = ground_id
    revolute_def.bodyIdB = body4
    revolute_def.localFrameA = b2d.Transform({p = pivot, q = {1, 0}})
    revolute_def.localFrameB = b2d.Transform({p = {-1.0, 0}, q = {1, 0}})
    b2d.create_revolute_joint(world, revolute_def)

    position_x = position_x + 5.0

    -- 5. Weld joint
    body_def.position = {position_x, position_y}
    local body5 = b2d.create_body(world, body_def)
    b2d.create_polygon_shape(body5, shape_def, box)
    table.insert(body_ids, body5)

    pivot = {position_x - 1.0, position_y}
    local weld_def = b2d.default_weld_joint_def()
    weld_def.bodyIdA = ground_id
    weld_def.bodyIdB = body5
    weld_def.localFrameA = b2d.Transform({p = pivot, q = {1, 0}})
    weld_def.localFrameB = b2d.Transform({p = {-1.0, 0}, q = {1, 0}})
    weld_def.angularHertz = 1.0
    weld_def.angularDampingRatio = 0.5
    weld_def.linearHertz = 1.0
    weld_def.linearDampingRatio = 0.5
    b2d.create_weld_joint(world, weld_def)

    position_x = position_x + 5.0

    -- 6. Wheel joint
    body_def.position = {position_x, position_y}
    local body6 = b2d.create_body(world, body_def)
    b2d.create_polygon_shape(body6, shape_def, box)
    table.insert(body_ids, body6)

    pivot = {position_x - 1.0, position_y}
    local wheel_def = b2d.default_wheel_joint_def()
    wheel_def.bodyIdA = ground_id
    wheel_def.bodyIdB = body6
    wheel_def.localFrameA = b2d.Transform({p = pivot, q = {1, 0}})
    wheel_def.localFrameB = b2d.Transform({p = {-1.0, 0}, q = {1, 0}})
    wheel_def.hertz = 1.0
    wheel_def.dampingRatio = 0.7
    wheel_def.lowerTranslation = -1.0
    wheel_def.upperTranslation = 1.0
    wheel_def.enableLimit = true
    wheel_def.enableMotor = true
    wheel_def.maxMotorTorque = 10.0
    wheel_def.motorSpeed = 1.0
    b2d.create_wheel_joint(world, wheel_def)
end

function M.update_gui(world)
    imgui.begin_window("Motion Locks")

    local changed
    changed, lock_linear_x = imgui.checkbox("Lock Linear X", lock_linear_x)
    if changed then
        local motion_locks = b2d.MotionLocks()
        motion_locks.linearX = lock_linear_x
        motion_locks.linearY = lock_linear_y
        motion_locks.angularZ = lock_angular_z
        for _, body_id in ipairs(body_ids) do
            b2d.body_set_motion_locks(body_id, motion_locks)
            b2d.body_set_awake(body_id, true)
        end
    end

    changed, lock_linear_y = imgui.checkbox("Lock Linear Y", lock_linear_y)
    if changed then
        local motion_locks = b2d.MotionLocks()
        motion_locks.linearX = lock_linear_x
        motion_locks.linearY = lock_linear_y
        motion_locks.angularZ = lock_angular_z
        for _, body_id in ipairs(body_ids) do
            b2d.body_set_motion_locks(body_id, motion_locks)
            b2d.body_set_awake(body_id, true)
        end
    end

    changed, lock_angular_z = imgui.checkbox("Lock Angular Z", lock_angular_z)
    if changed then
        local motion_locks = b2d.MotionLocks()
        motion_locks.linearX = lock_linear_x
        motion_locks.linearY = lock_linear_y
        motion_locks.angularZ = lock_angular_z
        for _, body_id in ipairs(body_ids) do
            b2d.body_set_motion_locks(body_id, motion_locks)
            b2d.body_set_awake(body_id, true)
        end
    end

    imgui.text_unformatted("L: Apply impulse to first body")

    imgui.end_window()
end

M.controls = "L: Apply impulse"

function M.on_key(key, world)
    local app = require("sokol.app")
    if key == app.Keycode.L then
        b2d.body_apply_linear_impulse_to_center(body_ids[1], {100, 0}, true)
    end
end

function M.render(camera, world)
    local joint_names = {"Distance", "Motor", "Prismatic", "Revolute", "Weld", "Wheel"}

    for i, body_id in ipairs(body_ids) do
        local pos = b2d.body_get_position(body_id)
        local rot = b2d.body_get_rotation(body_id)
        local angle = b2d.rot_get_angle(rot)
        local color = b2d.body_is_awake(body_id) and draw.colors.dynamic or draw.colors.sleeping

        draw.solid_box(pos[1], pos[2], 1.0, 1.0, angle, color)
        draw.box(pos[1], pos[2], 1.0, 1.0, angle, {0, 0, 0, 1})
    end
end

function M.cleanup()
    ground_id = nil
    body_ids = {}
end

return M
