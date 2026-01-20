-- joint_event.lua - Box2D official Joint Event sample
-- Demonstrates joint force events for breakable constraints
local b2d = require("b2d")
local draw = require("examples.b2d.draw")

local M = {}

M.camera = {
    center_x = 0,
    center_y = 5,
    zoom = 15,
}

M.controls = "Space: Drop heavy body"

local ground_id = nil
local chain_bodies = {}
local joint_ids = {}
local heavy_body = nil

function M.create_scene(world)
    chain_bodies = {}
    joint_ids = {}
    heavy_body = nil

    -- Ground
    local body_def = b2d.default_body_def()
    ground_id = b2d.create_body(world, body_def)

    local shape_def = b2d.default_shape_def()
    local segment = b2d.Segment({point1 = {-20, 0}, point2 = {20, 0}})
    b2d.create_segment_shape(ground_id, shape_def, segment)

    -- Ceiling anchor
    segment = b2d.Segment({point1 = {-5, 12}, point2 = {5, 12}})
    b2d.create_segment_shape(ground_id, shape_def, segment)

    -- Create hanging chain
    local chain_length = 8
    local prev_body = ground_id
    local y = 12

    for i = 1, chain_length do
        body_def = b2d.default_body_def()
        body_def.type = b2d.BodyType.DYNAMICBODY
        body_def.position = {0, y - i * 1.2}
        local body = b2d.create_body(world, body_def)

        shape_def = b2d.default_shape_def()
        local box = b2d.make_box(0.3, 0.5)
        b2d.create_polygon_shape(body, shape_def, box)

        -- Create revolute joint
        local joint_def = b2d.default_revolute_joint_def()
        joint_def.bodyIdA = prev_body
        joint_def.bodyIdB = body
        local frame_a = b2d.Transform()
        if i == 1 then
            frame_a.p = {0, 12}
        else
            frame_a.p = {0, -0.5}
        end
        frame_a.q = {c = 1, s = 0}
        joint_def.localFrameA = frame_a
        local frame_b = b2d.Transform()
        frame_b.p = {0, 0.5}
        frame_b.q = {c = 1, s = 0}
        joint_def.localFrameB = frame_b

        local joint = b2d.create_revolute_joint(world, joint_def)
        table.insert(joint_ids, joint)
        table.insert(chain_bodies, body)
        prev_body = body
        y = y - 1.2
    end
end

function M.on_key(key, world)
    local app = require("sokol.app")

    if key == app.Keycode.SPACE and not heavy_body then
        -- Drop heavy body on chain
        local body_def = b2d.default_body_def()
        body_def.type = b2d.BodyType.DYNAMICBODY
        body_def.position = {0, 15}
        heavy_body = b2d.create_body(world, body_def)

        local shape_def = b2d.default_shape_def()
        shape_def.density = 10  -- Heavy
        local box = b2d.make_box(1, 1)
        b2d.create_polygon_shape(heavy_body, shape_def, box)
    end
end

function M.render(camera, world)
    -- Draw ground and ceiling
    draw.line(-20, 0, 20, 0, draw.colors.static)
    draw.line(-5, 12, 5, 12, draw.colors.static)

    -- Draw chain bodies
    for _, body_id in ipairs(chain_bodies) do
        if b2d.body_is_valid(body_id) then
            local pos = b2d.body_get_position(body_id)
            local rot = b2d.body_get_rotation(body_id)
            local angle = b2d.rot_get_angle(rot)
            local color = b2d.body_is_awake(body_id) and draw.colors.dynamic or draw.colors.sleeping
            draw.solid_box(pos[1], pos[2], 0.3, 0.5, angle, color)
            draw.box(pos[1], pos[2], 0.3, 0.5, angle, {0, 0, 0, 1})
        end
    end

    -- Draw joints
    for _, joint_id in ipairs(joint_ids) do
        if b2d.joint_is_valid(joint_id) then
            local anchor = b2d.joint_get_world_anchor_a(joint_id)
            draw.point(anchor[1], anchor[2], 5, {0.5, 0.5, 0.8, 1})
        end
    end

    -- Draw heavy body
    if heavy_body and b2d.body_is_valid(heavy_body) then
        local pos = b2d.body_get_position(heavy_body)
        local rot = b2d.body_get_rotation(heavy_body)
        local angle = b2d.rot_get_angle(rot)
        draw.solid_box(pos[1], pos[2], 1, 1, angle, {0.8, 0.3, 0.3, 1})
        draw.box(pos[1], pos[2], 1, 1, angle, {0, 0, 0, 1})
    end
end

function M.cleanup()
    ground_id = nil
    chain_bodies = {}
    joint_ids = {}
    heavy_body = nil
end

return M
