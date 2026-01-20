-- compound_shapes.lua - Compound shapes (tables, spaceship)
local b2d = require("b2d")
local draw = require("examples.b2d.draw")

local M = {}

M.camera = {
    center_x = 0,
    center_y = 6,
    zoom = 12.5,
}

local ground_id = nil
local bodies = {}

function M.create_scene(world)
    bodies = {}

    -- Ground (thin box instead of segment)
    local body_def = b2d.default_body_def()
    body_def.position = {0, -0.1}
    ground_id = b2d.create_body(world, body_def)

    local shape_def = b2d.default_shape_def()
    local ground_box = b2d.make_box(50, 0.1)
    b2d.create_polygon_shape(ground_id, shape_def, ground_box)

    -- Table 1 (short legs)
    body_def = b2d.default_body_def()
    body_def.type = b2d.BodyType.DYNAMICBODY
    body_def.position = {-15, 1}
    local table1_id = b2d.create_body(world, body_def)

    shape_def = b2d.default_shape_def()
    local top = b2d.make_offset_box(3, 0.5, {0, 3.5}, {1, 0})
    local left_leg = b2d.make_offset_box(0.5, 1.5, {-2.5, 1.5}, {1, 0})
    local right_leg = b2d.make_offset_box(0.5, 1.5, {2.5, 1.5}, {1, 0})
    b2d.create_polygon_shape(table1_id, shape_def, top)
    b2d.create_polygon_shape(table1_id, shape_def, left_leg)
    b2d.create_polygon_shape(table1_id, shape_def, right_leg)
    table.insert(bodies, {id = table1_id, type = "table1"})

    -- Table 2 (tall legs)
    body_def.position = {-5, 1}
    local table2_id = b2d.create_body(world, body_def)

    top = b2d.make_offset_box(3, 0.5, {0, 3.5}, {1, 0})
    left_leg = b2d.make_offset_box(0.5, 2, {-2.5, 2}, {1, 0})
    right_leg = b2d.make_offset_box(0.5, 2, {2.5, 2}, {1, 0})
    b2d.create_polygon_shape(table2_id, shape_def, top)
    b2d.create_polygon_shape(table2_id, shape_def, left_leg)
    b2d.create_polygon_shape(table2_id, shape_def, right_leg)
    table.insert(bodies, {id = table2_id, type = "table2"})

    -- Spaceship 1 (using boxes as approximation)
    body_def.position = {5, 1}
    local ship1_id = b2d.create_body(world, body_def)

    -- Use tilted boxes as wing approximation
    local left_wing = b2d.make_offset_box(1.2, 0.3, {-1, 2}, b2d.make_rot(1.1))
    local right_wing = b2d.make_offset_box(1.2, 0.3, {1, 2}, b2d.make_rot(-1.1))
    b2d.create_polygon_shape(ship1_id, shape_def, left_wing)
    b2d.create_polygon_shape(ship1_id, shape_def, right_wing)
    table.insert(bodies, {id = ship1_id, type = "ship1"})

    -- Spaceship 2 (with body)
    body_def.position = {15, 1}
    local ship2_id = b2d.create_body(world, body_def)

    local left_wing2 = b2d.make_offset_box(1.2, 0.3, {-1, 2}, b2d.make_rot(1.1))
    local right_wing2 = b2d.make_offset_box(1.2, 0.3, {1, 2}, b2d.make_rot(-1.1))
    local body_box = b2d.make_offset_box(0.5, 1, {0, 1}, {1, 0})
    b2d.create_polygon_shape(ship2_id, shape_def, left_wing2)
    b2d.create_polygon_shape(ship2_id, shape_def, right_wing2)
    b2d.create_polygon_shape(ship2_id, shape_def, body_box)
    table.insert(bodies, {id = ship2_id, type = "ship2"})
end

function M.render(camera, world)
    -- Ground
    draw.solid_box(0, -0.1, 50, 0.1, 0, draw.colors.static)

    -- Draw compound bodies
    for _, body in ipairs(bodies) do
        local color = b2d.body_is_awake(body.id) and draw.colors.dynamic or draw.colors.sleeping
        local pos = b2d.body_get_position(body.id)
        local rot = b2d.body_get_rotation(body.id)
        local angle = b2d.rot_get_angle(rot)
        local c, s = rot[1], rot[2]

        local function transform(ox, oy)
            return pos[1] + ox * c - oy * s, pos[2] + ox * s + oy * c
        end

        if body.type == "table1" then
            local tx, ty = transform(0, 3.5)
            draw.solid_box(tx, ty, 3, 0.5, angle, color)
            tx, ty = transform(-2.5, 1.5)
            draw.solid_box(tx, ty, 0.5, 1.5, angle, color)
            tx, ty = transform(2.5, 1.5)
            draw.solid_box(tx, ty, 0.5, 1.5, angle, color)

        elseif body.type == "table2" then
            local tx, ty = transform(0, 3.5)
            draw.solid_box(tx, ty, 3, 0.5, angle, color)
            tx, ty = transform(-2.5, 2)
            draw.solid_box(tx, ty, 0.5, 2, angle, color)
            tx, ty = transform(2.5, 2)
            draw.solid_box(tx, ty, 0.5, 2, angle, color)

        elseif body.type == "ship1" then
            -- Left wing (box approximation)
            local lx, ly = transform(-1, 2)
            draw.solid_box(lx, ly, 1.2, 0.3, angle + 1.1, color)
            -- Right wing
            local rx, ry = transform(1, 2)
            draw.solid_box(rx, ry, 1.2, 0.3, angle - 1.1, color)

        elseif body.type == "ship2" then
            -- Left wing
            local lx, ly = transform(-1, 2)
            draw.solid_box(lx, ly, 1.2, 0.3, angle + 1.1, color)
            -- Right wing
            local rx, ry = transform(1, 2)
            draw.solid_box(rx, ry, 1.2, 0.3, angle - 1.1, color)
            -- Body
            local bx, by = transform(0, 1)
            draw.solid_box(bx, by, 0.5, 1, angle, color)
        end
    end
end

function M.cleanup()
    ground_id = nil
    bodies = {}
end

return M
