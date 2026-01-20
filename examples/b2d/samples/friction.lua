-- friction.lua - Friction demo with ramps
local b2d = require("b2d")
local draw = require("examples.b2d.draw")

local M = {}

M.camera = {
    center_x = 0,
    center_y = 14,
    zoom = 15,
}

local ground_id = nil
local bodies = {}

function M.create_scene(world)
    bodies = {}

    -- Ground and ramps
    local body_def = b2d.default_body_def()
    ground_id = b2d.create_body(world, body_def)

    local shape_def = b2d.default_shape_def()
    shape_def.material = b2d.SurfaceMaterial({friction = 0.2})

    -- Floor (thin box instead of segment)
    local floor = b2d.make_offset_box(40, 0.1, {0, 0}, {1, 0})
    b2d.create_polygon_shape(ground_id, shape_def, floor)

    -- Ramps (alternating left and right)
    local ramp1 = b2d.make_offset_box(13, 0.25, {-4, 22}, b2d.make_rot(-0.25))
    b2d.create_polygon_shape(ground_id, shape_def, ramp1)

    local stopper1 = b2d.make_offset_box(0.25, 1, {10.5, 19}, {1, 0})
    b2d.create_polygon_shape(ground_id, shape_def, stopper1)

    local ramp2 = b2d.make_offset_box(13, 0.25, {4, 14}, b2d.make_rot(0.25))
    b2d.create_polygon_shape(ground_id, shape_def, ramp2)

    local stopper2 = b2d.make_offset_box(0.25, 1, {-10.5, 11}, {1, 0})
    b2d.create_polygon_shape(ground_id, shape_def, stopper2)

    local ramp3 = b2d.make_offset_box(13, 0.25, {-4, 6}, b2d.make_rot(-0.25))
    b2d.create_polygon_shape(ground_id, shape_def, ramp3)

    -- Boxes with varying friction
    local box = b2d.make_box(0.5, 0.5)
    local frictions = {0.75, 0.5, 0.35, 0.1, 0.0}

    for i, friction in ipairs(frictions) do
        body_def = b2d.default_body_def()
        body_def.type = b2d.BodyType.DYNAMICBODY
        body_def.position = {-15 + 4 * (i - 1), 28}

        local body_id = b2d.create_body(world, body_def)

        shape_def = b2d.default_shape_def()
        shape_def.density = 25
        shape_def.material = b2d.SurfaceMaterial({friction = friction})
        b2d.create_polygon_shape(body_id, shape_def, box)

        table.insert(bodies, {id = body_id, friction = friction})
    end
end

function M.render(camera, world)
    -- Draw ramps
    draw.solid_box(0, 0, 40, 0.1, 0, draw.colors.static)
    draw.solid_box(-4, 22, 13, 0.25, -0.25, draw.colors.static)
    draw.solid_box(10.5, 19, 0.25, 1, 0, draw.colors.static)
    draw.solid_box(4, 14, 13, 0.25, 0.25, draw.colors.static)
    draw.solid_box(-10.5, 11, 0.25, 1, 0, draw.colors.static)
    draw.solid_box(-4, 6, 13, 0.25, -0.25, draw.colors.static)

    -- Boxes
    for _, body in ipairs(bodies) do
        local pos = b2d.body_get_position(body.id)
        local rot = b2d.body_get_rotation(body.id)
        local angle = b2d.rot_get_angle(rot)
        local color = b2d.body_is_awake(body.id) and draw.colors.dynamic or draw.colors.sleeping
        draw.solid_box(pos[1], pos[2], 0.5, 0.5, angle, color)
        draw.box(pos[1], pos[2], 0.5, 0.5, angle, {0, 0, 0, 1})
    end
end

function M.cleanup()
    ground_id = nil
    bodies = {}
end

return M
