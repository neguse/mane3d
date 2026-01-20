-- capsule_stack.lua - Stack of capsules
local b2d = require("b2d")
local draw = require("examples.b2d.draw")

local M = {}

M.camera = {
    center_x = 0,
    center_y = 8,
    zoom = 25,
}

local ground_id = nil
local bodies = {}

local ROW_COUNT = 8
local COLUMN_COUNT = 4
local RADIUS = 0.25
local LENGTH = 0.5

function M.create_scene(world)
    bodies = {}

    -- Ground
    local body_def = b2d.default_body_def()
    body_def.position = {0, -1}
    ground_id = b2d.create_body(world, body_def)

    local shape_def = b2d.default_shape_def()
    local ground_box = b2d.make_box(40, 1)
    b2d.create_polygon_shape(ground_id, shape_def, ground_box)

    -- Capsule stacks
    local capsule = b2d.Capsule({
        center1 = {x = 0, y = -LENGTH},
        center2 = {x = 0, y = LENGTH},
        radius = RADIUS
    })

    for col = 0, COLUMN_COUNT - 1 do
        for row = 0, ROW_COUNT - 1 do
            body_def = b2d.default_body_def()
            body_def.type = b2d.BodyType.DYNAMICBODY
            body_def.position = {
                (col - COLUMN_COUNT / 2) * (RADIUS * 4),
                LENGTH + RADIUS + row * (LENGTH * 2 + RADIUS * 2.2)
            }

            local body_id = b2d.create_body(world, body_def)
            shape_def = b2d.default_shape_def()
            b2d.create_capsule_shape(body_id, shape_def, capsule)
            table.insert(bodies, body_id)
        end
    end
end

function M.render(camera, world)
    -- Ground
    draw.solid_box(0, -1, 40, 1, 0, draw.colors.static)
    draw.box(0, -1, 40, 1, 0, {0, 0, 0, 1})

    -- Capsules
    for _, body_id in ipairs(bodies) do
        local pos = b2d.body_get_position(body_id)
        local rot = b2d.body_get_rotation(body_id)
        local c, s = rot[1], rot[2]
        local p1 = {pos[1] - (-LENGTH) * s, pos[2] + (-LENGTH) * c}
        local p2 = {pos[1] - LENGTH * s, pos[2] + LENGTH * c}
        local color = b2d.body_is_awake(body_id) and draw.colors.dynamic or draw.colors.sleeping
        draw.solid_capsule(p1, p2, RADIUS, color)
        draw.capsule(p1, p2, RADIUS, {0, 0, 0, 1})
    end
end

function M.cleanup()
    ground_id = nil
    bodies = {}
end

return M
