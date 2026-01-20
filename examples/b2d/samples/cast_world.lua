-- cast_world.lua - Box2D official Cast World sample
-- Demonstrates ray and shape casting against the world.
local b2d = require("b2d")
local draw = require("examples.b2d.draw")

local M = {}

M.camera = {
    center_x = 0,
    center_y = 5,
    zoom = 20,
}

local ground_id = nil
local body_ids = {}
local ray_start = {-15, 5}
local ray_end = {15, 5}

function M.create_scene(world)
    body_ids = {}

    -- Ground
    local body_def = b2d.default_body_def()
    ground_id = b2d.create_body(world, body_def)

    local shape_def = b2d.default_shape_def()
    local segment = b2d.Segment({point1 = {-20, 0}, point2 = {20, 0}})
    b2d.create_segment_shape(ground_id, shape_def, segment)

    -- Create various shapes
    -- Circles
    for i = 1, 3 do
        body_def = b2d.default_body_def()
        body_def.type = b2d.BodyType.DYNAMICBODY
        body_def.position = {-10 + i * 5, 5}
        local body_id = b2d.create_body(world, body_def)

        local circle = b2d.Circle({center = {0, 0}, radius = 1})
        b2d.create_circle_shape(body_id, shape_def, circle)
        table.insert(body_ids, body_id)
    end

    -- Boxes
    for i = 1, 3 do
        body_def = b2d.default_body_def()
        body_def.type = b2d.BodyType.DYNAMICBODY
        body_def.position = {-8 + i * 4, 2}
        local body_id = b2d.create_body(world, body_def)

        local box = b2d.make_box(0.8, 0.8)
        b2d.create_polygon_shape(body_id, shape_def, box)
        table.insert(body_ids, body_id)
    end
end

M.controls = "Click to set ray start/end"

function M.on_mouse_down(wx, wy, button, world, camera)
    if button == 0 then
        ray_start = {wx, wy}
    else
        ray_end = {wx, wy}
    end
end

function M.render(camera, world)
    -- Draw ground
    draw.line(-20, 0, 20, 0, draw.colors.static)

    -- Draw bodies
    for _, body_id in ipairs(body_ids) do
        if b2d.body_is_valid(body_id) then
            local pos = b2d.body_get_position(body_id)
            local rot = b2d.body_get_rotation(body_id)
            local angle = b2d.rot_get_angle(rot)
            local color = b2d.body_is_awake(body_id) and draw.colors.dynamic or draw.colors.sleeping

            -- Simplified - draw as circles
            draw.solid_circle(pos[1], pos[2], 0.8, color)
            draw.circle(pos[1], pos[2], 0.8, {0, 0, 0, 1})
        end
    end

    -- Draw ray
    draw.line(ray_start[1], ray_start[2], ray_end[1], ray_end[2], {1, 1, 0, 1})
    draw.point(ray_start[1], ray_start[2], 6, {0, 1, 0, 1})
    draw.point(ray_end[1], ray_end[2], 6, {1, 0, 0, 1})

    -- Perform ray cast
    local direction = {ray_end[1] - ray_start[1], ray_end[2] - ray_start[2]}
    local length = math.sqrt(direction[1]^2 + direction[2]^2)

    if length > 0 then
        local result = b2d.world_cast_ray_closest(world, ray_start, direction, b2d.default_query_filter())

        if result and result.hit then
            -- Draw hit point
            draw.point(result.point[1], result.point[2], 10, {1, 0, 0, 1})

            -- Draw normal
            local nx, ny = result.point[1] + result.normal[1] * 0.5, result.point[2] + result.normal[2] * 0.5
            draw.line(result.point[1], result.point[2], nx, ny, {0, 0, 1, 1})
        end
    end
end

function M.cleanup()
    ground_id = nil
    body_ids = {}
    ray_start = {-15, 5}
    ray_end = {15, 5}
end

return M
