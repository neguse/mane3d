-- chain_drop.lua - Box2D official Chain Drop sample
-- Demonstrates dropping a fast-moving object onto a chain shape.
local b2d = require("b2d")
local draw = require("examples.b2d.draw")

local M = {}

M.camera = {
    center_x = 0,
    center_y = 0,
    zoom = 8.75,
}

local ground_id = nil
local body_id = nil
local speed = -42
local y_offset = -0.1

local function launch(world)
    if body_id and b2d.body_is_valid(body_id) then
        b2d.destroy_body(body_id)
    end

    local body_def = b2d.default_body_def()
    body_def.type = b2d.BodyType.DYNAMICBODY
    body_def.linearVelocity = {0, speed}
    body_def.position = {0, 10 + y_offset}
    body_def.rotation = b2d.make_rot(0.5 * math.pi)

    -- Lock angular rotation
    local motion_locks = b2d.MotionLocks()
    motion_locks.angularZ = true
    body_def.motionLocks = motion_locks

    body_id = b2d.create_body(world, body_def)

    local shape_def = b2d.default_shape_def()
    local circle = b2d.Circle({center = {0, 0}, radius = 0.5})
    b2d.create_circle_shape(body_id, shape_def, circle)
end

function M.create_scene(world)
    -- Ground with chain shape
    local body_def = b2d.default_body_def()
    body_def.position = {0, -6}
    ground_id = b2d.create_body(world, body_def)

    local points = {{-10, -2}, {10, -2}, {10, 1}, {-10, 1}}
    local chain_def = b2d.default_chain_def()
    chain_def.points = points
    chain_def.count = #points
    chain_def.isLoop = true
    b2d.create_chain(ground_id, chain_def)

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
    -- Draw chain (box shape)
    local gx, gy = 0, -6
    draw.line(gx - 10, gy - 2, gx + 10, gy - 2, draw.colors.static)
    draw.line(gx + 10, gy - 2, gx + 10, gy + 1, draw.colors.static)
    draw.line(gx + 10, gy + 1, gx - 10, gy + 1, draw.colors.static)
    draw.line(gx - 10, gy + 1, gx - 10, gy - 2, draw.colors.static)

    -- Draw falling body
    if body_id and b2d.body_is_valid(body_id) then
        local pos = b2d.body_get_position(body_id)
        local color = b2d.body_is_awake(body_id) and draw.colors.dynamic or draw.colors.sleeping
        draw.solid_circle(pos[1], pos[2], 0.5, color)
        draw.circle(pos[1], pos[2], 0.5, {0, 0, 0, 1})
    end
end

function M.cleanup()
    ground_id = nil
    body_id = nil
end

return M
