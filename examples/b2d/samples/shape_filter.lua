-- shape_filter.lua - Box2D official Shape Filter sample
-- Demonstrates collision filtering between different teams
local b2d = require("b2d")
local draw = require("examples.b2d.draw")

local M = {}

M.camera = {
    center_x = 0,
    center_y = 5,
    zoom = 10,
}

-- Team bits
local TEAM1 = 1
local TEAM2 = 2
local TEAM3 = 4

local ground_id = nil
local player_ids = {}

function M.create_scene(world)
    player_ids = {}

    -- Ground
    local body_def = b2d.default_body_def()
    ground_id = b2d.create_body(world, body_def)

    local shape_def = b2d.default_shape_def()
    local segment = b2d.Segment({point1 = {-10, 0}, point2 = {10, 0}})
    b2d.create_segment_shape(ground_id, shape_def, segment)

    -- Player 1 (Team 1)
    body_def = b2d.default_body_def()
    body_def.type = b2d.BodyType.DYNAMICBODY
    body_def.position = {-4, 3}
    local player1 = b2d.create_body(world, body_def)

    shape_def = b2d.default_shape_def()
    local filter = b2d.Filter()
    filter.categoryBits = TEAM1
    filter.maskBits = TEAM2 + TEAM3  -- Collides with team 2 and 3
    shape_def.filter = filter
    local box = b2d.make_box(1, 1)
    b2d.create_polygon_shape(player1, shape_def, box)
    table.insert(player_ids, {id = player1, team = 1, color = {1, 0.3, 0.3, 1}})

    -- Player 2 (Team 2)
    body_def.position = {0, 3}
    local player2 = b2d.create_body(world, body_def)

    filter.categoryBits = TEAM2
    filter.maskBits = TEAM1 + TEAM3  -- Collides with team 1 and 3
    shape_def.filter = filter
    b2d.create_polygon_shape(player2, shape_def, box)
    table.insert(player_ids, {id = player2, team = 2, color = {0.3, 1, 0.3, 1}})

    -- Player 3 (Team 3)
    body_def.position = {4, 3}
    local player3 = b2d.create_body(world, body_def)

    filter.categoryBits = TEAM3
    filter.maskBits = TEAM1 + TEAM2  -- Collides with team 1 and 2
    shape_def.filter = filter
    b2d.create_polygon_shape(player3, shape_def, box)
    table.insert(player_ids, {id = player3, team = 3, color = {0.3, 0.3, 1, 1}})
end

function M.render(camera, world)
    -- Draw ground
    draw.line(-10, 0, 10, 0, draw.colors.static)

    -- Draw players
    for _, player in ipairs(player_ids) do
        if b2d.body_is_valid(player.id) then
            local pos = b2d.body_get_position(player.id)
            local rot = b2d.body_get_rotation(player.id)
            local angle = b2d.rot_get_angle(rot)
            draw.solid_box(pos[1], pos[2], 1, 1, angle, player.color)
            draw.box(pos[1], pos[2], 1, 1, angle, {0, 0, 0, 1})
        end
    end
end

function M.cleanup()
    ground_id = nil
    player_ids = {}
end

return M
