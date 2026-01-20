-- vertical_stack.lua - Vertical stack of boxes
local b2d = require("b2d")
local draw = require("examples.b2d.draw")

local M = {}

M.camera = {
    center_x = 0,
    center_y = 10,
    zoom = 25,
}

local ground_id = nil
local boxes = {}

local COUNT = 10
local BOX_SIZE = 0.5

function M.create_scene(world)
    boxes = {}

    -- Ground
    local body_def = b2d.default_body_def()
    body_def.position = {0, -1}
    ground_id = b2d.create_body(world, body_def)

    local shape_def = b2d.default_shape_def()
    local ground_box = b2d.make_box(40, 1)
    b2d.create_polygon_shape(ground_id, shape_def, ground_box)

    -- Stack of boxes
    local box = b2d.make_box(BOX_SIZE, BOX_SIZE)
    shape_def = b2d.default_shape_def()
    shape_def.density = 1
    shape_def.material = b2d.SurfaceMaterial({ friction = 0.6 })

    for i = 1, COUNT do
        body_def = b2d.default_body_def()
        body_def.type = b2d.BodyType.DYNAMICBODY
        body_def.position = {0, BOX_SIZE + (i - 1) * BOX_SIZE * 2.1}

        local box_id = b2d.create_body(world, body_def)
        b2d.create_polygon_shape(box_id, shape_def, box)
        table.insert(boxes, box_id)
    end
end

function M.render(camera, world)
    -- Ground
    draw.solid_box(0, -1, 40, 1, 0, draw.colors.static)

    -- Boxes
    for _, box_id in ipairs(boxes) do
        local pos = b2d.body_get_position(box_id)
        local rot = b2d.body_get_rotation(box_id)
        local angle = b2d.rot_get_angle(rot)
        local color = b2d.body_is_awake(box_id) and draw.colors.dynamic or draw.colors.sleeping
        draw.solid_box(pos[1], pos[2], BOX_SIZE, BOX_SIZE, angle, color)
        draw.box(pos[1], pos[2], BOX_SIZE, BOX_SIZE, angle, {0, 0, 0, 1})
    end
end

function M.cleanup()
    ground_id = nil
    boxes = {}
end

return M
