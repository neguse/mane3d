-- wind.lua - Box2D official Wind sample
-- Demonstrates wind forces using b2Shape_ApplyWind.
local b2d = require("b2d")
local draw = require("examples.b2d.draw")

local M = {}

M.camera = {
    center_x = 0,
    center_y = 1,
    zoom = 2,
}

local ground_id = nil
local body_ids = {}
local wind = {6, 0}
local drag = 1.0
local lift = 0.75
local noise = {0, 0}
local count = 10

local function random_range(min, max)
    return min + math.random() * (max - min)
end

local function lerp(a, b, t)
    return a + (b - a) * t
end

local function create_scene_impl(world)
    body_ids = {}

    local radius = 0.1

    local shape_def = b2d.default_shape_def()
    shape_def.density = 20

    local body_def = b2d.default_body_def()
    body_def.type = b2d.BodyType.DYNAMICBODY
    body_def.gravityScale = 0.5
    body_def.enableSleep = false

    -- Create capsule shape for wind effect
    local capsule = b2d.Capsule({
        center1 = {0, -radius},
        center2 = {0, radius},
        radius = 0.25 * radius
    })

    local prev_body = ground_id
    local prev_anchor = {0, 2 + radius}

    for i = 0, count - 1 do
        body_def.position = {0, 2 - 2 * radius * i}
        local body_id = b2d.create_body(world, body_def)

        b2d.create_capsule_shape(body_id, shape_def, capsule)
        table.insert(body_ids, body_id)

        -- Create joint
        local joint_def = b2d.default_revolute_joint_def()
        joint_def.bodyIdA = prev_body
        joint_def.bodyIdB = body_id
        joint_def.hertz = 0.1
        joint_def.dampingRatio = 0
        joint_def.enableSpring = true

        -- Set frame positions using Transform
        joint_def.localFrameA = b2d.Transform({p = prev_anchor, q = {1, 0}})
        joint_def.localFrameB = b2d.Transform({p = {0, radius}, q = {1, 0}})

        b2d.create_revolute_joint(world, joint_def)

        -- Chain to next
        prev_body = body_id
        prev_anchor = {0, -radius}
    end
end

function M.create_scene(world)
    -- Create ground
    local body_def = b2d.default_body_def()
    ground_id = b2d.create_body(world, body_def)

    noise = {0, 0}
    create_scene_impl(world)
end

M.controls = "Arrow keys: Adjust wind"

function M.update(world, dt)
    -- Apply wind to all bodies
    local speed = math.sqrt(wind[1] * wind[1] + wind[2] * wind[2])
    local dir_x, dir_y = 0, 0
    if speed > 0 then
        dir_x, dir_y = wind[1] / speed, wind[2] / speed
    end

    local wind_with_noise = {
        speed * (dir_x + noise[1]),
        speed * (dir_y + noise[2])
    }

    for _, body_id in ipairs(body_ids) do
        if b2d.body_is_valid(body_id) then
            -- Get shapes and apply wind
            local shapes = b2d.body_get_shapes(body_id)
            if shapes then
                for _, shape_id in ipairs(shapes) do
                    b2d.shape_apply_wind(shape_id, wind_with_noise, drag, lift, true)
                end
            end
        end
    end

    -- Add noise variation
    local rand_x = random_range(-0.3, 0.3)
    local rand_y = random_range(-0.3, 0.3)
    noise[1] = lerp(noise[1], rand_x, 0.05)
    noise[2] = lerp(noise[2], rand_y, 0.05)
end

function M.on_key(key, world)
    local app = require("sokol.app")

    if key == app.Keycode.LEFT then
        wind[1] = wind[1] - 1
    elseif key == app.Keycode.RIGHT then
        wind[1] = wind[1] + 1
    elseif key == app.Keycode.UP then
        wind[2] = wind[2] + 1
    elseif key == app.Keycode.DOWN then
        wind[2] = wind[2] - 1
    end
end

function M.render(camera, world)
    -- Draw pivot point
    draw.point(0, 2.1, 5, draw.colors.static)

    -- Draw wind direction
    local wind_scale = 0.1
    draw.line(0, 0, wind[1] * wind_scale, wind[2] * wind_scale, {1, 0, 1, 1})

    -- Draw bodies
    for _, body_id in ipairs(body_ids) do
        if b2d.body_is_valid(body_id) then
            local pos = b2d.body_get_position(body_id)
            local rot = b2d.body_get_rotation(body_id)
            local angle = b2d.rot_get_angle(rot)

            local color = b2d.body_is_awake(body_id) and draw.colors.dynamic or draw.colors.sleeping

            -- Draw capsule (simplified as circle)
            draw.solid_circle(pos[1], pos[2], 0.1, color)
            draw.circle(pos[1], pos[2], 0.1, {0, 0, 0, 1})
        end
    end

    -- Draw wind info
    draw.point(-1.5, 1.8, 2, {1, 1, 1, 1})
end

function M.cleanup()
    ground_id = nil
    body_ids = {}
    noise = {0, 0}
end

return M
