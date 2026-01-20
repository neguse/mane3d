-- bad_body.lua - Box2D official Bad Body sample
-- A dynamic body with no mass behaves like kinematic body
local b2d = require("b2d")
local draw = require("examples.b2d.draw")

local M = {}

M.camera = {
    center_x = 0,
    center_y = 5,
    zoom = 15,
}

local ground_id = nil
local bad_body_id = nil
local normal_body_id = nil

function M.create_scene(world)
    -- Ground
    local body_def = b2d.default_body_def()
    ground_id = b2d.create_body(world, body_def)

    local shape_def = b2d.default_shape_def()
    local segment = b2d.Segment({point1 = {-20, 0}, point2 = {20, 0}})
    b2d.create_segment_shape(ground_id, shape_def, segment)

    -- Bad body - dynamic but no shapes (no mass)
    body_def = b2d.default_body_def()
    body_def.type = b2d.BodyType.DYNAMICBODY
    body_def.position = {-2, 5}
    bad_body_id = b2d.create_body(world, body_def)
    -- Note: No shape added, so no mass - this is the "bad" body

    -- Normal body for comparison
    body_def = b2d.default_body_def()
    body_def.type = b2d.BodyType.DYNAMICBODY
    body_def.position = {2, 3}
    body_def.rotation = b2d.make_rot(0.25 * math.pi)
    normal_body_id = b2d.create_body(world, body_def)

    local capsule = b2d.Capsule({center1 = {0, -1}, center2 = {0, 1}, radius = 1})
    b2d.create_capsule_shape(normal_body_id, shape_def, capsule)
end

function M.update(world, dt)
    -- Apply force to bad body (won't move because no mass)
    if bad_body_id and b2d.body_is_valid(bad_body_id) then
        b2d.body_apply_force_to_center(bad_body_id, {0, 10}, true)
    end
end

function M.render(camera, world)
    -- Draw ground
    draw.line(-20, 0, 20, 0, draw.colors.static)

    -- Draw bad body position (just a marker)
    if bad_body_id and b2d.body_is_valid(bad_body_id) then
        local pos = b2d.body_get_position(bad_body_id)
        draw.point(pos[1], pos[2], 10, {1, 0, 0, 1})  -- Red marker
    end

    -- Draw normal body
    if normal_body_id and b2d.body_is_valid(normal_body_id) then
        local pos = b2d.body_get_position(normal_body_id)
        local rot = b2d.body_get_rotation(normal_body_id)
        local angle = b2d.rot_get_angle(rot)
        local color = b2d.body_is_awake(normal_body_id) and draw.colors.dynamic or draw.colors.sleeping

        -- Draw capsule
        local c = math.cos(angle)
        local s = math.sin(angle)
        local p1 = {pos[1] + s, pos[2] - c}
        local p2 = {pos[1] - s, pos[2] + c}
        draw.solid_circle(p1[1], p1[2], 1, color)
        draw.solid_circle(p2[1], p2[2], 1, color)
        draw.circle(p1[1], p1[2], 1, {0, 0, 0, 1})
        draw.circle(p2[1], p2[2], 1, {0, 0, 0, 1})
    end
end

function M.cleanup()
    ground_id = nil
    bad_body_id = nil
    normal_body_id = nil
end

return M
