-- init.lua - Box2D Sample Selector (ImGui version)
local app = require("sokol.app")
local gfx = require("sokol.gfx")
local glue = require("sokol.glue")
local imgui = require("imgui")
local log = require("lib.log")
local b2d = require("b2d")
local draw = require("examples.b2d.draw")
local Camera = require("examples.b2d.camera")

local samples = {
    -- Basic
    {category = "Basic", name = "Hello World", path = "examples.b2d.samples.hello"},

    -- Stacking
    {category = "Stacking", name = "Single Box", path = "examples.b2d.samples.single_box"},
    {category = "Stacking", name = "Vertical Stack", path = "examples.b2d.samples.vertical_stack"},
    {category = "Stacking", name = "Circle Stack", path = "examples.b2d.samples.circle_stack"},
    {category = "Stacking", name = "Tilted Stack", path = "examples.b2d.samples.tilted_stack"},
    {category = "Stacking", name = "Capsule Stack", path = "examples.b2d.samples.capsule_stack"},
    {category = "Stacking", name = "Cliff", path = "examples.b2d.samples.cliff"},
    {category = "Stacking", name = "Arch", path = "examples.b2d.samples.arch"},
    {category = "Stacking", name = "Double Domino", path = "examples.b2d.samples.double_domino"},
    {category = "Stacking", name = "Confined", path = "examples.b2d.samples.confined"},
    {category = "Stacking", name = "Card House", path = "examples.b2d.samples.card_house"},

    -- Shapes
    {category = "Shapes", name = "Restitution", path = "examples.b2d.samples.restitution"},
    {category = "Shapes", name = "Friction", path = "examples.b2d.samples.friction"},
    {category = "Shapes", name = "Compound Shapes", path = "examples.b2d.samples.compound_shapes"},
    {category = "Shapes", name = "Rounded", path = "examples.b2d.samples.rounded"},
    {category = "Shapes", name = "Ellipse", path = "examples.b2d.samples.ellipse"},

    -- Bodies
    {category = "Bodies", name = "Body Type", path = "examples.b2d.samples.body_type"},
    {category = "Bodies", name = "Sleep", path = "examples.b2d.samples.sleep"},
    {category = "Bodies", name = "Weeble", path = "examples.b2d.samples.weeble"},

    -- Collision
    {category = "Collision", name = "Ray Cast", path = "examples.b2d.samples.ray_cast"},
    {category = "Collision", name = "Overlap", path = "examples.b2d.samples.overlap"},
    {category = "Collision", name = "Shape Distance", path = "examples.b2d.samples.shape_distance"},

    -- Joints
    {category = "Joints", name = "Distance Joint", path = "examples.b2d.samples.distance_joint"},
    {category = "Joints", name = "Motor Joint", path = "examples.b2d.samples.motor_joint"},
    {category = "Joints", name = "Prismatic Joint", path = "examples.b2d.samples.prismatic_joint"},
    {category = "Joints", name = "Revolute Joint", path = "examples.b2d.samples.revolute_joint"},
    {category = "Joints", name = "Wheel Joint", path = "examples.b2d.samples.wheel_joint"},
    {category = "Joints", name = "Ball & Chain", path = "examples.b2d.samples.ball_and_chain"},
    {category = "Joints", name = "Cantilever", path = "examples.b2d.samples.cantilever"},
    {category = "Joints", name = "Ragdoll", path = "examples.b2d.samples.ragdoll"},
    {category = "Joints", name = "Soft Body", path = "examples.b2d.samples.soft_body"},
    {category = "Joints", name = "Doohickey", path = "examples.b2d.samples.doohickey"},
    {category = "Joints", name = "Bridge", path = "examples.b2d.samples.bridge"},
    {category = "Joints", name = "Scissor Lift", path = "examples.b2d.samples.scissor_lift"},
    {category = "Joints", name = "Door", path = "examples.b2d.samples.door"},
    {category = "Joints", name = "Gear Lift", path = "examples.b2d.samples.gear_lift"},
    {category = "Joints", name = "Motion Locks", path = "examples.b2d.samples.motion_locks"},
    {category = "Joints", name = "Breakable", path = "examples.b2d.samples.breakable_joint"},
    {category = "Joints", name = "Top Down Friction", path = "examples.b2d.samples.top_down_friction"},
    {category = "Joints", name = "Filter Joint", path = "examples.b2d.samples.filter_joint"},
    {category = "Joints", name = "Joint Separation", path = "examples.b2d.samples.joint_separation"},
    {category = "Joints", name = "Driving", path = "examples.b2d.samples.driving"},

    -- Shapes
    {category = "Shapes", name = "Chain Shape", path = "examples.b2d.samples.chain_shape"},
    {category = "Shapes", name = "Conveyor Belt", path = "examples.b2d.samples.conveyor_belt"},

    -- Events
    {category = "Events", name = "Contact Event", path = "examples.b2d.samples.contact_event"},

    -- Shapes (additional)
    {category = "Shapes", name = "Rolling Resistance", path = "examples.b2d.samples.rolling_resistance"},
    {category = "Shapes", name = "Explosion", path = "examples.b2d.samples.explosion"},
    {category = "Shapes", name = "Wind", path = "examples.b2d.samples.wind"},

    -- Bodies (additional)
    {category = "Bodies", name = "Pivot", path = "examples.b2d.samples.pivot"},
    {category = "Bodies", name = "Kinematic", path = "examples.b2d.samples.kinematic"},

    -- Continuous
    {category = "Continuous", name = "Bounce House", path = "examples.b2d.samples.bounce_house"},
    {category = "Continuous", name = "Pinball", path = "examples.b2d.samples.pinball"},

    -- Character
    {category = "Character", name = "Mover", path = "examples.b2d.samples.mover"},

    -- Geometry
    {category = "Geometry", name = "Convex Hull", path = "examples.b2d.samples.convex_hull"},

    -- Events (additional)
    {category = "Events", name = "Sensor Funnel", path = "examples.b2d.samples.sensor_funnel"},

    -- Shapes (more)
    {category = "Shapes", name = "Offset Shapes", path = "examples.b2d.samples.offset_shapes"},

    -- Continuous (additional)
    {category = "Continuous", name = "Chain Drop", path = "examples.b2d.samples.chain_drop"},

    -- Events (more)
    {category = "Events", name = "Foot Sensor", path = "examples.b2d.samples.foot_sensor"},
    {category = "Events", name = "Platformer", path = "examples.b2d.samples.platformer"},

    -- Robustness
    {category = "Robustness", name = "High Mass Ratio", path = "examples.b2d.samples.high_mass_ratio"},

    -- Benchmark
    {category = "Benchmark", name = "Tumbler", path = "examples.b2d.samples.tumbler"},
    {category = "Benchmark", name = "Pyramid", path = "examples.b2d.samples.pyramid"},
    {category = "Benchmark", name = "Barrel", path = "examples.b2d.samples.barrel"},

    -- Collision (additional)
    {category = "Collision", name = "Cast World", path = "examples.b2d.samples.cast_world"},
    {category = "Collision", name = "Overlap World", path = "examples.b2d.samples.overlap_world"},

    -- Stacking (additional)
    {category = "Stacking", name = "Circle Impulse", path = "examples.b2d.samples.circle_impulse"},

    -- Determinism
    {category = "Determinism", name = "Falling Hinges", path = "examples.b2d.samples.falling_hinges"},

    -- World
    {category = "World", name = "Large World", path = "examples.b2d.samples.large_world"},

    -- Continuous (more)
    {category = "Continuous", name = "Chain Slide", path = "examples.b2d.samples.chain_slide"},
    {category = "Continuous", name = "Segment Slide", path = "examples.b2d.samples.segment_slide"},
    {category = "Continuous", name = "Skinny Box", path = "examples.b2d.samples.skinny_box"},
    {category = "Continuous", name = "Drop", path = "examples.b2d.samples.drop"},
    {category = "Continuous", name = "Wedge", path = "examples.b2d.samples.wedge"},

    -- Robustness (more)
    {category = "Robustness", name = "Overlap Recovery", path = "examples.b2d.samples.overlap_recovery"},
    {category = "Robustness", name = "Tiny Pyramid", path = "examples.b2d.samples.tiny_pyramid"},

    -- Bodies (more)
    {category = "Bodies", name = "Bad Body", path = "examples.b2d.samples.bad_body"},
    {category = "Bodies", name = "Mixed Locks", path = "examples.b2d.samples.mixed_locks"},
    {category = "Bodies", name = "Set Velocity", path = "examples.b2d.samples.set_velocity"},
    {category = "Bodies", name = "Wake Touching", path = "examples.b2d.samples.wake_touching"},

    -- Events (more)
    {category = "Events", name = "Body Move", path = "examples.b2d.samples.body_move"},
    {category = "Events", name = "Sensor Types", path = "examples.b2d.samples.sensor_types"},

    -- Shapes (more)
    {category = "Shapes", name = "Tangent Speed", path = "examples.b2d.samples.tangent_speed"},
    {category = "Shapes", name = "Modify Geometry", path = "examples.b2d.samples.modify_geometry"},
    {category = "Shapes", name = "Chain Link", path = "examples.b2d.samples.chain_link"},
    {category = "Shapes", name = "Shape Filter", path = "examples.b2d.samples.shape_filter"},

    -- Continuous (more)
    {category = "Continuous", name = "Ghost Bumps", path = "examples.b2d.samples.ghost_bumps"},

    -- Events (more)
    {category = "Events", name = "Sensor Bookend", path = "examples.b2d.samples.sensor_bookend"},
    {category = "Events", name = "Joint Event", path = "examples.b2d.samples.joint_event"},

    -- Issues
    {category = "Issues", name = "Shape Cast Chain", path = "examples.b2d.samples.shape_cast_chain"},
    {category = "Issues", name = "Bad Steiner", path = "examples.b2d.samples.bad_steiner"},

    -- Benchmark (more)
    {category = "Benchmark", name = "Many Pyramids", path = "examples.b2d.samples.many_pyramids"},
    {category = "Benchmark", name = "Joint Grid", path = "examples.b2d.samples.joint_grid"},
    {category = "Benchmark", name = "Spinner", path = "examples.b2d.samples.spinner"},
    {category = "Benchmark", name = "Rain", path = "examples.b2d.samples.rain"},
    {category = "Benchmark", name = "Smash", path = "examples.b2d.samples.smash"},

    -- Robustness (more)
    {category = "Robustness", name = "Cart", path = "examples.b2d.samples.cart"},

    -- Benchmark (more)
    {category = "Benchmark", name = "Compound", path = "examples.b2d.samples.compound_benchmark"},
    {category = "Benchmark", name = "Kinematic", path = "examples.b2d.samples.kinematic_benchmark"},
    {category = "Benchmark", name = "Many Tumblers", path = "examples.b2d.samples.many_tumblers"},

    -- Joints (more)
    {category = "Joints", name = "Scale Ragdoll", path = "examples.b2d.samples.scale_ragdoll"},
}

local selected_index = 1

-- State: "menu" or "sample"
local state = "menu"
local current_sample = nil
local sample_module = nil

-- Shared resources
local world = nil
local camera = nil

-- Simulation settings
local paused = false
local hertz = 60
local sub_steps = 4

local function create_world()
    local def = b2d.default_world_def()
    def.gravity = {0, -10}
    return b2d.create_world(def)
end

local function switch_to_sample(index)
    local sample = samples[index]
    if not sample then return end

    -- Load sample module
    local ok, mod = pcall(require, sample.path)
    if not ok then
        log.error("Error loading sample: " .. tostring(mod))
        return
    end

    -- Create world and camera
    world = create_world()
    camera = Camera.new({
        center_x = mod.camera and mod.camera.center_x or 0,
        center_y = mod.camera and mod.camera.center_y or 10,
        zoom = mod.camera and mod.camera.zoom or 20,
        width = app.width(),
        height = app.height(),
    })

    -- Initialize sample
    if mod.create_scene then
        local ok2, err = pcall(mod.create_scene, world)
        if not ok2 then
            log.error("Error in create_scene: " .. tostring(err))
            b2d.destroy_world(world)
            world = nil
            return
        end
    end

    sample_module = mod
    current_sample = sample
    state = "sample"
    paused = false
end

local function switch_to_menu()
    -- Cleanup sample
    if sample_module and sample_module.cleanup then
        pcall(sample_module.cleanup)
    end

    -- Destroy world
    if world then
        b2d.destroy_world(world)
        world = nil
    end

    sample_module = nil
    current_sample = nil
    camera = nil
    state = "menu"
end

local function restart_sample()
    if not sample_module then return end

    if sample_module.cleanup then
        pcall(sample_module.cleanup)
    end
    if world then
        b2d.destroy_world(world)
    end
    world = create_world()
    if sample_module.create_scene then
        sample_module.create_scene(world)
    end
    paused = false
end

-- Menu rendering with ImGui
local function menu_frame()
    imgui.new_frame()

    -- Center window
    local w, h = app.width(), app.height()
    imgui.set_next_window_pos({w * 0.1, h * 0.1})
    imgui.set_next_window_size({w * 0.8, h * 0.8})

    if imgui.begin("Box2D Samples", nil, 2 + 4) then  -- NoResize + NoMove
        -- Sample list
        local current_category = nil
        for i, sample in ipairs(samples) do
            -- Category header
            if sample.category ~= current_category then
                current_category = sample.category
                imgui.separator()
                imgui.text_unformatted("[" .. current_category .. "]")
            end

            -- Sample button
            local label = "  " .. sample.name
            if i == selected_index then
                label = "> " .. sample.name
            end

            if imgui.button(label) then
                selected_index = i
                switch_to_sample(i)
            end
        end

        imgui.separator()
        imgui.text_unformatted("Click to run sample. ESC to quit.")
    end
    imgui.end_()

    -- Render
    gfx.begin_pass(gfx.Pass({
        action = gfx.PassAction({colors = {gfx.ColorAttachmentAction({
            load_action = gfx.LoadAction.CLEAR,
            clear_value = gfx.Color({r = 0.1, g = 0.1, b = 0.15, a = 1.0}),
        })}}),
        swapchain = glue.swapchain(),
    }))
    imgui.render()
    gfx.end_pass()
    gfx.commit()
end

local function sample_frame()
    -- Update physics
    if not paused then
        b2d.world_step(world, 1.0 / hertz, sub_steps)
    end

    -- Custom update
    if sample_module.update then
        sample_module.update(world, 1.0 / hertz)
    end

    -- ImGui overlay
    imgui.new_frame()

    imgui.set_next_window_pos({10, 10}, 2)  -- Cond.ONCE = 2
    imgui.set_next_window_size({220, 280}, 2)  -- Cond.ONCE = 2

    if imgui.begin("Controls") then
        imgui.text_unformatted(current_sample.name)
        imgui.separator()

        if imgui.button(paused and "Resume" or "Pause") then
            paused = not paused
        end
        if imgui.button("Restart") then
            restart_sample()
        end
        if imgui.button("Back to Menu") then
            state = "menu_pending"  -- defer to end of frame
        end

        imgui.separator()
        local changed, new_hertz = imgui.slider_int("Hz", hertz, 30, 120)
        if changed then hertz = new_hertz end

        local changed2, new_steps = imgui.slider_int("Sub-steps", sub_steps, 1, 8)
        if changed2 then sub_steps = new_steps end

        imgui.separator()
        imgui.text_unformatted("R: Restart, P: Pause")
        imgui.text_unformatted("ESC: Menu")

        -- Sample-specific controls
        if sample_module.controls then
            imgui.separator()
            imgui.text_unformatted("Sample Controls:")
            imgui.text_unformatted(sample_module.controls)
        end
    end
    imgui.end_()

    -- Render scene
    gfx.begin_pass(gfx.Pass({
        action = gfx.PassAction({colors = {gfx.ColorAttachmentAction({
            load_action = gfx.LoadAction.CLEAR,
            clear_value = gfx.Color({r = 0.2, g = 0.2, b = 0.3, a = 1.0}),
        })}}),
        swapchain = glue.swapchain(),
    }))

    draw.begin_frame(camera)
    if sample_module.render then
        sample_module.render(camera, world)
    end
    draw.end_frame()

    imgui.render()
    gfx.end_pass()
    gfx.commit()

    -- Handle deferred menu switch
    if state == "menu_pending" then
        switch_to_menu()
    end
end

local function menu_event(ev)
    imgui.handle_event(ev)

    if ev.type == app.EventType.KEY_DOWN then
        if ev.key_code == app.Keycode.ESCAPE then
            app.quit()
        end
    end
end

local function sample_event(ev)
    imgui.handle_event(ev)

    -- Camera events (always allow for now)
    camera:on_event(ev)

    if ev.type == app.EventType.KEY_DOWN then
        if ev.key_code == app.Keycode.ESCAPE then
            switch_to_menu()
        elseif ev.key_code == app.Keycode.R then
            restart_sample()
        elseif ev.key_code == app.Keycode.P then
            paused = not paused
        end
        -- Sample-specific key handling
        if sample_module.on_key then
            sample_module.on_key(ev.key_code, world)
        end
    end
    if ev.type == app.EventType.MOUSE_DOWN and sample_module.on_mouse_down then
        local wx, wy = camera:screen_to_world(ev.mouse_x, ev.mouse_y)
        sample_module.on_mouse_down(wx, wy, ev.mouse_button, world, camera)
    elseif ev.type == app.EventType.MOUSE_UP and sample_module.on_mouse_up then
        local wx, wy = camera:screen_to_world(ev.mouse_x, ev.mouse_y)
        sample_module.on_mouse_up(wx, wy, ev.mouse_button, world, camera)
    elseif ev.type == app.EventType.MOUSE_MOVE and sample_module.on_mouse_move then
        local wx, wy = camera:screen_to_world(ev.mouse_x, ev.mouse_y)
        sample_module.on_mouse_move(wx, wy, world, camera)
    end
end

app.run(app.Desc({
    width = 800,
    height = 600,
    window_title = "Box2D Samples",

    init_cb = function()
        gfx.setup(gfx.Desc({environment = glue.environment()}))
        imgui.setup()
        draw.setup()
    end,

    frame_cb = function()
        if state == "menu" then
            menu_frame()
        elseif state == "sample" then
            sample_frame()
        end
    end,

    cleanup_cb = function()
        if state == "sample" then
            switch_to_menu()
        end
        draw.shutdown()
        imgui.shutdown()
        gfx.shutdown()
    end,

    event_cb = function(ev)
        if state == "menu" then
            menu_event(ev)
        elseif state == "sample" then
            sample_event(ev)
        end
    end,
}))
