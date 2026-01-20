-- doohickey.lua - Box2D official Doohickey sample
-- A mechanism with two wheels connected by sliding bars.
local b2d = require("b2d")
local draw = require("examples.b2d.draw")

local M = {}

M.camera = {
    center_x = 0,
    center_y = 5,
    zoom = 25 * 0.35,
}

local ground_id = nil
local doohickeys = {}  -- Each doohickey: {wheel1, wheel2, bar1, bar2}

local function create_doohickey(world, position, scale)
    local doo = {wheels = {}, bars = {}}

    local body_def = b2d.default_body_def()
    body_def.type = b2d.BodyType.DYNAMICBODY

    local shape_def = b2d.default_shape_def()
    shape_def.material = {rollingResistance = 0.1}

    local circle = b2d.Circle({center = {0, 0}, radius = 1.0 * scale})
    local capsule = b2d.Capsule({
        center1 = {-3.5 * scale, 0},
        center2 = {3.5 * scale, 0},
        radius = 0.15 * scale
    })

    -- Wheel 1
    body_def.position = {position[1] + scale * (-5), position[2] + scale * 3}
    local wheel1 = b2d.create_body(world, body_def)
    b2d.create_circle_shape(wheel1, shape_def, circle)
    table.insert(doo.wheels, wheel1)

    -- Wheel 2
    body_def.position = {position[1] + scale * 5, position[2] + scale * 3}
    local wheel2 = b2d.create_body(world, body_def)
    b2d.create_circle_shape(wheel2, shape_def, circle)
    table.insert(doo.wheels, wheel2)

    -- Bar 1
    body_def.position = {position[1] + scale * (-1.5), position[2] + scale * 3}
    local bar1 = b2d.create_body(world, body_def)
    b2d.create_capsule_shape(bar1, shape_def, capsule)
    table.insert(doo.bars, bar1)

    -- Bar 2
    body_def.position = {position[1] + scale * 1.5, position[2] + scale * 3}
    local bar2 = b2d.create_body(world, body_def)
    b2d.create_capsule_shape(bar2, shape_def, capsule)
    table.insert(doo.bars, bar2)

    -- Revolute joint: wheel1 <-> bar1
    local revolute_def = b2d.default_revolute_joint_def()
    revolute_def.bodyIdA = wheel1
    revolute_def.bodyIdB = bar1
    revolute_def.localFrameA = b2d.Transform({p = {0, 0}, q = {1, 0}})
    revolute_def.localFrameB = b2d.Transform({p = {-3.5 * scale, 0}, q = {1, 0}})
    revolute_def.enableMotor = true
    revolute_def.maxMotorTorque = 2.0 * scale
    b2d.create_revolute_joint(world, revolute_def)

    -- Revolute joint: wheel2 <-> bar2
    revolute_def.bodyIdA = wheel2
    revolute_def.bodyIdB = bar2
    revolute_def.localFrameA = b2d.Transform({p = {0, 0}, q = {1, 0}})
    revolute_def.localFrameB = b2d.Transform({p = {3.5 * scale, 0}, q = {1, 0}})
    revolute_def.enableMotor = true
    revolute_def.maxMotorTorque = 2.0 * scale
    b2d.create_revolute_joint(world, revolute_def)

    -- Prismatic joint: bar1 <-> bar2 (sliding)
    local prismatic_def = b2d.default_prismatic_joint_def()
    prismatic_def.bodyIdA = bar1
    prismatic_def.bodyIdB = bar2
    prismatic_def.localFrameA = b2d.Transform({p = {2.0 * scale, 0}, q = {1, 0}})
    prismatic_def.localFrameB = b2d.Transform({p = {-2.0 * scale, 0}, q = {1, 0}})
    prismatic_def.lowerTranslation = -2.0 * scale
    prismatic_def.upperTranslation = 2.0 * scale
    prismatic_def.enableLimit = true
    prismatic_def.enableMotor = true
    prismatic_def.maxMotorForce = 2.0 * scale
    prismatic_def.enableSpring = true
    prismatic_def.hertz = 1.0
    prismatic_def.dampingRatio = 0.5
    b2d.create_prismatic_joint(world, prismatic_def)

    return doo
end

function M.create_scene(world)
    doohickeys = {}

    -- Ground
    local body_def = b2d.default_body_def()
    ground_id = b2d.create_body(world, body_def)
    local shape_def = b2d.default_shape_def()
    local segment = b2d.Segment({point1 = {-20, 0}, point2 = {20, 0}})
    b2d.create_segment_shape(ground_id, shape_def, segment)

    -- Box on ground
    local box = b2d.make_offset_box(1.0, 1.0, {0, 1}, 0)
    b2d.create_polygon_shape(ground_id, shape_def, box)

    -- Create 4 doohickeys stacked vertically
    local y = 4.0
    for i = 1, 4 do
        local doo = create_doohickey(world, {0, y}, 0.5)
        table.insert(doohickeys, doo)
        y = y + 2.0
    end
end

function M.render(camera, world)
    -- Ground
    draw.line(-20, 0, 20, 0, draw.colors.static)

    -- Box
    draw.solid_box(0, 1, 1, 1, 0, draw.colors.static)
    draw.box(0, 1, 1, 1, 0, {0, 0, 0, 1})

    -- Draw doohickeys
    local scale = 0.5
    for _, doo in ipairs(doohickeys) do
        -- Wheels
        for _, wheel in ipairs(doo.wheels) do
            local pos = b2d.body_get_position(wheel)
            local color = b2d.body_is_awake(wheel) and draw.colors.dynamic or draw.colors.sleeping
            draw.solid_circle(pos[1], pos[2], 1.0 * scale, color)
            draw.circle(pos[1], pos[2], 1.0 * scale, {0, 0, 0, 1})
        end

        -- Bars (capsules)
        for _, bar in ipairs(doo.bars) do
            local pos = b2d.body_get_position(bar)
            local rot = b2d.body_get_rotation(bar)
            local angle = b2d.rot_get_angle(rot)
            local color = b2d.body_is_awake(bar) and draw.colors.dynamic or draw.colors.sleeping

            local c, s = math.cos(angle), math.sin(angle)
            local c1x = pos[1] + (-3.5 * scale) * c
            local c1y = pos[2] + (-3.5 * scale) * s
            local c2x = pos[1] + (3.5 * scale) * c
            local c2y = pos[2] + (3.5 * scale) * s
            draw.solid_capsule(c1x, c1y, c2x, c2y, 0.15 * scale, color)
            draw.capsule(c1x, c1y, c2x, c2y, 0.15 * scale, {0, 0, 0, 1})
        end
    end
end

function M.cleanup()
    ground_id = nil
    doohickeys = {}
end

return M
