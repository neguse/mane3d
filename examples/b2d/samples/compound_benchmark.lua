-- compound_benchmark.lua - Box2D official Compound Benchmark sample
-- Many compound shapes benchmark
local b2d = require("b2d")
local draw = require("examples.b2d.draw")

local M = {}

M.camera = {
    center_x = 0,
    center_y = 15,
    zoom = 40,
}

local ground_id = nil
local body_ids = {}

function M.create_scene(world)
    body_ids = {}

    -- Ground
    local body_def = b2d.default_body_def()
    ground_id = b2d.create_body(world, body_def)

    local shape_def = b2d.default_shape_def()
    local segment = b2d.Segment({point1 = {-40, 0}, point2 = {40, 0}})
    b2d.create_segment_shape(ground_id, shape_def, segment)

    -- Create compound shapes (L-shapes, T-shapes)
    local rows = 8
    local cols = 10

    for row = 0, rows - 1 do
        for col = 0, cols - 1 do
            body_def = b2d.default_body_def()
            body_def.type = b2d.BodyType.DYNAMICBODY
            body_def.position = {
                (col - cols / 2) * 3,
                2 + row * 3
            }
            local body = b2d.create_body(world, body_def)

            -- Create compound shape (L-shape)
            local shape_type = (row + col) % 3

            if shape_type == 0 then
                -- L-shape
                local box1 = b2d.make_offset_box(0.5, 1, {0, 0}, {1, 0})
                local box2 = b2d.make_offset_box(0.5, 0.5, {0.5, -0.5}, {1, 0})
                b2d.create_polygon_shape(body, shape_def, box1)
                b2d.create_polygon_shape(body, shape_def, box2)
            elseif shape_type == 1 then
                -- T-shape
                local box1 = b2d.make_offset_box(1, 0.3, {0, 0.5}, {1, 0})
                local box2 = b2d.make_offset_box(0.3, 0.7, {0, -0.3}, {1, 0})
                b2d.create_polygon_shape(body, shape_def, box1)
                b2d.create_polygon_shape(body, shape_def, box2)
            else
                -- Plus shape
                local box1 = b2d.make_offset_box(0.8, 0.2, {0, 0}, {1, 0})
                local box2 = b2d.make_offset_box(0.2, 0.8, {0, 0}, {1, 0})
                b2d.create_polygon_shape(body, shape_def, box1)
                b2d.create_polygon_shape(body, shape_def, box2)
            end

            table.insert(body_ids, body)
        end
    end
end

function M.render(camera, world)
    -- Draw ground
    draw.line(-40, 0, 40, 0, draw.colors.static)

    -- Draw bodies (simplified - just show center)
    for _, body_id in ipairs(body_ids) do
        if b2d.body_is_valid(body_id) then
            local pos = b2d.body_get_position(body_id)
            local rot = b2d.body_get_rotation(body_id)
            local angle = b2d.rot_get_angle(rot)
            local color = b2d.body_is_awake(body_id) and draw.colors.dynamic or draw.colors.sleeping

            -- Draw simplified compound shape
            draw.solid_box(pos[1], pos[2], 0.8, 0.8, angle, color)
        end
    end
end

function M.cleanup()
    ground_id = nil
    body_ids = {}
end

return M
