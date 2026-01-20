-- cantilever.lua - Box2D official Cantilever sample
-- This sample shows the limitations of an iterative solver. The cantilever sags
-- even though the weld joint is stiff as possible.
local b2d = require("b2d")
local draw = require("examples.b2d.draw")
local imgui = require("imgui")

local M = {}

M.camera = {
    center_x = 0,
    center_y = 0,
    zoom = 25 * 0.35,
}

local ground_id = nil
local body_ids = {}
local joint_ids = {}
local tip_id = nil

local link_count = 8
local linear_hertz = 15.0
local linear_damping_ratio = 0.5
local angular_hertz = 5.0
local angular_damping_ratio = 0.5
local gravity_scale = 1.0
local collide_connected = false

function M.create_scene(world)
    body_ids = {}
    joint_ids = {}

    -- Ground (empty body for joint anchor)
    local body_def = b2d.default_body_def()
    ground_id = b2d.create_body(world, body_def)

    local hx = 0.5
    local capsule = b2d.Capsule({center1 = {-hx, 0}, center2 = {hx, 0}, radius = 0.125})

    local shape_def = b2d.default_shape_def()
    shape_def.density = 20.0

    local joint_def = b2d.default_weld_joint_def()

    local prev_body_id = ground_id

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
        joint_def.linearHertz = linear_hertz
        joint_def.linearDampingRatio = linear_damping_ratio
        joint_def.angularHertz = angular_hertz
        joint_def.angularDampingRatio = angular_damping_ratio

        local joint_id = b2d.create_weld_joint(world, joint_def)
        table.insert(joint_ids, joint_id)

        -- Experimental tuning
        b2d.joint_set_constraint_tuning(joint_id, 120.0, 10.0)

        prev_body_id = body_id
    end

    tip_id = prev_body_id
end

function M.update_gui(world)
    imgui.begin_window("Cantilever")

    local changed
    changed, linear_hertz = imgui.slider_float("Linear Hertz", linear_hertz, 0, 20)
    if changed then
        for _, joint_id in ipairs(joint_ids) do
            b2d.weld_joint_set_linear_hertz(joint_id, linear_hertz)
        end
    end

    changed, linear_damping_ratio = imgui.slider_float("Linear Damping", linear_damping_ratio, 0, 10)
    if changed then
        for _, joint_id in ipairs(joint_ids) do
            b2d.weld_joint_set_linear_damping_ratio(joint_id, linear_damping_ratio)
        end
    end

    changed, angular_hertz = imgui.slider_float("Angular Hertz", angular_hertz, 0, 20)
    if changed then
        for _, joint_id in ipairs(joint_ids) do
            b2d.weld_joint_set_angular_hertz(joint_id, angular_hertz)
        end
    end

    changed, angular_damping_ratio = imgui.slider_float("Angular Damping", angular_damping_ratio, 0, 10)
    if changed then
        for _, joint_id in ipairs(joint_ids) do
            b2d.weld_joint_set_angular_damping_ratio(joint_id, angular_damping_ratio)
        end
    end

    changed, collide_connected = imgui.checkbox("Collide Connected", collide_connected)
    if changed then
        for _, joint_id in ipairs(joint_ids) do
            b2d.joint_set_collide_connected(joint_id, collide_connected)
        end
    end

    changed, gravity_scale = imgui.slider_float("Gravity Scale", gravity_scale, -1, 1)
    if changed then
        for _, body_id in ipairs(body_ids) do
            b2d.body_set_gravity_scale(body_id, gravity_scale)
        end
    end

    imgui.separator()
    local tip_pos = b2d.body_get_position(tip_id)
    imgui.text(string.format("tip-y = %.2f", tip_pos[2]))

    imgui.end_window()
end

function M.render(camera, world)
    -- Draw anchor point
    draw.solid_circle(0, 0, 0.15, {1, 1, 0, 1})

    -- Draw cantilever links (capsules)
    local hx = 0.5
    for _, body_id in ipairs(body_ids) do
        local pos = b2d.body_get_position(body_id)
        local rot = b2d.body_get_rotation(body_id)
        local angle = b2d.rot_get_angle(rot)
        local color = b2d.body_is_awake(body_id) and draw.colors.dynamic or draw.colors.sleeping

        -- Capsule: center1={-0.5, 0}, center2={0.5, 0}, radius=0.125
        local c, s = math.cos(angle), math.sin(angle)
        local c1x = pos[1] + (-hx) * c - 0 * s
        local c1y = pos[2] + (-hx) * s + 0 * c
        local c2x = pos[1] + hx * c - 0 * s
        local c2y = pos[2] + hx * s + 0 * c
        draw.solid_capsule(c1x, c1y, c2x, c2y, 0.125, color)
        draw.capsule(c1x, c1y, c2x, c2y, 0.125, {0, 0, 0, 1})
    end
end

function M.cleanup()
    ground_id = nil
    body_ids = {}
    joint_ids = {}
    tip_id = nil
end

return M
