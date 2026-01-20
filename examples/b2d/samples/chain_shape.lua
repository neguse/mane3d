-- chain_shape.lua - Box2D official Chain Shape sample
-- Demonstrates chain shapes for smooth terrain.
local b2d = require("b2d")
local draw = require("examples.b2d.draw")
local imgui = require("imgui")

local M = {}

M.camera = {
    center_x = 0,
    center_y = 0,
    zoom = 25 * 1.75,
}

local ground_id = nil
local body_id = nil
local shape_type = 0  -- 0=circle, 1=capsule, 2=box
local friction = 0.2
local restitution = 0.0

-- Chain points
local chain_points = {
    {-56.885498, 12.8985004},
    {-56.885498, 16.2057495},
    {56.885498, 16.2057495},
    {56.885498, -16.2057514},
    {51.5935059, -16.2057514},
    {43.6559982, -10.9139996},
    {35.7184982, -10.9139996},
    {27.7809982, -10.9139996},
    {21.1664963, -14.2212505},
    {11.9059982, -16.2057514},
    {0, -16.2057514},
    {-10.5835037, -14.8827496},
    {-17.1980019, -13.5597477},
    {-21.1665001, -12.2370014},
    {-25.1355019, -9.5909977},
    {-31.75, -3.63799858},
    {-38.3644981, 6.2840004},
    {-42.3334999, 9.59125137},
    {-47.625, 11.5755005},
    {-56.885498, 12.8985004},
}

local function launch(world)
    if body_id then
        b2d.destroy_body(body_id)
        body_id = nil
    end

    local body_def = b2d.default_body_def()
    body_def.type = b2d.BodyType.DYNAMICBODY
    body_def.position = {-55.0, 13.5}
    body_id = b2d.create_body(world, body_def)

    local shape_def = b2d.default_shape_def()
    shape_def.material = b2d.SurfaceMaterial({friction = friction, restitution = restitution})

    if shape_type == 0 then
        local circle = b2d.Circle({center = {0, 0}, radius = 0.5})
        b2d.create_circle_shape(body_id, shape_def, circle)
    elseif shape_type == 1 then
        local capsule = b2d.Capsule({center1 = {-0.5, 0}, center2 = {0.5, 0}, radius = 0.25})
        b2d.create_capsule_shape(body_id, shape_def, capsule)
    else
        local box = b2d.make_box(0.5, 0.5)
        b2d.create_polygon_shape(body_id, shape_def, box)
    end
end

function M.create_scene(world)
    -- Ground with chain
    local body_def = b2d.default_body_def()
    ground_id = b2d.create_body(world, body_def)

    local chain_def = b2d.default_chain_def()
    chain_def.points = chain_points
    chain_def.count = #chain_points
    chain_def.isLoop = true
    b2d.create_chain(ground_id, chain_def)

    -- Launch initial shape
    launch(world)
end

function M.update_gui(world)
    imgui.begin_window("Chain Shape")

    local shape_types = {"Circle", "Capsule", "Box"}
    local changed
    changed, shape_type = imgui.combo("Shape", shape_type, shape_types)
    if changed then
        launch(world)
    end

    changed, friction = imgui.slider_float("Friction", friction, 0, 1)
    changed, restitution = imgui.slider_float("Restitution", restitution, 0, 2)

    if imgui.button("Launch") then
        launch(world)
    end

    imgui.end_window()
end

function M.render(camera, world)
    -- Draw chain
    for i = 1, #chain_points do
        local p1 = chain_points[i]
        local p2 = chain_points[(i % #chain_points) + 1]
        draw.line(p1[1], p1[2], p2[1], p2[2], draw.colors.static)
    end

    -- Draw body
    if body_id and b2d.body_is_valid(body_id) then
        local pos = b2d.body_get_position(body_id)
        local rot = b2d.body_get_rotation(body_id)
        local angle = b2d.rot_get_angle(rot)
        local color = b2d.body_is_awake(body_id) and draw.colors.dynamic or draw.colors.sleeping

        if shape_type == 0 then
            draw.solid_circle(pos[1], pos[2], 0.5, color)
            draw.circle(pos[1], pos[2], 0.5, {0, 0, 0, 1})
        elseif shape_type == 1 then
            local c, s = math.cos(angle), math.sin(angle)
            local c1x = pos[1] + (-0.5) * c
            local c1y = pos[2] + (-0.5) * s
            local c2x = pos[1] + (0.5) * c
            local c2y = pos[2] + (0.5) * s
            draw.solid_capsule(c1x, c1y, c2x, c2y, 0.25, color)
            draw.capsule(c1x, c1y, c2x, c2y, 0.25, {0, 0, 0, 1})
        else
            draw.solid_box(pos[1], pos[2], 0.5, 0.5, angle, color)
            draw.box(pos[1], pos[2], 0.5, 0.5, angle, {0, 0, 0, 1})
        end
    end

    -- Draw coordinate axes
    draw.line(0, 0, 0.5, 0, {1, 0, 0, 1})
    draw.line(0, 0, 0, 0.5, {0, 1, 0, 1})
end

function M.cleanup()
    ground_id = nil
    body_id = nil
end

return M
