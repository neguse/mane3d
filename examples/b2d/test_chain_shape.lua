-- test_chain_shape.lua - Headless Chain Shape test
local b2d = require("b2d")

print("Chain Shape Headless Test")
print("=========================")

-- Create world
local def = b2d.default_world_def()
def.gravity = {0, -10}
local world = b2d.create_world(def)
print("World created")

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

-- Ground with chain
local body_def = b2d.default_body_def()
local ground_id = b2d.create_body(world, body_def)

local chain_def = b2d.default_chain_def()
chain_def.points = chain_points
chain_def.count = #chain_points
chain_def.isLoop = true
b2d.create_chain(ground_id, chain_def)
print("Chain shape created with " .. #chain_points .. " points")

-- Dynamic circle
body_def = b2d.default_body_def()
body_def.type = b2d.BodyType.DYNAMICBODY
body_def.position = {-55.0, 13.5}
local body_id = b2d.create_body(world, body_def)

local shape_def = b2d.default_shape_def()
shape_def.material = b2d.SurfaceMaterial({friction = 0.2})
local circle = b2d.Circle({center = {0, 0}, radius = 0.5})
b2d.create_circle_shape(body_id, shape_def, circle)
print("Dynamic circle created")

-- Simulate
print("\nSimulating...")
for i = 1, 300 do  -- 5 seconds
    b2d.world_step(world, 1.0/60.0, 4)
end

local pos = b2d.body_get_position(body_id)
print("Circle position after 5s: x =", pos[1], "y =", pos[2])

-- The circle should have rolled along the chain
local traveled = pos[1] - (-55.0)
print("Distance traveled:", traveled)

-- Cleanup
b2d.destroy_world(world)
print("\n=========================")
print("Chain Shape Test OK!")
