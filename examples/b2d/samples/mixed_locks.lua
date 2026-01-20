-- mixed_locks.lua - Box2D official Mixed Locks sample
-- Demonstrates motion locks on dynamic bodies
local b2d = require("b2d")
local draw = require("examples.b2d.draw")

local M = {}

M.camera = {
    center_x = 0,
    center_y = 3,
    zoom = 8,
}

local ground_id = nil
local body_ids = {}
local body_labels = {}

function M.create_scene(world)
    body_ids = {}
    body_labels = {}

    -- Ground
    local body_def = b2d.default_body_def()
    body_def.position = {0, -0.5}
    ground_id = b2d.create_body(world, body_def)

    local shape_def = b2d.default_shape_def()
    local box = b2d.make_box(10, 0.5)
    b2d.create_polygon_shape(ground_id, shape_def, box)

    local small_box = b2d.make_box(0.5, 0.5)

    -- No locks (normal)
    body_def = b2d.default_body_def()
    body_def.type = b2d.BodyType.DYNAMICBODY
    body_def.position = {-4, 2}
    local body_id = b2d.create_body(world, body_def)
    b2d.create_polygon_shape(body_id, shape_def, small_box)
    table.insert(body_ids, body_id)
    table.insert(body_labels, "normal")

    -- Lock angular Z only
    body_def = b2d.default_body_def()
    body_def.type = b2d.BodyType.DYNAMICBODY
    body_def.position = {-3, 3}
    local motion_locks = b2d.MotionLocks()
    motion_locks.angularZ = true
    body_def.motionLocks = motion_locks
    body_id = b2d.create_body(world, body_def)
    b2d.create_polygon_shape(body_id, shape_def, small_box)
    table.insert(body_ids, body_id)
    table.insert(body_labels, "ang z")

    -- Lock linear X only
    body_def = b2d.default_body_def()
    body_def.type = b2d.BodyType.DYNAMICBODY
    body_def.position = {-2, 2}
    motion_locks = b2d.MotionLocks()
    motion_locks.linearX = true
    body_def.motionLocks = motion_locks
    body_id = b2d.create_body(world, body_def)
    b2d.create_polygon_shape(body_id, shape_def, small_box)
    table.insert(body_ids, body_id)
    table.insert(body_labels, "lin x")

    -- Lock linear Y and angular Z
    body_def = b2d.default_body_def()
    body_def.type = b2d.BodyType.DYNAMICBODY
    body_def.position = {-1, 2.5}
    motion_locks = b2d.MotionLocks()
    motion_locks.linearY = true
    motion_locks.angularZ = true
    body_def.motionLocks = motion_locks
    body_id = b2d.create_body(world, body_def)
    b2d.create_polygon_shape(body_id, shape_def, small_box)
    table.insert(body_ids, body_id)
    table.insert(body_labels, "lin y ang z")

    -- Lock all
    body_def = b2d.default_body_def()
    body_def.type = b2d.BodyType.DYNAMICBODY
    body_def.position = {0, 1}
    motion_locks = b2d.MotionLocks()
    motion_locks.linearX = true
    motion_locks.linearY = true
    motion_locks.angularZ = true
    body_def.motionLocks = motion_locks
    body_id = b2d.create_body(world, body_def)
    b2d.create_polygon_shape(body_id, shape_def, small_box)
    table.insert(body_ids, body_id)
    table.insert(body_labels, "full")
end

function M.render(camera, world)
    -- Draw ground
    draw.solid_box(0, -0.5, 10, 0.5, 0, draw.colors.static)
    draw.box(0, -0.5, 10, 0.5, 0, {0, 0, 0, 1})

    -- Draw bodies
    for i, body_id in ipairs(body_ids) do
        if b2d.body_is_valid(body_id) then
            local pos = b2d.body_get_position(body_id)
            local rot = b2d.body_get_rotation(body_id)
            local angle = b2d.rot_get_angle(rot)
            local color = b2d.body_is_awake(body_id) and draw.colors.dynamic or draw.colors.sleeping
            draw.solid_box(pos[1], pos[2], 0.5, 0.5, angle, color)
            draw.box(pos[1], pos[2], 0.5, 0.5, angle, {0, 0, 0, 1})
        end
    end
end

function M.cleanup()
    ground_id = nil
    body_ids = {}
    body_labels = {}
end

return M
