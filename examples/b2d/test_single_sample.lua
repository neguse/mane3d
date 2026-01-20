-- test_single_sample.lua - Test a single Box2D sample
-- Usage: mane3d-test.exe examples/b2d/test_single_sample.lua <sample_name>
-- Example: mane3d-test.exe examples/b2d/test_single_sample.lua hello

local b2d = require("b2d")

local sample_name = arg[1]
if not sample_name then
    print("Usage: test_single_sample.lua <sample_name>")
    print("Example: test_single_sample.lua hello")
    os.exit(1)
end

local sample_path = "examples.b2d.samples." .. sample_name

local function create_world()
    local def = b2d.default_world_def()
    def.gravity = {0, -10}
    return b2d.create_world(def)
end

local ok, mod = pcall(require, sample_path)
if not ok then
    print("FAIL (require: " .. tostring(mod) .. ")")
    os.exit(1)
end

local world = create_world()
local error_msg = nil

-- Test create_scene
if mod.create_scene then
    local ok2, err = pcall(mod.create_scene, world)
    if not ok2 then
        error_msg = "create_scene: " .. tostring(err)
    end
end

-- Test update (a few steps)
if not error_msg and mod.update then
    for i = 1, 10 do
        local ok2, err = pcall(mod.update, world, 1/60)
        if not ok2 then
            error_msg = "update: " .. tostring(err)
            break
        end
    end
end

-- Step world
if not error_msg then
    for i = 1, 60 do
        b2d.world_step(world, 1/60, 4)
    end
end

-- Test cleanup
if not error_msg and mod.cleanup then
    local ok2, err = pcall(mod.cleanup)
    if not ok2 then
        error_msg = "cleanup: " .. tostring(err)
    end
end

-- Destroy world
b2d.destroy_world(world)

if error_msg then
    print("FAIL (" .. error_msg .. ")")
    os.exit(1)
else
    print("OK")
    os.exit(0)
end
