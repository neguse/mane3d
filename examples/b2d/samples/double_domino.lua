-- double_domino.lua - Domino chain reaction
local b2d = require("b2d")
local draw = require("examples.b2d.draw")

local M = {}

M.camera = {
    center_x = 0,
    center_y = 4,
    zoom = 6.25,
}

local ground_id = nil
local bodies = {}

local COUNT = 15

function M.create_scene(world)
    bodies = {}

    -- Ground
    local body_def = b2d.default_body_def()
    body_def.position = {0, -1}
    ground_id = b2d.create_body(world, body_def)

    local shape_def = b2d.default_shape_def()
    local ground_box = b2d.make_box(100, 1)
    b2d.create_polygon_shape(ground_id, shape_def, ground_box)

    -- Dominoes
    local box = b2d.make_box(0.125, 0.5)
    shape_def = b2d.default_shape_def()
    shape_def.material = b2d.SurfaceMaterial({friction = 0.6})

    body_def = b2d.default_body_def()
    body_def.type = b2d.BodyType.DYNAMICBODY

    local x = -0.5 * COUNT
    for i = 0, COUNT - 1 do
        body_def.position = {x, 0.5}
        local body_id = b2d.create_body(world, body_def)
        b2d.create_polygon_shape(body_id, shape_def, box)

        -- Push the first domino
        if i == 0 then
            b2d.body_apply_linear_impulse(body_id, {0.2, 0}, {x, 1}, true)
        end

        table.insert(bodies, body_id)
        x = x + 1
    end
end

function M.render(camera, world)
    -- Ground
    draw.solid_box(0, -1, 100, 1, 0, draw.colors.static)
    draw.box(0, -1, 100, 1, 0, {0, 0, 0, 1})

    -- Dominoes
    for _, body_id in ipairs(bodies) do
        local pos = b2d.body_get_position(body_id)
        local rot = b2d.body_get_rotation(body_id)
        local angle = b2d.rot_get_angle(rot)
        local color = b2d.body_is_awake(body_id) and draw.colors.dynamic or draw.colors.sleeping
        draw.solid_box(pos[1], pos[2], 0.125, 0.5, angle, color)
        draw.box(pos[1], pos[2], 0.125, 0.5, angle, {0, 0, 0, 1})
    end
end

function M.cleanup()
    ground_id = nil
    bodies = {}
end

return M
