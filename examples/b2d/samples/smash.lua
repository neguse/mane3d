-- smash.lua - Box2D official Smash Benchmark sample
-- Heavy object smashing through stack
local b2d = require("b2d")
local draw = require("examples.b2d.draw")

local M = {}

M.camera = {
    center_x = 0,
    center_y = 15,
    zoom = 40,
}

M.controls = "Space: Drop smash ball"

local ground_id = nil
local body_ids = {}
local smash_ball = nil

function M.create_scene(world)
    body_ids = {}
    smash_ball = nil

    -- Ground
    local body_def = b2d.default_body_def()
    ground_id = b2d.create_body(world, body_def)

    local shape_def = b2d.default_shape_def()
    local segment = b2d.Segment({point1 = {-30, 0}, point2 = {30, 0}})
    b2d.create_segment_shape(ground_id, shape_def, segment)

    -- Build a tower of boxes
    local rows = 15
    local cols = 6
    local box_size = 0.8

    local box = b2d.make_box(box_size, box_size)

    for row = 0, rows - 1 do
        for col = 0, cols - 1 do
            body_def = b2d.default_body_def()
            body_def.type = b2d.BodyType.DYNAMICBODY
            body_def.position = {
                (col - cols / 2 + 0.5) * box_size * 2,
                box_size + row * box_size * 2
            }
            local body = b2d.create_body(world, body_def)
            b2d.create_polygon_shape(body, shape_def, box)
            table.insert(body_ids, body)
        end
    end
end

function M.on_key(key, world)
    local app = require("sokol.app")

    if key == app.Keycode.SPACE and not smash_ball then
        -- Create heavy smash ball
        local body_def = b2d.default_body_def()
        body_def.type = b2d.BodyType.DYNAMICBODY
        body_def.position = {0, 40}
        body_def.linearVelocity = {0, -50}
        body_def.isBullet = true
        smash_ball = b2d.create_body(world, body_def)

        local shape_def = b2d.default_shape_def()
        shape_def.density = 10
        local circle = b2d.Circle({center = {0, 0}, radius = 2})
        b2d.create_circle_shape(smash_ball, shape_def, circle)
    end
end

function M.render(camera, world)
    -- Draw ground
    draw.line(-30, 0, 30, 0, draw.colors.static)

    -- Draw tower boxes
    for _, body_id in ipairs(body_ids) do
        if b2d.body_is_valid(body_id) then
            local pos = b2d.body_get_position(body_id)
            local rot = b2d.body_get_rotation(body_id)
            local angle = b2d.rot_get_angle(rot)
            local color = b2d.body_is_awake(body_id) and draw.colors.dynamic or draw.colors.sleeping
            draw.solid_box(pos[1], pos[2], 0.8, 0.8, angle, color)
        end
    end

    -- Draw smash ball
    if smash_ball and b2d.body_is_valid(smash_ball) then
        local pos = b2d.body_get_position(smash_ball)
        draw.solid_circle(pos[1], pos[2], 2, {0.9, 0.2, 0.2, 1})
        draw.circle(pos[1], pos[2], 2, {0, 0, 0, 1})
    end
end

function M.cleanup()
    ground_id = nil
    body_ids = {}
    smash_ball = nil
end

return M
