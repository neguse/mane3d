-- joint_grid.lua - Box2D official Joint Grid Benchmark sample
-- Grid of bodies connected by distance joints
local b2d = require("b2d")
local draw = require("examples.b2d.draw")

local M = {}

M.camera = {
    center_x = 0,
    center_y = 10,
    zoom = 25,
}

local ground_id = nil
local body_ids = {}
local joint_ids = {}

function M.create_scene(world)
    body_ids = {}
    joint_ids = {}

    -- Ground
    local body_def = b2d.default_body_def()
    ground_id = b2d.create_body(world, body_def)

    local shape_def = b2d.default_shape_def()
    local segment = b2d.Segment({point1 = {-20, 0}, point2 = {20, 0}})
    b2d.create_segment_shape(ground_id, shape_def, segment)

    -- Create grid of bodies
    local rows = 8
    local cols = 10
    local spacing = 1.5
    local start_x = -(cols - 1) * spacing / 2
    local start_y = 5

    local grid = {}
    local circle = b2d.Circle({center = {0, 0}, radius = 0.3})

    for row = 0, rows - 1 do
        grid[row] = {}
        for col = 0, cols - 1 do
            body_def = b2d.default_body_def()
            body_def.type = b2d.BodyType.DYNAMICBODY
            body_def.position = {start_x + col * spacing, start_y + row * spacing}
            local body = b2d.create_body(world, body_def)
            b2d.create_circle_shape(body, shape_def, circle)
            table.insert(body_ids, body)
            grid[row][col] = body
        end
    end

    -- Connect with distance joints
    for row = 0, rows - 1 do
        for col = 0, cols - 1 do
            local body = grid[row][col]

            -- Helper to make frame
            local function make_frame(px, py)
                local f = b2d.Transform()
                f.p = {px, py}
                f.q = {c = 1, s = 0}
                return f
            end

            -- Horizontal connection
            if col < cols - 1 then
                local neighbor = grid[row][col + 1]
                local joint_def = b2d.default_distance_joint_def()
                joint_def.bodyIdA = body
                joint_def.bodyIdB = neighbor
                joint_def.localFrameA = make_frame(0, 0)
                joint_def.localFrameB = make_frame(0, 0)
                joint_def.length = spacing
                joint_def.hertz = 5
                joint_def.dampingRatio = 0.5
                local joint = b2d.create_distance_joint(world, joint_def)
                table.insert(joint_ids, joint)
            end

            -- Vertical connection
            if row < rows - 1 then
                local neighbor = grid[row + 1][col]
                local joint_def = b2d.default_distance_joint_def()
                joint_def.bodyIdA = body
                joint_def.bodyIdB = neighbor
                joint_def.localFrameA = make_frame(0, 0)
                joint_def.localFrameB = make_frame(0, 0)
                joint_def.length = spacing
                joint_def.hertz = 5
                joint_def.dampingRatio = 0.5
                local joint = b2d.create_distance_joint(world, joint_def)
                table.insert(joint_ids, joint)
            end
        end
    end
end

function M.render(camera, world)
    -- Draw ground
    draw.line(-20, 0, 20, 0, draw.colors.static)

    -- Draw joints
    for _, joint_id in ipairs(joint_ids) do
        if b2d.joint_is_valid(joint_id) then
            local anchor_a = b2d.joint_get_world_anchor_a(joint_id)
            local anchor_b = b2d.joint_get_world_anchor_b(joint_id)
            draw.line(anchor_a[1], anchor_a[2], anchor_b[1], anchor_b[2], {0.5, 0.5, 0.5, 0.5})
        end
    end

    -- Draw bodies
    for _, body_id in ipairs(body_ids) do
        if b2d.body_is_valid(body_id) then
            local pos = b2d.body_get_position(body_id)
            local color = b2d.body_is_awake(body_id) and draw.colors.dynamic or draw.colors.sleeping
            draw.solid_circle(pos[1], pos[2], 0.3, color)
        end
    end
end

function M.cleanup()
    ground_id = nil
    body_ids = {}
    joint_ids = {}
end

return M
