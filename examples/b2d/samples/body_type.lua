-- body_type.lua - Demo of static, kinematic, and dynamic bodies
local b2d = require("b2d")
local draw = require("examples.b2d.draw")

local M = {}

M.camera = {
    center_x = 0,
    center_y = 8,
    zoom = 12,
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
    local ground_box = b2d.make_box(20, 0.1)
    b2d.create_polygon_shape(ground_id, shape_def, ground_box)

    -- Static body (blue)
    body_def = b2d.default_body_def()
    body_def.type = b2d.BodyType.STATICBODY
    body_def.position = {-8, 2}
    local static_body = b2d.create_body(world, body_def)

    shape_def = b2d.default_shape_def()
    local box = b2d.make_box(1, 1)
    b2d.create_polygon_shape(static_body, shape_def, box)
    table.insert(bodies, {id = static_body, type = "static", hw = 1, hh = 1})

    -- Kinematic body (green) - moves left and right
    body_def = b2d.default_body_def()
    body_def.type = b2d.BodyType.KINEMATICBODY
    body_def.position = {0, 5}
    body_def.linearVelocity = {3, 0}
    local kinematic_body = b2d.create_body(world, body_def)

    shape_def = b2d.default_shape_def()
    local platform = b2d.make_box(4, 0.5)
    b2d.create_polygon_shape(kinematic_body, shape_def, platform)
    table.insert(bodies, {id = kinematic_body, type = "kinematic", hw = 4, hh = 0.5})

    -- Dynamic bodies (yellow/orange)
    for i = 1, 5 do
        body_def = b2d.default_body_def()
        body_def.type = b2d.BodyType.DYNAMICBODY
        body_def.position = {-2 + i * 1.2, 8 + i * 0.5}

        local dynamic_body = b2d.create_body(world, body_def)

        shape_def = b2d.default_shape_def()
        local dbox = b2d.make_box(0.5, 0.5)
        b2d.create_polygon_shape(dynamic_body, shape_def, dbox)
        table.insert(bodies, {id = dynamic_body, type = "dynamic", hw = 0.5, hh = 0.5})
    end
end

function M.update(world, dt)
    -- Update kinematic body (bounce at edges)
    for _, body in ipairs(bodies) do
        if body.type == "kinematic" then
            local pos = b2d.body_get_position(body.id)
            local vel = b2d.body_get_linear_velocity(body.id)
            if (pos[1] < -10 and vel[1] < 0) or (pos[1] > 10 and vel[1] > 0) then
                b2d.body_set_linear_velocity(body.id, {-vel[1], vel[2]})
            end
        end
    end
end

function M.render(camera, world)
    -- Ground
    draw.solid_box(0, -0.1, 20, 0.1, 0, draw.colors.static)

    -- Bodies with different colors based on type
    for _, body in ipairs(bodies) do
        local color
        if body.type == "static" then
            color = {0.5, 0.5, 0.9, 1}  -- Blue
        elseif body.type == "kinematic" then
            color = {0.5, 0.9, 0.5, 1}  -- Green
        else
            color = b2d.body_is_awake(body.id) and draw.colors.dynamic or draw.colors.sleeping
        end
        local pos = b2d.body_get_position(body.id)
        local rot = b2d.body_get_rotation(body.id)
        local angle = b2d.rot_get_angle(rot)
        draw.solid_box(pos[1], pos[2], body.hw, body.hh, angle, color)
        draw.box(pos[1], pos[2], body.hw, body.hh, angle, {0, 0, 0, 1})
    end
end

function M.cleanup()
    ground_id = nil
    bodies = {}
end

return M
