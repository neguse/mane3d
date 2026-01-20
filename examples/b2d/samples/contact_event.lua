-- contact_event.lua - Box2D official Contact Event sample (simplified)
-- Demonstrates contact events with a controllable player.
local b2d = require("b2d")
local draw = require("examples.b2d.draw")
local imgui = require("imgui")

local M = {}

M.camera = {
    center_x = 0,
    center_y = 0,
    zoom = 25 * 1.5,
}

local ground_id = nil
local player_id = nil
local debris_ids = {}
local force = 200.0

local function spawn_debris(world)
    local body_def = b2d.default_body_def()
    body_def.type = b2d.BodyType.DYNAMICBODY
    body_def.position = {math.random() * 60 - 30, math.random() * 60 - 30}
    body_def.rotation = b2d.make_rot(math.random() * 2 * math.pi)
    body_def.linearVelocity = {math.random() * 10 - 5, math.random() * 10 - 5}
    body_def.angularVelocity = math.random() * 2 - 1
    body_def.gravityScale = 0.0

    local body_id = b2d.create_body(world, body_def)

    local shape_def = b2d.default_shape_def()
    shape_def.restitution = 0.8
    shape_def.enableContactEvents = false

    local debris_type = #debris_ids % 3
    if debris_type == 0 then
        local circle = b2d.Circle({center = {0, 0}, radius = 0.5})
        b2d.create_circle_shape(body_id, shape_def, circle)
    elseif debris_type == 1 then
        local capsule = b2d.Capsule({center1 = {0, -0.25}, center2 = {0, 0.25}, radius = 0.25})
        b2d.create_capsule_shape(body_id, shape_def, capsule)
    else
        local box = b2d.make_box(0.4, 0.6)
        b2d.create_polygon_shape(body_id, shape_def, box)
    end

    table.insert(debris_ids, body_id)
end

function M.create_scene(world)
    debris_ids = {}

    -- Ground (walls)
    local body_def = b2d.default_body_def()
    ground_id = b2d.create_body(world, body_def)

    local points = {{40, -40}, {-40, -40}, {-40, 40}, {40, 40}}
    local chain_def = b2d.default_chain_def()
    chain_def.points = points
    chain_def.count = #points
    chain_def.isLoop = true
    b2d.create_chain(ground_id, chain_def)

    -- Player
    body_def = b2d.default_body_def()
    body_def.type = b2d.BodyType.DYNAMICBODY
    body_def.gravityScale = 0.0
    body_def.linearDamping = 0.5
    body_def.angularDamping = 0.5
    body_def.isBullet = true
    player_id = b2d.create_body(world, body_def)

    local circle = b2d.Circle({center = {0, 0}, radius = 1.0})
    local shape_def = b2d.default_shape_def()
    shape_def.enableContactEvents = true
    b2d.create_circle_shape(player_id, shape_def, circle)

    -- Spawn initial debris
    for i = 1, 20 do
        spawn_debris(world)
    end
end

function M.update(world, dt)
    -- Handle contact events - destroy debris that touches player
    local contact_events = b2d.world_get_contact_events(world)

    if contact_events and contact_events.beginEvents then
        for _, event in ipairs(contact_events.beginEvents) do
            local body_a = b2d.shape_get_body(event.shapeIdA)
            local body_b = b2d.shape_get_body(event.shapeIdB)

            -- Check if one is the player and the other is debris
            local debris_to_destroy = nil
            if body_a == player_id then
                debris_to_destroy = body_b
            elseif body_b == player_id then
                debris_to_destroy = body_a
            end

            if debris_to_destroy then
                -- Find and remove from debris list
                for i, debris_id in ipairs(debris_ids) do
                    if debris_id == debris_to_destroy then
                        b2d.destroy_body(debris_id)
                        table.remove(debris_ids, i)
                        -- Spawn new debris
                        spawn_debris(world)
                        break
                    end
                end
            end
        end
    end
end

function M.update_gui(world)
    imgui.begin_window("Contact Event")
    local changed
    changed, force = imgui.slider_float("Force", force, 100, 500)
    imgui.text_unformatted("WASD to move player")
    imgui.text_unformatted("Debris count: " .. #debris_ids)
    imgui.end_window()
end

M.controls = "WASD: Move player"

function M.on_key(key, world)
    local app = require("sokol.app")
    local pos = b2d.body_get_position(player_id)

    if key == app.Keycode.A then
        b2d.body_apply_force(player_id, {-force, 0}, pos, true)
    elseif key == app.Keycode.D then
        b2d.body_apply_force(player_id, {force, 0}, pos, true)
    elseif key == app.Keycode.W then
        b2d.body_apply_force(player_id, {0, force}, pos, true)
    elseif key == app.Keycode.S then
        b2d.body_apply_force(player_id, {0, -force}, pos, true)
    end
end

function M.render(camera, world)
    -- Draw walls
    local walls = {{40, -40}, {-40, -40}, {-40, 40}, {40, 40}, {40, -40}}
    for i = 1, #walls - 1 do
        draw.line(walls[i][1], walls[i][2], walls[i+1][1], walls[i+1][2], draw.colors.static)
    end

    -- Draw player
    local pos = b2d.body_get_position(player_id)
    local color = b2d.body_is_awake(player_id) and {0.2, 0.8, 0.2, 1} or draw.colors.sleeping
    draw.solid_circle(pos[1], pos[2], 1.0, color)
    draw.circle(pos[1], pos[2], 1.0, {0, 0, 0, 1})

    -- Draw debris
    for _, debris_id in ipairs(debris_ids) do
        if b2d.body_is_valid(debris_id) then
            local dpos = b2d.body_get_position(debris_id)
            local dcolor = b2d.body_is_awake(debris_id) and draw.colors.dynamic or draw.colors.sleeping
            draw.solid_circle(dpos[1], dpos[2], 0.5, dcolor)
            draw.circle(dpos[1], dpos[2], 0.5, {0, 0, 0, 1})
        end
    end
end

function M.cleanup()
    ground_id = nil
    player_id = nil
    debris_ids = {}
end

return M
