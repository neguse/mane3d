Lua Binding Mapping and Automation Plan (Draft)
================================================

Purpose
-------
Define a consistent, scalable mapping from C/C++ APIs to Lua, and outline
an automation pipeline that can keep up as new deps are added.
Primary direction: raw bindings are auto-generated; higher-level API design
is optional and typically manual.

Scope
-----
- Libraries: sokol, imgui, bc7enc, box2d, stb, and future deps in deps/.
- Output targets: C binding layer, Lua module wrapper, LuaCATS type stubs.

Non-goals (for now)
-------------------
- Performance tuning of individual bindings.
- Runtime feature changes in existing Lua modules.

Lua Mapping Specification
-------------------------

Modules and naming
------------------
- C prefix or C++ namespace maps to a Lua module.
- Function names become snake_case with prefix removed.
- Lua keywords get a trailing underscore.
- C++ overloads are unified under one Lua name using type dispatch.
  - A secondary, mangled suffix form can be generated for debugging or
    direct calls when needed.

Primitive and enum types
------------------------
- bool/int/float/double -> boolean/integer/number.
- const char* -> string.
- enums -> integer, with constants exposed as Module.EnumName.
- flag enums remain numeric (bit ops in Lua).

Structs and POD types
---------------------
- Struct constructors: T({ ... }) returns userdata with metatable.
- Fields are readable and writable via __index/__newindex.
- Small math types (Vec2, Vec4, Color, Rot, etc.) accept:
  - array form: {1, 2, ...}
  - named form: {x=, y=, z=, w=}

Handles and ownership
---------------------
- Handle-like IDs are userdata or integers consistently per library.
- create/destroy pairing is preserved.
- __gc policy is decided per library and documented.

Pointers, arrays, and buffers
-----------------------------
- const void* + size:
  - accept string (binary blob), or lightuserdata + size.
- T* non-const are treated as out or inout:
  - expose extra return values in Lua.
- const T* + count:
  - accept Lua array of tables.
- Fixed arrays (T[N]):
  - accept Lua array of values.

Callbacks
---------
- Lua function registered and stored in registry.
- Trampoline handles Lua -> C calls with type conversion.
- Lifetime of the callback is explicit and tied to the owning struct/object.

Error and status handling
-------------------------
- Prefer returning values as-is if the C API already signals errors.
- If needed, use (nil, err) for failures in wrapper-layer logic.

Binding Approaches and Trade-offs
---------------------------------

Current approach in this repo (clang IR + Python codegen)
---------------------------------------------------------
- Flow: clang AST -> normalized IR -> C wrappers + Lua wrappers + LuaCATS.
- Pros:
  - Works well for C APIs (sokol, stb, bc7enc).
  - Deterministic output; easy to diff and regenerate.
  - No runtime dependency beyond Lua C API.
  - Can emit type stubs alongside code.
- Cons:
  - Edge cases require manual rules (callbacks, special structs, C++ refs).
  - C++ headers add complexity (namespaces, overloads, templates).
  - Requires clang and build-time tooling setup.

Alternative: sol2 v3 (C++ binding library)
------------------------------------------
Overview
  - Bindings are written in C++ using templates (no separate codegen step).
  - C++ types/classes are exposed via usertype registration.
  - Runtime binding is created during module init.

Pros
  - Strong C++ support: classes, methods, overloads, properties.
  - Type-safe bindings with compile-time checking.
  - No AST/IR pipeline to maintain.
  - Good fit when the API is already C++ and object-oriented.

Cons
  - Requires C++ binding code for each library (manual maintenance).
  - Template-heavy; compile times and binary size can grow.
  - Not ideal for pure C APIs unless you write wrappers.
  - Harder to auto-generate LuaCATS types without extra tooling.
  - Binding shape lives in C++ code (diffs are less obvious than IR output).

Fit for this project
  - ImGui/Box2D could be bound via sol2, but still need manual type adapters
    for ImVec2/ImVec4, callbacks, and out params.
  - C libs (sokol, stb, bc7enc) would need C++ wrappers, losing some of the
    advantage of direct C binding.
  - Mixed approach is possible but increases complexity and build time.

Other binding approaches (brief)
--------------------------------
- Manual Lua C API:
  - Pros: minimal deps, maximum control, minimal binary size.
  - Cons: slow to write, error-prone, hard to keep in sync.
- SWIG/tolua++ style generators:
  - Pros: broad language support, quick start.
  - Cons: limited control, dated workflows, hard to customize.
- LuaJIT FFI (if using LuaJIT):
  - Pros: no C glue, fast iteration.
  - Cons: not available on standard Lua, ABI pitfalls, weaker lifetime control.

Single-method feasibility and manual split
------------------------------------------
Short answer: a single method can wrap a large subset, but not "most libraries"
in a robust, idiomatic way. A manual/automatic split is realistically required.

Why single-method breaks down
-----------------------------
- C++ templates, overload sets, and inline-heavy APIs are hard to reflect cleanly.
- Ownership and lifetime rules rarely map 1:1 to Lua GC.
- Callbacks and function pointers need explicit trampoline code.
- APIs using out params, custom allocators, or thread-local state need custom glue.
- Macros and conditional compilation often hide APIs from a generic AST pass.

Recommended split (policy)
--------------------------
Auto-bind by default
- C ABI, free functions.
- Primitive types, enums, POD structs.
- Handle-style IDs with explicit create/destroy.
- Arrays with explicit count and clear ownership.

Manual or shim-required
- Complex C++ classes, templates, virtual dispatch.
- APIs returning owned pointers or requiring caller-managed buffers.
- Callbacks, event systems, or async task APIs.
- Non-POD structs, unions, bitfields, or opaque private fields.
- Function-pointer fields inside structs.

Operational approach
--------------------
- Start from auto-generated bindings.
- Use a manifest to mark: skip, rename, override type mapping, and manual shims.
- Maintain "bindability" rules that flag functions needing manual handling.
- Prefer C shims when a C++ API blocks clean auto-binding.

Current deps mapped to patterns
-------------------------------

Pattern P1: Flat C API + POD + handle-style IDs
- Libraries: sokol
- Notes:
  - Many "Desc" structs and value-type handles.
  - Some callback fields inside structs (sapp, saudio).
  - Special-case binary ranges (sg_range).

Pattern P2: Data-processing C/C++ API with binary buffers
- Libraries: stb (stb_image), bc7enc (manual C++ wrapper)
- Notes:
  - Functions take byte buffers and return byte buffers.
  - Library-owned memory must be freed in C after copying to Lua.
  - Options are best passed as Lua tables.

Pattern P3: C API with rich math structs + arrays + callbacks
- Libraries: box2d
- Notes:
  - Many small math types (b2Vec2, b2Rot, b2Transform).
  - Arrays and (ptr, count) pairs are common.
  - Task callbacks and event streams need trampolines or shims.

Pattern P4: C++ namespace API with overloads and references
- Libraries: imgui
- Notes:
  - Overloads need type-based dispatch.
  - References (const ImVec2&) map to table forms.
  - Many functions require manual skip or custom wrappers.

Pattern-specific transformations
--------------------------------

P1: Flat C API + POD + handle-style IDs
- Convert prefix to module and snake_case function names.
- Generate struct constructors from Lua tables.
- Map handle structs to userdata; keep create/destroy as-is.
- Convert sg_range (or similar) from Lua string to {ptr, size}.
- Generate callback trampolines for function-pointer fields.

P2: Data-processing C/C++ API with binary buffers
- Accept input as Lua strings; validate size.
- Return output as Lua strings; free C buffers immediately after copy.
- Use Lua tables for optional params with defaults.
- Convert errors to (nil, message).
- Optional: add C shim if the API is C++-only (bc7enc).

P3: C API with rich math structs + arrays + callbacks
- Map math structs to table forms (array or named fields).
- Convert (const T*, count) to Lua arrays, allocate temp C arrays.
- Return out params as extra return values.
- Provide callback registration and lifetime rules.
- For event buffers, return arrays of tables (or iterators).

P4: C++ namespace API with overloads and references
- Generate mangled C wrappers per overload.
- Provide Lua-side dispatch based on type (table vs number vs string).
- Map references to table forms; return tables for value structs.
- Skip complex callbacks or provide manual wrappers where needed.

Bindability rules (auto vs manual)
----------------------------------

Auto-bind eligible (default)
----------------------------
- C ABI (or exposed as C via shim).
- Functions with parameters limited to:
  - primitives, enums, POD structs
  - const T* + count (array input)
  - const void* + size (binary input)
  - T* out params (converted to extra returns)
- Structs with:
  - POD fields only (no unions/bitfields/opaque internals)
  - no function pointers inside (unless callback support is enabled)
- No varargs.
- No ownership transfer of heap memory without a matching free function.

Manual/shim required
--------------------
- C++ classes, templates, virtual methods, or heavy overload sets.
- APIs returning owned pointers or requiring caller-managed buffers.
- Callback-heavy APIs (events, async, function-pointer fields) unless a
  supported trampoline pattern exists.
- Opaque structs without handle semantics or missing create/destroy pairs.
- Non-POD structs, unions, bitfields, or flexible array members.
- APIs hidden behind macros/ifdefs where AST cannot see full surface.

Bindability analyzer output
---------------------------
- For each function/struct:
  - classification: auto | needs_shim | skip
  - reasons list (e.g., "varargs", "function pointer", "returns owned ptr")
  - confidence score (low/medium/high)
- Manifest can override any classification explicitly.
Policy preference: allowlist-based selection (wildcard/regex) to reduce drift,
instead of long skip lists.

API observation checklist
-------------------------
Before deciding auto vs manual, inspect the C/C++ API with this checklist:

Ownership and lifetime
----------------------
- Who owns returned pointers or buffers? Is there a matching free?
- Are handles invalidated by shutdown/reinit?
- Are IDs recycled (can stale IDs reappear)?

Threading and callbacks
-----------------------
- Is the API thread-safe? Which functions are main-thread only?
- Callbacks: which thread do they run on? Re-entrant? Can they call back into API?
- Are callbacks stored in structs or set via registration functions?

Data shapes and semantics
-------------------------
- Does the API rely on (ptr, count) patterns? Fixed arrays? Flexible arrays?
- Are there unions / bitfields / opaque structs?
- Do ints/void* encode enums or flags (implicit types)?

Error and control flow
----------------------
- Error signaling: return codes, errno, exceptions, logging?
- Do errors require cleanup or additional calls?

API style and intent
--------------------
- Is the API fundamentally declarative or imperative?
- Are “Descriptor/Def” structs expected to be partially filled?
- Is there a stable subset that should be frozen as a long-term Lua API?

Converting C/C++ API reference to Lua reference
-----------------------------------------------
Goal: keep Lua API docs in sync with upstream C/C++ headers.

Approach
--------
- Use the same IR as binding generation as the source of truth.
- Generate Lua-facing docs/types:
  - LuaCATS stubs (already in use).
  - Optional Markdown reference with function signatures and brief notes.
- Apply the same allow/skip patterns as bindings to avoid drift.

Doc mapping rules (raw bindings)
--------------------------------
- Function names: snake_case with prefix removed.
- Types: map to LuaCATS equivalents (number/integer/boolean/string, core types).
- Out params: listed as additional return values.
- Structs: document as constructor + fields (if exposed).
- Enums/flags: list constants and note bitwise usage.

Manual additions
----------------
- For APIs that require shims, allow per-function manual doc overrides.
- Keep a small “doc patch” file per module when needed.

Current deps: bindability classification (summary)
--------------------------------------------------
Note: high-level summary only; final decisions live in manifests.

sokol
-----
- auto: most of the flat C API and POD structs (sg_*, sapp_*, stm_*, etc.).
- needs_shim: callbacks in structs (sapp callbacks, saudio stream), sg_range
  (string/buffer mapping), and dummy backend variations.
- skip/manual: platform-specific handles where Lua exposure is undesired.

imgui
-----
- auto: limited subset via generated C wrappers for simple functions/structs.
- needs_shim: overload resolution, const ref params (ImVec2/ImVec4),
  and selected functions that require custom dispatch.
- skip/manual: functions with complex callbacks, internal state, or
  heavy pointer usage (already skipped in generator).

box2d
-----
- auto: most C API functions and POD structs with math types.
- needs_shim: task system callbacks, event streams, and (ptr,count) arrays
  that require temporary allocations.
- skip/manual: opaque internal structs or APIs not exposed in current generator.

stb (stb_image)
--------------
- auto: simple functions with string buffers (file/memory load).
- needs_shim: none beyond error mapping and string/buffer handling.

bc7enc (rdo_bc_encoder)
-----------------------
- auto: no (C++ API is not a clean C ABI).
- needs_shim: required C++ wrapper to expose a C-friendly surface.
- skip/manual: direct binding to C++ types without wrapper.

Minimal manifest schema (v0)
----------------------------
Purpose: enough data to classify APIs and generate bindings deterministically.

Required
- module: Lua module name (e.g., "sokol.gfx", "imgui", "b2d")
- language: "c" or "c++"
- headers: entry header(s)
- include_paths: include search paths
- defines: compile-time defines for AST extraction

Optional
- prefix/namespace: C prefix or C++ namespace
- output:
  - c_binding: output path for generated C/C++ bindings
  - lua_wrapper: output path for Lua wrapper (if used)
  - types: output path for LuaCATS stubs
- rules:
  - allow_out_params: true/false
  - array_patterns: list of (ptr,count) parameter pairs
  - buffer_types: map (e.g., sg_range => string/buffer)
  - struct_table_forms: map of struct -> {array|named|both}
  - callback_support: true/false
  - strict_validation_default: strict|fast
- overrides:
  - allow: list of function/struct name patterns (wildcard/regex)
  - skip: list of function/struct name patterns (wildcard/regex)
  - rename: map original -> lua_name
  - type_override: map type -> lua_type
  - manual_shim: list of functions handled by custom code

Example (YAML)
--------------
module: "b2d"
language: "c"
headers:
  - "deps/box2d/include/box2d/box2d.h"
include_paths:
  - "deps/box2d/include"
defines: []
prefix: "b2"
output:
  c_binding: "gen/bindings/b2d.c"
  types: "gen/types/b2d.lua"
rules:
  allow_out_params: true
  array_patterns:
    - {ptr: "const b2Vec2*", count: "int"}
  struct_table_forms:
    b2Vec2: both
    b2Rot: both
  callback_support: true
overrides:
  allow:
    - "^b2[A-Za-z0-9_]*$"
  skip:
    - "^b2World_Draw$"
  manual_shim:
    - "b2SetAllocator"

Automation Plan
---------------

Pipeline overview
-----------------
1. Read manifest for each library (headers, include paths, defines).
2. Extract AST/IR via clang (C or C++).
3. Normalize IR into a common schema.
4. Apply mapping rules and overrides.
5. Generate:
   - C binding layer (Lua C API)
   - Lua wrapper (type dispatch, convenience API)
   - LuaCATS type stubs
6. Emit diff report and basic validation output.

Manifest requirements (per library)
-----------------------------------
- Header entry points and include paths.
- Defines and language mode (C vs C++).
- Prefix/namespace and module name.
- Skip/rename rules.
- Type overrides (Vec2 is table, etc.).
- Out-params and callback rules.
- Ownership policy (gc or explicit destroy).

Shared runtime helpers
----------------------
- Common C helpers for:
  - stack checking
  - string/buffer conversion
  - array decoding/encoding
  - callback registration
  - error logging
- Keep generated code small by calling shared helpers.

C++ strategy options
--------------------
- Option A: parse C++ AST directly and generate bindings.
- Option B: generate a C shim per C++ lib, then treat as C.
- Recommendation: use B for complex C++ libs (ImGui, Box2D),
  A for simple C++ headers if needed.

Robustness and validation
-------------------------
- Report API diffs (added/removed/changed).
- Compile generated C/C++ bindings as a check step.
- Run a minimal Lua smoke test for module loads.

Static error detection and guardrails
------------------------------------
Goal: catch Lua wrapper mistakes without executing the game runtime.

Prevent mistakes (design-time)
------------------------------
- Keep Lua wrappers declarative (table-driven dispatch rules) where possible.
- Generate from a single source of truth (IR + manifest); avoid hand edits.
- Emit LuaCATS stubs for editor type checking and autocomplete.
- Keep templates small and deterministic to reduce AI/codegen drift.

Detect mistakes without execution
---------------------------------
- Parse-only syntax check: run `luac -p` on generated Lua files.
- Static lint: use luacheck for common Lua mistakes (unused vars, globals).
- Type checking: use lua-language-server with LuaCATS stubs (offline).
- Schema validation: validate generated module tables against expected signature
  (names, arity, and return counts) as a data-level check.
- Compile-only check of C/C++ bindings (no runtime execution).

Detect mistakes early (fast feedback)
-------------------------------------
- Fail generation on unknown/unsupported types unless explicitly allowed.
- Emit "TODO" markers and a report for manual review.
- Add small golden tests (expected wrappers) for critical APIs.
- Keep a "bindability" checklist that flags callbacks, out params, and C++
  references needing manual attention.

Notes on runtime checks
-----------------------
- Runtime smoke tests are still valuable, but should be a second line of
  defense after static checks.

Runtime validation for table-based APIs
---------------------------------------
Motivation: table-heavy APIs are easy to misuse (wrong type, wrong key, missing
required fields), so runtime checks are needed in addition to static checks.
Validation can run in strict or fast mode depending on build/runtime settings.

Recommended runtime checks
--------------------------
- Enforce table-or-userdata inputs when structs are expected.
- Validate required keys and type of each field (number/boolean/string/table).
- Validate enums and flag ranges when values are numeric.
- Validate array sizes for fixed-size fields (e.g., Vec2, Vec4).
- Warn or error on unknown keys in strict mode.
- Provide clear error messages: function name, parameter index, and key name.

Performance strategy
--------------------
- Gate checks behind a runtime flag (strict vs fast).
- Default to strict in debug/dev, fast in release.
- Optionally keep a lightweight "shape" check even in fast mode.

Generation hooks
----------------
- Emit per-struct validators from IR (field list and expected types).
- Reuse validators in:
  - struct constructors (T({ ... }))
  - functions that accept inline tables
- Allow manifest overrides to mark fields as optional or to skip validation.

Open Questions
--------------
- For each library, do we allow __gc destruction or keep manual destroy?
- For handles, should Lua use userdata or integer IDs consistently?
- For buffers, should binary strings be the primary path?

Next Steps
----------
1. Decide on ownership and handle policies.
2. Define the manifest schema (minimal v0).
3. Implement a pilot binding using the new pipeline (e.g., stb or bc7enc).
