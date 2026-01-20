-- shape_cast_chain.lua - Box2D official Shape Cast Chain sample
-- Tests shape casting against chain shapes
local b2d = require("b2d")
local draw = require("examples.b2d.draw")

local M = {}

M.camera = {
    center_x = 0,
    center_y = 0,
    zoom = 2,
}

M.controls = "WASD: Move character"

local ground_id = nil
local character_id = nil
local velocity = {0, 0}

function M.create_scene(world)
    velocity = {0, 0}

    -- Ground chain shape (loop)
    local body_def = b2d.default_body_def()
    ground_id = b2d.create_body(world, body_def)

    local points = {
        {1, 0},
        {-1, 0},
        {-1, -1},
        {1, -1},
    }

    local chain_def = b2d.default_chain_def()
    chain_def.points = points
    chain_def.count = #points
    chain_def.isLoop = true
    b2d.create_chain(ground_id, chain_def)

    -- Character (kinematic)
    body_def = b2d.default_body_def()
    body_def.type = b2d.BodyType.KINEMATICBODY
    body_def.position = {0, 0.103}
    local motion_locks = b2d.MotionLocks()
    motion_locks.angularZ = true
    body_def.motionLocks = motion_locks
    character_id = b2d.create_body(world, body_def)

    local shape_def = b2d.default_shape_def()
    local box = b2d.make_box(0.1, 0.1)
    b2d.create_polygon_shape(character_id, shape_def, box)
end

function M.update(world, dt)
    local app = require("sokol.app")

    -- Handle input
    if app.key_pressed(app.Keycode.A) then
        velocity[1] = velocity[1] - dt * 5
    end
    if app.key_pressed(app.Keycode.D) then
        velocity[1] = velocity[1] + dt * 5
    end
    if app.key_pressed(app.Keycode.S) then
        velocity[2] = velocity[2] - dt * 5
    end
    if app.key_pressed(app.Keycode.W) then
        velocity[2] = velocity[2] + dt * 5
    end

    -- Apply velocity friction
    velocity[1] = velocity[1] * 0.95
    velocity[2] = velocity[2] * 0.95

    -- Move character
    if character_id and b2d.body_is_valid(character_id) then
        local pos = b2d.body_get_position(character_id)
        local new_pos = {pos[1] + velocity[1] * dt, pos[2] + velocity[2] * dt}
        b2d.body_set_transform(character_id, new_pos, {1, 0})
    end
end

function M.on_key(key, world)
    local app = require("sokol.app")

    if key == app.Keycode.A then
        velocity[1] = -1
    elseif key == app.Keycode.D then
        velocity[1] = 1
    elseif key == app.Keycode.W then
        velocity[2] = 1
    elseif key == app.Keycode.S then
        velocity[2] = -1
    end
end

function M.render(camera, world)
    -- Draw chain shape
    local points = {{1, 0}, {-1, 0}, {-1, -1}, {1, -1}}
    for i = 1, #points do
        local j = i % #points + 1
        draw.line(points[i][1], points[i][2], points[j][1], points[j][2], draw.colors.static)
    end

    -- Draw character
    if character_id and b2d.body_is_valid(character_id) then
        local pos = b2d.body_get_position(character_id)
        draw.solid_box(pos[1], pos[2], 0.1, 0.1, 0, {0.3, 0.7, 0.3, 1})
        draw.box(pos[1], pos[2], 0.1, 0.1, 0, {0, 0, 0, 1})
    end
end

function M.cleanup()
    ground_id = nil
    character_id = nil
    velocity = {0, 0}
end

return M
