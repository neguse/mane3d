-- skinny_box.lua - Box2D official Skinny Box sample
-- Demonstrates continuous collision with very thin objects
local b2d = require("b2d")
local draw = require("examples.b2d.draw")

local M = {}

M.camera = {
    center_x = 1,
    center_y = 5,
    zoom = 6.25,
}

local ground_id = nil
local body_ids = {}

function M.create_scene(world)
    body_ids = {}

    -- Ground
    local body_def = b2d.default_body_def()
    ground_id = b2d.create_body(world, body_def)

    local shape_def = b2d.default_shape_def()
    local segment = b2d.Segment({point1 = {-10, 0}, point2 = {10, 0}})
    b2d.create_segment_shape(ground_id, shape_def, segment)

    -- Thin vertical walls
    segment = b2d.Segment({point1 = {-2, 0}, point2 = {-2, 10}})
    b2d.create_segment_shape(ground_id, shape_def, segment)
    segment = b2d.Segment({point1 = {4, 0}, point2 = {4, 10}})
    b2d.create_segment_shape(ground_id, shape_def, segment)

    -- Create very thin (skinny) boxes falling
    for i = 1, 5 do
        body_def = b2d.default_body_def()
        body_def.type = b2d.BodyType.DYNAMICBODY
        body_def.position = {0, 3 + i * 2}
        body_def.rotation = b2d.make_rot(0.3 * i)
        local body = b2d.create_body(world, body_def)

        -- Very thin box (skinny)
        local box = b2d.make_box(1.5, 0.02)
        b2d.create_polygon_shape(body, shape_def, box)
        table.insert(body_ids, body)
    end
end

function M.render(camera, world)
    -- Draw ground and walls
    draw.line(-10, 0, 10, 0, draw.colors.static)
    draw.line(-2, 0, -2, 10, draw.colors.static)
    draw.line(4, 0, 4, 10, draw.colors.static)

    -- Draw skinny boxes
    for _, body_id in ipairs(body_ids) do
        if b2d.body_is_valid(body_id) then
            local pos = b2d.body_get_position(body_id)
            local rot = b2d.body_get_rotation(body_id)
            local angle = b2d.rot_get_angle(rot)
            local color = b2d.body_is_awake(body_id) and draw.colors.dynamic or draw.colors.sleeping
            draw.solid_box(pos[1], pos[2], 1.5, 0.02, angle, color)
            draw.box(pos[1], pos[2], 1.5, 0.02, angle, {0, 0, 0, 1})
        end
    end
end

function M.cleanup()
    ground_id = nil
    body_ids = {}
end

return M
