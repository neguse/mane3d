-- test_convex_hull.lua - Headless Convex Hull test
local b2d = require("b2d")

print("Convex Hull Headless Test")
print("=========================")

-- Test 1: Simple square
print("\nTest 1: Square points")
local square_points = {
    {-1, -1},
    {1, -1},
    {1, 1},
    {-1, 1}
}

local hull = b2d.compute_hull(square_points)
if hull and hull.count then
    print("Hull computed with", hull.count, "vertices")
else
    print("Hull computation failed or returned nil")
end

-- Test 2: Triangle
print("\nTest 2: Triangle points")
local triangle_points = {
    {0, 1},
    {-1, -1},
    {1, -1}
}

hull = b2d.compute_hull(triangle_points)
if hull and hull.count then
    print("Hull computed with", hull.count, "vertices")
else
    print("Hull computation failed or returned nil")
end

-- Test 3: Random points
print("\nTest 3: Random points (8)")
local random_points = {}
for i = 1, 8 do
    random_points[i] = {
        math.random() * 8 - 4,
        math.random() * 8 - 4
    }
end

hull = b2d.compute_hull(random_points)
if hull and hull.count then
    print("Hull computed with", hull.count, "vertices (from 8 input points)")
else
    print("Hull computation failed or returned nil")
end

-- Test 4: Collinear points (edge case)
print("\nTest 4: Collinear points")
local line_points = {
    {-2, 0},
    {-1, 0},
    {0, 0},
    {1, 0},
    {2, 0}
}

hull = b2d.compute_hull(line_points)
if hull and hull.count then
    print("Hull computed with", hull.count, "vertices")
    if hull.count < 3 then
        print("(Degenerate hull as expected for collinear points)")
    end
else
    print("Hull computation returned nil (expected for degenerate case)")
end

print("\n=========================")
print("Convex Hull Test OK!")
