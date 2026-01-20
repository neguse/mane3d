-- shape_distance.lua - Distance between shapes demo
local b2d = require("b2d")
local draw = require("examples.b2d.draw")

local M = {}

M.camera = {
    center_x = 0,
    center_y = 2,
    zoom = 15,
}

M.controls = "Mouse: Move shape"

local bodies = {}
local moving_body_id = nil
local moving_pos = {3, 5}

function M.create_scene(world)
    bodies = {}
    moving_pos = {3, 5}

    -- Note: This demo uses no gravity
    -- The world is created by init.lua with gravity={0,-10}, but we can work around it

    -- Static circle
    local body_def = b2d.default_body_def()
    body_def.type = b2d.BodyType.STATICBODY
    body_def.position = {-5, 5}
    local circle_body = b2d.create_body(world, body_def)

    local shape_def = b2d.default_shape_def()
    local circle = b2d.Circle({center = {x = 0, y = 0}, radius = 1.5})
    b2d.create_circle_shape(circle_body, shape_def, circle)
    table.insert(bodies, {id = circle_body, type = "circle", radius = 1.5})

    -- Static box
    body_def.position = {-5, -2}
    local box_body = b2d.create_body(world, body_def)

    local box = b2d.make_box(2, 1)
    b2d.create_polygon_shape(box_body, shape_def, box)
    table.insert(bodies, {id = box_body, type = "box", hw = 2, hh = 1})

    -- Static capsule
    body_def.position = {5, -2}
    local capsule_body = b2d.create_body(world, body_def)

    local capsule = b2d.Capsule({center1 = {x = -1.5, y = 0}, center2 = {x = 1.5, y = 0}, radius = 0.5})
    b2d.create_capsule_shape(capsule_body, shape_def, capsule)
    table.insert(bodies, {id = capsule_body, type = "capsule_h"})

    -- Moving circle (controlled by mouse)
    body_def = b2d.default_body_def()
    body_def.type = b2d.BodyType.KINEMATICBODY
    body_def.position = {moving_pos[1], moving_pos[2]}
    moving_body_id = b2d.create_body(world, body_def)

    local moving_circle = b2d.Circle({center = {x = 0, y = 0}, radius = 1})
    b2d.create_circle_shape(moving_body_id, shape_def, moving_circle)
    table.insert(bodies, {id = moving_body_id, type = "moving_circle", radius = 1})
end

function M.on_mouse_move(wx, wy, world, camera)
    moving_pos = {wx, wy}
end

function M.update(world, dt)
    if moving_body_id then
        b2d.body_set_transform(moving_body_id, moving_pos, {1, 0})
    end
end

function M.render(camera, world)
    -- Draw bodies
    for _, body in ipairs(bodies) do
        local pos = b2d.body_get_position(body.id)
        local rot = b2d.body_get_rotation(body.id)
        local angle = b2d.rot_get_angle(rot)

        local color = body.type == "moving_circle" and {0.3, 0.9, 0.3, 1} or draw.colors.static

        if body.type == "circle" or body.type == "moving_circle" then
            draw.solid_circle_axis(pos[1], pos[2], body.radius, rot, color)
        elseif body.type == "box" then
            draw.solid_box(pos[1], pos[2], body.hw, body.hh, angle, color)
            draw.box(pos[1], pos[2], body.hw, body.hh, angle, {0, 0, 0, 1})
        elseif body.type == "capsule_h" then
            local c, s = rot[1], rot[2]
            local p1 = {pos[1] + (-1.5) * c, pos[2] + (-1.5) * s}
            local p2 = {pos[1] + 1.5 * c, pos[2] + 1.5 * s}
            draw.solid_capsule(p1, p2, 0.5, color)
            draw.capsule(p1, p2, 0.5, {0, 0, 0, 1})
        end
    end

    -- Draw distance lines from moving body to all static bodies
    local moving_pos_current = b2d.body_get_position(moving_body_id)
    for _, body in ipairs(bodies) do
        if body.id ~= moving_body_id then
            local other_pos = b2d.body_get_position(body.id)

            local dx = other_pos[1] - moving_pos_current[1]
            local dy = other_pos[2] - moving_pos_current[2]
            local dist = math.sqrt(dx * dx + dy * dy)

            local moving_radius = 1
            local other_size = 0
            if body.type == "circle" then
                other_size = body.radius
            elseif body.type == "box" then
                other_size = math.sqrt(body.hw^2 + body.hh^2)
            elseif body.type == "capsule_h" then
                other_size = 2
            end

            local edge_dist = dist - moving_radius - other_size

            local line_color
            if edge_dist < 0.5 then
                line_color = {1, 0, 0, 1}
            elseif edge_dist < 2 then
                line_color = {1, 1, 0, 1}
            else
                line_color = {0, 1, 0, 1}
            end

            draw.line(moving_pos_current[1], moving_pos_current[2],
                     other_pos[1], other_pos[2], line_color)
        end
    end
end

function M.cleanup()
    bodies = {}
    moving_body_id = nil
end

return M
