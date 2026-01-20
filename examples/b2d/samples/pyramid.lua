-- pyramid.lua - Box2D official Large Pyramid Benchmark sample
-- Stacking a large pyramid of boxes.
local b2d = require("b2d")
local draw = require("examples.b2d.draw")

local M = {}

M.camera = {
    center_x = 0,
    center_y = 15,
    zoom = 40,
}

local ground_id = nil
local box_ids = {}

function M.create_scene(world)
    box_ids = {}

    -- Ground
    local body_def = b2d.default_body_def()
    ground_id = b2d.create_body(world, body_def)

    local shape_def = b2d.default_shape_def()
    local segment = b2d.Segment({point1 = {-50, 0}, point2 = {50, 0}})
    b2d.create_segment_shape(ground_id, shape_def, segment)

    -- Build pyramid
    local count = 20
    local box_size = 0.5

    shape_def = b2d.default_shape_def()
    local box = b2d.make_box(box_size, box_size)

    local y = box_size
    local delta_y = 2.0 * box_size

    for i = count, 1, -1 do
        local x = -box_size * (i - 1)

        for j = 1, i do
            body_def = b2d.default_body_def()
            body_def.type = b2d.BodyType.DYNAMICBODY
            body_def.position = {x, y}
            local body_id = b2d.create_body(world, body_def)
            b2d.create_polygon_shape(body_id, shape_def, box)
            table.insert(box_ids, body_id)

            x = x + 2.0 * box_size
        end

        y = y + delta_y
    end
end

function M.render(camera, world)
    -- Draw ground
    draw.line(-50, 0, 50, 0, draw.colors.static)

    -- Draw boxes
    for _, box_id in ipairs(box_ids) do
        if b2d.body_is_valid(box_id) then
            local pos = b2d.body_get_position(box_id)
            local rot = b2d.body_get_rotation(box_id)
            local angle = b2d.rot_get_angle(rot)
            local color = b2d.body_is_awake(box_id) and draw.colors.dynamic or draw.colors.sleeping
            draw.solid_box(pos[1], pos[2], 0.5, 0.5, angle, color)
            draw.box(pos[1], pos[2], 0.5, 0.5, angle, {0, 0, 0, 1})
        end
    end
end

function M.cleanup()
    ground_id = nil
    box_ids = {}
end

return M
