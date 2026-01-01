-- mane3d example: Section 8 - Lighting
-- Based on lettier/3d-game-shaders-for-beginners
local gfx = require("sokol.gfx")
local app = require("sokol.app")
local glue = require("sokol.glue")
local util = require("util")
local glm = require("glm")

-- Camera
local camera_pos = glm.vec3(0, -15, 8)
local camera_target = glm.vec3(0, 0, 3)
local camera_up = glm.vec3(0, 0, 1)  -- Z-up coordinate system
local camera_yaw = 0
local camera_pitch = 0.3

-- Light
local light_pos = glm.vec3(5, -5, 10)
local light_color = glm.vec3(2, 1.9, 1.8)  -- brighter
local ambient_color = glm.vec3(0.5, 0.5, 0.5)  -- brighter

-- Graphics resources
local shader = nil
local pipeline = nil
local vbuf = nil
local ibuf = nil
local mesh_data = nil

-- Time
local t = 0

-- Input
local keys_down = {}
local mouse_captured = false
local last_mouse_x, last_mouse_y = 0, 0

-- Shader: Phong lighting with texture support
local shader_source = [[
@vs vs
in vec3 pos;
in vec3 normal;
in vec2 uv;

out vec3 v_normal;
out vec3 v_world_pos;
out vec4 v_diffuse;
out vec4 v_light_pos;
out vec4 v_light_color;
out vec4 v_ambient;
out vec4 v_camera_pos;
out vec4 v_specular;

layout(binding=0) uniform params {
    mat4 mvp;
    mat4 model;
    vec4 light_pos;
    vec4 light_color;
    vec4 ambient_color;
    vec4 camera_pos;
    vec4 material_diffuse;
    vec4 material_specular;  // w = shininess
};

void main() {
    gl_Position = mvp * vec4(pos, 1.0);
    v_normal = normalize(mat3(model) * normal);
    v_world_pos = (model * vec4(pos, 1.0)).xyz;
    v_diffuse = material_diffuse;
    v_light_pos = light_pos;
    v_light_color = light_color;
    v_ambient = ambient_color;
    v_camera_pos = camera_pos;
    v_specular = material_specular;
}
@end

@fs fs
in vec3 v_normal;
in vec3 v_world_pos;
in vec4 v_diffuse;
in vec4 v_light_pos;
in vec4 v_light_color;
in vec4 v_ambient;
in vec4 v_camera_pos;
in vec4 v_specular;

out vec4 frag_color;

void main() {
    vec3 n = normalize(v_normal);
    vec3 light_dir = normalize(v_light_pos.xyz - v_world_pos);
    vec3 view_dir = normalize(v_camera_pos.xyz - v_world_pos);

    // Ambient
    vec3 ambient = v_ambient.rgb * v_diffuse.rgb;

    // Diffuse
    float diff = max(dot(n, light_dir), 0.0);
    vec3 diffuse = v_light_color.rgb * diff * v_diffuse.rgb;

    // Specular (Blinn-Phong)
    vec3 halfway = normalize(light_dir + view_dir);
    float spec = pow(max(dot(n, halfway), 0.0), v_specular.w);
    vec3 specular = v_light_color.rgb * spec * v_specular.rgb;

    vec3 result = ambient + diffuse + specular;
    frag_color = vec4(result, 1.0);
}
@end

@program lighting vs fs
]]

-- Generate a simple cube for testing
local function make_cube_vertices()
    local v = {}
    local faces = {
        -- front (z+)
        {{ -0.5, -0.5,  0.5}, { 0.5, -0.5,  0.5}, { 0.5,  0.5,  0.5}, {-0.5,  0.5,  0.5}, {0, 0, 1}, {{0,0},{1,0},{1,1},{0,1}}},
        -- back (z-)
        {{ 0.5, -0.5, -0.5}, {-0.5, -0.5, -0.5}, {-0.5,  0.5, -0.5}, { 0.5,  0.5, -0.5}, {0, 0, -1}, {{0,0},{1,0},{1,1},{0,1}}},
        -- top (y+)
        {{-0.5,  0.5,  0.5}, { 0.5,  0.5,  0.5}, { 0.5,  0.5, -0.5}, {-0.5,  0.5, -0.5}, {0, 1, 0}, {{0,0},{1,0},{1,1},{0,1}}},
        -- bottom (y-)
        {{-0.5, -0.5, -0.5}, { 0.5, -0.5, -0.5}, { 0.5, -0.5,  0.5}, {-0.5, -0.5,  0.5}, {0, -1, 0}, {{0,0},{1,0},{1,1},{0,1}}},
        -- right (x+)
        {{ 0.5, -0.5,  0.5}, { 0.5, -0.5, -0.5}, { 0.5,  0.5, -0.5}, { 0.5,  0.5,  0.5}, {1, 0, 0}, {{0,0},{1,0},{1,1},{0,1}}},
        -- left (x-)
        {{-0.5, -0.5, -0.5}, {-0.5, -0.5,  0.5}, {-0.5,  0.5,  0.5}, {-0.5,  0.5, -0.5}, {-1, 0, 0}, {{0,0},{1,0},{1,1},{0,1}}},
    }

    for _, face in ipairs(faces) do
        local n = face[5]
        local uvs = face[6]
        for i = 1, 4 do
            local p = face[i]
            -- pos (3) + normal (3) + uv (2) = 8 floats
            table.insert(v, p[1])
            table.insert(v, p[2])
            table.insert(v, p[3])
            table.insert(v, n[1])
            table.insert(v, n[2])
            table.insert(v, n[3])
            table.insert(v, uvs[i][1])
            table.insert(v, uvs[i][2])
        end
    end
    return v
end

local function make_cube_indices()
    local indices = {}
    for face = 0, 5 do
        local base = face * 4
        table.insert(indices, base + 0)
        table.insert(indices, base + 1)
        table.insert(indices, base + 2)
        table.insert(indices, base + 0)
        table.insert(indices, base + 2)
        table.insert(indices, base + 3)
    end
    return indices
end

local function pack_indices(indices)
    return string.pack(string.rep("H", #indices), table.unpack(indices))
end

function init()
    util.info("Lighting example init")

    -- Compile shader
    -- Single uniform block: 2 mat4 + 6 vec4 = 128 + 96 = 224 bytes
    shader = util.compile_shader(shader_source, "lighting", {
        {
            stage = gfx.ShaderStage.VERTEX,
            size = 224,
            glsl_uniforms = {
                { type = gfx.UniformType.MAT4, glsl_name = "mvp" },
                { type = gfx.UniformType.MAT4, glsl_name = "model" },
                { type = gfx.UniformType.FLOAT4, glsl_name = "light_pos" },
                { type = gfx.UniformType.FLOAT4, glsl_name = "light_color" },
                { type = gfx.UniformType.FLOAT4, glsl_name = "ambient_color" },
                { type = gfx.UniformType.FLOAT4, glsl_name = "camera_pos" },
                { type = gfx.UniformType.FLOAT4, glsl_name = "material_diffuse" },
                { type = gfx.UniformType.FLOAT4, glsl_name = "material_specular" },
            },
        },
    }, {
        { hlsl_sem_name = "TEXCOORD", hlsl_sem_index = 0 },
        { hlsl_sem_name = "TEXCOORD", hlsl_sem_index = 1 },
        { hlsl_sem_name = "TEXCOORD", hlsl_sem_index = 2 },
    })

    if not shader then
        util.error("Failed to compile shader")
        return
    end

    -- Create pipeline
    pipeline = gfx.make_pipeline(gfx.PipelineDesc({
        shader = shader,
        layout = {
            attrs = {
                { format = gfx.VertexFormat.FLOAT3 },  -- pos
                { format = gfx.VertexFormat.FLOAT3 },  -- normal
                { format = gfx.VertexFormat.FLOAT2 },  -- uv
            },
        },
        index_type = gfx.IndexType.UINT16,
        cull_mode = gfx.CullMode.BACK,
        depth = {
            write_enabled = true,
            compare = gfx.CompareFunc.LESS_EQUAL,
        },
    }))

    -- Create cube geometry
    local vertices = make_cube_vertices()
    local indices = make_cube_indices()

    vbuf = gfx.make_buffer(gfx.BufferDesc({
        data = gfx.Range(util.pack_floats(vertices)),
    }))

    ibuf = gfx.make_buffer(gfx.BufferDesc({
        usage = { index_buffer = true },
        data = gfx.Range(pack_indices(indices)),
    }))

    mesh_data = {
        vertex_count = #vertices / 8,
        index_count = #indices,
    }

    util.info("Init complete")
end

function frame()
    t = t + 1/60

    -- Update camera based on input
    local move_speed = 0.2
    local forward = glm.vec3(
        math.sin(camera_yaw) * math.cos(camera_pitch),
        math.cos(camera_yaw) * math.cos(camera_pitch),
        math.sin(camera_pitch)
    )
    local right = glm.normalize(glm.cross(forward, camera_up))

    if keys_down["W"] then camera_pos = camera_pos + forward * move_speed end
    if keys_down["S"] then camera_pos = camera_pos - forward * move_speed end
    if keys_down["A"] then camera_pos = camera_pos - right * move_speed end
    if keys_down["D"] then camera_pos = camera_pos + right * move_speed end
    if keys_down["SPACE"] then camera_pos = camera_pos + camera_up * move_speed end
    if keys_down["LEFT_SHIFT"] then camera_pos = camera_pos - camera_up * move_speed end

    -- Animate light
    light_pos = glm.vec3(
        math.sin(t * 0.5) * 8,
        math.cos(t * 0.5) * 8,
        6 + math.sin(t * 0.3) * 2
    )

    -- Matrices
    local w = app.width()
    local h = app.height()
    local aspect = w / h

    local proj = glm.perspective(math.rad(60), aspect, 0.1, 100)
    -- Simple fixed camera looking at origin
    local eye = glm.vec3(0, -10, 5)
    local center = glm.vec3(0, 0, 0)
    local up = glm.vec3(0, 0, 1)
    local view = glm.lookat(eye, center, up)
    camera_pos = eye  -- for lighting calculation

    -- Begin pass
    gfx.begin_pass(gfx.Pass({
        action = gfx.PassAction({
            colors = {{
                load_action = gfx.LoadAction.CLEAR,
                clear_value = { r = 0.1, g = 0.1, b = 0.15, a = 1.0 }
            }},
            depth = {
                load_action = gfx.LoadAction.CLEAR,
                clear_value = 1.0
            },
        }),
        swapchain = glue.swapchain(),
    }))

    gfx.apply_pipeline(pipeline)
    gfx.apply_bindings(gfx.Bindings({
        vertex_buffers = { vbuf },
        index_buffer = ibuf,
    }))

    -- Draw multiple cubes
    local positions = {
        {0, 0, 0},
        {3, 0, 0},
        {-3, 0, 0},
        {0, 3, 0},
        {0, -3, 0},
        {0, 0, 3},
        {1.5, 1.5, 1.5},
        {-1.5, -1.5, 1.5},
    }

    local colors = {
        {1, 0.3, 0.3},
        {0.3, 1, 0.3},
        {0.3, 0.3, 1},
        {1, 1, 0.3},
        {1, 0.3, 1},
        {0.3, 1, 1},
        {1, 0.6, 0.2},
        {0.6, 0.2, 1},
    }

    for i, pos in ipairs(positions) do
        local model = glm.translate(glm.vec3(pos[1], pos[2], pos[3]))
        model = model * glm.rotate(t * (0.5 + i * 0.1), glm.vec3(0.5, 0.3, 0.1):normalize())
        local mvp = proj * view * model

        local color = colors[i]

        -- All uniforms in one block: mvp, model, light_pos, light_color, ambient_color, camera_pos, diffuse, specular
        local uniforms = mvp:pack() .. model:pack() .. util.pack_floats({
            light_pos.x, light_pos.y, light_pos.z, 1,
            light_color.x, light_color.y, light_color.z, 1,
            ambient_color.x, ambient_color.y, ambient_color.z, 1,
            camera_pos.x, camera_pos.y, camera_pos.z, 1,
            color[1], color[2], color[3], 1,  -- diffuse
            0.5, 0.5, 0.5, 32,  -- specular + shininess
        })

        gfx.apply_uniforms(0, gfx.Range(uniforms))
        gfx.draw(0, mesh_data.index_count, 1)
    end

    -- Draw light indicator (small bright cube)
    local light_model = glm.translate(light_pos) * glm.scale(glm.vec3(0.2, 0.2, 0.2))
    local light_mvp = proj * view * light_model

    local uniforms = light_mvp:pack() .. light_model:pack() .. util.pack_floats({
        light_pos.x, light_pos.y, light_pos.z, 1,
        1, 1, 1, 1,  -- light color (ignored for emissive)
        5, 5, 5, 1,  -- high ambient = emissive look
        camera_pos.x, camera_pos.y, camera_pos.z, 1,
        1, 0.9, 0.7, 1,  -- yellow diffuse
        0, 0, 0, 1,  -- no specular
    })

    gfx.apply_uniforms(0, gfx.Range(uniforms))
    gfx.draw(0, mesh_data.index_count, 1)

    gfx.end_pass()
    gfx.commit()
end

function event(ev)
    if ev:type() == app.EventType.KEY_DOWN then
        local key = ev:key_code()
        if key == app.KeyCode.ESCAPE then
            mouse_captured = false
            app.show_mouse(true)
            app.lock_mouse(false)
        elseif key == app.KeyCode.W then keys_down["W"] = true
        elseif key == app.KeyCode.S then keys_down["S"] = true
        elseif key == app.KeyCode.A then keys_down["A"] = true
        elseif key == app.KeyCode.D then keys_down["D"] = true
        elseif key == app.KeyCode.SPACE then keys_down["SPACE"] = true
        elseif key == app.KeyCode.LEFT_SHIFT then keys_down["LEFT_SHIFT"] = true
        end
    elseif ev:type() == app.EventType.KEY_UP then
        local key = ev:key_code()
        if key == app.KeyCode.W then keys_down["W"] = false
        elseif key == app.KeyCode.S then keys_down["S"] = false
        elseif key == app.KeyCode.A then keys_down["A"] = false
        elseif key == app.KeyCode.D then keys_down["D"] = false
        elseif key == app.KeyCode.SPACE then keys_down["SPACE"] = false
        elseif key == app.KeyCode.LEFT_SHIFT then keys_down["LEFT_SHIFT"] = false
        end
    elseif ev:type() == app.EventType.MOUSE_DOWN then
        mouse_captured = true
        app.show_mouse(false)
        app.lock_mouse(true)
    elseif ev:type() == app.EventType.MOUSE_MOVE then
        if mouse_captured then
            local dx = ev:mouse_dx()
            local dy = ev:mouse_dy()
            camera_yaw = camera_yaw + dx * 0.003
            camera_pitch = camera_pitch - dy * 0.003
            camera_pitch = math.max(-1.5, math.min(1.5, camera_pitch))
        end
    end
end

function cleanup()
    util.info("Lighting cleanup")
end
