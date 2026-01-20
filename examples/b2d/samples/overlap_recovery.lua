-- overlap_recovery.lua - Box2D official Overlap Recovery sample
-- Demonstrates overlap recovery for stacked boxes
local b2d = require("b2d")
local draw = require("examples.b2d.draw")

local M = {}

M.camera = {
    center_x = 0,
    center_y = 5,
    zoom = 15,
}

local body_ids = {}
local base_count = 5
local extent = 0.5
local overlap = 0.5

function M.create_scene(world)
    body_ids = {}

    -- Ground
    local body_def = b2d.default_body_def()
    local ground_id = b2d.create_body(world, body_def)

    local shape_def = b2d.default_shape_def()
    local segment = b2d.Segment({point1 = {-20, 0}, point2 = {20, 0}})
    b2d.create_segment_shape(ground_id, shape_def, segment)

    -- Create pyramid with overlap
    body_def = b2d.default_body_def()
    body_def.type = b2d.BodyType.DYNAMICBODY

    local box = b2d.make_box(extent, extent)
    local fraction = 1 - overlap

    local y = extent
    for i = 0, base_count - 1 do
        local x = fraction * extent * (i - base_count)
        for j = i, base_count - 1 do
            body_def.position = {x, y}
            local body_id = b2d.create_body(world, body_def)
            b2d.create_polygon_shape(body_id, shape_def, box)
            table.insert(body_ids, body_id)

            x = x + 2 * fraction * extent
        end
        y = y + 2 * fraction * extent
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
            draw.solid_box(pos[1], pos[2], extent, extent, angle, color)
            draw.box(pos[1], pos[2], extent, extent, angle, {0, 0, 0, 1})
        end
    end
end

function M.cleanup()
    body_ids = {}
end

return M
