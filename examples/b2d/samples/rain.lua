-- rain.lua - Box2D official Rain Benchmark sample
-- Many bodies falling like rain
local b2d = require("b2d")
local draw = require("examples.b2d.draw")

local M = {}

M.camera = {
    center_x = 0,
    center_y = 20,
    zoom = 50,
}

local ground_id = nil
local body_ids = {}
local max_bodies = 500
local spawn_timer = 0

function M.create_scene(world)
    body_ids = {}
    spawn_timer = 0

    -- Ground
    local body_def = b2d.default_body_def()
    ground_id = b2d.create_body(world, body_def)

    local shape_def = b2d.default_shape_def()

    -- Floor
    local segment = b2d.Segment({point1 = {-30, 0}, point2 = {30, 0}})
    b2d.create_segment_shape(ground_id, shape_def, segment)

    -- Some obstacles
    for i = 1, 10 do
        local x = (i - 5) * 5
        local y = 10 + math.random() * 10
        local box = b2d.make_offset_box(1.5, 0.3, {x, y}, b2d.make_rot(math.random() * math.pi))
        b2d.create_polygon_shape(ground_id, shape_def, box)
    end
end

local function spawn_body(world)
    if #body_ids >= max_bodies then
        -- Remove oldest body
        local oldest = table.remove(body_ids, 1)
        if b2d.body_is_valid(oldest) then
            b2d.destroy_body(oldest)
        end
    end

    local body_def = b2d.default_body_def()
    body_def.type = b2d.BodyType.DYNAMICBODY
    body_def.position = {math.random() * 50 - 25, 40 + math.random() * 10}
    local body = b2d.create_body(world, body_def)

    local shape_def = b2d.default_shape_def()
    local circle = b2d.Circle({center = {0, 0}, radius = 0.2 + math.random() * 0.2})
    b2d.create_circle_shape(body, shape_def, circle)

    table.insert(body_ids, body)
end

function M.update(world, dt)
    spawn_timer = spawn_timer + dt
    if spawn_timer > 0.02 then
        spawn_body(world)
        spawn_timer = 0
    end
end

function M.render(camera, world)
    -- Draw ground
    draw.line(-30, 0, 30, 0, draw.colors.static)

    -- Draw obstacles
    for i = 1, 10 do
        local x = (i - 5) * 5
        local y = 10 + ((i * 7) % 10)  -- Approximate positions
        draw.solid_box(x, y, 1.5, 0.3, 0, draw.colors.static)
    end

    -- Draw rain drops
    for _, body_id in ipairs(body_ids) do
        if b2d.body_is_valid(body_id) then
            local pos = b2d.body_get_position(body_id)
            local color = b2d.body_is_awake(body_id) and {0.3, 0.5, 0.9, 1} or draw.colors.sleeping
            draw.solid_circle(pos[1], pos[2], 0.25, color)
        end
    end
end

function M.cleanup()
    ground_id = nil
    body_ids = {}
end

return M
