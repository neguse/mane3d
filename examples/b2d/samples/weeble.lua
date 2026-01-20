-- weeble.lua - Self-righting weeble toy
local b2d = require("b2d")
local draw = require("examples.b2d.draw")
local app = require("sokol.app")

local M = {}

M.camera = {
    center_x = 0,
    center_y = 5,
    zoom = 12.5,
}

M.controls = "SPACE: Push weeble"

local ground_id = nil
local weeble_id = nil

function M.create_scene(world)
    -- Ground (thin box instead of segment)
    local body_def = b2d.default_body_def()
    body_def.position = {0, -0.1}
    ground_id = b2d.create_body(world, body_def)

    local shape_def = b2d.default_shape_def()
    local ground_box = b2d.make_box(20, 0.1)
    b2d.create_polygon_shape(ground_id, shape_def, ground_box)

    -- Weeble (capsule with low center of mass)
    body_def = b2d.default_body_def()
    body_def.type = b2d.BodyType.DYNAMICBODY
    body_def.position = {0, 3}
    body_def.rotation = b2d.make_rot(0.25 * math.pi)  -- Start tilted
    weeble_id = b2d.create_body(world, body_def)

    -- Main capsule shape
    local capsule = b2d.Capsule({center1 = {x = 0, y = -1}, center2 = {x = 0, y = 1}, radius = 1})
    shape_def = b2d.default_shape_def()
    b2d.create_capsule_shape(weeble_id, shape_def, capsule)

    -- Lower the center of mass using mass data (parallel axis theorem)
    local mass = b2d.body_get_mass(weeble_id)
    local inertia = b2d.body_get_rotational_inertia(weeble_id)
    local offset = 1.5
    -- See: https://en.wikipedia.org/wiki/Parallel_axis_theorem
    inertia = inertia + mass * offset * offset
    local mass_data = b2d.MassData({ mass = mass, center = {x = 0, y = -offset}, rotationalInertia = inertia })
    b2d.body_set_mass_data(weeble_id, mass_data)
end

function M.on_key(key_code, world)
    if key_code == app.Keycode.SPACE then
        -- Push the weeble
        b2d.body_apply_linear_impulse(weeble_id, {5, 0}, b2d.body_get_position(weeble_id), true)
    end
end

function M.render(camera, world)
    -- Ground
    draw.solid_box(0, -0.1, 20, 0.1, 0, draw.colors.static)

    -- Weeble
    local pos = b2d.body_get_position(weeble_id)
    local rot = b2d.body_get_rotation(weeble_id)
    local c, s = rot[1], rot[2]

    local color = b2d.body_is_awake(weeble_id) and draw.colors.dynamic or draw.colors.sleeping

    -- Draw capsule
    local p1 = {pos[1] + 0 * c - (-1) * s, pos[2] + 0 * s + (-1) * c}
    local p2 = {pos[1] + 0 * c - 1 * s, pos[2] + 0 * s + 1 * c}
    draw.solid_capsule(p1, p2, 1, color)
    draw.capsule(p1, p2, 1, {0, 0, 0, 1})
end

function M.cleanup()
    ground_id = nil
    weeble_id = nil
end

return M
