import { EditorView, basicSetup } from 'codemirror'
import { StreamLanguage } from '@codemirror/language'
import { lua } from '@codemirror/legacy-modes/mode/lua'
import { oneDark } from '@codemirror/theme-one-dark'

const defaultCode = `-- Simple Raytracer - Sphere with lighting
local gfx = require("sokol.gfx")
local shdc = require("shdc")

local pip, bind
local time = 0

local vs = [[
@vs vs
in vec2 position;
out vec2 uv;
void main() {
    gl_Position = vec4(position, 0.0, 1.0);
    uv = position * 0.5 + 0.5;
}
@end
]]

local fs = [[
@fs fs
in vec2 uv;
out vec4 frag_color;

layout(binding=0) uniform fs_params {
    float time;
    vec2 resolution;
};

float sdSphere(vec3 p, float r) { return length(p) - r; }

vec3 getNormal(vec3 p) {
    vec2 e = vec2(0.001, 0);
    float d = sdSphere(p, 1.0);
    return normalize(vec3(
        sdSphere(p + e.xyy, 1.0) - d,
        sdSphere(p + e.yxy, 1.0) - d,
        sdSphere(p + e.yyx, 1.0) - d
    ));
}

void main() {
    vec2 st = (uv * 2.0 - 1.0) * vec2(resolution.x/resolution.y, 1.0);
    vec3 camPos = vec3(sin(time*0.5)*3.0, 1.0, cos(time*0.5)*3.0);
    vec3 rayDir = normalize(vec3(st, -1.5) - vec3(0, 0, 2));

    // Simple orbit camera
    float c = cos(time*0.5), s = sin(time*0.5);
    rayDir = vec3(rayDir.x*c - rayDir.z*s, rayDir.y, rayDir.x*s + rayDir.z*c);

    float t = 0.0;
    vec3 col = vec3(0.1, 0.1, 0.2);
    for (int i = 0; i < 64; i++) {
        vec3 p = camPos + rayDir * t;
        float d = sdSphere(p, 1.0);
        if (d < 0.001) {
            vec3 n = getNormal(p);
            vec3 L = normalize(vec3(1, 1, 1));
            col = vec3(0.8, 0.3, 0.2) * max(dot(n, L), 0.1);
            col += pow(max(dot(reflect(-L, n), -rayDir), 0.0), 32.0) * 0.5;
            break;
        }
        t += d;
        if (t > 100.0) break;
    }
    frag_color = vec4(col, 1.0);
}
@end
@program raytracer vs fs
]]

function init()
    -- Compile shader (source, program_name, lang)
    local result = shdc.compile(vs .. fs, "raytracer", "wgsl")
    if not result.success then
        print("Shader compile error: " .. (result.error or "unknown"))
        return
    end

    -- Create shader from compiled sources
    local shd = gfx.make_shader(gfx.ShaderDesc({
        vertex_func = { source = result.vs_source },
        fragment_func = { source = result.fs_source },
        uniform_blocks = {
            {
                stage = gfx.ShaderStage.FRAGMENT,
                size = 16,  -- time (float) + padding + resolution (vec2)
            }
        }
    }))

    pip = gfx.make_pipeline(gfx.PipelineDesc({
        shader = shd,
        layout = {
            attrs = { { format = gfx.VertexFormat.FLOAT2 } }
        }
    }))

    -- Fullscreen triangle
    local verts = { -1, -1,  3, -1,  -1, 3 }
    local data = string.pack(string.rep("f", #verts), table.unpack(verts))
    bind = {
        vertex_buffers = { gfx.make_buffer(gfx.BufferDesc({ data = gfx.Range(data) })) }
    }
end

function frame()
    time = time + 1/60

    local glue = require("sokol.glue")

    gfx.begin_pass(gfx.Pass({
        action = gfx.PassAction({
            colors = {{
                load_action = gfx.LoadAction.CLEAR,
                clear_value = { r = 0, g = 0, b = 0, a = 1 }
            }}
        }),
        swapchain = glue.swapchain()
    }))

    gfx.apply_pipeline(pip)
    gfx.apply_bindings(gfx.Bindings(bind))

    -- Pack uniform data: time (float) + padding + resolution (vec2)
    local uniform_data = string.pack("ffff", time, 0, 800, 600)
    gfx.apply_uniforms(gfx.ShaderStage.FRAGMENT, gfx.Range(uniform_data))

    gfx.draw(0, 3, 1)
    gfx.end_pass()
    gfx.commit()
end

function cleanup() end
function event(ev) end
`

let editorView: EditorView | null = null

export function createEditor(container: HTMLElement): EditorView {
  editorView = new EditorView({
    doc: defaultCode,
    extensions: [
      basicSetup,
      StreamLanguage.define(lua),
      oneDark,
      EditorView.theme({
        '&': { height: '100%' },
        '.cm-scroller': { overflow: 'auto' },
      }),
    ],
    parent: container,
  })
  return editorView
}

export function getCode(): string {
  return editorView?.state.doc.toString() ?? ''
}

export function setCode(code: string): void {
  if (!editorView) return
  editorView.dispatch({
    changes: { from: 0, to: editorView.state.doc.length, insert: code },
  })
}
