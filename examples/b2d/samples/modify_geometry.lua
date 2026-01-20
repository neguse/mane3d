-- modify_geometry.lua - Box2D official Modify Geometry sample
-- Demonstrates modifying shape geometry at runtime
local b2d = require("b2d")
local draw = require("examples.b2d.draw")

local M = {}

M.camera = {
    center_x = 0,
    center_y = 5,
    zoom = 6.25,
}

M.controls = "1-3: Change shape, +/-: Scale"

local ground_id = nil
local kinematic_body = nil
local dynamic_body = nil
local shape_id = nil
local current_shape = 1  -- 1=circle, 2=box, 3=capsule
local scale = 1

function M.create_scene(world)
    -- Ground
    local body_def = b2d.default_body_def()
    ground_id = b2d.create_body(world, body_def)

    local shape_def = b2d.default_shape_def()
    local box = b2d.make_offset_box(10, 1, {0, -1}, {1, 0})
    b2d.create_polygon_shape(ground_id, shape_def, box)

    -- Dynamic body on top
    body_def = b2d.default_body_def()
    body_def.type = b2d.BodyType.DYNAMICBODY
    body_def.position = {0, 4}
    dynamic_body = b2d.create_body(world, body_def)

    box = b2d.make_box(1, 1)
    b2d.create_polygon_shape(dynamic_body, shape_def, box)

    -- Kinematic body (the one we'll modify)
    body_def = b2d.default_body_def()
    body_def.type = b2d.BodyType.KINEMATICBODY
    body_def.position = {0, 1}
    kinematic_body = b2d.create_body(world, body_def)

    local circle = b2d.Circle({center = {0, 0}, radius = 0.5})
    shape_id = b2d.create_circle_shape(kinematic_body, shape_def, circle)
    current_shape = 1
    scale = 1
end

function M.on_key(key, world)
    local app = require("sokol.app")

    if key == app.Keycode.KP_1 or key == app.Keycode.N1 then
        current_shape = 1
    elseif key == app.Keycode.KP_2 or key == app.Keycode.N2 then
        current_shape = 2
    elseif key == app.Keycode.KP_3 or key == app.Keycode.N3 then
        current_shape = 3
    elseif key == app.Keycode.EQUAL or key == app.Keycode.KP_ADD then
        scale = math.min(scale + 0.1, 2)
    elseif key == app.Keycode.MINUS or key == app.Keycode.KP_SUBTRACT then
        scale = math.max(scale - 0.1, 0.3)
    end
end

function M.render(camera, world)
    -- Draw ground
    draw.solid_box(0, -1, 10, 1, 0, draw.colors.static)
    draw.box(0, -1, 10, 1, 0, {0, 0, 0, 1})

    -- Draw kinematic body based on current shape
    if kinematic_body and b2d.body_is_valid(kinematic_body) then
        local pos = b2d.body_get_position(kinematic_body)
        local color = {0.4, 0.6, 0.8, 1}

        if current_shape == 1 then
            draw.solid_circle(pos[1], pos[2], 0.5 * scale, color)
            draw.circle(pos[1], pos[2], 0.5 * scale, {0, 0, 0, 1})
        elseif current_shape == 2 then
            draw.solid_box(pos[1], pos[2], 0.5 * scale, 0.5 * scale, 0, color)
            draw.box(pos[1], pos[2], 0.5 * scale, 0.5 * scale, 0, {0, 0, 0, 1})
        else
            -- Capsule approximation
            draw.solid_circle(pos[1], pos[2] + 0.3 * scale, 0.2 * scale, color)
            draw.solid_circle(pos[1], pos[2] - 0.3 * scale, 0.2 * scale, color)
            draw.solid_box(pos[1], pos[2], 0.2 * scale, 0.3 * scale, 0, color)
        end
    end

    -- Draw dynamic body
    if dynamic_body and b2d.body_is_valid(dynamic_body) then
        local pos = b2d.body_get_position(dynamic_body)
        local rot = b2d.body_get_rotation(dynamic_body)
        local angle = b2d.rot_get_angle(rot)
        local color = b2d.body_is_awake(dynamic_body) and draw.colors.dynamic or draw.colors.sleeping
        draw.solid_box(pos[1], pos[2], 1, 1, angle, color)
        draw.box(pos[1], pos[2], 1, 1, angle, {0, 0, 0, 1})
    end
end

function M.cleanup()
    ground_id = nil
    kinematic_body = nil
    dynamic_body = nil
    shape_id = nil
end

return M
