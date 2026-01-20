-- confined.lua - Confined circles
local b2d = require("b2d")
local draw = require("examples.b2d.draw")

local M = {}

M.camera = {
    center_x = 0,
    center_y = 10,
    zoom = 12.5,
}

local ground_id = nil
local bodies = {}

local GRID_COUNT = 25
local RADIUS = 0.5

function M.create_scene(world)
    bodies = {}

    -- Container walls (using capsules)
    local body_def = b2d.default_body_def()
    ground_id = b2d.create_body(world, body_def)

    local shape_def = b2d.default_shape_def()

    -- Bottom
    local capsule = b2d.Capsule({center1 = {x = -10.5, y = 0}, center2 = {x = 10.5, y = 0}, radius = 0.5})
    b2d.create_capsule_shape(ground_id, shape_def, capsule)

    -- Left
    capsule = b2d.Capsule({center1 = {x = -10.5, y = 0}, center2 = {x = -10.5, y = 20.5}, radius = 0.5})
    b2d.create_capsule_shape(ground_id, shape_def, capsule)

    -- Right
    capsule = b2d.Capsule({center1 = {x = 10.5, y = 0}, center2 = {x = 10.5, y = 20.5}, radius = 0.5})
    b2d.create_capsule_shape(ground_id, shape_def, capsule)

    -- Top
    capsule = b2d.Capsule({center1 = {x = -10.5, y = 20.5}, center2 = {x = 10.5, y = 20.5}, radius = 0.5})
    b2d.create_capsule_shape(ground_id, shape_def, capsule)

    -- Create circles (no gravity)
    body_def = b2d.default_body_def()
    body_def.type = b2d.BodyType.DYNAMICBODY
    body_def.gravityScale = 0

    shape_def = b2d.default_shape_def()
    local circle = b2d.Circle({center = {x = 0, y = 0}, radius = RADIUS})

    for col = 0, GRID_COUNT - 1 do
        for row = 0, GRID_COUNT - 1 do
            body_def.position = {
                -8.75 + col * 18 / GRID_COUNT,
                1.5 + row * 18 / GRID_COUNT
            }
            local body_id = b2d.create_body(world, body_def)
            b2d.create_circle_shape(body_id, shape_def, circle)
            table.insert(bodies, body_id)
        end
    end
end

function M.render(camera, world)
    -- Draw container walls
    draw.solid_capsule({-10.5, 0}, {10.5, 0}, 0.5, draw.colors.static)
    draw.solid_capsule({-10.5, 0}, {-10.5, 20.5}, 0.5, draw.colors.static)
    draw.solid_capsule({10.5, 0}, {10.5, 20.5}, 0.5, draw.colors.static)
    draw.solid_capsule({-10.5, 20.5}, {10.5, 20.5}, 0.5, draw.colors.static)

    -- Draw circles
    for _, body_id in ipairs(bodies) do
        local color = b2d.body_is_awake(body_id) and draw.colors.dynamic or draw.colors.sleeping
        local pos = b2d.body_get_position(body_id)
        local rot = b2d.body_get_rotation(body_id)
        draw.solid_circle_axis(pos[1], pos[2], RADIUS, rot, color)
    end
end

function M.cleanup()
    ground_id = nil
    bodies = {}
end

return M
