-- falling_hinges.lua - Box2D official Falling Hinges (Determinism) sample
-- Demonstrates deterministic simulation with hinged bodies.
local b2d = require("b2d")
local draw = require("examples.b2d.draw")

local M = {}

M.camera = {
    center_x = 0,
    center_y = 10,
    zoom = 25,
}

local ground_id = nil
local body_ids = {}
local joint_ids = {}

function M.create_scene(world)
    body_ids = {}
    joint_ids = {}

    -- Ground
    local body_def = b2d.default_body_def()
    ground_id = b2d.create_body(world, body_def)

    local shape_def = b2d.default_shape_def()
    local segment = b2d.Segment({point1 = {-20, 0}, point2 = {20, 0}})
    b2d.create_segment_shape(ground_id, shape_def, segment)

    -- Create chains of hinged boxes
    local num_chains = 5
    local chain_length = 8
    local spacing = 6

    for chain = 0, num_chains - 1 do
        local start_x = -12 + chain * spacing
        local prev_body = ground_id

        for i = 0, chain_length - 1 do
            body_def = b2d.default_body_def()
            body_def.type = b2d.BodyType.DYNAMICBODY
            body_def.position = {start_x, 20 - i * 1.5}
            local body_id = b2d.create_body(world, body_def)

            shape_def = b2d.default_shape_def()
            local box = b2d.make_box(0.3, 0.6)
            b2d.create_polygon_shape(body_id, shape_def, box)

            -- Create revolute joint
            local joint_def = b2d.default_revolute_joint_def()
            joint_def.bodyIdA = prev_body
            joint_def.bodyIdB = body_id

            local frame_a = b2d.Transform()
            if i == 0 then
                frame_a.p = {start_x, 20}
            else
                frame_a.p = {0, -0.6}
            end
            frame_a.q = {c = 1, s = 0}
            joint_def.localFrameA = frame_a
            local frame_b = b2d.Transform()
            frame_b.p = {0, 0.6}
            frame_b.q = {c = 1, s = 0}
            joint_def.localFrameB = frame_b

            local joint_id = b2d.create_revolute_joint(world, joint_def)
            table.insert(joint_ids, joint_id)

            table.insert(body_ids, body_id)
            prev_body = body_id
        end
    end
end

function M.render(camera, world)
    -- Draw ground
    draw.line(-20, 0, 20, 0, draw.colors.static)

    -- Draw bodies
    for _, body_id in ipairs(body_ids) do
        if b2d.body_is_valid(body_id) then
            local pos = b2d.body_get_position(body_id)
            local rot = b2d.body_get_rotation(body_id)
            local angle = b2d.rot_get_angle(rot)
            local color = b2d.body_is_awake(body_id) and draw.colors.dynamic or draw.colors.sleeping
            draw.solid_box(pos[1], pos[2], 0.3, 0.6, angle, color)
            draw.box(pos[1], pos[2], 0.3, 0.6, angle, {0, 0, 0, 1})
        end
    end

    -- Draw joints
    for _, joint_id in ipairs(joint_ids) do
        if b2d.joint_is_valid(joint_id) then
            local anchor_a = b2d.joint_get_world_anchor_a(joint_id)
            local anchor_b = b2d.joint_get_world_anchor_b(joint_id)
            draw.point(anchor_a[1], anchor_a[2], 4, {0.5, 0.5, 0.8, 1})
        end
    end
end

function M.cleanup()
    ground_id = nil
    body_ids = {}
    joint_ids = {}
end

return M
