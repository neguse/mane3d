-- offset_shapes.lua - Box2D official Offset Shapes sample
-- Demonstrates creating shapes with local offsets.
local b2d = require("b2d")
local draw = require("examples.b2d.draw")

local M = {}

M.camera = {
    center_x = 2,
    center_y = 8,
    zoom = 14,
}

local ground_id = nil
local body_ids = {}

function M.create_scene(world)
    body_ids = {}

    -- Ground with offset box
    local body_def = b2d.default_body_def()
    body_def.position = {-1, 1}
    ground_id = b2d.create_body(world, body_def)

    local shape_def = b2d.default_shape_def()

    -- Offset box (rotated 90 degrees)
    local rot = b2d.make_rot(0.5 * math.pi)
    local box = b2d.make_offset_box(1.0, 1.0, {10, -2}, rot)
    b2d.create_polygon_shape(ground_id, shape_def, box)

    -- Dynamic capsule with offset
    local capsule = b2d.Capsule({center1 = {-5, 1}, center2 = {-4, 1}, radius = 0.25})
    body_def = b2d.default_body_def()
    body_def.position = {13.5, -0.75}
    body_def.type = b2d.BodyType.DYNAMICBODY
    local body_id = b2d.create_body(world, body_def)
    b2d.create_capsule_shape(body_id, shape_def, capsule)
    table.insert(body_ids, body_id)

    -- Dynamic box with offset (rotated 90 degrees)
    rot = b2d.make_rot(0.5 * math.pi)
    box = b2d.make_offset_box(0.75, 0.5, {9, 2}, rot)
    body_def = b2d.default_body_def()
    body_def.position = {0, 0}
    body_def.type = b2d.BodyType.DYNAMICBODY
    body_id = b2d.create_body(world, body_def)
    b2d.create_polygon_shape(body_id, shape_def, box)
    table.insert(body_ids, body_id)
end

function M.render(camera, world)
    -- Draw world origin axes
    draw.line(0, 0, 1, 0, {1, 0, 0, 1})  -- X axis
    draw.line(0, 0, 0, 1, {0, 1, 0, 1})  -- Y axis

    -- Draw ground (static offset box)
    local gx, gy = -1, 1
    local ox, oy = 10, -2
    local wx, wy = gx + ox, gy + oy
    draw.solid_box(wx, wy, 1, 1, 0.5 * math.pi, draw.colors.static)
    draw.box(wx, wy, 1, 1, 0.5 * math.pi, {0, 0, 0, 1})

    -- Draw dynamic bodies
    for i, body_id in ipairs(body_ids) do
        if b2d.body_is_valid(body_id) then
            local pos = b2d.body_get_position(body_id)
            local rot = b2d.body_get_rotation(body_id)
            local angle = b2d.rot_get_angle(rot)

            local color = b2d.body_is_awake(body_id) and draw.colors.dynamic or draw.colors.sleeping

            -- Draw based on shape type (simplified - draw circles at body position)
            if i == 1 then
                -- Capsule (offset)
                local ox1, oy1 = -5, 1
                local ox2, oy2 = -4, 1
                local c, s = math.cos(angle), math.sin(angle)

                local wx1 = pos[1] + c * ox1 - s * oy1
                local wy1 = pos[2] + s * ox1 + c * oy1
                local wx2 = pos[1] + c * ox2 - s * oy2
                local wy2 = pos[2] + s * ox2 + c * oy2

                draw.solid_circle(wx1, wy1, 0.25, color)
                draw.solid_circle(wx2, wy2, 0.25, color)
                draw.line(wx1, wy1, wx2, wy2, color)
            else
                -- Box (offset, rotated 90 degrees from body)
                local ox, oy = 9, 2
                local c, s = math.cos(angle), math.sin(angle)

                local wx = pos[1] + c * ox - s * oy
                local wy = pos[2] + s * ox + c * oy

                draw.solid_box(wx, wy, 0.5, 0.75, angle + 0.5 * math.pi, color)
                draw.box(wx, wy, 0.5, 0.75, angle + 0.5 * math.pi, {0, 0, 0, 1})
            end
        end
    end
end

function M.cleanup()
    ground_id = nil
    body_ids = {}
end

return M
