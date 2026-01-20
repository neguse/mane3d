-- barrel.lua - Box2D official Barrel Benchmark sample
-- Many bodies falling into a barrel-shaped container.
local b2d = require("b2d")
local draw = require("examples.b2d.draw")

local M = {}

M.camera = {
    center_x = 8,
    center_y = 53,
    zoom = 60,
}

local ground_id = nil
local body_ids = {}
local spawn_timer = 0
local max_bodies = 200

function M.create_scene(world)
    body_ids = {}
    spawn_timer = 0

    -- Ground
    local body_def = b2d.default_body_def()
    ground_id = b2d.create_body(world, body_def)

    local shape_def = b2d.default_shape_def()

    -- Barrel shape using chain
    local barrel_width = 16
    local barrel_height = 100
    local points = {
        {-barrel_width / 2, 0},
        {-barrel_width / 2, barrel_height},
        {barrel_width / 2, barrel_height},
        {barrel_width / 2, 0},
    }

    local chain_def = b2d.default_chain_def()
    chain_def.points = points
    chain_def.count = #points
    chain_def.isLoop = false
    b2d.create_chain(ground_id, chain_def)

    -- Bottom
    local segment = b2d.Segment({point1 = {-barrel_width/2, 0}, point2 = {barrel_width/2, 0}})
    b2d.create_segment_shape(ground_id, shape_def, segment)
end

local function spawn_body(world)
    if #body_ids >= max_bodies then return end

    local body_def = b2d.default_body_def()
    body_def.type = b2d.BodyType.DYNAMICBODY
    body_def.position = {
        math.random() * 10 - 5,
        80 + math.random() * 10
    }
    local body_id = b2d.create_body(world, body_def)

    local shape_def = b2d.default_shape_def()

    -- Random shape
    local shape_type = math.random(1, 3)
    if shape_type == 1 then
        local circle = b2d.Circle({center = {0, 0}, radius = 0.5})
        b2d.create_circle_shape(body_id, shape_def, circle)
    elseif shape_type == 2 then
        local box = b2d.make_box(0.4, 0.4)
        b2d.create_polygon_shape(body_id, shape_def, box)
    else
        local capsule = b2d.Capsule({center1 = {0, -0.3}, center2 = {0, 0.3}, radius = 0.2})
        b2d.create_capsule_shape(body_id, shape_def, capsule)
    end

    table.insert(body_ids, body_id)
end

function M.update(world, dt)
    spawn_timer = spawn_timer + dt
    if spawn_timer > 0.05 then
        spawn_body(world)
        spawn_timer = 0
    end
end

function M.render(camera, world)
    -- Draw barrel
    local barrel_width = 16
    local barrel_height = 100
    draw.line(-barrel_width/2, 0, -barrel_width/2, barrel_height, draw.colors.static)
    draw.line(barrel_width/2, 0, barrel_width/2, barrel_height, draw.colors.static)
    draw.line(-barrel_width/2, 0, barrel_width/2, 0, draw.colors.static)

    -- Draw bodies
    for _, body_id in ipairs(body_ids) do
        if b2d.body_is_valid(body_id) then
            local pos = b2d.body_get_position(body_id)
            local color = b2d.body_is_awake(body_id) and draw.colors.dynamic or draw.colors.sleeping
            draw.solid_circle(pos[1], pos[2], 0.5, color)
            draw.circle(pos[1], pos[2], 0.5, {0, 0, 0, 1})
        end
    end
end

function M.cleanup()
    ground_id = nil
    body_ids = {}
end

return M
