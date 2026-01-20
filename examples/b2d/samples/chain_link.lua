-- chain_link.lua - Box2D official Chain Link sample
-- Demonstrates linking two chain shapes together
local b2d = require("b2d")
local draw = require("examples.b2d.draw")

local M = {}

M.camera = {
    center_x = 0,
    center_y = 0,
    zoom = 15,
}

local ground_id = nil
local body_ids = {}

function M.create_scene(world)
    body_ids = {}

    -- Ground with two linked chain shapes
    local body_def = b2d.default_body_def()
    ground_id = b2d.create_body(world, body_def)

    -- First chain - left side
    local points1 = {
        {-10, 0},
        {-8, 1},
        {-5, 1},
        {-3, 0},
        {0, 0},
    }

    local chain_def = b2d.default_chain_def()
    chain_def.points = points1
    chain_def.count = #points1
    chain_def.isLoop = false
    b2d.create_chain(ground_id, chain_def)

    -- Second chain - right side (linked at {0,0})
    local points2 = {
        {0, 0},
        {3, 0},
        {5, 1},
        {8, 1},
        {10, 0},
    }

    chain_def = b2d.default_chain_def()
    chain_def.points = points2
    chain_def.count = #points2
    chain_def.isLoop = false
    b2d.create_chain(ground_id, chain_def)

    -- Dynamic bodies on the chains
    local shape_def = b2d.default_shape_def()

    -- Circle on left chain
    body_def = b2d.default_body_def()
    body_def.type = b2d.BodyType.DYNAMICBODY
    body_def.position = {-5, 2}
    local body = b2d.create_body(world, body_def)
    local circle = b2d.Circle({center = {0, 0}, radius = 0.5})
    b2d.create_circle_shape(body, shape_def, circle)
    table.insert(body_ids, body)

    -- Capsule in middle
    body_def.position = {0, 2}
    body = b2d.create_body(world, body_def)
    local capsule = b2d.Capsule({center1 = {-0.5, 0}, center2 = {0.5, 0}, radius = 0.25})
    b2d.create_capsule_shape(body, shape_def, capsule)
    table.insert(body_ids, body)

    -- Box on right chain
    body_def.position = {5, 2}
    body = b2d.create_body(world, body_def)
    local box = b2d.make_box(0.5, 0.5)
    b2d.create_polygon_shape(body, shape_def, box)
    table.insert(body_ids, body)
end

function M.render(camera, world)
    -- Draw chains
    local points1 = {{-10, 0}, {-8, 1}, {-5, 1}, {-3, 0}, {0, 0}}
    local points2 = {{0, 0}, {3, 0}, {5, 1}, {8, 1}, {10, 0}}

    for i = 1, #points1 - 1 do
        draw.line(points1[i][1], points1[i][2], points1[i+1][1], points1[i+1][2], draw.colors.static)
    end
    for i = 1, #points2 - 1 do
        draw.line(points2[i][1], points2[i][2], points2[i+1][1], points2[i+1][2], draw.colors.static)
    end

    -- Draw link point
    draw.point(0, 0, 8, {1, 1, 0, 1})

    -- Draw bodies
    for i, body_id in ipairs(body_ids) do
        if b2d.body_is_valid(body_id) then
            local pos = b2d.body_get_position(body_id)
            local rot = b2d.body_get_rotation(body_id)
            local angle = b2d.rot_get_angle(rot)
            local color = b2d.body_is_awake(body_id) and draw.colors.dynamic or draw.colors.sleeping

            if i == 1 then
                -- Circle
                draw.solid_circle(pos[1], pos[2], 0.5, color)
                draw.circle(pos[1], pos[2], 0.5, {0, 0, 0, 1})
            elseif i == 2 then
                -- Capsule (approximate)
                local c = math.cos(angle)
                local s = math.sin(angle)
                draw.solid_circle(pos[1] - 0.5 * c, pos[2] - 0.5 * s, 0.25, color)
                draw.solid_circle(pos[1] + 0.5 * c, pos[2] + 0.5 * s, 0.25, color)
            else
                -- Box
                draw.solid_box(pos[1], pos[2], 0.5, 0.5, angle, color)
                draw.box(pos[1], pos[2], 0.5, 0.5, angle, {0, 0, 0, 1})
            end
        end
    end
end

function M.cleanup()
    ground_id = nil
    body_ids = {}
end

return M
