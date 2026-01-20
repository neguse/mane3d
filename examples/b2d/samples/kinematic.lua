-- kinematic.lua - Box2D official Kinematic sample
-- Demonstrates driving a kinematic body to follow a target path.
local b2d = require("b2d")
local draw = require("examples.b2d.draw")

local M = {}

M.camera = {
    center_x = 0,
    center_y = 0,
    zoom = 4,
}

local body_id = nil
local amplitude = 2.0
local time = 0

function M.create_scene(world)
    time = 0

    -- Kinematic body
    local body_def = b2d.default_body_def()
    body_def.type = b2d.BodyType.KINEMATICBODY
    body_def.position = {2 * amplitude, 0}

    body_id = b2d.create_body(world, body_def)

    local box = b2d.make_box(0.1, 1.0)
    local shape_def = b2d.default_shape_def()
    b2d.create_polygon_shape(body_id, shape_def, box)
end

function M.update(world, dt)
    time = time + dt

    -- Calculate target position (Lissajous curve)
    local target_x = 2 * amplitude * math.cos(time)
    local target_y = amplitude * math.sin(2 * time)
    local target_angle = 2 * time

    -- Set target transform for kinematic body
    local rot = b2d.make_rot(target_angle)
    local transform = b2d.Transform({
        p = {target_x, target_y},
        q = rot
    })

    b2d.body_set_target_transform(body_id, transform, dt, true)
end

function M.render(camera, world)
    -- Draw target path (Lissajous curve)
    local prev_x, prev_y = nil, nil
    for i = 0, 100 do
        local t = i * 0.1
        local x = 2 * amplitude * math.cos(t)
        local y = amplitude * math.sin(2 * t)

        if prev_x then
            draw.line(prev_x, prev_y, x, y, {0.3, 0.3, 0.5, 0.5})
        end
        prev_x, prev_y = x, y
    end

    -- Draw current target
    local target_x = 2 * amplitude * math.cos(time)
    local target_y = amplitude * math.sin(2 * time)
    draw.point(target_x, target_y, 10, {0.8, 0.2, 0.8, 1})

    -- Draw target orientation line
    local target_angle = 2 * time
    local ax = math.cos(target_angle + math.pi / 2)
    local ay = math.sin(target_angle + math.pi / 2)
    draw.line(target_x - 0.5 * ax, target_y - 0.5 * ay,
              target_x + 0.5 * ax, target_y + 0.5 * ay, {0.8, 0.2, 0.8, 1})

    -- Draw kinematic body
    if body_id and b2d.body_is_valid(body_id) then
        local pos = b2d.body_get_position(body_id)
        local rot = b2d.body_get_rotation(body_id)
        local angle = b2d.rot_get_angle(rot)

        draw.solid_box(pos[1], pos[2], 0.1, 1.0, angle, draw.colors.kinematic)
        draw.box(pos[1], pos[2], 0.1, 1.0, angle, {0, 0, 0, 1})
    end
end

function M.cleanup()
    body_id = nil
    time = 0
end

return M
