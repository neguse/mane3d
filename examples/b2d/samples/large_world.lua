-- large_world.lua - Box2D official Large World sample
-- Demonstrates simulation across a large world space.
local b2d = require("b2d")
local draw = require("examples.b2d.draw")

local M = {}

M.camera = {
    center_x = 0,
    center_y = 50,
    zoom = 100,
}

local ground_ids = {}
local body_ids = {}

function M.create_scene(world)
    ground_ids = {}
    body_ids = {}

    local shape_def = b2d.default_shape_def()

    -- Create ground segments at different locations
    local ground_positions = {
        {-100, 0}, {0, 0}, {100, 0}, {200, 0}
    }

    for _, pos in ipairs(ground_positions) do
        local body_def = b2d.default_body_def()
        body_def.position = pos
        local ground_id = b2d.create_body(world, body_def)

        local segment = b2d.Segment({point1 = {-50, 0}, point2 = {50, 0}})
        b2d.create_segment_shape(ground_id, shape_def, segment)

        table.insert(ground_ids, ground_id)
    end

    -- Create pyramids at different locations
    local pyramid_centers = {-100, 0, 100, 200}

    for _, center_x in ipairs(pyramid_centers) do
        local count = 8
        local box_size = 1

        local y = box_size
        for i = count, 1, -1 do
            local x = center_x - box_size * (i - 1)

            for j = 1, i do
                local body_def = b2d.default_body_def()
                body_def.type = b2d.BodyType.DYNAMICBODY
                body_def.position = {x, y}
                local body_id = b2d.create_body(world, body_def)

                local box = b2d.make_box(box_size, box_size)
                b2d.create_polygon_shape(body_id, shape_def, box)
                table.insert(body_ids, body_id)

                x = x + 2 * box_size
            end
            y = y + 2 * box_size
        end
    end
end

M.controls = "Arrow keys: Pan camera"

function M.on_key(key, world)
    local app = require("sokol.app")
    local pan_speed = 10

    if key == app.Keycode.LEFT then
        M.camera.center_x = M.camera.center_x - pan_speed
    elseif key == app.Keycode.RIGHT then
        M.camera.center_x = M.camera.center_x + pan_speed
    elseif key == app.Keycode.UP then
        M.camera.center_y = M.camera.center_y + pan_speed
    elseif key == app.Keycode.DOWN then
        M.camera.center_y = M.camera.center_y - pan_speed
    end
end

function M.render(camera, world)
    -- Draw grounds
    local ground_positions = {
        {-100, 0}, {0, 0}, {100, 0}, {200, 0}
    }
    for _, pos in ipairs(ground_positions) do
        draw.line(pos[1] - 50, 0, pos[1] + 50, 0, draw.colors.static)
    end

    -- Draw bodies
    for _, body_id in ipairs(body_ids) do
        if b2d.body_is_valid(body_id) then
            local pos = b2d.body_get_position(body_id)
            local rot = b2d.body_get_rotation(body_id)
            local angle = b2d.rot_get_angle(rot)
            local color = b2d.body_is_awake(body_id) and draw.colors.dynamic or draw.colors.sleeping
            draw.solid_box(pos[1], pos[2], 1, 1, angle, color)
            draw.box(pos[1], pos[2], 1, 1, angle, {0, 0, 0, 1})
        end
    end

    -- Draw world coordinate markers
    for x = -100, 200, 100 do
        draw.point(x, 0, 5, {1, 1, 0, 1})
    end
end

function M.cleanup()
    ground_ids = {}
    body_ids = {}
end

return M
