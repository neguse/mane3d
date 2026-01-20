-- explosion.lua - Box2D official Explosion sample
-- Demonstrates explosion impulses with rotating weld joints.
local b2d = require("b2d")
local draw = require("examples.b2d.draw")
local imgui = require("imgui")

local M = {}

M.camera = {
    center_x = 0,
    center_y = 0,
    zoom = 14,
}

local ground_id = nil
local joint_ids = {}
local radius = 7
local falloff = 3
local impulse = 10
local reference_angle = 0

function M.create_scene(world)
    joint_ids = {}
    reference_angle = 0

    local body_def = b2d.default_body_def()
    ground_id = b2d.create_body(world, body_def)

    body_def.type = b2d.BodyType.DYNAMICBODY
    body_def.gravityScale = 0

    local shape_def = b2d.default_shape_def()

    local r = 8
    for angle = 0, 330, 30 do
        local rad = angle * math.pi / 180
        local c, s = math.cos(rad), math.sin(rad)

        body_def.position = {r * c, r * s}
        local body_id = b2d.create_body(world, body_def)

        local box = b2d.make_box(1.0, 0.1)
        b2d.create_polygon_shape(body_id, shape_def, box)

        local weld_def = b2d.default_weld_joint_def()
        weld_def.bodyIdA = ground_id
        weld_def.bodyIdB = body_id
        weld_def.angularHertz = 0.5
        weld_def.angularDampingRatio = 0.7
        weld_def.linearHertz = 0.5
        weld_def.linearDampingRatio = 0.7

        -- Set frame positions using Transform
        weld_def.localFrameA = b2d.Transform({p = {r * c, r * s}, q = {1, 0}})
        weld_def.localFrameB = b2d.Transform({p = {0, 0}, q = {1, 0}})

        local joint_id = b2d.create_weld_joint(world, weld_def)
        table.insert(joint_ids, joint_id)
    end
end

M.controls = "Space: Explode"

function M.update(world, dt)
    -- Rotate the reference angle
    reference_angle = reference_angle + 60 * math.pi / 180 * dt

    -- Update joint reference angles (simplified - full update would use SetLocalFrameA)
end

function M.on_key(key, world)
    local app = require("sokol.app")

    if key == app.Keycode.SPACE then
        -- Trigger explosion
        local explosion_def = b2d.default_explosion_def()
        explosion_def.position = {0, 0}
        explosion_def.radius = radius
        explosion_def.falloff = falloff
        explosion_def.impulsePerLength = impulse
        b2d.world_explode(world, explosion_def)
    end
end

function M.render(camera, world)
    -- Draw explosion radius circles
    draw.circle(0, 0, radius + falloff, {0.2, 0.3, 0.8, 1})  -- Outer (falloff)
    draw.circle(0, 0, radius, {0.8, 0.7, 0.2, 1})  -- Inner (full impulse)

    -- Draw ground (center point)
    draw.point(0, 0, 5, draw.colors.static)

    -- Draw bodies attached by weld joints
    local r = 8
    for i, joint_id in ipairs(joint_ids) do
        if b2d.joint_is_valid(joint_id) then
            local angle = (i - 1) * 30 * math.pi / 180
            local c, s = math.cos(angle), math.sin(angle)
            local x, y = r * c, r * s

            -- Get actual body from joint
            local body_id = b2d.joint_get_body_b(joint_id)
            if b2d.body_is_valid(body_id) then
                local pos = b2d.body_get_position(body_id)
                local rot = b2d.body_get_rotation(body_id)
                local body_angle = b2d.rot_get_angle(rot)

                local color = b2d.body_is_awake(body_id) and draw.colors.dynamic or draw.colors.sleeping
                draw.solid_box(pos[1], pos[2], 1.0, 0.1, body_angle, color)
                draw.box(pos[1], pos[2], 1.0, 0.1, body_angle, {0, 0, 0, 1})
            end
        end
    end

    -- UI hint
    draw.point(-12, 12, 2, {1, 1, 1, 1})
end

function M.cleanup()
    ground_id = nil
    joint_ids = {}
    reference_angle = 0
end

return M
