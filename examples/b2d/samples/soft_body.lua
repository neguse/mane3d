-- soft_body.lua - Box2D official Soft Body (Donut) sample
-- A soft body ring made of capsules connected by weld joints.
local b2d = require("b2d")
local draw = require("examples.b2d.draw")

local M = {}

M.camera = {
    center_x = 0,
    center_y = 5,
    zoom = 25 * 0.25,
}

local ground_id = nil
local donut_bodies = {}
local donut_joints = {}
local sides = 7

local function create_donut(world, position, scale)
    donut_bodies = {}
    donut_joints = {}

    local radius = 1.0 * scale
    local delta_angle = 2.0 * math.pi / sides
    local length = 2.0 * math.pi * radius / sides

    local capsule = b2d.Capsule({
        center1 = {0, -0.5 * length},
        center2 = {0, 0.5 * length},
        radius = 0.25 * scale
    })

    local body_def = b2d.default_body_def()
    body_def.type = b2d.BodyType.DYNAMICBODY

    local shape_def = b2d.default_shape_def()
    local filter = b2d.Filter()
    filter.groupIndex = -1  -- Don't collide with self
    shape_def.filter = filter
    shape_def.material = {friction = 0.3}

    -- Create bodies in a circle
    local angle = 0
    for i = 1, sides do
        body_def.position = {
            radius * math.cos(angle) + position[1],
            radius * math.sin(angle) + position[2]
        }
        body_def.rotation = b2d.make_rot(angle)

        local body_id = b2d.create_body(world, body_def)
        b2d.create_capsule_shape(body_id, shape_def, capsule)
        table.insert(donut_bodies, body_id)

        angle = angle + delta_angle
    end

    -- Create weld joints connecting adjacent bodies
    local weld_def = b2d.default_weld_joint_def()
    weld_def.angularHertz = 5.0
    weld_def.angularDampingRatio = 0.0

    local prev_body_id = donut_bodies[sides]  -- Start with last body
    for i = 1, sides do
        weld_def.bodyIdA = prev_body_id
        weld_def.bodyIdB = donut_bodies[i]

        -- Local anchors at capsule ends
        local qA = b2d.body_get_rotation(prev_body_id)
        local qB = b2d.body_get_rotation(donut_bodies[i])
        local q_rel = b2d.inv_mul_rot(qA, qB)

        weld_def.localFrameA = b2d.Transform({p = {0, 0.5 * length}, q = q_rel})
        weld_def.localFrameB = b2d.Transform({p = {0, -0.5 * length}, q = {1, 0}})

        local joint_id = b2d.create_weld_joint(world, weld_def)
        table.insert(donut_joints, joint_id)

        prev_body_id = donut_bodies[i]
    end
end

function M.create_scene(world)
    -- Ground
    local body_def = b2d.default_body_def()
    ground_id = b2d.create_body(world, body_def)
    local shape_def = b2d.default_shape_def()
    local segment = b2d.Segment({point1 = {-20, 0}, point2 = {20, 0}})
    b2d.create_segment_shape(ground_id, shape_def, segment)

    -- Create donut at height 10
    create_donut(world, {0, 10}, 2.0)
end

function M.render(camera, world)
    -- Ground
    draw.line(-20, 0, 20, 0, draw.colors.static)

    -- Draw donut bodies (capsules)
    local scale = 2.0
    local radius = 1.0 * scale
    local length = 2.0 * math.pi * radius / sides
    local cap_radius = 0.25 * scale

    for _, body_id in ipairs(donut_bodies) do
        local pos = b2d.body_get_position(body_id)
        local rot = b2d.body_get_rotation(body_id)
        local angle = b2d.rot_get_angle(rot)
        local color = b2d.body_is_awake(body_id) and draw.colors.dynamic or draw.colors.sleeping

        -- Capsule endpoints in world space
        local c, s = math.cos(angle), math.sin(angle)
        local half_len = 0.5 * length
        local c1x = pos[1] - s * half_len
        local c1y = pos[2] + c * half_len
        local c2x = pos[1] + s * half_len
        local c2y = pos[2] - c * half_len

        draw.solid_capsule(c1x, c1y, c2x, c2y, cap_radius, color)
        draw.capsule(c1x, c1y, c2x, c2y, cap_radius, {0, 0, 0, 1})
    end
end

function M.cleanup()
    ground_id = nil
    donut_bodies = {}
    donut_joints = {}
end

return M
