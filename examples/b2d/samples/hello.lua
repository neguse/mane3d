-- hello.lua - Minimal Box2D example (Hello World)
local b2d = require("b2d")
local draw = require("examples.b2d.draw")

local M = {}

M.camera = {
    center_x = 0,
    center_y = 4,
    zoom = 12,
}

local ground_id = nil
local body_id = nil

function M.create_scene(world)
    -- Ground body
    local body_def = b2d.default_body_def()
    body_def.position = {0, -10}
    ground_id = b2d.create_body(world, body_def)

    local shape_def = b2d.default_shape_def()
    local ground_box = b2d.make_box(50, 10)
    b2d.create_polygon_shape(ground_id, shape_def, ground_box)

    -- Dynamic body
    body_def = b2d.default_body_def()
    body_def.type = b2d.BodyType.DYNAMICBODY
    body_def.position = {0, 4}
    body_id = b2d.create_body(world, body_def)

    shape_def = b2d.default_shape_def()
    shape_def.density = 1
    shape_def.material = b2d.SurfaceMaterial({ friction = 0.3 })
    local dynamic_box = b2d.make_box(1, 1)
    b2d.create_polygon_shape(body_id, shape_def, dynamic_box)
end

function M.render(camera, world)
    -- Ground
    draw.solid_box(0, -10, 50, 10, 0, draw.colors.static)

    -- Dynamic body
    local pos = b2d.body_get_position(body_id)
    local rot = b2d.body_get_rotation(body_id)
    local angle = b2d.rot_get_angle(rot)
    local color = b2d.body_is_awake(body_id) and draw.colors.dynamic or draw.colors.sleeping
    draw.solid_box(pos[1], pos[2], 1, 1, angle, color)
    draw.box(pos[1], pos[2], 1, 1, angle, {0, 0, 0, 1})
end

function M.cleanup()
    ground_id = nil
    body_id = nil
end

return M
