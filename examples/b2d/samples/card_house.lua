-- card_house.lua - Card house structure
local b2d = require("b2d")
local draw = require("examples.b2d.draw")

local M = {}

M.camera = {
    center_x = 0.75,
    center_y = 0.9,
    zoom = 1.25,
}

local ground_id = nil
local bodies = {}

local CARD_HEIGHT = 0.2
local CARD_THICKNESS = 0.001

function M.create_scene(world)
    bodies = {}

    -- Ground
    local body_def = b2d.default_body_def()
    body_def.position = {0, -2}
    ground_id = b2d.create_body(world, body_def)

    local shape_def = b2d.default_shape_def()
    shape_def.material = b2d.SurfaceMaterial({friction = 0.7})
    local ground_box = b2d.make_box(40, 2)
    b2d.create_polygon_shape(ground_id, shape_def, ground_box)

    -- Card angles
    local angle0 = 25 * math.pi / 180
    local angle1 = -25 * math.pi / 180
    local angle2 = 0.5 * math.pi

    local card_box = b2d.make_box(CARD_THICKNESS, CARD_HEIGHT)
    body_def = b2d.default_body_def()
    body_def.type = b2d.BodyType.DYNAMICBODY

    local nb = 5
    local z0 = 0
    local y = CARD_HEIGHT - 0.02

    while nb > 0 do
        local z = z0
        for i = 0, nb - 1 do
            -- Horizontal card (except last in row)
            if i ~= nb - 1 then
                body_def.position = {z + 0.25, y + CARD_HEIGHT - 0.015}
                body_def.rotation = b2d.make_rot(angle2)
                local body_id = b2d.create_body(world, body_def)
                b2d.create_polygon_shape(body_id, shape_def, card_box)
                table.insert(bodies, body_id)
            end

            -- Left leaning card
            body_def.position = {z, y}
            body_def.rotation = b2d.make_rot(angle1)
            local body_id = b2d.create_body(world, body_def)
            b2d.create_polygon_shape(body_id, shape_def, card_box)
            table.insert(bodies, body_id)

            z = z + 0.175

            -- Right leaning card
            body_def.position = {z, y}
            body_def.rotation = b2d.make_rot(angle0)
            body_id = b2d.create_body(world, body_def)
            b2d.create_polygon_shape(body_id, shape_def, card_box)
            table.insert(bodies, body_id)

            z = z + 0.175
        end
        y = y + CARD_HEIGHT * 2 - 0.03
        z0 = z0 + 0.175
        nb = nb - 1
    end
end

function M.render(camera, world)
    -- Ground
    draw.solid_box(0, -2, 40, 2, 0, draw.colors.static)
    draw.box(0, -2, 40, 2, 0, {0, 0, 0, 1})

    -- Cards
    for _, body_id in ipairs(bodies) do
        local pos = b2d.body_get_position(body_id)
        local rot = b2d.body_get_rotation(body_id)
        local angle = b2d.rot_get_angle(rot)
        local color = b2d.body_is_awake(body_id) and draw.colors.dynamic or draw.colors.sleeping
        draw.solid_box(pos[1], pos[2], CARD_THICKNESS, CARD_HEIGHT, angle, color)
        draw.box(pos[1], pos[2], CARD_THICKNESS, CARD_HEIGHT, angle, {0, 0, 0, 1})
    end
end

function M.cleanup()
    ground_id = nil
    bodies = {}
end

return M
