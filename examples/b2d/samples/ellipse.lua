-- ellipse.lua - Ellipse-like shapes demo (diamond with radius)
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

    -- Use capsules for ellipse-like shapes
    local capsule = b2d.Capsule({center1 = {x = 0, y = -0.15}, center2 = {x = 0, y = 0.15}, radius = 0.2})

    -- Create ellipse-like shapes
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
            b2d.create_capsule_shape(body_id, shape_def, capsule)

            table.insert(bodies, {id = body_id})
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

    -- Draw ellipse-like shapes (as circles for simplicity)
    for _, body in ipairs(bodies) do
        local color = b2d.body_is_awake(body.id) and draw.colors.dynamic or draw.colors.sleeping
        local pos = b2d.body_get_position(body.id)
        local rot = b2d.body_get_rotation(body.id)
        draw.solid_circle_axis(pos[1], pos[2], 0.35, rot, color)
    end
end

function M.cleanup()
    ground_id = nil
    bodies = {}
end

return M
