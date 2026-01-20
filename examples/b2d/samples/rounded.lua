-- rounded.lua - Rounded shapes demo
local b2d = require("b2d")
local draw = require("examples.b2d.draw")

local M = {}

M.camera = {
    center_x = 2,
    center_y = 8,
    zoom = 14,
}

local ground_id = nil
local bodies = {}

function M.create_scene(world)
    bodies = {}

    -- Ground with walls
    local body_def = b2d.default_body_def()
    ground_id = b2d.create_body(world, body_def)

    local shape_def = b2d.default_shape_def()

    -- Floor
    local floor = b2d.make_offset_box(20, 1, {0, -1}, {1, 0})
    b2d.create_polygon_shape(ground_id, shape_def, floor)

    -- Left wall
    local left_wall = b2d.make_offset_box(1, 5, {-19, 5}, {1, 0})
    b2d.create_polygon_shape(ground_id, shape_def, left_wall)

    -- Right wall
    local right_wall = b2d.make_offset_box(1, 5, {19, 5}, {1, 0})
    b2d.create_polygon_shape(ground_id, shape_def, right_wall)

    -- Create rounded boxes
    body_def = b2d.default_body_def()
    body_def.type = b2d.BodyType.DYNAMICBODY

    shape_def = b2d.default_shape_def()

    local y = 2
    local xcount, ycount = 10, 10

    for _ = 0, ycount - 1 do
        local x = -5
        for _ = 0, xcount - 1 do
            body_def.position = {x, y}
            local body_id = b2d.create_body(world, body_def)

            -- Random rounded box
            local hw = 0.3 + math.random() * 0.2
            local hh = 0.3 + math.random() * 0.2
            local radius = 0.05 + math.random() * 0.15
            local rounded_box = b2d.make_rounded_box(hw, hh, radius)
            b2d.create_polygon_shape(body_id, shape_def, rounded_box)

            table.insert(bodies, {id = body_id, hw = hw, hh = hh, radius = radius})
            x = x + 1
        end
        y = y + 1
    end
end

function M.render(camera, world)
    -- Draw ground
    draw.solid_box(0, -1, 20, 1, 0, draw.colors.static)
    draw.solid_box(-19, 5, 1, 5, 0, draw.colors.static)
    draw.solid_box(19, 5, 1, 5, 0, draw.colors.static)

    -- Draw rounded boxes
    for _, body in ipairs(bodies) do
        local color = b2d.body_is_awake(body.id) and draw.colors.dynamic or draw.colors.sleeping
        local pos = b2d.body_get_position(body.id)
        local rot = b2d.body_get_rotation(body.id)
        local angle = b2d.rot_get_angle(rot)
        draw.solid_rounded_box(pos[1], pos[2], body.hw, body.hh, body.radius, angle, color)
        draw.rounded_box(pos[1], pos[2], body.hw, body.hh, body.radius, angle, {0, 0, 0, 1})
    end
end

function M.cleanup()
    ground_id = nil
    bodies = {}
end

return M
