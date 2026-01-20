-- bad_steiner.lua - Box2D official Bad Steiner sample
-- Tests handling of degenerate triangle polygons
local b2d = require("b2d")
local draw = require("examples.b2d.draw")

local M = {}

M.camera = {
    center_x = 0,
    center_y = 1.75,
    zoom = 2.5,
}

local ground_id = nil
local body_id = nil

function M.create_scene(world)
    -- Ground
    local body_def = b2d.default_body_def()
    ground_id = b2d.create_body(world, body_def)

    local shape_def = b2d.default_shape_def()
    local segment = b2d.Segment({point1 = {-100, 0}, point2 = {100, 0}})
    b2d.create_segment_shape(ground_id, shape_def, segment)

    -- Create a body with a degenerate (very thin) triangle
    body_def = b2d.default_body_def()
    body_def.type = b2d.BodyType.DYNAMICBODY
    body_def.position = {-48, 62}
    body_id = b2d.create_body(world, body_def)

    -- These points form a nearly degenerate triangle
    local points = {
        {48.76 + 48, -60.57 - 62},
        {48.74 + 48, -60.54 - 62},
        {48.68 + 48, -60.56 - 62},
    }

    -- Compute hull and create polygon
    local hull = b2d.compute_hull(points)
    if hull then
        local polygon = b2d.make_polygon(hull, 0)
        if polygon then
            b2d.create_polygon_shape(body_id, shape_def, polygon)
        else
            -- Fallback to small box if polygon fails
            local box = b2d.make_box(0.1, 0.1)
            b2d.create_polygon_shape(body_id, shape_def, box)
        end
    else
        -- Fallback to small box if hull fails
        local box = b2d.make_box(0.1, 0.1)
        b2d.create_polygon_shape(body_id, shape_def, box)
    end
end

function M.render(camera, world)
    -- Draw ground
    draw.line(-5, 0, 5, 0, draw.colors.static)

    -- Draw body
    if body_id and b2d.body_is_valid(body_id) then
        local pos = b2d.body_get_position(body_id)
        local color = b2d.body_is_awake(body_id) and draw.colors.dynamic or draw.colors.sleeping
        draw.solid_circle(pos[1], pos[2], 0.1, color)
        draw.circle(pos[1], pos[2], 0.1, {0, 0, 0, 1})
    end
end

function M.cleanup()
    ground_id = nil
    body_id = nil
end

return M
