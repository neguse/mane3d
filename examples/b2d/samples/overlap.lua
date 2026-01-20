-- overlap.lua - Overlap query demo
local b2d = require("b2d")
local draw = require("examples.b2d.draw")

local M = {}

M.camera = {
    center_x = 0,
    center_y = 6,
    zoom = 18,
}

M.controls = "Mouse: Move query area"

local ground_id = nil
local bodies = {}
local query_center = {0, 5}
local query_radius = 3
local overlapping_bodies = {}

function M.create_scene(world)
    bodies = {}
    overlapping_bodies = {}
    query_center = {0, 5}
    query_radius = 3

    -- Ground (thin box instead of segment)
    local body_def = b2d.default_body_def()
    body_def.position = {0, -0.1}
    ground_id = b2d.create_body(world, body_def)

    local shape_def = b2d.default_shape_def()
    local ground_box = b2d.make_box(20, 0.1)
    b2d.create_polygon_shape(ground_id, shape_def, ground_box)

    -- Create scattered shapes
    math.randomseed(42)
    for i = 1, 20 do
        body_def = b2d.default_body_def()
        body_def.type = b2d.BodyType.DYNAMICBODY
        body_def.position = {-10 + math.random() * 20, 2 + math.random() * 10}
        local body_id = b2d.create_body(world, body_def)

        shape_def = b2d.default_shape_def()

        local shape_type = i % 3
        if shape_type == 0 then
            local circle = b2d.Circle({center = {x = 0, y = 0}, radius = 0.3 + math.random() * 0.3})
            b2d.create_circle_shape(body_id, shape_def, circle)
            table.insert(bodies, {id = body_id, type = "circle", radius = 0.3 + (i % 5) * 0.1})
        elseif shape_type == 1 then
            local hw, hh = 0.3 + math.random() * 0.3, 0.3 + math.random() * 0.3
            local box = b2d.make_box(hw, hh)
            b2d.create_polygon_shape(body_id, shape_def, box)
            table.insert(bodies, {id = body_id, type = "box", hw = hw, hh = hh})
        else
            local capsule = b2d.Capsule({center1 = {x = 0, y = -0.3}, center2 = {x = 0, y = 0.3}, radius = 0.2})
            b2d.create_capsule_shape(body_id, shape_def, capsule)
            table.insert(bodies, {id = body_id, type = "capsule"})
        end
    end
end

local function perform_overlap_query(world)
    overlapping_bodies = {}

    -- Simple distance-based overlap check (since world_overlap_circle may not be available)
    for _, body in ipairs(bodies) do
        local pos = b2d.body_get_position(body.id)
        local dx = pos[1] - query_center[1]
        local dy = pos[2] - query_center[2]
        local dist = math.sqrt(dx * dx + dy * dy)

        -- Get approximate body radius
        local body_radius = 0.5
        if body.type == "circle" then
            body_radius = body.radius
        elseif body.type == "box" then
            body_radius = math.sqrt(body.hw^2 + body.hh^2)
        elseif body.type == "capsule" then
            body_radius = 0.5
        end

        if dist < query_radius + body_radius then
            overlapping_bodies[tostring(body.id)] = true
        end
    end
end

function M.on_mouse_move(wx, wy, world, camera)
    query_center = {wx, wy}
end

function M.on_scroll(scroll_y, world, camera)
    query_radius = math.max(0.5, math.min(10, query_radius + scroll_y * 0.5))
end

function M.update(world, dt)
    perform_overlap_query(world)
end

function M.render(camera, world)
    -- Ground
    draw.solid_box(0, -0.1, 20, 0.1, 0, draw.colors.static)

    -- Draw query circle
    draw.circle(query_center[1], query_center[2], query_radius, {0, 1, 1, 0.5}, 32)

    -- Draw bodies
    for _, body in ipairs(bodies) do
        local pos = b2d.body_get_position(body.id)
        local rot = b2d.body_get_rotation(body.id)
        local angle = b2d.rot_get_angle(rot)

        local is_overlapping = overlapping_bodies[tostring(body.id)]
        local color = is_overlapping and {1, 0.5, 0, 1} or draw.colors.dynamic

        if body.type == "circle" then
            draw.solid_circle_axis(pos[1], pos[2], body.radius, rot, color)
        elseif body.type == "box" then
            draw.solid_box(pos[1], pos[2], body.hw, body.hh, angle, color)
            draw.box(pos[1], pos[2], body.hw, body.hh, angle, {0, 0, 0, 1})
        elseif body.type == "capsule" then
            local c, s = rot[1], rot[2]
            local p1 = {pos[1] + 0 * c - (-0.3) * s, pos[2] + 0 * s + (-0.3) * c}
            local p2 = {pos[1] + 0 * c - 0.3 * s, pos[2] + 0 * s + 0.3 * c}
            draw.solid_capsule(p1, p2, 0.2, color)
            draw.capsule(p1, p2, 0.2, {0, 0, 0, 1})
        end
    end
end

function M.cleanup()
    ground_id = nil
    bodies = {}
    overlapping_bodies = {}
end

return M
