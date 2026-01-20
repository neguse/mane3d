-- circle_impulse.lua - Box2D official Circle Impulse sample
-- Demonstrates applying impulses to stacked circles.
local b2d = require("b2d")
local draw = require("examples.b2d.draw")

local M = {}

M.camera = {
    center_x = 0,
    center_y = 10,
    zoom = 25,
}

local ground_id = nil
local circle_ids = {}

function M.create_scene(world)
    circle_ids = {}

    -- Ground
    local body_def = b2d.default_body_def()
    ground_id = b2d.create_body(world, body_def)

    local shape_def = b2d.default_shape_def()
    local segment = b2d.Segment({point1 = {-20, 0}, point2 = {20, 0}})
    b2d.create_segment_shape(ground_id, shape_def, segment)

    -- Walls
    segment = b2d.Segment({point1 = {-20, 0}, point2 = {-20, 30}})
    b2d.create_segment_shape(ground_id, shape_def, segment)
    segment = b2d.Segment({point1 = {20, 0}, point2 = {20, 30}})
    b2d.create_segment_shape(ground_id, shape_def, segment)

    -- Stack of circles
    local rows = 10
    local cols = 10
    local radius = 0.5
    local spacing = 2.2 * radius

    for row = 0, rows - 1 do
        for col = 0, cols - 1 do
            body_def = b2d.default_body_def()
            body_def.type = b2d.BodyType.DYNAMICBODY
            body_def.position = {
                (col - cols / 2 + 0.5) * spacing,
                radius + row * spacing
            }
            local body_id = b2d.create_body(world, body_def)

            shape_def = b2d.default_shape_def()
            local circle = b2d.Circle({center = {0, 0}, radius = radius})
            b2d.create_circle_shape(body_id, shape_def, circle)

            table.insert(circle_ids, body_id)
        end
    end
end

M.controls = "Click: Apply impulse, Space: Explosion"

function M.on_mouse_down(wx, wy, button, world, camera)
    -- Apply impulse to nearby circles
    local impulse_strength = 50

    for _, body_id in ipairs(circle_ids) do
        if b2d.body_is_valid(body_id) then
            local pos = b2d.body_get_position(body_id)
            local dx, dy = pos[1] - wx, pos[2] - wy
            local dist = math.sqrt(dx * dx + dy * dy)

            if dist < 3 and dist > 0.1 then
                local factor = impulse_strength / dist
                b2d.body_apply_linear_impulse_to_center(body_id, {dx * factor, dy * factor}, true)
            end
        end
    end
end

function M.on_key(key, world)
    local app = require("sokol.app")

    if key == app.Keycode.SPACE then
        -- Central explosion
        local center = {0, 5}
        local impulse_strength = 100

        for _, body_id in ipairs(circle_ids) do
            if b2d.body_is_valid(body_id) then
                local pos = b2d.body_get_position(body_id)
                local dx, dy = pos[1] - center[1], pos[2] - center[2]
                local dist = math.sqrt(dx * dx + dy * dy)

                if dist > 0.1 then
                    local factor = impulse_strength / (dist + 1)
                    b2d.body_apply_linear_impulse_to_center(body_id, {dx * factor, dy * factor}, true)
                end
            end
        end
    end
end

function M.render(camera, world)
    -- Draw ground and walls
    draw.line(-20, 0, 20, 0, draw.colors.static)
    draw.line(-20, 0, -20, 30, draw.colors.static)
    draw.line(20, 0, 20, 30, draw.colors.static)

    -- Draw circles
    for _, body_id in ipairs(circle_ids) do
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
    circle_ids = {}
end

return M
