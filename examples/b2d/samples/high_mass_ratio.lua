-- high_mass_ratio.lua - Box2D official High Mass Ratio sample
-- Demonstrates stability with extreme mass ratios.
local b2d = require("b2d")
local draw = require("examples.b2d.draw")

local M = {}

M.camera = {
    center_x = 0,
    center_y = 8,
    zoom = 25,
}

local ground_id = nil
local body_ids = {}

function M.create_scene(world)
    body_ids = {}

    -- Ground
    local body_def = b2d.default_body_def()
    ground_id = b2d.create_body(world, body_def)

    local shape_def = b2d.default_shape_def()
    local segment = b2d.Segment({point1 = {-40, 0}, point2 = {40, 0}})
    b2d.create_segment_shape(ground_id, shape_def, segment)

    -- Heavy box at bottom
    body_def = b2d.default_body_def()
    body_def.type = b2d.BodyType.DYNAMICBODY
    body_def.position = {0, 1}
    local heavy_id = b2d.create_body(world, body_def)

    shape_def = b2d.default_shape_def()
    shape_def.density = 100.0  -- Very heavy
    local box = b2d.make_box(2, 1)
    b2d.create_polygon_shape(heavy_id, shape_def, box)
    table.insert(body_ids, {id = heavy_id, heavy = true})

    -- Light boxes stacked on top
    shape_def = b2d.default_shape_def()
    shape_def.density = 1.0  -- Light

    for i = 1, 5 do
        body_def = b2d.default_body_def()
        body_def.type = b2d.BodyType.DYNAMICBODY
        body_def.position = {0, 2.5 + i * 1.1}
        local light_id = b2d.create_body(world, body_def)

        box = b2d.make_box(0.5, 0.5)
        b2d.create_polygon_shape(light_id, shape_def, box)
        table.insert(body_ids, {id = light_id, heavy = false})
    end

    -- Second stack with even more extreme ratio
    body_def = b2d.default_body_def()
    body_def.type = b2d.BodyType.DYNAMICBODY
    body_def.position = {-10, 1}
    heavy_id = b2d.create_body(world, body_def)

    shape_def = b2d.default_shape_def()
    shape_def.density = 1000.0  -- Extremely heavy
    box = b2d.make_box(2, 1)
    b2d.create_polygon_shape(heavy_id, shape_def, box)
    table.insert(body_ids, {id = heavy_id, heavy = true})

    shape_def = b2d.default_shape_def()
    shape_def.density = 0.1  -- Very light

    for i = 1, 3 do
        body_def = b2d.default_body_def()
        body_def.type = b2d.BodyType.DYNAMICBODY
        body_def.position = {-10, 2.5 + i * 1.1}
        local light_id = b2d.create_body(world, body_def)

        box = b2d.make_box(0.5, 0.5)
        b2d.create_polygon_shape(light_id, shape_def, box)
        table.insert(body_ids, {id = light_id, heavy = false})
    end
end

function M.render(camera, world)
    -- Draw ground
    draw.line(-40, 0, 40, 0, draw.colors.static)

    -- Draw bodies
    for _, body_info in ipairs(body_ids) do
        local body_id = body_info.id
        if b2d.body_is_valid(body_id) then
            local pos = b2d.body_get_position(body_id)
            local rot = b2d.body_get_rotation(body_id)
            local angle = b2d.rot_get_angle(rot)

            local color
            if body_info.heavy then
                color = {0.6, 0.2, 0.2, 1}  -- Red for heavy
            else
                color = b2d.body_is_awake(body_id) and draw.colors.dynamic or draw.colors.sleeping
            end

            local hw = body_info.heavy and 2 or 0.5
            local hh = body_info.heavy and 1 or 0.5

            draw.solid_box(pos[1], pos[2], hw, hh, angle, color)
            draw.box(pos[1], pos[2], hw, hh, angle, {0, 0, 0, 1})
        end
    end
end

function M.cleanup()
    ground_id = nil
    body_ids = {}
end

return M
