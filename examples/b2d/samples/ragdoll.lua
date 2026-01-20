-- ragdoll.lua - Box2D official Ragdoll sample
-- A human ragdoll with 11 bones connected by revolute joints.
local b2d = require("b2d")
local draw = require("examples.b2d.draw")
local imgui = require("imgui")

local M = {}

M.camera = {
    center_x = 0,
    center_y = 12,
    zoom = 16,
}

-- Bone indices
local BONE_HIP = 1
local BONE_TORSO = 2
local BONE_HEAD = 3
local BONE_UPPER_LEFT_LEG = 4
local BONE_LOWER_LEFT_LEG = 5
local BONE_UPPER_RIGHT_LEG = 6
local BONE_LOWER_RIGHT_LEG = 7
local BONE_UPPER_LEFT_ARM = 8
local BONE_LOWER_LEFT_ARM = 9
local BONE_UPPER_RIGHT_ARM = 10
local BONE_LOWER_RIGHT_ARM = 11
local BONE_COUNT = 11

local ground_id = nil
local bones = {}  -- {body_id, joint_id, friction_scale, parent_index}

local joint_friction_torque = 0.03
local joint_hertz = 5.0
local joint_damping_ratio = 0.5

local function create_human(world, position, scale)
    bones = {}
    for i = 1, BONE_COUNT do
        bones[i] = {body_id = nil, joint_id = nil, friction_scale = 1.0, parent_index = -1}
    end

    local body_def = b2d.default_body_def()
    body_def.type = b2d.BodyType.DYNAMICBODY
    body_def.sleepThreshold = 0.1

    local shape_def = b2d.default_shape_def()
    shape_def.material = {friction = 0.2}
    local filter = b2d.Filter()
    filter.groupIndex = -1
    filter.categoryBits = 2
    filter.maskBits = 3  -- 1 | 2
    shape_def.filter = filter

    local foot_shape_def = b2d.default_shape_def()
    foot_shape_def.material = {friction = 0.05}
    local foot_filter = b2d.Filter()
    foot_filter.groupIndex = -1
    foot_filter.categoryBits = 2
    foot_filter.maskBits = 1
    foot_shape_def.filter = foot_filter

    local s = scale
    local max_torque = joint_friction_torque * s
    local enable_motor = true
    local enable_limit = true

    local px, py = position[1], position[2]

    -- Hip
    do
        local bone = bones[BONE_HIP]
        bone.parent_index = -1
        body_def.position = {px + 0, py + 0.95 * s}
        bone.body_id = b2d.create_body(world, body_def)
        local capsule = b2d.Capsule({center1 = {0, -0.02 * s}, center2 = {0, 0.02 * s}, radius = 0.095 * s})
        b2d.create_capsule_shape(bone.body_id, shape_def, capsule)
    end

    -- Torso
    do
        local bone = bones[BONE_TORSO]
        bone.parent_index = BONE_HIP
        bone.friction_scale = 0.5
        body_def.position = {px + 0, py + 1.2 * s}
        bone.body_id = b2d.create_body(world, body_def)
        local capsule = b2d.Capsule({center1 = {0, -0.135 * s}, center2 = {0, 0.135 * s}, radius = 0.09 * s})
        b2d.create_capsule_shape(bone.body_id, shape_def, capsule)

        local pivot = {px + 0, py + 1.0 * s}
        local joint_def = b2d.default_revolute_joint_def()
        joint_def.bodyIdA = bones[bone.parent_index].body_id
        joint_def.bodyIdB = bone.body_id
        local anchorA = b2d.body_get_local_point(joint_def.bodyIdA, pivot)
        local anchorB = b2d.body_get_local_point(joint_def.bodyIdB, pivot)
        joint_def.localFrameA = b2d.Transform({p = anchorA, q = {1, 0}})
        joint_def.localFrameB = b2d.Transform({p = anchorB, q = {1, 0}})
        joint_def.enableLimit = enable_limit
        joint_def.lowerAngle = -0.25 * math.pi
        joint_def.upperAngle = 0
        joint_def.enableMotor = enable_motor
        joint_def.maxMotorTorque = bone.friction_scale * max_torque
        joint_def.enableSpring = joint_hertz > 0
        joint_def.hertz = joint_hertz
        joint_def.dampingRatio = joint_damping_ratio
        bone.joint_id = b2d.create_revolute_joint(world, joint_def)
    end

    -- Head
    do
        local bone = bones[BONE_HEAD]
        bone.parent_index = BONE_TORSO
        bone.friction_scale = 0.25
        body_def.position = {px + 0, py + 1.475 * s}
        bone.body_id = b2d.create_body(world, body_def)
        local capsule = b2d.Capsule({center1 = {0, -0.038 * s}, center2 = {0, 0.039 * s}, radius = 0.075 * s})
        b2d.create_capsule_shape(bone.body_id, shape_def, capsule)

        local pivot = {px + 0, py + 1.4 * s}
        local joint_def = b2d.default_revolute_joint_def()
        joint_def.bodyIdA = bones[bone.parent_index].body_id
        joint_def.bodyIdB = bone.body_id
        local anchorA = b2d.body_get_local_point(joint_def.bodyIdA, pivot)
        local anchorB = b2d.body_get_local_point(joint_def.bodyIdB, pivot)
        joint_def.localFrameA = b2d.Transform({p = anchorA, q = {1, 0}})
        joint_def.localFrameB = b2d.Transform({p = anchorB, q = {1, 0}})
        joint_def.enableLimit = enable_limit
        joint_def.lowerAngle = -0.3 * math.pi
        joint_def.upperAngle = 0.1 * math.pi
        joint_def.enableMotor = enable_motor
        joint_def.maxMotorTorque = bone.friction_scale * max_torque
        joint_def.enableSpring = joint_hertz > 0
        joint_def.hertz = joint_hertz
        joint_def.dampingRatio = joint_damping_ratio
        bone.joint_id = b2d.create_revolute_joint(world, joint_def)
    end

    -- Upper Left Leg
    do
        local bone = bones[BONE_UPPER_LEFT_LEG]
        bone.parent_index = BONE_HIP
        bone.friction_scale = 1.0
        body_def.position = {px + 0, py + 0.775 * s}
        bone.body_id = b2d.create_body(world, body_def)
        local capsule = b2d.Capsule({center1 = {0, -0.125 * s}, center2 = {0, 0.125 * s}, radius = 0.06 * s})
        b2d.create_capsule_shape(bone.body_id, shape_def, capsule)

        local pivot = {px + 0, py + 0.9 * s}
        local joint_def = b2d.default_revolute_joint_def()
        joint_def.bodyIdA = bones[bone.parent_index].body_id
        joint_def.bodyIdB = bone.body_id
        local anchorA = b2d.body_get_local_point(joint_def.bodyIdA, pivot)
        local anchorB = b2d.body_get_local_point(joint_def.bodyIdB, pivot)
        joint_def.localFrameA = b2d.Transform({p = anchorA, q = {1, 0}})
        joint_def.localFrameB = b2d.Transform({p = anchorB, q = {1, 0}})
        joint_def.enableLimit = enable_limit
        joint_def.lowerAngle = -0.05 * math.pi
        joint_def.upperAngle = 0.4 * math.pi
        joint_def.enableMotor = enable_motor
        joint_def.maxMotorTorque = bone.friction_scale * max_torque
        joint_def.enableSpring = joint_hertz > 0
        joint_def.hertz = joint_hertz
        joint_def.dampingRatio = joint_damping_ratio
        bone.joint_id = b2d.create_revolute_joint(world, joint_def)
    end

    -- Foot polygon for lower legs
    local foot_points = {
        {-0.03 * s, -0.185 * s},
        {0.11 * s, -0.185 * s},
        {0.11 * s, -0.16 * s},
        {-0.03 * s, -0.14 * s},
    }
    local foot_hull = b2d.compute_hull(foot_points)
    local foot_polygon = b2d.make_polygon(foot_hull, 0.015 * s)

    -- Lower Left Leg
    do
        local bone = bones[BONE_LOWER_LEFT_LEG]
        bone.parent_index = BONE_UPPER_LEFT_LEG
        bone.friction_scale = 0.5
        body_def.position = {px + 0, py + 0.475 * s}
        bone.body_id = b2d.create_body(world, body_def)
        local capsule = b2d.Capsule({center1 = {0, -0.155 * s}, center2 = {0, 0.125 * s}, radius = 0.045 * s})
        b2d.create_capsule_shape(bone.body_id, shape_def, capsule)
        b2d.create_polygon_shape(bone.body_id, foot_shape_def, foot_polygon)

        local pivot = {px + 0, py + 0.625 * s}
        local joint_def = b2d.default_revolute_joint_def()
        joint_def.bodyIdA = bones[bone.parent_index].body_id
        joint_def.bodyIdB = bone.body_id
        local anchorA = b2d.body_get_local_point(joint_def.bodyIdA, pivot)
        local anchorB = b2d.body_get_local_point(joint_def.bodyIdB, pivot)
        joint_def.localFrameA = b2d.Transform({p = anchorA, q = {1, 0}})
        joint_def.localFrameB = b2d.Transform({p = anchorB, q = {1, 0}})
        joint_def.enableLimit = enable_limit
        joint_def.lowerAngle = -0.5 * math.pi
        joint_def.upperAngle = -0.02 * math.pi
        joint_def.enableMotor = enable_motor
        joint_def.maxMotorTorque = bone.friction_scale * max_torque
        joint_def.enableSpring = joint_hertz > 0
        joint_def.hertz = joint_hertz
        joint_def.dampingRatio = joint_damping_ratio
        bone.joint_id = b2d.create_revolute_joint(world, joint_def)
    end

    -- Upper Right Leg
    do
        local bone = bones[BONE_UPPER_RIGHT_LEG]
        bone.parent_index = BONE_HIP
        bone.friction_scale = 1.0
        body_def.position = {px + 0, py + 0.775 * s}
        bone.body_id = b2d.create_body(world, body_def)
        local capsule = b2d.Capsule({center1 = {0, -0.125 * s}, center2 = {0, 0.125 * s}, radius = 0.06 * s})
        b2d.create_capsule_shape(bone.body_id, shape_def, capsule)

        local pivot = {px + 0, py + 0.9 * s}
        local joint_def = b2d.default_revolute_joint_def()
        joint_def.bodyIdA = bones[bone.parent_index].body_id
        joint_def.bodyIdB = bone.body_id
        local anchorA = b2d.body_get_local_point(joint_def.bodyIdA, pivot)
        local anchorB = b2d.body_get_local_point(joint_def.bodyIdB, pivot)
        joint_def.localFrameA = b2d.Transform({p = anchorA, q = {1, 0}})
        joint_def.localFrameB = b2d.Transform({p = anchorB, q = {1, 0}})
        joint_def.enableLimit = enable_limit
        joint_def.lowerAngle = -0.05 * math.pi
        joint_def.upperAngle = 0.4 * math.pi
        joint_def.enableMotor = enable_motor
        joint_def.maxMotorTorque = bone.friction_scale * max_torque
        joint_def.enableSpring = joint_hertz > 0
        joint_def.hertz = joint_hertz
        joint_def.dampingRatio = joint_damping_ratio
        bone.joint_id = b2d.create_revolute_joint(world, joint_def)
    end

    -- Lower Right Leg
    do
        local bone = bones[BONE_LOWER_RIGHT_LEG]
        bone.parent_index = BONE_UPPER_RIGHT_LEG
        bone.friction_scale = 0.5
        body_def.position = {px + 0, py + 0.475 * s}
        bone.body_id = b2d.create_body(world, body_def)
        local capsule = b2d.Capsule({center1 = {0, -0.155 * s}, center2 = {0, 0.125 * s}, radius = 0.045 * s})
        b2d.create_capsule_shape(bone.body_id, shape_def, capsule)
        b2d.create_polygon_shape(bone.body_id, foot_shape_def, foot_polygon)

        local pivot = {px + 0, py + 0.625 * s}
        local joint_def = b2d.default_revolute_joint_def()
        joint_def.bodyIdA = bones[bone.parent_index].body_id
        joint_def.bodyIdB = bone.body_id
        local anchorA = b2d.body_get_local_point(joint_def.bodyIdA, pivot)
        local anchorB = b2d.body_get_local_point(joint_def.bodyIdB, pivot)
        joint_def.localFrameA = b2d.Transform({p = anchorA, q = {1, 0}})
        joint_def.localFrameB = b2d.Transform({p = anchorB, q = {1, 0}})
        joint_def.enableLimit = enable_limit
        joint_def.lowerAngle = -0.5 * math.pi
        joint_def.upperAngle = -0.02 * math.pi
        joint_def.enableMotor = enable_motor
        joint_def.maxMotorTorque = bone.friction_scale * max_torque
        joint_def.enableSpring = joint_hertz > 0
        joint_def.hertz = joint_hertz
        joint_def.dampingRatio = joint_damping_ratio
        bone.joint_id = b2d.create_revolute_joint(world, joint_def)
    end

    -- Upper Left Arm
    do
        local bone = bones[BONE_UPPER_LEFT_ARM]
        bone.parent_index = BONE_TORSO
        bone.friction_scale = 0.5
        body_def.position = {px + 0, py + 1.225 * s}
        bone.body_id = b2d.create_body(world, body_def)
        local capsule = b2d.Capsule({center1 = {0, -0.125 * s}, center2 = {0, 0.125 * s}, radius = 0.035 * s})
        b2d.create_capsule_shape(bone.body_id, shape_def, capsule)

        local pivot = {px + 0, py + 1.35 * s}
        local joint_def = b2d.default_revolute_joint_def()
        joint_def.bodyIdA = bones[bone.parent_index].body_id
        joint_def.bodyIdB = bone.body_id
        local anchorA = b2d.body_get_local_point(joint_def.bodyIdA, pivot)
        local anchorB = b2d.body_get_local_point(joint_def.bodyIdB, pivot)
        joint_def.localFrameA = b2d.Transform({p = anchorA, q = {1, 0}})
        joint_def.localFrameB = b2d.Transform({p = anchorB, q = {1, 0}})
        joint_def.enableLimit = enable_limit
        joint_def.lowerAngle = -0.1 * math.pi
        joint_def.upperAngle = 0.8 * math.pi
        joint_def.enableMotor = enable_motor
        joint_def.maxMotorTorque = bone.friction_scale * max_torque
        joint_def.enableSpring = joint_hertz > 0
        joint_def.hertz = joint_hertz
        joint_def.dampingRatio = joint_damping_ratio
        bone.joint_id = b2d.create_revolute_joint(world, joint_def)
    end

    -- Lower Left Arm
    do
        local bone = bones[BONE_LOWER_LEFT_ARM]
        bone.parent_index = BONE_UPPER_LEFT_ARM
        bone.friction_scale = 0.1
        body_def.position = {px + 0, py + 0.975 * s}
        bone.body_id = b2d.create_body(world, body_def)
        local capsule = b2d.Capsule({center1 = {0, -0.125 * s}, center2 = {0, 0.125 * s}, radius = 0.03 * s})
        b2d.create_capsule_shape(bone.body_id, shape_def, capsule)

        local pivot = {px + 0, py + 1.1 * s}
        local joint_def = b2d.default_revolute_joint_def()
        joint_def.bodyIdA = bones[bone.parent_index].body_id
        joint_def.bodyIdB = bone.body_id
        local anchorA = b2d.body_get_local_point(joint_def.bodyIdA, pivot)
        local anchorB = b2d.body_get_local_point(joint_def.bodyIdB, pivot)
        local elbow_rot = b2d.make_rot(0.25 * math.pi)
        joint_def.localFrameA = b2d.Transform({p = anchorA, q = elbow_rot})
        joint_def.localFrameB = b2d.Transform({p = anchorB, q = {1, 0}})
        joint_def.enableLimit = enable_limit
        joint_def.lowerAngle = -0.2 * math.pi
        joint_def.upperAngle = 0.3 * math.pi
        joint_def.enableMotor = enable_motor
        joint_def.maxMotorTorque = bone.friction_scale * max_torque
        joint_def.enableSpring = joint_hertz > 0
        joint_def.hertz = joint_hertz
        joint_def.dampingRatio = joint_damping_ratio
        bone.joint_id = b2d.create_revolute_joint(world, joint_def)
    end

    -- Upper Right Arm
    do
        local bone = bones[BONE_UPPER_RIGHT_ARM]
        bone.parent_index = BONE_TORSO
        bone.friction_scale = 0.5
        body_def.position = {px + 0, py + 1.225 * s}
        bone.body_id = b2d.create_body(world, body_def)
        local capsule = b2d.Capsule({center1 = {0, -0.125 * s}, center2 = {0, 0.125 * s}, radius = 0.035 * s})
        b2d.create_capsule_shape(bone.body_id, shape_def, capsule)

        local pivot = {px + 0, py + 1.35 * s}
        local joint_def = b2d.default_revolute_joint_def()
        joint_def.bodyIdA = bones[bone.parent_index].body_id
        joint_def.bodyIdB = bone.body_id
        local anchorA = b2d.body_get_local_point(joint_def.bodyIdA, pivot)
        local anchorB = b2d.body_get_local_point(joint_def.bodyIdB, pivot)
        joint_def.localFrameA = b2d.Transform({p = anchorA, q = {1, 0}})
        joint_def.localFrameB = b2d.Transform({p = anchorB, q = {1, 0}})
        joint_def.enableLimit = enable_limit
        joint_def.lowerAngle = -0.1 * math.pi
        joint_def.upperAngle = 0.8 * math.pi
        joint_def.enableMotor = enable_motor
        joint_def.maxMotorTorque = bone.friction_scale * max_torque
        joint_def.enableSpring = joint_hertz > 0
        joint_def.hertz = joint_hertz
        joint_def.dampingRatio = joint_damping_ratio
        bone.joint_id = b2d.create_revolute_joint(world, joint_def)
    end

    -- Lower Right Arm
    do
        local bone = bones[BONE_LOWER_RIGHT_ARM]
        bone.parent_index = BONE_UPPER_RIGHT_ARM
        bone.friction_scale = 0.1
        body_def.position = {px + 0, py + 0.975 * s}
        bone.body_id = b2d.create_body(world, body_def)
        local capsule = b2d.Capsule({center1 = {0, -0.125 * s}, center2 = {0, 0.125 * s}, radius = 0.03 * s})
        b2d.create_capsule_shape(bone.body_id, shape_def, capsule)

        local pivot = {px + 0, py + 1.1 * s}
        local joint_def = b2d.default_revolute_joint_def()
        joint_def.bodyIdA = bones[bone.parent_index].body_id
        joint_def.bodyIdB = bone.body_id
        local anchorA = b2d.body_get_local_point(joint_def.bodyIdA, pivot)
        local anchorB = b2d.body_get_local_point(joint_def.bodyIdB, pivot)
        local elbow_rot = b2d.make_rot(0.25 * math.pi)
        joint_def.localFrameA = b2d.Transform({p = anchorA, q = elbow_rot})
        joint_def.localFrameB = b2d.Transform({p = anchorB, q = {1, 0}})
        joint_def.enableLimit = enable_limit
        joint_def.lowerAngle = -0.2 * math.pi
        joint_def.upperAngle = 0.3 * math.pi
        joint_def.enableMotor = enable_motor
        joint_def.maxMotorTorque = bone.friction_scale * max_torque
        joint_def.enableSpring = joint_hertz > 0
        joint_def.hertz = joint_hertz
        joint_def.dampingRatio = joint_damping_ratio
        bone.joint_id = b2d.create_revolute_joint(world, joint_def)
    end
end

local function set_joint_friction_torque(torque)
    if torque == 0 then
        for i = 2, BONE_COUNT do
            if bones[i].joint_id then
                b2d.revolute_joint_enable_motor(bones[i].joint_id, false)
            end
        end
    else
        for i = 2, BONE_COUNT do
            if bones[i].joint_id then
                b2d.revolute_joint_enable_motor(bones[i].joint_id, true)
                b2d.revolute_joint_set_max_motor_torque(bones[i].joint_id, bones[i].friction_scale * torque)
            end
        end
    end
end

local function set_joint_spring_hertz(hertz)
    if hertz == 0 then
        for i = 2, BONE_COUNT do
            if bones[i].joint_id then
                b2d.revolute_joint_enable_spring(bones[i].joint_id, false)
            end
        end
    else
        for i = 2, BONE_COUNT do
            if bones[i].joint_id then
                b2d.revolute_joint_enable_spring(bones[i].joint_id, true)
                b2d.revolute_joint_set_spring_hertz(bones[i].joint_id, hertz)
            end
        end
    end
end

local function set_joint_damping_ratio(damping)
    for i = 2, BONE_COUNT do
        if bones[i].joint_id then
            b2d.revolute_joint_set_spring_damping_ratio(bones[i].joint_id, damping)
        end
    end
end

local current_world = nil

function M.create_scene(world)
    current_world = world

    -- Ground
    local body_def = b2d.default_body_def()
    ground_id = b2d.create_body(world, body_def)
    local shape_def = b2d.default_shape_def()
    local segment = b2d.Segment({point1 = {-20, 0}, point2 = {20, 0}})
    b2d.create_segment_shape(ground_id, shape_def, segment)

    -- Spawn ragdoll at height 25
    create_human(world, {0, 25}, 1.0)

    -- Contact tuning
    b2d.world_set_contact_tuning(world, 240.0, 0.0, 2.0)
end

function M.update_gui(world)
    imgui.begin_window("Ragdoll")

    local changed
    changed, joint_friction_torque = imgui.slider_float("Friction", joint_friction_torque, 0, 1)
    if changed then
        set_joint_friction_torque(joint_friction_torque)
    end

    changed, joint_hertz = imgui.slider_float("Hertz", joint_hertz, 0, 10)
    if changed then
        set_joint_spring_hertz(joint_hertz)
    end

    changed, joint_damping_ratio = imgui.slider_float("Damping", joint_damping_ratio, 0, 4)
    if changed then
        set_joint_damping_ratio(joint_damping_ratio)
    end

    if imgui.button("Respawn") then
        -- Destroy old ragdoll
        for i = BONE_COUNT, 1, -1 do
            if bones[i].joint_id then
                b2d.destroy_joint(bones[i].joint_id, false)
            end
        end
        for i = BONE_COUNT, 1, -1 do
            if bones[i].body_id then
                b2d.destroy_body(bones[i].body_id)
            end
        end
        -- Respawn
        create_human(current_world, {0, 25}, 1.0)
    end

    imgui.end_window()
end

function M.render(camera, world)
    -- Ground
    draw.line(-20, 0, 20, 0, draw.colors.static)

    -- Draw bones as capsules
    for i = 1, BONE_COUNT do
        local bone = bones[i]
        if bone.body_id then
            local pos = b2d.body_get_position(bone.body_id)
            local rot = b2d.body_get_rotation(bone.body_id)
            local angle = b2d.rot_get_angle(rot)
            local color = b2d.body_is_awake(bone.body_id) and draw.colors.dynamic or draw.colors.sleeping

            -- Simple capsule approximation (each bone has different sizes)
            local c, s = math.cos(angle), math.sin(angle)
            local half_len = 0.1  -- approximate
            local radius = 0.05

            -- Different sizes per bone
            if i == BONE_HIP then
                half_len, radius = 0.02, 0.095
            elseif i == BONE_TORSO then
                half_len, radius = 0.135, 0.09
            elseif i == BONE_HEAD then
                half_len, radius = 0.04, 0.075
            elseif i == BONE_UPPER_LEFT_LEG or i == BONE_UPPER_RIGHT_LEG then
                half_len, radius = 0.125, 0.06
            elseif i == BONE_LOWER_LEFT_LEG or i == BONE_LOWER_RIGHT_LEG then
                half_len, radius = 0.14, 0.045
            elseif i == BONE_UPPER_LEFT_ARM or i == BONE_UPPER_RIGHT_ARM then
                half_len, radius = 0.125, 0.035
            elseif i == BONE_LOWER_LEFT_ARM or i == BONE_LOWER_RIGHT_ARM then
                half_len, radius = 0.125, 0.03
            end

            local c1x = pos[1] - s * half_len
            local c1y = pos[2] + c * half_len
            local c2x = pos[1] + s * half_len
            local c2y = pos[2] - c * half_len
            draw.solid_capsule(c1x, c1y, c2x, c2y, radius, color)
            draw.capsule(c1x, c1y, c2x, c2y, radius, {0, 0, 0, 1})
        end
    end
end

function M.cleanup()
    ground_id = nil
    bones = {}
    current_world = nil
end

return M
