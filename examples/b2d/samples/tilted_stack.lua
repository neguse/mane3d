-- tilted_stack.lua - Tilted stack of boxes
local b2d = require("b2d")
local draw = require("examples.b2d.draw")

local M = {}

M.camera = {
    center_x = 0,
    center_y = 8,
    zoom = 25,
}

local ground_id = nil
local bodies = {}

local ROW_COUNT = 10
local BOX_SIZE = 0.5

function M.create_scene(world)
    bodies = {}

    -- Ground
    local body_def = b2d.default_body_def()
    body_def.position = {0, -1}
    ground_id = b2d.create_body(world, body_def)

    local shape_def = b2d.default_shape_def()
    local ground_box = b2d.make_box(40, 1)
    b2d.create_polygon_shape(ground_id, shape_def, ground_box)

    -- Tilted stack
    local box = b2d.make_box(BOX_SIZE, BOX_SIZE)
    local tilt = 0.1

    for row = 0, ROW_COUNT - 1 do
        body_def = b2d.default_body_def()
        body_def.type = b2d.BodyType.DYNAMICBODY
        body_def.position = {row * tilt, BOX_SIZE + row * (BOX_SIZE * 2.05)}

        local body_id = b2d.create_body(world, body_def)
        shape_def = b2d.default_shape_def()
        b2d.create_polygon_shape(body_id, shape_def, box)
        table.insert(bodies, body_id)
    end
end

function M.render(camera, world)
    -- Ground
    draw.solid_box(0, -1, 40, 1, 0, draw.colors.static)
    draw.box(0, -1, 40, 1, 0, {0, 0, 0, 1})

    -- Bodies
    for _, body_id in ipairs(bodies) do
        local pos = b2d.body_get_position(body_id)
        local rot = b2d.body_get_rotation(body_id)
        local angle = b2d.rot_get_angle(rot)
        local color = b2d.body_is_awake(body_id) and draw.colors.dynamic or draw.colors.sleeping
        draw.solid_box(pos[1], pos[2], BOX_SIZE, BOX_SIZE, angle, color)
        draw.box(pos[1], pos[2], BOX_SIZE, BOX_SIZE, angle, {0, 0, 0, 1})
    end
end

function M.cleanup()
    ground_id = nil
    bodies = {}
end

return M
