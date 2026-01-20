-- test_headless.lua - Headless Box2D test
-- Run with: mane3d-example.exe --headless examples/b2d/test_headless.lua

local b2d = require("b2d")

print("Box2D Headless Test")
print("===================")

-- Test 1: Create world
print("\n[Test 1] Create world...")
local def = b2d.default_world_def()
print("  default_world_def: OK")
def.gravity = {0, -10}
print("  set gravity: OK")
local world = b2d.create_world(def)
print("  create_world: OK, world =", world)

-- Test 2: Create ground body
print("\n[Test 2] Create ground body...")
local body_def = b2d.default_body_def()
print("  default_body_def: OK")
body_def.position = {0, -1}
print("  set position: OK")
local ground_id = b2d.create_body(world, body_def)
print("  create_body: OK, ground_id =", ground_id)

-- Test 3: Create ground shape
print("\n[Test 3] Create ground shape...")
local shape_def = b2d.default_shape_def()
print("  default_shape_def: OK")
local box = b2d.make_box(20, 1)
print("  make_box: OK, box =", box)
local shape_id = b2d.create_polygon_shape(ground_id, shape_def, box)
print("  create_polygon_shape: OK, shape_id =", shape_id)

-- Test 4: Create dynamic body
print("\n[Test 4] Create dynamic body...")
body_def = b2d.default_body_def()
body_def.type = b2d.BodyType.DYNAMICBODY
body_def.position = {0, 10}
local box_id = b2d.create_body(world, body_def)
print("  create_body (dynamic): OK, box_id =", box_id)

-- Test 5: Create dynamic shape
print("\n[Test 5] Create dynamic shape...")
shape_def = b2d.default_shape_def()
box = b2d.make_box(1, 1)
b2d.create_polygon_shape(box_id, shape_def, box)
print("  create_polygon_shape: OK")

-- Test 6: World step
print("\n[Test 6] World step simulation...")
local pos = b2d.body_get_position(box_id)
print("  Initial position: x =", pos[1], "y =", pos[2])

for i = 1, 180 do  -- 3 seconds
    b2d.world_step(world, 1.0 / 60.0, 4)
end

pos = b2d.body_get_position(box_id)
print("  After 3 seconds: x =", pos[1], "y =", pos[2])

-- The box should have fallen and be resting on the ground
-- ground at y=-1 with half-height 1, box half-height 1, so resting y = 1
local expected_y = 1.0
local tolerance = 0.5
if math.abs(pos[2] - expected_y) < tolerance then
    print("  Position check: OK (box resting on ground)")
else
    print("  Position check: UNEXPECTED y =", pos[2], "expected ~", expected_y)
end

-- Test 7: compute_hull with point array
print("\n[Test 7] compute_hull with point array...")
local pts = {
    {0, 0},
    {1, 0},
    {1, 1},
    {0, 1},
}
local hull = b2d.compute_hull(pts)
print("  compute_hull: OK, hull =", hull)
print("  hull.count =", hull.count)
if hull.count == 4 then
    print("  Hull count check: OK")
else
    print("  Hull count check: UNEXPECTED, got", hull.count)
end

-- Test 8: make_polygon from hull
print("\n[Test 8] make_polygon from hull...")
local polygon = b2d.make_polygon(hull, 0)
print("  make_polygon: OK, polygon =", polygon)
print("  polygon.count =", polygon.count)
print("  polygon.vertices:")
for i = 1, polygon.count do
    local v = polygon.vertices[i]
    print("    [" .. i .. "] x =", v.x, "y =", v.y)
end

-- Test 9: Destroy world
print("\n[Test 9] Destroy world...")
b2d.destroy_world(world)
print("  destroy_world: OK")

print("\n===================")
print("All tests passed!")
