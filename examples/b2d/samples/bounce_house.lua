-- bounce_house.lua - Box2D official Bounce House sample
-- Demonstrates continuous collision with bullet bodies bouncing in an enclosed area.
local b2d = require("b2d")
local draw = require("examples.b2d.draw")

local M = {}

M.camera = {
    center_x = 0,
    center_y = 0,
    zoom = 11.25,
}

local ground_id = nil
local body_id = nil

local function launch(world)
    if body_id and b2d.body_is_valid(body_id) then
        b2d.destroy_body(body_id)
    end

    local body_def = b2d.default_body_def()
    body_def.type = b2d.BodyType.DYNAMICBODY
    body_def.linearVelocity = {10, 20}
    body_def.position = {0, 0}
    body_def.gravityScale = 0
    body_def.isBullet = true
    body_def.allowFastRotation = true

    body_id = b2d.create_body(world, body_def)

    local shape_def = b2d.default_shape_def()
    shape_def.density = 1
    shape_def.material = b2d.SurfaceMaterial({restitution = 1.0, friction = 0})

    local circle = b2d.Circle({center = {0, 0}, radius = 0.5})
    b2d.create_circle_shape(body_id, shape_def, circle)
end

function M.create_scene(world)
    -- Ground (walls)
    local body_def = b2d.default_body_def()
    ground_id = b2d.create_body(world, body_def)

    local shape_def = b2d.default_shape_def()

    -- Bottom wall
    local segment = b2d.Segment({point1 = {-10, -10}, point2 = {10, -10}})
    b2d.create_segment_shape(ground_id, shape_def, segment)

    -- Right wall
    segment = b2d.Segment({point1 = {10, -10}, point2 = {10, 10}})
    b2d.create_segment_shape(ground_id, shape_def, segment)

    -- Top wall
    segment = b2d.Segment({point1 = {10, 10}, point2 = {-10, 10}})
    b2d.create_segment_shape(ground_id, shape_def, segment)

    -- Left wall
    segment = b2d.Segment({point1 = {-10, 10}, point2 = {-10, -10}})
    b2d.create_segment_shape(ground_id, shape_def, segment)

    -- Launch the bouncing ball
    launch(world)
end

M.controls = "Space: Re-launch"

function M.on_key(key, world)
    local app = require("sokol.app")

    if key == app.Keycode.SPACE then
        launch(world)
    end
end

function M.render(camera, world)
    -- Draw walls
    draw.line(-10, -10, 10, -10, draw.colors.static)
    draw.line(10, -10, 10, 10, draw.colors.static)
    draw.line(10, 10, -10, 10, draw.colors.static)
    draw.line(-10, 10, -10, -10, draw.colors.static)

    -- Draw bouncing ball
    if body_id and b2d.body_is_valid(body_id) then
        local pos = b2d.body_get_position(body_id)
        local color = b2d.body_is_awake(body_id) and draw.colors.dynamic or draw.colors.sleeping

        draw.solid_circle(pos[1], pos[2], 0.5, color)
        draw.circle(pos[1], pos[2], 0.5, {0, 0, 0, 1})

        -- Draw velocity vector
        local vel = b2d.body_get_linear_velocity(body_id)
        local scale = 0.05
        draw.line(pos[1], pos[2], pos[1] + vel[1] * scale, pos[2] + vel[2] * scale, {0, 1, 0, 1})
    end
end

function M.cleanup()
    ground_id = nil
    body_id = nil
end

return M
