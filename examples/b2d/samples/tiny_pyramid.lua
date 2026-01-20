-- tiny_pyramid.lua - Box2D official Tiny Pyramid sample
-- Demonstrates stability with very small objects
local b2d = require("b2d")
local draw = require("examples.b2d.draw")

local M = {}

M.camera = {
    center_x = 0,
    center_y = 0.8,
    zoom = 1,
}

local body_ids = {}
local extent = 0.025  -- 2.5cm squares

function M.create_scene(world)
    body_ids = {}

    -- Ground
    local body_def = b2d.default_body_def()
    local ground_id = b2d.create_body(world, body_def)

    local shape_def = b2d.default_shape_def()
    local box = b2d.make_offset_box(5, 1, {0, -1}, {1, 0})
    b2d.create_polygon_shape(ground_id, shape_def, box)

    -- Create tiny pyramid
    body_def = b2d.default_body_def()
    body_def.type = b2d.BodyType.DYNAMICBODY

    local tiny_box = b2d.make_box(extent, extent)
    local base_count = 30

    for i = 0, base_count - 1 do
        local y = (2 * i + 1) * extent

        for j = i, base_count - 1 do
            local x = (i + 1) * extent + 2 * (j - i) * extent - base_count * extent
            body_def.position = {x, y}

            local body_id = b2d.create_body(world, body_def)
            b2d.create_polygon_shape(body_id, shape_def, tiny_box)
            table.insert(body_ids, body_id)
        end
    end
end

function M.render(camera, world)
    -- Draw ground
    draw.solid_box(0, -1, 5, 1, 0, draw.colors.static)
    draw.box(0, -1, 5, 1, 0, {0, 0, 0, 1})

    -- Draw bodies
    for _, body_id in ipairs(body_ids) do
        if b2d.body_is_valid(body_id) then
            local pos = b2d.body_get_position(body_id)
            local rot = b2d.body_get_rotation(body_id)
            local angle = b2d.rot_get_angle(rot)
            local color = b2d.body_is_awake(body_id) and draw.colors.dynamic or draw.colors.sleeping
            draw.solid_box(pos[1], pos[2], extent, extent, angle, color)
        end
    end
end

function M.cleanup()
    body_ids = {}
end

return M
