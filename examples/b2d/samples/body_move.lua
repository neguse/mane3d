-- body_move.lua - Box2D official Body Move Event sample
-- Demonstrates body move events for tracking transforms
local b2d = require("b2d")
local draw = require("examples.b2d.draw")

local M = {}

M.camera = {
    center_x = 0,
    center_y = 5,
    zoom = 20,
}

M.controls = "E: Explode"

local ground_id = nil
local body_ids = {}
local max_bodies = 100
local spawn_timer = 0
local explosion_pos = {0, 10}
local explosion_radius = 5

function M.create_scene(world)
    body_ids = {}
    spawn_timer = 0

    -- Ground
    local body_def = b2d.default_body_def()
    ground_id = b2d.create_body(world, body_def)

    local shape_def = b2d.default_shape_def()
    local segment = b2d.Segment({point1 = {-20, 0}, point2 = {20, 0}})
    b2d.create_segment_shape(ground_id, shape_def, segment)

    -- Walls
    segment = b2d.Segment({point1 = {-20, 0}, point2 = {-20, 20}})
    b2d.create_segment_shape(ground_id, shape_def, segment)
    segment = b2d.Segment({point1 = {20, 0}, point2 = {20, 20}})
    b2d.create_segment_shape(ground_id, shape_def, segment)
end

local function spawn_body(world)
    if #body_ids >= max_bodies then return end

    local body_def = b2d.default_body_def()
    body_def.type = b2d.BodyType.DYNAMICBODY
    body_def.position = {math.random() * 30 - 15, 15 + math.random() * 5}

    local body_id = b2d.create_body(world, body_def)

    local shape_def = b2d.default_shape_def()

    -- Random shape
    local shape_type = math.random(1, 3)
    if shape_type == 1 then
        local circle = b2d.Circle({center = {0, 0}, radius = 0.3 + math.random() * 0.3})
        b2d.create_circle_shape(body_id, shape_def, circle)
    elseif shape_type == 2 then
        local box = b2d.make_box(0.3 + math.random() * 0.3, 0.3 + math.random() * 0.3)
        b2d.create_polygon_shape(body_id, shape_def, box)
    else
        local capsule = b2d.Capsule({center1 = {0, -0.2}, center2 = {0, 0.2}, radius = 0.2})
        b2d.create_capsule_shape(body_id, shape_def, capsule)
    end

    table.insert(body_ids, body_id)
end

function M.update(world, dt)
    spawn_timer = spawn_timer + dt
    if spawn_timer > 0.25 and #body_ids < max_bodies then
        spawn_body(world)
        spawn_timer = 0
    end
end

function M.on_key(key, world)
    local app = require("sokol.app")

    if key == app.Keycode.E then
        -- Explode
        local def = b2d.default_explosion_def()
        def.position = explosion_pos
        def.radius = explosion_radius
        def.falloff = 0.1
        def.impulsePerLength = 10
        b2d.world_explode(world, def)
    end
end

function M.render(camera, world)
    -- Draw ground and walls
    draw.line(-20, 0, 20, 0, draw.colors.static)
    draw.line(-20, 0, -20, 20, draw.colors.static)
    draw.line(20, 0, 20, 20, draw.colors.static)

    -- Draw explosion radius
    draw.circle(explosion_pos[1], explosion_pos[2], explosion_radius, {0, 0.5, 1, 0.5})

    -- Draw bodies
    for _, body_id in ipairs(body_ids) do
        if b2d.body_is_valid(body_id) then
            local pos = b2d.body_get_position(body_id)
            local color = b2d.body_is_awake(body_id) and draw.colors.dynamic or draw.colors.sleeping
            draw.solid_circle(pos[1], pos[2], 0.4, color)
            draw.circle(pos[1], pos[2], 0.4, {0, 0, 0, 1})
        end
    end
end

function M.cleanup()
    ground_id = nil
    body_ids = {}
end

return M
