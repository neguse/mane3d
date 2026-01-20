-- ray_cast.lua - Ray casting demo
local b2d = require("b2d")
local draw = require("examples.b2d.draw")
local app = require("sokol.app")

local M = {}

M.camera = {
    center_x = 0,
    center_y = 6,
    zoom = 15,
}

M.controls = "Drag: Move ray endpoints"

local ground_id = nil
local bodies = {}
local ray_start = {-10, 5}
local ray_end = {10, 5}
local dragging = false

function M.create_scene(world)
    bodies = {}
    ray_start = {-10, 5}
    ray_end = {10, 5}
    dragging = false

    -- Ground (thin box instead of segment)
    local body_def = b2d.default_body_def()
    body_def.position = {0, -0.1}
    ground_id = b2d.create_body(world, body_def)

    local shape_def = b2d.default_shape_def()
    local ground_box = b2d.make_box(20, 0.1)
    b2d.create_polygon_shape(ground_id, shape_def, ground_box)

    -- Create various shapes to cast rays against
    -- Circle
    body_def = b2d.default_body_def()
    body_def.type = b2d.BodyType.STATICBODY
    body_def.position = {-5, 5}
    local circle_body = b2d.create_body(world, body_def)

    shape_def = b2d.default_shape_def()
    local circle = b2d.Circle({center = {x = 0, y = 0}, radius = 1})
    b2d.create_circle_shape(circle_body, shape_def, circle)
    table.insert(bodies, {id = circle_body, type = "circle", radius = 1})

    -- Box
    body_def.position = {0, 5}
    local box_body = b2d.create_body(world, body_def)

    local box = b2d.make_box(1, 1)
    b2d.create_polygon_shape(box_body, shape_def, box)
    table.insert(bodies, {id = box_body, type = "box", hw = 1, hh = 1})

    -- Capsule
    body_def.position = {5, 5}
    local capsule_body = b2d.create_body(world, body_def)

    local capsule = b2d.Capsule({center1 = {x = 0, y = -1}, center2 = {x = 0, y = 1}, radius = 0.5})
    b2d.create_capsule_shape(capsule_body, shape_def, capsule)
    table.insert(bodies, {id = capsule_body, type = "capsule"})

    -- Dynamic bodies
    for i = 1, 3 do
        body_def = b2d.default_body_def()
        body_def.type = b2d.BodyType.DYNAMICBODY
        body_def.position = {-3 + i * 2, 10}
        local dyn_body = b2d.create_body(world, body_def)

        shape_def = b2d.default_shape_def()
        local small_box = b2d.make_box(0.5, 0.5)
        b2d.create_polygon_shape(dyn_body, shape_def, small_box)
        table.insert(bodies, {id = dyn_body, type = "dynamic_box", hw = 0.5, hh = 0.5})
    end
end

function M.on_mouse_down(wx, wy, button, world, camera)
    if button == app.Mousebutton.LEFT then
        local ds = math.sqrt((wx - ray_start[1])^2 + (wy - ray_start[2])^2)
        local de = math.sqrt((wx - ray_end[1])^2 + (wy - ray_end[2])^2)
        if ds < 0.5 then
            dragging = "start"
        elseif de < 0.5 then
            dragging = "end"
        end
    end
end

function M.on_mouse_up(wx, wy, button, world, camera)
    dragging = false
end

function M.on_mouse_move(wx, wy, world, camera)
    if dragging == "start" then
        ray_start = {wx, wy}
    elseif dragging == "end" then
        ray_end = {wx, wy}
    end
end

function M.render(camera, world)
    -- Ground
    draw.solid_box(0, -0.1, 20, 0.1, 0, draw.colors.static)

    -- Draw bodies
    for _, body in ipairs(bodies) do
        local pos = b2d.body_get_position(body.id)
        local rot = b2d.body_get_rotation(body.id)
        local c, s = rot[1], rot[2]
        local angle = b2d.rot_get_angle(rot)

        local color
        if body.type == "dynamic_box" then
            color = b2d.body_is_awake(body.id) and draw.colors.dynamic or draw.colors.sleeping
        else
            color = draw.colors.static
        end

        if body.type == "circle" then
            draw.solid_circle_axis(pos[1], pos[2], body.radius, rot, color)
        elseif body.type == "box" or body.type == "dynamic_box" then
            draw.solid_box(pos[1], pos[2], body.hw, body.hh, angle, color)
            draw.box(pos[1], pos[2], body.hw, body.hh, angle, {0, 0, 0, 1})
        elseif body.type == "capsule" then
            local p1 = {pos[1] + 0 * c - (-1) * s, pos[2] + 0 * s + (-1) * c}
            local p2 = {pos[1] + 0 * c - 1 * s, pos[2] + 0 * s + 1 * c}
            draw.solid_capsule(p1, p2, 0.5, draw.colors.static)
            draw.capsule(p1, p2, 0.5, {0, 0, 0, 1})
        end
    end

    -- Draw ray
    draw.line(ray_start[1], ray_start[2], ray_end[1], ray_end[2], {1, 1, 0, 1})

    -- Simple ray-circle intersection check (since world_cast_ray_closest may not be available)
    local ray_dx = ray_end[1] - ray_start[1]
    local ray_dy = ray_end[2] - ray_start[2]
    local ray_len = math.sqrt(ray_dx * ray_dx + ray_dy * ray_dy)
    if ray_len > 0 then
        local dir_x, dir_y = ray_dx / ray_len, ray_dy / ray_len

        local closest_t = ray_len
        local hit_body = nil

        for _, body in ipairs(bodies) do
            local pos = b2d.body_get_position(body.id)
            local radius = 0
            if body.type == "circle" then
                radius = body.radius
            elseif body.type == "box" or body.type == "dynamic_box" then
                radius = math.sqrt(body.hw^2 + body.hh^2)
            elseif body.type == "capsule" then
                radius = 1.5
            end

            -- Simple circle intersection
            local ox = pos[1] - ray_start[1]
            local oy = pos[2] - ray_start[2]
            local proj = ox * dir_x + oy * dir_y
            if proj > 0 and proj < closest_t then
                local perp_x = ox - proj * dir_x
                local perp_y = oy - proj * dir_y
                local perp_dist = math.sqrt(perp_x * perp_x + perp_y * perp_y)
                if perp_dist < radius then
                    local t = proj - math.sqrt(radius * radius - perp_dist * perp_dist)
                    if t > 0 and t < closest_t then
                        closest_t = t
                        hit_body = body
                    end
                end
            end
        end

        if hit_body then
            local hit_x = ray_start[1] + dir_x * closest_t
            local hit_y = ray_start[2] + dir_y * closest_t
            draw.solid_circle(hit_x, hit_y, 0.15, {1, 0, 0, 1})
        end
    end

    -- Draw ray endpoints
    draw.solid_circle(ray_start[1], ray_start[2], 0.2, {0, 1, 1, 1})
    draw.solid_circle(ray_end[1], ray_end[2], 0.2, {1, 0, 1, 1})
end

function M.cleanup()
    ground_id = nil
    bodies = {}
    dragging = false
end

return M
