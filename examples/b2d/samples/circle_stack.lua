-- circle_stack.lua - Stack of circles
local b2d = require("b2d")
local draw = require("examples.b2d.draw")

local M = {}

M.camera = {
    center_x = 0,
    center_y = 10,
    zoom = 25,
}

local ground_id = nil
local circles = {}

local COUNT = 10
local RADIUS = 0.5

function M.create_scene(world)
    circles = {}

    -- Ground
    local body_def = b2d.default_body_def()
    body_def.position = {0, -1}
    ground_id = b2d.create_body(world, body_def)

    local shape_def = b2d.default_shape_def()
    local ground_box = b2d.make_box(40, 1)
    b2d.create_polygon_shape(ground_id, shape_def, ground_box)

    -- Stack of circles
    local circle = b2d.Circle({center = {x = 0, y = 0}, radius = RADIUS})
    shape_def = b2d.default_shape_def()
    shape_def.density = 1
    shape_def.material = b2d.SurfaceMaterial({ friction = 0.3 })

    for i = 1, COUNT do
        body_def = b2d.default_body_def()
        body_def.type = b2d.BodyType.DYNAMICBODY
        body_def.position = {0, RADIUS + (i - 1) * RADIUS * 2.1}

        local circle_id = b2d.create_body(world, body_def)
        b2d.create_circle_shape(circle_id, shape_def, circle)
        table.insert(circles, circle_id)
    end
end

function M.render(camera, world)
    -- Ground
    draw.solid_box(0, -1, 40, 1, 0, draw.colors.static)

    -- Circles
    for _, circle_id in ipairs(circles) do
        local pos = b2d.body_get_position(circle_id)
        local rot = b2d.body_get_rotation(circle_id)
        local color = b2d.body_is_awake(circle_id) and draw.colors.dynamic or draw.colors.sleeping
        draw.solid_circle_axis(pos[1], pos[2], RADIUS, rot, color)
    end
end

function M.cleanup()
    ground_id = nil
    circles = {}
end

return M
