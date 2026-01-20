-- many_pyramids.lua - Box2D official Many Pyramids Benchmark sample
-- Multiple pyramids benchmark
local b2d = require("b2d")
local draw = require("examples.b2d.draw")

local M = {}

M.camera = {
    center_x = 0,
    center_y = 30,
    zoom = 80,
}

local ground_id = nil
local body_ids = {}

function M.create_scene(world)
    body_ids = {}

    -- Ground
    local body_def = b2d.default_body_def()
    ground_id = b2d.create_body(world, body_def)

    local shape_def = b2d.default_shape_def()
    local segment = b2d.Segment({point1 = {-100, 0}, point2 = {100, 0}})
    b2d.create_segment_shape(ground_id, shape_def, segment)

    -- Create multiple pyramids
    local pyramid_count = 5
    local base_count = 10
    local box_size = 0.5

    local box = b2d.make_box(box_size, box_size)

    for p = 0, pyramid_count - 1 do
        local start_x = (p - pyramid_count / 2) * 15

        local y = box_size
        for i = base_count, 1, -1 do
            local x = start_x - box_size * (i - 1)

            for j = 1, i do
                body_def = b2d.default_body_def()
                body_def.type = b2d.BodyType.DYNAMICBODY
                body_def.position = {x, y}
                local body = b2d.create_body(world, body_def)
                b2d.create_polygon_shape(body, shape_def, box)
                table.insert(body_ids, body)

                x = x + 2 * box_size
            end
            y = y + 2 * box_size
        end
    end
end

function M.render(camera, world)
    -- Draw ground
    draw.line(-100, 0, 100, 0, draw.colors.static)

    -- Draw bodies
    for _, body_id in ipairs(body_ids) do
        if b2d.body_is_valid(body_id) then
            local pos = b2d.body_get_position(body_id)
            local rot = b2d.body_get_rotation(body_id)
            local angle = b2d.rot_get_angle(rot)
            local color = b2d.body_is_awake(body_id) and draw.colors.dynamic or draw.colors.sleeping
            draw.solid_box(pos[1], pos[2], 0.5, 0.5, angle, color)
        end
    end
end

function M.cleanup()
    ground_id = nil
    body_ids = {}
end

return M
