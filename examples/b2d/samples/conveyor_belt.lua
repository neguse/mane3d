-- conveyor_belt.lua - Box2D official Conveyor Belt sample
-- Demonstrates tangent speed for conveyor belt effect.
local b2d = require("b2d")
local draw = require("examples.b2d.draw")

local M = {}

M.camera = {
    center_x = 2,
    center_y = 7.5,
    zoom = 12,
}

local ground_id = nil
local platform_id = nil
local box_ids = {}

function M.create_scene(world)
    box_ids = {}

    -- Ground
    local body_def = b2d.default_body_def()
    ground_id = b2d.create_body(world, body_def)

    local shape_def = b2d.default_shape_def()
    local segment = b2d.Segment({point1 = {-20, 0}, point2 = {20, 0}})
    b2d.create_segment_shape(ground_id, shape_def, segment)

    -- Platform (conveyor belt)
    body_def = b2d.default_body_def()
    body_def.position = {-5, 5}
    platform_id = b2d.create_body(world, body_def)

    local box = b2d.make_rounded_box(10.0, 0.25, 0.25)

    shape_def = b2d.default_shape_def()
    shape_def.material = b2d.SurfaceMaterial({friction = 0.8, tangentSpeed = 2.0})  -- Conveyor belt speed
    b2d.create_polygon_shape(platform_id, shape_def, box)

    -- Boxes
    shape_def = b2d.default_shape_def()
    local cube = b2d.make_square(0.5)

    for i = 0, 4 do
        body_def = b2d.default_body_def()
        body_def.type = b2d.BodyType.DYNAMICBODY
        body_def.position = {-10 + 2 * i, 7}
        local body_id = b2d.create_body(world, body_def)
        b2d.create_polygon_shape(body_id, shape_def, cube)
        table.insert(box_ids, body_id)
    end
end

function M.render(camera, world)
    -- Ground
    draw.line(-20, 0, 20, 0, draw.colors.static)

    -- Platform (conveyor belt) with direction arrows
    draw.solid_box(-5, 5, 10, 0.25, 0, {0.3, 0.5, 0.3, 1})
    draw.box(-5, 5, 10, 0.25, 0, {0, 0, 0, 1})

    -- Direction indicators
    for i = -4, 4 do
        local x = -5 + i * 2
        draw.line(x, 5.3, x + 0.5, 5.3, {1, 1, 0, 1})
        draw.line(x + 0.3, 5.4, x + 0.5, 5.3, {1, 1, 0, 1})
        draw.line(x + 0.3, 5.2, x + 0.5, 5.3, {1, 1, 0, 1})
    end

    -- Draw boxes
    for _, body_id in ipairs(box_ids) do
        local pos = b2d.body_get_position(body_id)
        local rot = b2d.body_get_rotation(body_id)
        local angle = b2d.rot_get_angle(rot)
        local color = b2d.body_is_awake(body_id) and draw.colors.dynamic or draw.colors.sleeping

        draw.solid_box(pos[1], pos[2], 0.5, 0.5, angle, color)
        draw.box(pos[1], pos[2], 0.5, 0.5, angle, {0, 0, 0, 1})
    end
end

function M.cleanup()
    ground_id = nil
    platform_id = nil
    box_ids = {}
end

return M
