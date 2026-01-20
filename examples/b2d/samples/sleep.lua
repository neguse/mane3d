-- sleep.lua - Demo of body sleeping and waking
local b2d = require("b2d")
local draw = require("examples.b2d.draw")

local M = {}

M.camera = {
    center_x = 0,
    center_y = 6,
    zoom = 15,
}

local ground_id = nil
local bodies = {}

function M.create_scene(world)
    bodies = {}

    -- Ground (thin box instead of segment)
    local body_def = b2d.default_body_def()
    body_def.position = {0, -0.1}
    ground_id = b2d.create_body(world, body_def)

    local shape_def = b2d.default_shape_def()
    local ground_box = b2d.make_box(40, 0.1)
    b2d.create_polygon_shape(ground_id, shape_def, ground_box)

    -- Sleeping body (starts asleep)
    body_def = b2d.default_body_def()
    body_def.type = b2d.BodyType.DYNAMICBODY
    body_def.position = {-6, 3}
    body_def.isAwake = false
    local sleeping_body = b2d.create_body(world, body_def)

    shape_def = b2d.default_shape_def()
    local box = b2d.make_box(1, 1)
    b2d.create_polygon_shape(sleeping_body, shape_def, box)
    table.insert(bodies, {id = sleeping_body, hw = 1, hh = 1, label = "Starts asleep"})

    -- Body with sleep disabled (starts asleep but will wake immediately)
    body_def = b2d.default_body_def()
    body_def.type = b2d.BodyType.DYNAMICBODY
    body_def.position = {0, 3}
    body_def.isAwake = false
    body_def.enableSleep = false
    local no_sleep_body = b2d.create_body(world, body_def)

    shape_def = b2d.default_shape_def()
    local circle = b2d.Circle({center = {x = 0, y = 0}, radius = 1})
    b2d.create_circle_shape(no_sleep_body, shape_def, circle)
    table.insert(bodies, {id = no_sleep_body, radius = 1, label = "Sleep disabled"})

    -- Normal awake body
    body_def = b2d.default_body_def()
    body_def.type = b2d.BodyType.DYNAMICBODY
    body_def.position = {6, 3}
    local awake_body = b2d.create_body(world, body_def)

    shape_def = b2d.default_shape_def()
    b2d.create_polygon_shape(awake_body, shape_def, box)
    table.insert(bodies, {id = awake_body, hw = 1, hh = 1, label = "Normal"})

    -- Falling body to wake up the sleeping body
    body_def = b2d.default_body_def()
    body_def.type = b2d.BodyType.DYNAMICBODY
    body_def.position = {-6, 10}
    local falling_body = b2d.create_body(world, body_def)

    shape_def = b2d.default_shape_def()
    local small_box = b2d.make_box(0.5, 0.5)
    b2d.create_polygon_shape(falling_body, shape_def, small_box)
    table.insert(bodies, {id = falling_body, hw = 0.5, hh = 0.5, label = "Waker"})
end

function M.render(camera, world)
    -- Ground
    draw.solid_box(0, -0.1, 40, 0.1, 0, draw.colors.static)

    -- Bodies
    for _, body in ipairs(bodies) do
        local awake = b2d.body_is_awake(body.id)
        local color = awake and draw.colors.dynamic or draw.colors.sleeping
        local pos = b2d.body_get_position(body.id)
        local rot = b2d.body_get_rotation(body.id)

        if body.radius then
            draw.solid_circle_axis(pos[1], pos[2], body.radius, rot, color)
        else
            local angle = b2d.rot_get_angle(rot)
            draw.solid_box(pos[1], pos[2], body.hw, body.hh, angle, color)
            draw.box(pos[1], pos[2], body.hw, body.hh, angle, {0, 0, 0, 1})
        end
    end
end

function M.cleanup()
    ground_id = nil
    bodies = {}
end

return M
