-- foot_sensor.lua - Box2D official Foot Sensor sample
-- Demonstrates using a sensor to detect ground contact for jumping.
local b2d = require("b2d")
local draw = require("examples.b2d.draw")

local M = {}

M.camera = {
    center_x = 0,
    center_y = 5,
    zoom = 15,
}

local ground_id = nil
local player_id = nil
local foot_sensor_id = nil
local on_ground = false
local ground_contact_count = 0

function M.create_scene(world)
    on_ground = false
    ground_contact_count = 0

    -- Ground
    local body_def = b2d.default_body_def()
    ground_id = b2d.create_body(world, body_def)

    local shape_def = b2d.default_shape_def()

    -- Floor
    local segment = b2d.Segment({point1 = {-20, 0}, point2 = {20, 0}})
    b2d.create_segment_shape(ground_id, shape_def, segment)

    -- Platforms
    local platforms = {
        {{-8, 3}, {-4, 3}},
        {{4, 5}, {10, 5}},
        {{-3, 7}, {3, 7}},
    }
    for _, p in ipairs(platforms) do
        segment = b2d.Segment({point1 = p[1], point2 = p[2]})
        b2d.create_segment_shape(ground_id, shape_def, segment)
    end

    -- Player body
    body_def = b2d.default_body_def()
    body_def.type = b2d.BodyType.DYNAMICBODY
    body_def.position = {0, 2}
    body_def.fixedRotation = true
    player_id = b2d.create_body(world, body_def)

    -- Player shape (capsule)
    shape_def = b2d.default_shape_def()
    local capsule = b2d.Capsule({center1 = {0, -0.5}, center2 = {0, 0.5}, radius = 0.3})
    b2d.create_capsule_shape(player_id, shape_def, capsule)

    -- Foot sensor (small box at bottom of player)
    shape_def = b2d.default_shape_def()
    shape_def.isSensor = true
    shape_def.enableSensorEvents = true
    local foot_box = b2d.make_offset_box(0.25, 0.1, {0, -0.7}, {1, 0})
    foot_sensor_id = b2d.create_polygon_shape(player_id, shape_def, foot_box)
end

M.controls = "WASD: Move, Space: Jump"

local move_left = false
local move_right = false

function M.update(world, dt)
    -- Process sensor events
    local sensor_events = b2d.world_get_sensor_events(world)
    if sensor_events then
        if sensor_events.beginEvents then
            for _, event in ipairs(sensor_events.beginEvents) do
                if event.sensorShapeId == foot_sensor_id then
                    ground_contact_count = ground_contact_count + 1
                end
            end
        end
        if sensor_events.endEvents then
            for _, event in ipairs(sensor_events.endEvents) do
                if event.sensorShapeId == foot_sensor_id then
                    ground_contact_count = math.max(0, ground_contact_count - 1)
                end
            end
        end
    end

    on_ground = ground_contact_count > 0

    -- Apply movement
    if player_id and b2d.body_is_valid(player_id) then
        local vel = b2d.body_get_linear_velocity(player_id)
        local target_vx = 0
        if move_left then target_vx = target_vx - 5 end
        if move_right then target_vx = target_vx + 5 end

        b2d.body_set_linear_velocity(player_id, {target_vx, vel[2]})
    end
end

function M.on_key(key, world)
    local app = require("sokol.app")

    if key == app.Keycode.A or key == app.Keycode.LEFT then
        move_left = true
    elseif key == app.Keycode.D or key == app.Keycode.RIGHT then
        move_right = true
    elseif key == app.Keycode.SPACE or key == app.Keycode.W or key == app.Keycode.UP then
        if on_ground and player_id and b2d.body_is_valid(player_id) then
            local vel = b2d.body_get_linear_velocity(player_id)
            b2d.body_set_linear_velocity(player_id, {vel[1], 10})
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
    -- Draw ground and platforms
    draw.line(-20, 0, 20, 0, draw.colors.static)
    draw.line(-8, 3, -4, 3, draw.colors.static)
    draw.line(4, 5, 10, 5, draw.colors.static)
    draw.line(-3, 7, 3, 7, draw.colors.static)

    -- Draw player
    if player_id and b2d.body_is_valid(player_id) then
        local pos = b2d.body_get_position(player_id)
        local color = on_ground and {0.2, 0.8, 0.2, 1} or {0.8, 0.2, 0.2, 1}

        -- Draw capsule
        draw.solid_circle(pos[1], pos[2] + 0.5, 0.3, color)
        draw.solid_circle(pos[1], pos[2] - 0.5, 0.3, color)
        draw.solid_box(pos[1], pos[2], 0.3, 0.5, 0, color)
        draw.circle(pos[1], pos[2] + 0.5, 0.3, {0, 0, 0, 1})
        draw.circle(pos[1], pos[2] - 0.5, 0.3, {0, 0, 0, 1})

        -- Draw foot sensor indicator
        local sensor_color = on_ground and {0, 1, 0, 0.5} or {1, 0, 0, 0.3}
        draw.box(pos[1], pos[2] - 0.7, 0.25, 0.1, 0, sensor_color)
    end

    -- Draw grounded indicator
    local indicator_color = on_ground and {0, 1, 0, 1} or {1, 0, 0, 1}
    draw.point(-18, 13, 8, indicator_color)
end

function M.cleanup()
    ground_id = nil
    player_id = nil
    foot_sensor_id = nil
    on_ground = false
    ground_contact_count = 0
    move_left = false
    move_right = false
end

return M
