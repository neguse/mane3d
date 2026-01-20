-- arch.lua - Stone arch structure (official Box2D sample)
local b2d = require("b2d")
local draw = require("examples.b2d.draw")

local M = {}

M.camera = {
    center_x = 0,
    center_y = 8,
    zoom = 25 * 0.35,
}

local ground_id = nil
local bodies = {}

-- Arch stone point data (9 points for inner and outer curves)
local ps1_raw = {
    {16.0, 0.0},
    {14.93803712795643, 5.133601056842984},
    {13.79871746027416, 10.24928069555078},
    {12.56252963284711, 15.34107019122473},
    {11.20040987372525, 20.39856541571217},
    {9.66521217819836, 25.40369899225096},
    {7.87179930638133, 30.3179337000085},
    {5.635199558196225, 35.03820717801641},
    {2.405937953536585, 39.09554102558315},
}

local ps2_raw = {
    {24.0, 0.0},
    {22.33619528222415, 6.02299846205841},
    {20.54936888969905, 12.00964361211476},
    {18.60854610798073, 17.9470321677465},
    {16.46769273811807, 23.81367936585418},
    {14.05325025774858, 29.57079353071012},
    {11.23551045834022, 35.13775818285372},
    {7.752568160730571, 40.30450679009583},
    {3.016931552701656, 44.28891593799322},
}

function M.create_scene(world)
    bodies = {}

    -- Scale points
    local scale = 0.25
    local ps1, ps2 = {}, {}
    for i = 1, 9 do
        ps1[i] = {ps1_raw[i][1] * scale, ps1_raw[i][2] * scale}
        ps2[i] = {ps2_raw[i][1] * scale, ps2_raw[i][2] * scale}
    end

    local shape_def = b2d.default_shape_def()
    shape_def.material = b2d.SurfaceMaterial({friction = 0.6})

    -- Ground (using box instead of segment for simplicity)
    local body_def = b2d.default_body_def()
    body_def.position = {0, -0.5}
    ground_id = b2d.create_body(world, body_def)
    local ground_box = b2d.make_box(100, 0.5)
    b2d.create_polygon_shape(ground_id, shape_def, ground_box)

    body_def = b2d.default_body_def()
    body_def.type = b2d.BodyType.DYNAMICBODY

    -- Right side arch stones (8 stones)
    for i = 1, 8 do
        local body_id = b2d.create_body(world, body_def)
        local pts = {ps1[i], ps2[i], ps2[i + 1], ps1[i + 1]}
        local hull = b2d.compute_hull(pts)
        local polygon = b2d.make_polygon(hull, 0)
        b2d.create_polygon_shape(body_id, shape_def, polygon)
        table.insert(bodies, {id = body_id, polygon = polygon})
    end

    -- Left side arch stones (mirrored, 8 stones)
    for i = 1, 8 do
        local body_id = b2d.create_body(world, body_def)
        local pts = {
            {-ps2[i][1], ps2[i][2]},
            {-ps1[i][1], ps1[i][2]},
            {-ps1[i + 1][1], ps1[i + 1][2]},
            {-ps2[i + 1][1], ps2[i + 1][2]},
        }
        local hull = b2d.compute_hull(pts)
        local polygon = b2d.make_polygon(hull, 0)
        b2d.create_polygon_shape(body_id, shape_def, polygon)
        table.insert(bodies, {id = body_id, polygon = polygon})
    end

    -- Keystone at top
    do
        local body_id = b2d.create_body(world, body_def)
        local pts = {ps1[9], ps2[9], {-ps2[9][1], ps2[9][2]}, {-ps1[9][1], ps1[9][2]}}
        local hull = b2d.compute_hull(pts)
        local polygon = b2d.make_polygon(hull, 0)
        b2d.create_polygon_shape(body_id, shape_def, polygon)
        table.insert(bodies, {id = body_id, polygon = polygon})
    end

    -- Top boxes (4 boxes)
    for i = 0, 3 do
        local box = b2d.make_box(2, 0.5)
        body_def.position = {0, 0.5 + ps2[9][2] + 1.0 * i}
        local body_id = b2d.create_body(world, body_def)
        b2d.create_polygon_shape(body_id, shape_def, box)
        table.insert(bodies, {id = body_id, polygon = box})
    end
end

function M.render(camera, world)
    -- Draw ground
    draw.solid_box(0, -0.5, 100, 0.5, 0, draw.colors.static)

    -- Draw bodies
    for _, body in ipairs(bodies) do
        local color = b2d.body_is_awake(body.id) and draw.colors.dynamic or draw.colors.sleeping
        local transform = b2d.body_get_transform(body.id)

        -- Get polygon vertices from the polygon userdata
        local polygon = body.polygon
        local verts = {}
        for i = 1, polygon.count do
            local v = polygon.vertices[i]
            verts[i] = {v.x, v.y}
        end

        -- Transform vertices
        local world_verts = draw.transform_polygon(verts, transform)
        draw.solid_polygon(world_verts, color)
        draw.polygon(world_verts, {0, 0, 0, 1})
    end
end

function M.cleanup()
    ground_id = nil
    bodies = {}
end

return M
