-- cliff.lua - Cliff sample with various shapes sliding
-- Based on Box2D samples/sample_stacking.cpp Cliff class
local b2d = require("b2d")
local draw = require("examples.b2d.draw")

local M = {}

-- Camera: zoom = 25.0f * 0.5f = 12.5, center = {0, 5}
M.camera = {
    center_x = 0,
    center_y = 5,
    zoom = 12.5,
}

M.controls = "SPACE: Flip direction"

local app = require("sokol.app")

local ground_id = nil
local bodies = {}
local flip = false
local current_world = nil

local function create_bodies(world)
    -- Destroy existing bodies
    for _, body in ipairs(bodies) do
        b2d.destroy_body(body.id)
    end
    bodies = {}

    local sign = flip and -1 or 1

    -- Shapes
    local capsule = b2d.Capsule({center1 = {x = -0.25, y = 0}, center2 = {x = 0.25, y = 0}, radius = 0.25})
    local circle = b2d.Circle({center = {x = 0, y = 0}, radius = 0.5})
    local square = b2d.make_square(0.5)

    local body_def = b2d.default_body_def()
    body_def.type = b2d.BodyType.DYNAMICBODY

    -- Capsules: friction=0.01, velocity=2*sign
    local shape_def = b2d.default_shape_def()
    shape_def.material = b2d.SurfaceMaterial({friction = 0.01})
    body_def.linearVelocity = {2 * sign, 0}

    local offset = flip and -4 or 0

    body_def.position = {-9 + offset, 4.25}
    local body_id = b2d.create_body(world, body_def)
    b2d.create_capsule_shape(body_id, shape_def, capsule)
    table.insert(bodies, {id = body_id, type = "capsule"})

    body_def.position = {2 + offset, 4.75}
    body_id = b2d.create_body(world, body_def)
    b2d.create_capsule_shape(body_id, shape_def, capsule)
    table.insert(bodies, {id = body_id, type = "capsule"})

    body_def.position = {13 + offset, 4.75}
    body_id = b2d.create_body(world, body_def)
    b2d.create_capsule_shape(body_id, shape_def, capsule)
    table.insert(bodies, {id = body_id, type = "capsule"})

    -- Squares: friction=0.01, velocity=2.5*sign
    shape_def = b2d.default_shape_def()
    shape_def.material = b2d.SurfaceMaterial({friction = 0.01})
    body_def.linearVelocity = {2.5 * sign, 0}

    body_def.position = {-11, 4.5}
    body_id = b2d.create_body(world, body_def)
    b2d.create_polygon_shape(body_id, shape_def, square)
    table.insert(bodies, {id = body_id, type = "box", size = 0.5})

    body_def.position = {0, 5}
    body_id = b2d.create_body(world, body_def)
    b2d.create_polygon_shape(body_id, shape_def, square)
    table.insert(bodies, {id = body_id, type = "box", size = 0.5})

    body_def.position = {11, 5}
    body_id = b2d.create_body(world, body_def)
    b2d.create_polygon_shape(body_id, shape_def, square)
    table.insert(bodies, {id = body_id, type = "box", size = 0.5})

    -- Circles: friction=0.2, velocity=1.5*sign
    shape_def = b2d.default_shape_def()
    shape_def.material = b2d.SurfaceMaterial({friction = 0.2})
    body_def.linearVelocity = {1.5 * sign, 0}

    offset = flip and 4 or 0

    body_def.position = {-13 + offset, 4.5}
    body_id = b2d.create_body(world, body_def)
    b2d.create_circle_shape(body_id, shape_def, circle)
    table.insert(bodies, {id = body_id, type = "circle", radius = 0.5})

    body_def.position = {-2 + offset, 5}
    body_id = b2d.create_body(world, body_def)
    b2d.create_circle_shape(body_id, shape_def, circle)
    table.insert(bodies, {id = body_id, type = "circle", radius = 0.5})

    body_def.position = {9 + offset, 5}
    body_id = b2d.create_body(world, body_def)
    b2d.create_circle_shape(body_id, shape_def, circle)
    table.insert(bodies, {id = body_id, type = "circle", radius = 0.5})
end

function M.create_scene(world)
    current_world = world
    bodies = {}

    -- Ground body
    local body_def = b2d.default_body_def()
    body_def.position = {0, 0}
    ground_id = b2d.create_body(world, body_def)

    local shape_def = b2d.default_shape_def()

    -- Main ground: b2MakeOffsetBox(100, 1, {0, -1}, b2Rot_identity)
    local ground_box = b2d.make_offset_box(100, 1, {0, -1}, {1, 0})
    b2d.create_polygon_shape(ground_id, shape_def, ground_box)

    -- Left platform: segment {{-14, 4}, {-8, 4}} -> thin box (segment crashes)
    -- Upper surface at y=4, so center at y=3.95 with half-height 0.05
    local left_platform = b2d.make_offset_box(3, 0.05, {-11, 3.95}, {1, 0})
    b2d.create_polygon_shape(ground_id, shape_def, left_platform)

    -- Center box: b2MakeOffsetBox(3, 0.5, {0, 4}, b2Rot_identity)
    local center_box = b2d.make_offset_box(3, 0.5, {0, 4}, {1, 0})
    b2d.create_polygon_shape(ground_id, shape_def, center_box)

    -- Right capsule: {{8.5, 4}, {13.5, 4}, 0.5}
    local platform_capsule = b2d.Capsule({center1 = {x = 8.5, y = 4}, center2 = {x = 13.5, y = 4}, radius = 0.5})
    b2d.create_capsule_shape(ground_id, shape_def, platform_capsule)

    -- Create dynamic bodies
    create_bodies(world)
end

-- Flip: SPACE key to toggle direction and recreate bodies
function M.on_key(key_code, world)
    if key_code == app.Keycode.SPACE then
        flip = not flip
        create_bodies(world)
    end
end

function M.render(camera, world)
    -- Ground
    draw.solid_box(0, -1, 100, 1, 0, draw.colors.static)
    -- Left platform (segment substitute)
    draw.line(-14, 4, -8, 4, draw.colors.static)
    -- Center box
    draw.solid_box(0, 4, 3, 0.5, 0, draw.colors.static)
    draw.box(0, 4, 3, 0.5, 0, {0, 0, 0, 1})
    -- Right capsule
    draw.solid_capsule({8.5, 4}, {13.5, 4}, 0.5, draw.colors.static)

    -- Dynamic bodies
    for _, body in ipairs(bodies) do
        local color = b2d.body_is_awake(body.id) and draw.colors.dynamic or draw.colors.sleeping
        if body.type == "capsule" then
            local pos = b2d.body_get_position(body.id)
            local rot = b2d.body_get_rotation(body.id)
            local c, s = rot[1], rot[2]
            local p1 = {pos[1] + (-0.25) * c, pos[2] + (-0.25) * s}
            local p2 = {pos[1] + 0.25 * c, pos[2] + 0.25 * s}
            draw.solid_capsule(p1, p2, 0.25, color)
            draw.capsule(p1, p2, 0.25, {0, 0, 0, 1})
        elseif body.type == "box" then
            local pos = b2d.body_get_position(body.id)
            local rot = b2d.body_get_rotation(body.id)
            local angle = b2d.rot_get_angle(rot)
            draw.solid_box(pos[1], pos[2], body.size, body.size, angle, color)
            draw.box(pos[1], pos[2], body.size, body.size, angle, {0, 0, 0, 1})
        elseif body.type == "circle" then
            local pos = b2d.body_get_position(body.id)
            local rot = b2d.body_get_rotation(body.id)
            draw.solid_circle_axis(pos[1], pos[2], body.radius, rot, color)
        end
    end
end

function M.cleanup()
    ground_id = nil
    bodies = {}
    flip = false
end

return M
