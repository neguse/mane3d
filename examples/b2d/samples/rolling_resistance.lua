-- rolling_resistance.lua - Box2D official Rolling Resistance sample
-- Demonstrates rolling resistance on circles rolling down slopes.
local b2d = require("b2d")
local draw = require("examples.b2d.draw")

local M = {}

M.camera = {
    center_x = 5,
    center_y = 20,
    zoom = 27.5,
}

local body_ids = {}
local ground_ids = {}
local resist_scale = 0.02
local lift = 0

local function create_scene(world)
    body_ids = {}
    ground_ids = {}

    local circle = b2d.Circle({center = {0, 0}, radius = 0.5})
    local shape_def = b2d.default_shape_def()

    for i = 0, 19 do
        -- Ground segment (slope)
        local body_def = b2d.default_body_def()
        local ground_id = b2d.create_body(world, body_def)
        table.insert(ground_ids, ground_id)

        local segment = b2d.Segment({
            point1 = {-40, 2 * i},
            point2 = {40, 2 * i + lift}
        })
        b2d.create_segment_shape(ground_id, shape_def, segment)

        -- Rolling circle
        body_def = b2d.default_body_def()
        body_def.type = b2d.BodyType.DYNAMICBODY
        body_def.position = {-39.5, 2 * i + 0.75}
        body_def.angularVelocity = -10
        body_def.linearVelocity = {5, 0}

        local body_id = b2d.create_body(world, body_def)

        -- Set rolling resistance via material
        local circle_shape_def = b2d.default_shape_def()
        circle_shape_def.material = b2d.SurfaceMaterial({rollingResistance = resist_scale * i})
        b2d.create_circle_shape(body_id, circle_shape_def, circle)

        table.insert(body_ids, body_id)
    end
end

function M.create_scene(world)
    create_scene(world)
end

M.controls = "1: Flat, 2: Uphill, 3: Downhill"

-- Store world reference for key handling
local stored_world = nil

function M.update(world, dt)
    stored_world = world
end

function M.on_key(key, world)
    local app = require("sokol.app")

    local need_restart = false
    if key == app.Keycode._1 then
        lift = 0
        need_restart = true
    elseif key == app.Keycode._2 then
        lift = 5
        need_restart = true
    elseif key == app.Keycode._3 then
        lift = -5
        need_restart = true
    end

    -- Note: actual restart is handled by pressing 'R' in the sample selector
    -- Here we just update the lift value
end

function M.render(camera, world)
    -- Draw ground segments
    for i = 0, 19 do
        local y1 = 2 * i
        local y2 = 2 * i + lift
        draw.line(-40, y1, 40, y2, draw.colors.static)
    end

    -- Draw circles
    for i, body_id in ipairs(body_ids) do
        if b2d.body_is_valid(body_id) then
            local pos = b2d.body_get_position(body_id)
            local color = b2d.body_is_awake(body_id) and draw.colors.dynamic or draw.colors.sleeping

            draw.solid_circle(pos[1], pos[2], 0.5, color)
            draw.circle(pos[1], pos[2], 0.5, {0, 0, 0, 1})
        end
    end

    -- Draw rolling resistance labels
    for i = 0, 19 do
        local resistance = resist_scale * i
        local label = string.format("%.2f", resistance)
        -- Labels would be drawn at (-41.5, 2*i + 1) but we use simple approach
        draw.point(-41, 2 * i + 0.5, 3, {1, 1, 1, 1})
    end
end

function M.cleanup()
    body_ids = {}
    ground_ids = {}
    stored_world = nil
end

return M
