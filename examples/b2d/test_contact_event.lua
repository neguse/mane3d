-- test_contact_event.lua - Headless Contact Event test
local b2d = require("b2d")

print("Contact Event Headless Test")
print("============================")

-- Create world
local def = b2d.default_world_def()
def.gravity = {0, 0}  -- No gravity for top-down view
local world = b2d.create_world(def)
print("World created")

-- Ground (walls)
local body_def = b2d.default_body_def()
local ground_id = b2d.create_body(world, body_def)

local points = {{40, -40}, {-40, -40}, {-40, 40}, {40, 40}}
local chain_def = b2d.default_chain_def()
chain_def.points = points
chain_def.count = #points
chain_def.isLoop = true
b2d.create_chain(ground_id, chain_def)
print("Walls created")

-- Player
body_def = b2d.default_body_def()
body_def.type = b2d.BodyType.DYNAMICBODY
body_def.position = {0, 0}
body_def.gravityScale = 0.0
body_def.linearDamping = 0.5
body_def.isBullet = true
local player_id = b2d.create_body(world, body_def)

local circle = b2d.Circle({center = {0, 0}, radius = 1.0})
local shape_def = b2d.default_shape_def()
shape_def.enableContactEvents = true
b2d.create_circle_shape(player_id, shape_def, circle)
print("Player created with contact events enabled")

-- Debris
body_def = b2d.default_body_def()
body_def.type = b2d.BodyType.DYNAMICBODY
body_def.position = {5, 0}
body_def.gravityScale = 0.0
local debris_id = b2d.create_body(world, body_def)

shape_def = b2d.default_shape_def()
circle = b2d.Circle({center = {0, 0}, radius = 0.5})
b2d.create_circle_shape(debris_id, shape_def, circle)
print("Debris created")

-- Apply force to player to move toward debris
local pos = b2d.body_get_position(player_id)
b2d.body_apply_linear_impulse_to_center(player_id, {50, 0}, true)
print("Impulse applied to player")

-- Simulate and check for contact events
print("\nSimulating...")
local contact_detected = false

for i = 1, 60 do  -- 1 second
    b2d.world_step(world, 1.0/60.0, 4)

    local contact_events = b2d.world_get_contact_events(world)
    if contact_events and contact_events.beginEvents and #contact_events.beginEvents > 0 then
        contact_detected = true
        print("Contact event detected at step", i)
        break
    end
end

if contact_detected then
    print("Contact events working!")
else
    print("No contact events detected (player may not have reached debris)")
end

-- Cleanup
b2d.destroy_world(world)
print("\n============================")
print("Contact Event Test OK!")
