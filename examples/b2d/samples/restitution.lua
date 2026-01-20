-- restitution.lua - Restitution (bounciness) demo
local b2d = require("b2d")
local draw = require("examples.b2d.draw")

local M = {}

M.camera = {
    center_x = 0,
    center_y = 15,
    zoom = 50,
}

local ground_id = nil
local bodies = {}

local COUNT = 20
local RADIUS = 0.5

function M.create_scene(world)
    bodies = {}

    -- Ground (thin box instead of segment)
    local body_def = b2d.default_body_def()
    body_def.position = {0, -0.1}
    ground_id = b2d.create_body(world, body_def)

    local shape_def = b2d.default_shape_def()
    local ground_box = b2d.make_box(40, 0.1)
    b2d.create_polygon_shape(ground_id, shape_def, ground_box)

    -- Circles with varying restitution
    local circle = b2d.Circle({center = {x = 0, y = 0}, radius = RADIUS})

    body_def = b2d.default_body_def()
    body_def.type = b2d.BodyType.DYNAMICBODY

    local dr = 1.0 / COUNT
    local dx = 80.0 / COUNT
    local x = -40.0 + dx * 0.5
    local restitution = 0

    for _ = 1, COUNT do
        shape_def = b2d.default_shape_def()
        shape_def.material = b2d.SurfaceMaterial({restitution = restitution})

        body_def.position = {x, 20}
        local body_id = b2d.create_body(world, body_def)
        b2d.create_circle_shape(body_id, shape_def, circle)
        table.insert(bodies, {id = body_id, restitution = restitution})

        restitution = restitution + dr
        x = x + dx
    end
end

function M.render(camera, world)
    -- Ground
    draw.solid_box(0, -0.1, 40, 0.1, 0, draw.colors.static)

    -- Circles
    for _, body in ipairs(bodies) do
        local color = b2d.body_is_awake(body.id) and draw.colors.dynamic or draw.colors.sleeping
        local pos = b2d.body_get_position(body.id)
        local rot = b2d.body_get_rotation(body.id)
        draw.solid_circle_axis(pos[1], pos[2], RADIUS, rot, color)
    end
end

function M.cleanup()
    ground_id = nil
    bodies = {}
end

return M
