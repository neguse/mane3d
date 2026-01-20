-- joint_separation.lua - Box2D official Joint Separation sample
-- Demonstrates measuring linear and angular separation of joints.
local b2d = require("b2d")
local draw = require("examples.b2d.draw")
local imgui = require("imgui")

local M = {}

M.camera = {
    center_x = 0,
    center_y = 8,
    zoom = 25,
}

local ground_id = nil
local body_ids = {}
local joint_ids = {}
local impulse = 500.0
local joint_hertz = 60.0
local joint_damping_ratio = 2.0

function M.create_scene(world)
    body_ids = {}
    joint_ids = {}

    -- Ground
    local body_def = b2d.default_body_def()
    ground_id = b2d.create_body(world, body_def)

    local shape_def = b2d.default_shape_def()
    local segment = b2d.Segment({point1 = {-40, 0}, point2 = {40, 0}})
    b2d.create_segment_shape(ground_id, shape_def, segment)

    local position_x = -20.0
    local position_y = 10.0

    body_def = b2d.default_body_def()
    body_def.type = b2d.BodyType.DYNAMICBODY
    body_def.enableSleep = false

    local box = b2d.make_box(1.0, 1.0)

    -- 1. Distance joint
    body_def.position = {position_x, position_y}
    local body1 = b2d.create_body(world, body_def)
    b2d.create_polygon_shape(body1, shape_def, box)
    table.insert(body_ids, body1)

    local length = 2.0
    local pivot1 = {position_x, position_y + 1.0 + length}
    local distance_def = b2d.default_distance_joint_def()
    distance_def.bodyIdA = ground_id
    distance_def.bodyIdB = body1
    distance_def.localFrameA = b2d.Transform({p = pivot1, q = {1, 0}})
    distance_def.localFrameB = b2d.Transform({p = {0, 1.0}, q = {1, 0}})
    distance_def.length = length
    distance_def.collideConnected = true
    table.insert(joint_ids, b2d.create_distance_joint(world, distance_def))

    position_x = position_x + 10.0

    -- 2. Prismatic joint
    body_def.position = {position_x, position_y}
    local body2 = b2d.create_body(world, body_def)
    b2d.create_polygon_shape(body2, shape_def, box)
    table.insert(body_ids, body2)

    local pivot = {position_x - 1.0, position_y}
    local prismatic_def = b2d.default_prismatic_joint_def()
    prismatic_def.bodyIdA = ground_id
    prismatic_def.bodyIdB = body2
    prismatic_def.localFrameA = b2d.Transform({p = pivot, q = {1, 0}})
    prismatic_def.localFrameB = b2d.Transform({p = {-1.0, 0}, q = {1, 0}})
    prismatic_def.collideConnected = true
    table.insert(joint_ids, b2d.create_prismatic_joint(world, prismatic_def))

    position_x = position_x + 10.0

    -- 3. Revolute joint
    body_def.position = {position_x, position_y}
    local body3 = b2d.create_body(world, body_def)
    b2d.create_polygon_shape(body3, shape_def, box)
    table.insert(body_ids, body3)

    pivot = {position_x - 1.0, position_y}
    local revolute_def = b2d.default_revolute_joint_def()
    revolute_def.bodyIdA = ground_id
    revolute_def.bodyIdB = body3
    revolute_def.localFrameA = b2d.Transform({p = pivot, q = {1, 0}})
    revolute_def.localFrameB = b2d.Transform({p = {-1.0, 0}, q = {1, 0}})
    revolute_def.collideConnected = true
    table.insert(joint_ids, b2d.create_revolute_joint(world, revolute_def))

    position_x = position_x + 10.0

    -- 4. Weld joint
    body_def.position = {position_x, position_y}
    local body4 = b2d.create_body(world, body_def)
    b2d.create_polygon_shape(body4, shape_def, box)
    table.insert(body_ids, body4)

    pivot = {position_x - 1.0, position_y}
    local weld_def = b2d.default_weld_joint_def()
    weld_def.bodyIdA = ground_id
    weld_def.bodyIdB = body4
    weld_def.localFrameA = b2d.Transform({p = pivot, q = {1, 0}})
    weld_def.localFrameB = b2d.Transform({p = {-1.0, 0}, q = {1, 0}})
    weld_def.collideConnected = true
    table.insert(joint_ids, b2d.create_weld_joint(world, weld_def))

    position_x = position_x + 10.0

    -- 5. Wheel joint
    body_def.position = {position_x, position_y}
    local body5 = b2d.create_body(world, body_def)
    b2d.create_polygon_shape(body5, shape_def, box)
    table.insert(body_ids, body5)

    pivot = {position_x - 1.0, position_y}
    local wheel_def = b2d.default_wheel_joint_def()
    wheel_def.bodyIdA = ground_id
    wheel_def.bodyIdB = body5
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
    wheel_def.collideConnected = true
    table.insert(joint_ids, b2d.create_wheel_joint(world, wheel_def))
end

function M.update_gui(world)
    imgui.begin_window("Joint Separation")

    local changed
    local gravity = b2d.world_get_gravity(world)
    changed, gravity[2] = imgui.slider_float("Gravity", gravity[2], -500, 500)
    if changed then
        b2d.world_set_gravity(world, gravity)
    end

    if imgui.button("Impulse") then
        for i, body_id in ipairs(body_ids) do
            local p = b2d.body_get_world_point(body_id, {1.0, 1.0})
            b2d.body_apply_linear_impulse(body_id, {impulse, -impulse}, p, true)
        end
    end

    changed, impulse = imgui.slider_float("Magnitude", impulse, 0, 1000)

    changed, joint_hertz = imgui.slider_float("Hertz", joint_hertz, 15, 120)
    if changed then
        for _, joint_id in ipairs(joint_ids) do
            if b2d.joint_is_valid(joint_id) then
                b2d.joint_set_constraint_tuning(joint_id, joint_hertz, joint_damping_ratio)
            end
        end
    end

    changed, joint_damping_ratio = imgui.slider_float("Damping", joint_damping_ratio, 0, 10)
    if changed then
        for _, joint_id in ipairs(joint_ids) do
            if b2d.joint_is_valid(joint_id) then
                b2d.joint_set_constraint_tuning(joint_id, joint_hertz, joint_damping_ratio)
            end
        end
    end

    imgui.end_window()
end

function M.render(camera, world)
    -- Ground
    draw.line(-40, 0, 40, 0, draw.colors.static)

    -- Draw bodies and joint info
    for i, body_id in ipairs(body_ids) do
        local pos = b2d.body_get_position(body_id)
        local rot = b2d.body_get_rotation(body_id)
        local angle = b2d.rot_get_angle(rot)
        local color = b2d.body_is_awake(body_id) and draw.colors.dynamic or draw.colors.sleeping

        draw.solid_box(pos[1], pos[2], 1.0, 1.0, angle, color)
        draw.box(pos[1], pos[2], 1.0, 1.0, angle, {0, 0, 0, 1})
    end

    -- Draw separation info for each joint
    for i, joint_id in ipairs(joint_ids) do
        if b2d.joint_is_valid(joint_id) then
            local linear_sep = b2d.joint_get_linear_separation(joint_id)
            local angular_sep = b2d.joint_get_angular_separation(joint_id)
            local frame = b2d.joint_get_local_frame_a(joint_id)
            -- Visual indicator at anchor
            draw.solid_circle(frame.p[1], frame.p[2], 0.1, {1, 1, 0, 1})
        end
    end
end

function M.cleanup()
    ground_id = nil
    body_ids = {}
    joint_ids = {}
end

return M
