-- pivot.lua - Box2D official Pivot sample
-- Demonstrates pivot velocity calculation for a rotating body.
local b2d = require("b2d")
local draw = require("examples.b2d.draw")

local M = {}

M.camera = {
    center_x = 0.8,
    center_y = 6.4,
    zoom = 10,
}

local ground_id = nil
local body_id = nil
local lever = 3.0

function M.create_scene(world)
    -- Ground
    local body_def = b2d.default_body_def()
    ground_id = b2d.create_body(world, body_def)

    local shape_def = b2d.default_shape_def()
    local segment = b2d.Segment({point1 = {-20, 0}, point2 = {20, 0}})
    b2d.create_segment_shape(ground_id, shape_def, segment)

    -- Dynamic body (rotating stick)
    local v = {5, 0}  -- Initial velocity

    body_def = b2d.default_body_def()
    body_def.type = b2d.BodyType.DYNAMICBODY
    body_def.position = {0, 3}
    body_def.gravityScale = 1
    body_def.linearVelocity = v

    body_id = b2d.create_body(world, body_def)

    -- Calculate angular velocity for pivot point
    local r = {0, -lever}
    -- omega = cross(v, r) / dot(r, r)
    local cross_vr = v[1] * r[2] - v[2] * r[1]
    local dot_rr = r[1] * r[1] + r[2] * r[2]
    local omega = cross_vr / dot_rr

    b2d.body_set_angular_velocity(body_id, omega)

    -- Create thin box shape
    local box = b2d.make_box(0.1, lever)
    b2d.create_polygon_shape(body_id, shape_def, box)
end

function M.render(camera, world)
    -- Draw ground
    draw.line(-20, 0, 20, 0, draw.colors.static)

    -- Draw body
    if body_id and b2d.body_is_valid(body_id) then
        local pos = b2d.body_get_position(body_id)
        local rot = b2d.body_get_rotation(body_id)
        local angle = b2d.rot_get_angle(rot)

        local color = b2d.body_is_awake(body_id) and draw.colors.dynamic or draw.colors.sleeping
        draw.solid_box(pos[1], pos[2], 0.1, lever, angle, color)
        draw.box(pos[1], pos[2], 0.1, lever, angle, {0, 0, 0, 1})

        -- Draw pivot point (bottom of stick)
        local world_r = b2d.body_get_world_vector(body_id, {0, -lever})
        local pivot_x = pos[1] + world_r[1]
        local pivot_y = pos[2] + world_r[2]
        draw.point(pivot_x, pivot_y, 5, {1, 0, 0, 1})

        -- Calculate and display pivot velocity
        local v = b2d.body_get_linear_velocity(body_id)
        local omega = b2d.body_get_angular_velocity(body_id)

        -- vp = v + cross(omega, r)
        local vp_x = v[1] - omega * world_r[2]
        local vp_y = v[2] + omega * world_r[1]

        -- Draw velocity vector at pivot
        local scale = 0.1
        draw.line(pivot_x, pivot_y, pivot_x + vp_x * scale, pivot_y + vp_y * scale, {0, 1, 0, 1})
    end
end

function M.cleanup()
    ground_id = nil
    body_id = nil
end

return M
