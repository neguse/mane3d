-- scale_ragdoll.lua - Box2D official Scale Ragdoll sample
-- Demonstrates ragdolls at different scales
local b2d = require("b2d")
local draw = require("examples.b2d.draw")

local M = {}

M.camera = {
    center_x = 0,
    center_y = 5,
    zoom = 15,
}

local ground_id = nil
local body_ids = {}
local joint_ids = {}

local function create_ragdoll(world, x, y, scale)
    local bodies = {}
    local joints = {}

    local body_def = b2d.default_body_def()
    body_def.type = b2d.BodyType.DYNAMICBODY

    local shape_def = b2d.default_shape_def()

    -- Torso
    body_def.position = {x, y}
    local torso = b2d.create_body(world, body_def)
    local box = b2d.make_box(0.3 * scale, 0.5 * scale)
    b2d.create_polygon_shape(torso, shape_def, box)
    table.insert(bodies, torso)

    -- Head
    body_def.position = {x, y + 0.8 * scale}
    local head = b2d.create_body(world, body_def)
    local circle = b2d.Circle({center = {0, 0}, radius = 0.2 * scale})
    b2d.create_circle_shape(head, shape_def, circle)
    table.insert(bodies, head)

    -- Helper to create frame
    local function make_frame(px, py)
        local f = b2d.Transform()
        f.p = {px, py}
        f.q = {c = 1, s = 0}
        return f
    end

    -- Head joint
    local joint_def = b2d.default_revolute_joint_def()
    joint_def.bodyIdA = torso
    joint_def.bodyIdB = head
    joint_def.localFrameA = make_frame(0, 0.5 * scale)
    joint_def.localFrameB = make_frame(0, -0.2 * scale)
    joint_def.enableLimit = true
    joint_def.lowerAngle = -0.5
    joint_def.upperAngle = 0.5
    local joint = b2d.create_revolute_joint(world, joint_def)
    table.insert(joints, joint)

    -- Left arm
    body_def.position = {x - 0.5 * scale, y + 0.3 * scale}
    local left_arm = b2d.create_body(world, body_def)
    box = b2d.make_box(0.2 * scale, 0.08 * scale)
    b2d.create_polygon_shape(left_arm, shape_def, box)
    table.insert(bodies, left_arm)

    joint_def.bodyIdA = torso
    joint_def.bodyIdB = left_arm
    joint_def.localFrameA = make_frame(-0.3 * scale, 0.3 * scale)
    joint_def.localFrameB = make_frame(0.2 * scale, 0)
    joint_def.lowerAngle = -1
    joint_def.upperAngle = 1
    joint = b2d.create_revolute_joint(world, joint_def)
    table.insert(joints, joint)

    -- Right arm
    body_def.position = {x + 0.5 * scale, y + 0.3 * scale}
    local right_arm = b2d.create_body(world, body_def)
    b2d.create_polygon_shape(right_arm, shape_def, box)
    table.insert(bodies, right_arm)

    joint_def.bodyIdA = torso
    joint_def.bodyIdB = right_arm
    joint_def.localFrameA = make_frame(0.3 * scale, 0.3 * scale)
    joint_def.localFrameB = make_frame(-0.2 * scale, 0)
    joint = b2d.create_revolute_joint(world, joint_def)
    table.insert(joints, joint)

    -- Left leg
    body_def.position = {x - 0.15 * scale, y - 0.8 * scale}
    local left_leg = b2d.create_body(world, body_def)
    box = b2d.make_box(0.08 * scale, 0.3 * scale)
    b2d.create_polygon_shape(left_leg, shape_def, box)
    table.insert(bodies, left_leg)

    joint_def.bodyIdA = torso
    joint_def.bodyIdB = left_leg
    joint_def.localFrameA = make_frame(-0.15 * scale, -0.5 * scale)
    joint_def.localFrameB = make_frame(0, 0.3 * scale)
    joint_def.lowerAngle = -0.8
    joint_def.upperAngle = 0.3
    joint = b2d.create_revolute_joint(world, joint_def)
    table.insert(joints, joint)

    -- Right leg
    body_def.position = {x + 0.15 * scale, y - 0.8 * scale}
    local right_leg = b2d.create_body(world, body_def)
    b2d.create_polygon_shape(right_leg, shape_def, box)
    table.insert(bodies, right_leg)

    joint_def.bodyIdA = torso
    joint_def.bodyIdB = right_leg
    joint_def.localFrameA = make_frame(0.15 * scale, -0.5 * scale)
    joint_def.localFrameB = make_frame(0, 0.3 * scale)
    joint = b2d.create_revolute_joint(world, joint_def)
    table.insert(joints, joint)

    return bodies, joints
end

function M.create_scene(world)
    body_ids = {}
    joint_ids = {}

    -- Ground
    local body_def = b2d.default_body_def()
    ground_id = b2d.create_body(world, body_def)

    local shape_def = b2d.default_shape_def()
    local segment = b2d.Segment({point1 = {-20, 0}, point2 = {20, 0}})
    b2d.create_segment_shape(ground_id, shape_def, segment)

    -- Create ragdolls at different scales
    local scales = {0.5, 1.0, 1.5, 2.0}
    local positions = {{-10, 8}, {-3, 8}, {4, 8}, {12, 8}}

    for i, scale in ipairs(scales) do
        local bodies, joints = create_ragdoll(world, positions[i][1], positions[i][2], scale)
        for _, b in ipairs(bodies) do
            table.insert(body_ids, b)
        end
        for _, j in ipairs(joints) do
            table.insert(joint_ids, j)
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
            local color = b2d.body_is_awake(body_id) and draw.colors.dynamic or draw.colors.sleeping
            draw.solid_circle(pos[1], pos[2], 0.2, color)
        end
    end

    -- Draw joints
    for _, joint_id in ipairs(joint_ids) do
        if b2d.joint_is_valid(joint_id) then
            local anchor_a = b2d.joint_get_world_anchor_a(joint_id)
            local anchor_b = b2d.joint_get_world_anchor_b(joint_id)
            draw.line(anchor_a[1], anchor_a[2], anchor_b[1], anchor_b[2], {0.5, 0.5, 0.8, 1})
        end
    end
end

function M.cleanup()
    ground_id = nil
    body_ids = {}
    joint_ids = {}
end

return M
