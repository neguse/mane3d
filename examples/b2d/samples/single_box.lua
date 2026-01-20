-- single_box.lua - Single falling box sample
local b2d = require("b2d")
local draw = require("examples.b2d.draw")

local M = {}

-- Camera settings
M.camera = {
    center_x = 0,
    center_y = 5,
    zoom = 15,
}

-- Local state
local ground_id = nil
local box_id = nil

function M.create_scene(world)
    -- Ground
    local body_def = b2d.default_body_def()
    body_def.position = {0, -1}
    ground_id = b2d.create_body(world, body_def)

    local shape_def = b2d.default_shape_def()
    local ground_box = b2d.make_box(20, 1)
    b2d.create_polygon_shape(ground_id, shape_def, ground_box)

    -- Dynamic box
    body_def = b2d.default_body_def()
    body_def.type = b2d.BodyType.DYNAMICBODY
    body_def.position = {0, 10}
    box_id = b2d.create_body(world, body_def)

    shape_def = b2d.default_shape_def()
    shape_def.density = 1
    shape_def.material = b2d.SurfaceMaterial({ friction = 0.3 })
    local box = b2d.make_box(1, 1)
    b2d.create_polygon_shape(box_id, shape_def, box)
end

function M.render(camera, world)
    -- Ground
    draw.solid_box(0, -1, 20, 1, 0, draw.colors.static)
    draw.box(0, -1, 20, 1, 0, {0, 0, 0, 1})

    -- Box
    local pos = b2d.body_get_position(box_id)
    local rot = b2d.body_get_rotation(box_id)
    local angle = b2d.rot_get_angle(rot)
    local color = b2d.body_is_awake(box_id) and draw.colors.dynamic or draw.colors.sleeping
    draw.solid_box(pos[1], pos[2], 1, 1, angle, color)
    draw.box(pos[1], pos[2], 1, 1, angle, {0, 0, 0, 1})
end

function M.cleanup()
    ground_id = nil
    box_id = nil
end

return M
