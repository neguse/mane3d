-- door.lua - Box2D official Door sample
-- A door attached with a revolute joint that has spring behavior.
local b2d = require("b2d")
local draw = require("examples.b2d.draw")
local imgui = require("imgui")

local M = {}

M.camera = {
    center_x = 0,
    center_y = 0,
    zoom = 4,
}

local ground_id = nil
local door_id = nil
local joint_id = nil

local enable_limit = true
local impulse = 50000.0
local joint_hertz = 240.0
local joint_damping_ratio = 1.0

function M.create_scene(world)
    -- Ground
    local body_def = b2d.default_body_def()
    body_def.position = {0, 0}
    ground_id = b2d.create_body(world, body_def)

    -- Door
    body_def = b2d.default_body_def()
    body_def.type = b2d.BodyType.DYNAMICBODY
    body_def.position = {0, 1.5}
    body_def.gravityScale = 0.0

    door_id = b2d.create_body(world, body_def)

    local shape_def = b2d.default_shape_def()
    shape_def.density = 1000.0

    local box = b2d.make_box(0.1, 1.5)
    b2d.create_polygon_shape(door_id, shape_def, box)

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
    revolute_def.motorSpeed = 0
    revolute_def.maxMotorTorque = 0
    revolute_def.enableMotor = false
    revolute_def.lowerAngle = -0.5 * math.pi
    revolute_def.upperAngle = 0.5 * math.pi
    revolute_def.enableLimit = enable_limit

    joint_id = b2d.create_revolute_joint(world, revolute_def)
    b2d.joint_set_constraint_tuning(joint_id, joint_hertz, joint_damping_ratio)
end

function M.update_gui(world)
    imgui.begin_window("Door")

    if imgui.button("Impulse") then
        local p = b2d.body_get_world_point(door_id, {0, 1.5})
        b2d.body_apply_linear_impulse(door_id, {impulse, 0}, p, true)
    end

    local changed
    changed, impulse = imgui.slider_float("Magnitude", impulse, 1000, 100000)

    changed, enable_limit = imgui.checkbox("Limit", enable_limit)
    if changed then
        b2d.revolute_joint_enable_limit(joint_id, enable_limit)
    end

    changed, joint_hertz = imgui.slider_float("Hertz", joint_hertz, 15, 480)
    if changed then
        b2d.joint_set_constraint_tuning(joint_id, joint_hertz, joint_damping_ratio)
    end

    changed, joint_damping_ratio = imgui.slider_float("Damping", joint_damping_ratio, 0, 10)
    if changed then
        b2d.joint_set_constraint_tuning(joint_id, joint_hertz, joint_damping_ratio)
    end

    imgui.end_window()
end

function M.render(camera, world)
    -- Draw door
    local pos = b2d.body_get_position(door_id)
    local rot = b2d.body_get_rotation(door_id)
    local angle = b2d.rot_get_angle(rot)
    local color = b2d.body_is_awake(door_id) and draw.colors.dynamic or draw.colors.sleeping
    draw.solid_box(pos[1], pos[2], 0.1, 1.5, angle, color)
    draw.box(pos[1], pos[2], 0.1, 1.5, angle, {0, 0, 0, 1})

    -- Draw pivot point
    draw.solid_circle(0, 0, 0.05, {0.5, 0.5, 0.5, 1})
end

function M.cleanup()
    ground_id = nil
    door_id = nil
    joint_id = nil
end

return M
