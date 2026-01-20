-- drop.lua - Box2D official Drop sample
-- Demonstrates dropping objects onto various shapes
local b2d = require("b2d")
local draw = require("examples.b2d.draw")

local M = {}

M.camera = {
    center_x = 0,
    center_y = 10,
    zoom = 25,
}

M.controls = "1-4: Scene types, Space: Drop body"

local ground_id = nil
local body_ids = {}
local scene_type = 1

local function clear_bodies(world)
    for _, body_id in ipairs(body_ids) do
        if b2d.body_is_valid(body_id) then
            b2d.destroy_body(body_id)
        end
    end
    body_ids = {}
end

local function create_ground(world)
    local body_def = b2d.default_body_def()
    ground_id = b2d.create_body(world, body_def)

    local shape_def = b2d.default_shape_def()

    if scene_type == 1 then
        -- Flat ground
        local segment = b2d.Segment({point1 = {-20, 0}, point2 = {20, 0}})
        b2d.create_segment_shape(ground_id, shape_def, segment)
    elseif scene_type == 2 then
        -- Ramp
        local segment = b2d.Segment({point1 = {-20, 0}, point2 = {0, 0}})
        b2d.create_segment_shape(ground_id, shape_def, segment)
        segment = b2d.Segment({point1 = {0, 0}, point2 = {20, 10}})
        b2d.create_segment_shape(ground_id, shape_def, segment)
    elseif scene_type == 3 then
        -- Steps
        for i = 0, 9 do
            local box = b2d.make_offset_box(2, 0.5, {-18 + i * 4, i * 1}, {1, 0})
            b2d.create_polygon_shape(ground_id, shape_def, box)
        end
    else
        -- V-shape
        local segment = b2d.Segment({point1 = {-10, 10}, point2 = {0, 0}})
        b2d.create_segment_shape(ground_id, shape_def, segment)
        segment = b2d.Segment({point1 = {0, 0}, point2 = {10, 10}})
        b2d.create_segment_shape(ground_id, shape_def, segment)
    end
end

local function drop_body(world)
    local body_def = b2d.default_body_def()
    body_def.type = b2d.BodyType.DYNAMICBODY
    body_def.position = {math.random() * 10 - 5, 15 + math.random() * 5}
    local body = b2d.create_body(world, body_def)

    local shape_def = b2d.default_shape_def()

    local shape_type = math.random(1, 3)
    if shape_type == 1 then
        local circle = b2d.Circle({center = {0, 0}, radius = 0.5})
        b2d.create_circle_shape(body, shape_def, circle)
    elseif shape_type == 2 then
        local box = b2d.make_box(0.4, 0.4)
        b2d.create_polygon_shape(body, shape_def, box)
    else
        local capsule = b2d.Capsule({center1 = {0, -0.3}, center2 = {0, 0.3}, radius = 0.2})
        b2d.create_capsule_shape(body, shape_def, capsule)
    end

    table.insert(body_ids, body)
end

function M.create_scene(world)
    body_ids = {}
    scene_type = 1
    create_ground(world)
end

function M.on_key(key, world)
    local app = require("sokol.app")

    if key == app.Keycode.N1 or key == app.Keycode.KP_1 then
        scene_type = 1
        if ground_id and b2d.body_is_valid(ground_id) then
            b2d.destroy_body(ground_id)
        end
        clear_bodies(world)
        create_ground(world)
    elseif key == app.Keycode.N2 or key == app.Keycode.KP_2 then
        scene_type = 2
        if ground_id and b2d.body_is_valid(ground_id) then
            b2d.destroy_body(ground_id)
        end
        clear_bodies(world)
        create_ground(world)
    elseif key == app.Keycode.N3 or key == app.Keycode.KP_3 then
        scene_type = 3
        if ground_id and b2d.body_is_valid(ground_id) then
            b2d.destroy_body(ground_id)
        end
        clear_bodies(world)
        create_ground(world)
    elseif key == app.Keycode.N4 or key == app.Keycode.KP_4 then
        scene_type = 4
        if ground_id and b2d.body_is_valid(ground_id) then
            b2d.destroy_body(ground_id)
        end
        clear_bodies(world)
        create_ground(world)
    elseif key == app.Keycode.SPACE then
        drop_body(world)
    end
end

function M.render(camera, world)
    -- Draw ground based on scene type
    if scene_type == 1 then
        draw.line(-20, 0, 20, 0, draw.colors.static)
    elseif scene_type == 2 then
        draw.line(-20, 0, 0, 0, draw.colors.static)
        draw.line(0, 0, 20, 10, draw.colors.static)
    elseif scene_type == 3 then
        for i = 0, 9 do
            draw.solid_box(-18 + i * 4, i * 1, 2, 0.5, 0, draw.colors.static)
        end
    else
        draw.line(-10, 10, 0, 0, draw.colors.static)
        draw.line(0, 0, 10, 10, draw.colors.static)
    end

    -- Draw bodies
    for _, body_id in ipairs(body_ids) do
        if b2d.body_is_valid(body_id) then
            local pos = b2d.body_get_position(body_id)
            local color = b2d.body_is_awake(body_id) and draw.colors.dynamic or draw.colors.sleeping
            draw.solid_circle(pos[1], pos[2], 0.4, color)
            draw.circle(pos[1], pos[2], 0.4, {0, 0, 0, 1})
        end
    end
end

function M.cleanup()
    ground_id = nil
    body_ids = {}
end

return M
