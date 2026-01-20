-- platformer.lua - Box2D official Platformer sample
-- Demonstrates one-way platforms using contact events.
local b2d = require("b2d")
local draw = require("examples.b2d.draw")

local M = {}

M.camera = {
    center_x = 0,
    center_y = 8,
    zoom = 20,
}

local ground_id = nil
local player_id = nil
local platform_ids = {}

function M.create_scene(world)
    platform_ids = {}

    -- Ground
    local body_def = b2d.default_body_def()
    ground_id = b2d.create_body(world, body_def)

    local shape_def = b2d.default_shape_def()
    local segment = b2d.Segment({point1 = {-20, 0}, point2 = {20, 0}})
    b2d.create_segment_shape(ground_id, shape_def, segment)

    -- Walls
    segment = b2d.Segment({point1 = {-15, 0}, point2 = {-15, 20}})
    b2d.create_segment_shape(ground_id, shape_def, segment)
    segment = b2d.Segment({point1 = {15, 0}, point2 = {15, 20}})
    b2d.create_segment_shape(ground_id, shape_def, segment)

    -- One-way platforms
    local platform_positions = {
        {-8, 4}, {0, 6}, {8, 8}, {-4, 10}, {4, 12}
    }

    for _, pos in ipairs(platform_positions) do
        body_def = b2d.default_body_def()
        body_def.position = pos
        local platform_id = b2d.create_body(world, body_def)

        shape_def = b2d.default_shape_def()
        local box = b2d.make_box(3, 0.2)
        b2d.create_polygon_shape(platform_id, shape_def, box)

        table.insert(platform_ids, platform_id)
    end

    -- Player
    body_def = b2d.default_body_def()
    body_def.type = b2d.BodyType.DYNAMICBODY
    body_def.position = {0, 2}
    body_def.fixedRotation = true
    player_id = b2d.create_body(world, body_def)

    shape_def = b2d.default_shape_def()
    local capsule = b2d.Capsule({center1 = {0, -0.5}, center2 = {0, 0.5}, radius = 0.3})
    b2d.create_capsule_shape(player_id, shape_def, capsule)
end

M.controls = "WASD: Move, Space: Jump"

local move_left = false
local move_right = false

function M.update(world, dt)
    if player_id and b2d.body_is_valid(player_id) then
        local vel = b2d.body_get_linear_velocity(player_id)
        local target_vx = 0
        if move_left then target_vx = target_vx - 8 end
        if move_right then target_vx = target_vx + 8 end
        b2d.body_set_linear_velocity(player_id, {target_vx, vel[2]})
    end
end

function M.on_key(key, world)
    local app = require("sokol.app")

    if key == app.Keycode.A or key == app.Keycode.LEFT then
        move_left = true
    elseif key == app.Keycode.D or key == app.Keycode.RIGHT then
        move_right = true
    elseif key == app.Keycode.SPACE or key == app.Keycode.W then
        if player_id and b2d.body_is_valid(player_id) then
            local vel = b2d.body_get_linear_velocity(player_id)
            b2d.body_set_linear_velocity(player_id, {vel[1], 12})
        end
    end
end

function M.on_key_up(key, world)
    local app = require("sokol.app")
    if key == app.Keycode.A or key == app.Keycode.LEFT then
        move_left = false
    elseif key == app.Keycode.D or key == app.Keycode.RIGHT then
        move_right = false
    end
end

function M.render(camera, world)
    -- Draw ground and walls
    draw.line(-20, 0, 20, 0, draw.colors.static)
    draw.line(-15, 0, -15, 20, draw.colors.static)
    draw.line(15, 0, 15, 20, draw.colors.static)

    -- Draw platforms
    local platform_positions = {
        {-8, 4}, {0, 6}, {8, 8}, {-4, 10}, {4, 12}
    }
    for _, pos in ipairs(platform_positions) do
        draw.solid_box(pos[1], pos[2], 3, 0.2, 0, {0.4, 0.6, 0.4, 1})
        draw.box(pos[1], pos[2], 3, 0.2, 0, {0, 0, 0, 1})
    end

    -- Draw player
    if player_id and b2d.body_is_valid(player_id) then
        local pos = b2d.body_get_position(player_id)
        local color = b2d.body_is_awake(player_id) and {0.3, 0.7, 0.3, 1} or draw.colors.sleeping

        draw.solid_circle(pos[1], pos[2] + 0.5, 0.3, color)
        draw.solid_circle(pos[1], pos[2] - 0.5, 0.3, color)
        draw.solid_box(pos[1], pos[2], 0.3, 0.5, 0, color)
        draw.circle(pos[1], pos[2] + 0.5, 0.3, {0, 0, 0, 1})
        draw.circle(pos[1], pos[2] - 0.5, 0.3, {0, 0, 0, 1})
    end
end

function M.cleanup()
    ground_id = nil
    player_id = nil
    platform_ids = {}
    move_left = false
    move_right = false
end

return M
