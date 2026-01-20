-- wake_touching.lua - Box2D official Wake Touching sample
-- Demonstrates waking bodies that are touching a specific body
local b2d = require("b2d")
local draw = require("examples.b2d.draw")

local M = {}

M.camera = {
    center_x = 0,
    center_y = 4,
    zoom = 8,
}

M.controls = "W: Wake all touching bodies"

local ground_id = nil
local body_ids = {}
local count = 10

function M.create_scene(world)
    body_ids = {}

    -- Ground
    local body_def = b2d.default_body_def()
    ground_id = b2d.create_body(world, body_def)

    local shape_def = b2d.default_shape_def()
    local segment = b2d.Segment({point1 = {-20, 0}, point2 = {20, 0}})
    b2d.create_segment_shape(ground_id, shape_def, segment)

    -- Create row of boxes
    body_def = b2d.default_body_def()
    body_def.type = b2d.BodyType.DYNAMICBODY

    local box = b2d.make_box(0.5, 0.5)
    local x = -1 * (count - 1)

    for i = 1, count do
        body_def.position = {x, 4}
        local body_id = b2d.create_body(world, body_def)
        b2d.create_polygon_shape(body_id, shape_def, box)
        table.insert(body_ids, body_id)
        x = x + 2
    end
end

function M.on_key(key, world)
    local app = require("sokol.app")

    if key == app.Keycode.W then
        -- Wake all bodies touching the ground
        if ground_id and b2d.body_is_valid(ground_id) then
            b2d.body_wake_touching(ground_id)
        end
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
            draw.solid_box(pos[1], pos[2], 0.5, 0.5, angle, color)
            draw.box(pos[1], pos[2], 0.5, 0.5, angle, {0, 0, 0, 1})
        end
    end
end

function M.cleanup()
    ground_id = nil
    body_ids = {}
end

return M
