-- tangent_speed.lua - Box2D official Tangent Speed sample
-- Demonstrates surface velocity using tangent speed
local b2d = require("b2d")
local draw = require("examples.b2d.draw")

local M = {}

M.camera = {
    center_x = 80,
    center_y = -20,
    zoom = 60,
}

local ground_id = nil
local ball_ids = {}
local spawn_timer = 0
local max_balls = 100

function M.create_scene(world)
    ball_ids = {}
    spawn_timer = 0

    -- Create a race track using segments with different tangent speeds
    local body_def = b2d.default_body_def()
    ground_id = b2d.create_body(world, body_def)

    -- Create track segments with varying tangent speeds
    local shape_def = b2d.default_shape_def()

    -- Start ramp
    shape_def.material = b2d.SurfaceMaterial({tangentSpeed = -10})
    local segment = b2d.Segment({point1 = {100, -20}, point2 = {120, -30}})
    b2d.create_segment_shape(ground_id, shape_def, segment)

    -- Flat sections with increasing speed
    local speeds = {-20, -30, -40, -50, -60, -70}
    local x = 120
    for i, speed in ipairs(speeds) do
        shape_def = b2d.default_shape_def()
        shape_def.material = b2d.SurfaceMaterial({tangentSpeed = speed})
        segment = b2d.Segment({point1 = {x, -30}, point2 = {x - 20, -30}})
        b2d.create_segment_shape(ground_id, shape_def, segment)
        x = x - 20
    end

    -- End ramp going up
    shape_def = b2d.default_shape_def()
    shape_def.material = b2d.SurfaceMaterial({tangentSpeed = -80})
    segment = b2d.Segment({point1 = {x, -30}, point2 = {x - 20, -20}})
    b2d.create_segment_shape(ground_id, shape_def, segment)
end

local function spawn_ball(world)
    if #ball_ids >= max_balls then return end

    local body_def = b2d.default_body_def()
    body_def.type = b2d.BodyType.DYNAMICBODY
    body_def.position = {110, -30}
    local ball = b2d.create_body(world, body_def)

    local shape_def = b2d.default_shape_def()
    shape_def.material = b2d.SurfaceMaterial({friction = 0.6, rollingResistance = 0.3})
    local circle = b2d.Circle({center = {0, 0}, radius = 0.5})
    b2d.create_circle_shape(ball, shape_def, circle)

    table.insert(ball_ids, ball)
end

function M.update(world, dt)
    spawn_timer = spawn_timer + dt
    if spawn_timer > 0.4 and #ball_ids < max_balls then
        spawn_ball(world)
        spawn_timer = 0
    end
end

function M.render(camera, world)
    -- Draw track
    draw.line(100, -20, 120, -30, {0.2, 0.2, 0.6, 1})
    local x = 120
    for i = 1, 6 do
        local color_intensity = 0.2 + i * 0.1
        draw.line(x, -30, x - 20, -30, {color_intensity, color_intensity, 0.6, 1})
        x = x - 20
    end
    draw.line(x, -30, x - 20, -20, {0.8, 0.2, 0.6, 1})

    -- Draw balls
    for _, ball_id in ipairs(ball_ids) do
        if b2d.body_is_valid(ball_id) then
            local pos = b2d.body_get_position(ball_id)
            local color = b2d.body_is_awake(ball_id) and draw.colors.dynamic or draw.colors.sleeping
            draw.solid_circle(pos[1], pos[2], 0.5, color)
            draw.circle(pos[1], pos[2], 0.5, {0, 0, 0, 1})
        end
    end
end

function M.cleanup()
    ground_id = nil
    ball_ids = {}
end

return M
