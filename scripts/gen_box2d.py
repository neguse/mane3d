#!/usr/bin/env python3
"""
Generate Box2D Lua bindings from box2d.h
Based on gen_lua.py (Sokol) and gen_imgui.py patterns.

## Naming Convention

Box2D uses various naming patterns:
    b2CreateWorld       -> create_world
    b2World_Step        -> world_step
    b2Body_GetPosition  -> body_get_position
    b2DefaultWorldDef   -> default_world_def
    b2Vec2              -> Vec2 (struct)

All functions become snake_case, structs become PascalCase.
"""
import sys
import os
import json
from datetime import datetime

# Add scripts directory to path
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

import gen_ir_box2d as ir

# Functions to skip (callbacks, complex types, internal)
SKIP_FUNCTIONS = {
    # Task callbacks (handled in C, not Lua)
    'b2SetAllocator',
    # Debug draw (needs custom implementation)
    'b2World_Draw',
    # Functions with complex callback params (filtered by gen_ir_box2d)
}

# Structs to skip (opaque or complex)
SKIP_STRUCTS = {
    'b2DynamicTree',  # Complex internal tree structure
    'b2TreeNode',     # Internal node
}

# Structs with base b2JointDef that need flattened accessors
JOINT_DEF_STRUCTS = {
    'b2DistanceJointDef',
    'b2MotorJointDef',
    'b2FilterJointDef',
    'b2PrismaticJointDef',
    'b2RevoluteJointDef',
    'b2WeldJointDef',
    'b2WheelJointDef',
}

# Box2D basic types that may not be in IR but are used in function signatures
# These are defined in math_functions.h and other headers
BOX2D_BASIC_TYPES = {
    'b2Vec2', 'b2Rot', 'b2Transform', 'b2Mat22', 'b2AABB', 'b2CosSin',
    'b2WorldId', 'b2BodyId', 'b2ShapeId', 'b2JointId', 'b2ChainId',
    'b2ContactId',  # Contact ID
    'b2Circle', 'b2Capsule', 'b2Segment', 'b2Polygon', 'b2Plane',
    'b2Hull', 'b2SegmentDistanceResult', 'b2DistanceProxy',
    'b2DistanceCache', 'b2DistanceInput', 'b2DistanceOutput',
    'b2SimplexVertex', 'b2Simplex', 'b2ShapeCastPairInput',
    'b2CastOutput', 'b2MassData', 'b2RayCastInput', 'b2ShapeCastInput',
    'b2RayResult', 'b2WorldDef', 'b2BodyDef', 'b2Filter', 'b2QueryFilter',
    'b2ShapeDef', 'b2ChainDef', 'b2Profile', 'b2Counters',
    'b2BodyMoveEvent', 'b2ContactHitEvent', 'b2ContactBeginTouchEvent',
    'b2ContactEndTouchEvent', 'b2SensorBeginTouchEvent', 'b2SensorEndTouchEvent',
    'b2DistanceJointDef', 'b2MotorJointDef', 'b2MouseJointDef',
    'b2NullJointDef', 'b2PrismaticJointDef', 'b2RevoluteJointDef',
    'b2WeldJointDef', 'b2WheelJointDef', 'b2ExplosionDef',
    'b2DebugDraw', 'b2TreeStats', 'b2ContactData', 'b2Manifold',
    'b2ManifoldPoint', 'b2TOIInput', 'b2TOIOutput', 'b2SweepInput',
    'b2Sweep', 'b2SensorEvents', 'b2ContactEvents', 'b2BodyEvents',
}

# Lua reserved keywords
LUA_KEYWORDS = {'and', 'break', 'do', 'else', 'elseif', 'end', 'false', 'for',
                'function', 'goto', 'if', 'in', 'local', 'nil', 'not', 'or',
                'repeat', 'return', 'then', 'true', 'until', 'while'}

def as_snake_case(name, prefix='b2'):
    """Convert Box2D name to snake_case.

    Examples:
        b2CreateWorld       -> create_world
        b2World_Step        -> world_step
        b2Body_GetPosition  -> body_get_position
        b2DefaultWorldDef   -> default_world_def
    """
    # Remove prefix
    if name.lower().startswith(prefix.lower()):
        name = name[len(prefix):]

    # Handle underscore separator (e.g., World_Step)
    if '_' in name:
        parts = name.split('_')
        result = []
        for part in parts:
            # Convert CamelCase part to snake_case
            snake = []
            for i, c in enumerate(part):
                if c.isupper() and i > 0:
                    snake.append('_')
                snake.append(c.lower())
            result.append(''.join(snake))
        return '_'.join(result)

    # Convert CamelCase to snake_case
    result = []
    for i, c in enumerate(name):
        if c.isupper() and i > 0:
            result.append('_')
        result.append(c.lower())
    return ''.join(result)

def as_pascal_case(name, prefix='b2'):
    """Convert Box2D name to PascalCase for Lua struct names.

    Examples:
        b2WorldDef -> WorldDef
        b2Vec2     -> Vec2
    """
    if name.lower().startswith(prefix.lower()):
        name = name[len(prefix):]
    # Capitalize first letter
    if name:
        name = name[0].upper() + name[1:]
    return name

def is_prim_type(t):
    return t in ['int', 'bool', 'char', 'int8_t', 'uint8_t', 'int16_t', 'uint16_t',
                 'int32_t', 'uint32_t', 'int64_t', 'uint64_t', 'float', 'double',
                 'uintptr_t', 'intptr_t', 'size_t']

def is_int_type(t):
    return t in ['int', 'int8_t', 'uint8_t', 'int16_t', 'uint16_t',
                 'int32_t', 'uint32_t', 'int64_t', 'uint64_t', 'size_t',
                 'uintptr_t', 'intptr_t', 'char']

def is_float_type(t):
    return t in ['float', 'double']

def is_string_ptr(t):
    return t in ['const char *', 'const char*', 'char *', 'char*']

def is_void_ptr(t):
    normalized = t.replace(' ', '')
    return normalized in ['void*']

def is_const_void_ptr(t):
    normalized = t.replace(' ', '')
    return normalized in ['constvoid*']

def extract_ptr_type(t):
    """Extract inner type from pointer type."""
    t = t.strip()
    if t.startswith('const '):
        t = t[6:]
    if t.endswith('*'):
        t = t[:-1].strip()
    return t

def is_array_type(t):
    return '[' in t and ']' in t

def extract_array_type(t):
    """Extract base type from array type."""
    return t[:t.index('[')].strip()

def extract_array_size(t):
    """Extract array size from type."""
    start = t.index('[') + 1
    end = t.index(']')
    return int(t[start:end])


class Box2DBindingGenerator:
    def __init__(self, ir_data):
        self.ir = ir_data
        self.funcs = [d for d in ir_data['decls'] if d['kind'] == 'func']
        self.structs = [d for d in ir_data['decls'] if d['kind'] == 'struct']
        self.enums = [d for d in ir_data['decls'] if d['kind'] in ('enum', 'consts')]
        self.out_lines = []

        # Build type sets for lookups
        self.struct_types = {s['name'] for s in self.structs if s['name'] not in SKIP_STRUCTS}
        # Add Box2D basic types that may not be in IR
        self.struct_types.update(BOX2D_BASIC_TYPES)
        self.enum_types = {e['name'] for e in self.enums if e.get('name')}

        # Get b2JointDef fields from IR for flattened accessors
        self.joint_def_fields = []
        for s in self.structs:
            if s['name'] == 'b2JointDef':
                self.joint_def_fields = [f for f in s.get('fields', []) if f.get('name')]
                break

    def emit(self, line=''):
        self.out_lines.append(line)

    def is_struct_type(self, t):
        return t in self.struct_types

    def is_enum_type(self, t):
        return t in self.enum_types

    def is_struct_ptr(self, t):
        inner = extract_ptr_type(t)
        return self.is_struct_type(inner) and '*' in t and 'const' not in t

    def is_const_struct_ptr(self, t):
        inner = extract_ptr_type(t)
        return self.is_struct_type(inner) and '*' in t and 'const' in t

    def get_return_type(self, func):
        """Extract return type from function."""
        func_type = func['type']
        paren = func_type.find('(')
        if paren > 0:
            return func_type[:paren].strip()
        return func_type

    def should_skip_func(self, func):
        """Check if function should be skipped."""
        name = func['name']
        if name in SKIP_FUNCTIONS:
            return True
        return False

    def should_skip_struct(self, struct):
        """Check if struct should be skipped."""
        return struct['name'] in SKIP_STRUCTS

    def get_lua_push_code(self, type_str, var_name):
        """Generate code to push a C value onto the Lua stack."""
        if type_str == 'void':
            return None
        elif type_str == 'bool':
            return f'lua_pushboolean(L, {var_name});'
        elif is_int_type(type_str):
            return f'lua_pushinteger(L, (lua_Integer){var_name});'
        elif is_float_type(type_str):
            return f'lua_pushnumber(L, (lua_Number){var_name});'
        elif is_string_ptr(type_str):
            return f'lua_pushstring(L, {var_name});'
        elif type_str == 'b2Vec2':
            # Push as table {x, y}
            return f'''lua_newtable(L);
    lua_pushnumber(L, {var_name}.x); lua_rawseti(L, -2, 1);
    lua_pushnumber(L, {var_name}.y); lua_rawseti(L, -2, 2);'''
        elif type_str == 'b2Rot':
            # Push as table {c, s}
            return f'''lua_newtable(L);
    lua_pushnumber(L, {var_name}.c); lua_rawseti(L, -2, 1);
    lua_pushnumber(L, {var_name}.s); lua_rawseti(L, -2, 2);'''
        elif type_str == 'b2CosSin':
            return f'''lua_newtable(L);
    lua_pushnumber(L, {var_name}.cosine); lua_rawseti(L, -2, 1);
    lua_pushnumber(L, {var_name}.sine); lua_rawseti(L, -2, 2);'''
        elif type_str == 'b2Transform':
            # Push as table {{px, py}, {c, s}}
            return f'''lua_newtable(L);
    lua_newtable(L); lua_pushnumber(L, {var_name}.p.x); lua_rawseti(L, -2, 1); lua_pushnumber(L, {var_name}.p.y); lua_rawseti(L, -2, 2); lua_rawseti(L, -2, 1);
    lua_newtable(L); lua_pushnumber(L, {var_name}.q.c); lua_rawseti(L, -2, 1); lua_pushnumber(L, {var_name}.q.s); lua_rawseti(L, -2, 2); lua_rawseti(L, -2, 2);'''
        elif type_str == 'b2AABB':
            # Push as table {{lx, ly}, {ux, uy}}
            return f'''lua_newtable(L);
    lua_newtable(L); lua_pushnumber(L, {var_name}.lowerBound.x); lua_rawseti(L, -2, 1); lua_pushnumber(L, {var_name}.lowerBound.y); lua_rawseti(L, -2, 2); lua_rawseti(L, -2, 1);
    lua_newtable(L); lua_pushnumber(L, {var_name}.upperBound.x); lua_rawseti(L, -2, 1); lua_pushnumber(L, {var_name}.upperBound.y); lua_rawseti(L, -2, 2); lua_rawseti(L, -2, 2);'''
        elif self.is_struct_type(type_str):
            struct_name = as_pascal_case(type_str)
            return f'{type_str}* ud = ({type_str}*)lua_newuserdatauv(L, sizeof({type_str}), 0);\n    *ud = {var_name};\n    luaL_setmetatable(L, "b2d.{struct_name}");'
        elif self.is_enum_type(type_str):
            return f'lua_pushinteger(L, (lua_Integer){var_name});'
        elif is_void_ptr(type_str) or is_const_void_ptr(type_str):
            return f'lua_pushlightuserdata(L, (void*){var_name});'
        else:
            return f'/* TODO: push {type_str} */ lua_pushnil(L);'

    def get_lua_to_code(self, type_str, arg_index, var_name):
        """Generate code to get a C value from the Lua stack."""
        # Strip const for basic type checks
        base_type = type_str.replace('const ', '').strip()

        if type_str == 'bool':
            return f'bool {var_name} = lua_toboolean(L, {arg_index});'
        elif is_int_type(base_type):
            return f'{base_type} {var_name} = ({base_type})luaL_checkinteger(L, {arg_index});'
        elif is_float_type(base_type):
            return f'{base_type} {var_name} = ({base_type})luaL_checknumber(L, {arg_index});'
        elif is_string_ptr(type_str):
            return f'const char* {var_name} = luaL_checkstring(L, {arg_index});'
        elif base_type == 'b2Vec2':
            # Read from table {x, y} or {[1]=x, [2]=y}
            return f'''b2Vec2 {var_name};
    luaL_checktype(L, {arg_index}, LUA_TTABLE);
    lua_rawgeti(L, {arg_index}, 1); {var_name}.x = (float)lua_tonumber(L, -1); lua_pop(L, 1);
    lua_rawgeti(L, {arg_index}, 2); {var_name}.y = (float)lua_tonumber(L, -1); lua_pop(L, 1);'''
        elif base_type == 'b2Rot':
            # Read from table {c, s}
            return f'''b2Rot {var_name};
    luaL_checktype(L, {arg_index}, LUA_TTABLE);
    lua_rawgeti(L, {arg_index}, 1); {var_name}.c = (float)lua_tonumber(L, -1); lua_pop(L, 1);
    lua_rawgeti(L, {arg_index}, 2); {var_name}.s = (float)lua_tonumber(L, -1); lua_pop(L, 1);'''
        elif base_type == 'b2CosSin':
            return f'''b2CosSin {var_name};
    luaL_checktype(L, {arg_index}, LUA_TTABLE);
    lua_rawgeti(L, {arg_index}, 1); {var_name}.cosine = (float)lua_tonumber(L, -1); lua_pop(L, 1);
    lua_rawgeti(L, {arg_index}, 2); {var_name}.sine = (float)lua_tonumber(L, -1); lua_pop(L, 1);'''
        elif base_type == 'b2Transform':
            # Read from table {{px, py}, {c, s}}
            return f'''b2Transform {var_name};
    luaL_checktype(L, {arg_index}, LUA_TTABLE);
    lua_rawgeti(L, {arg_index}, 1);
    lua_rawgeti(L, -1, 1); {var_name}.p.x = (float)lua_tonumber(L, -1); lua_pop(L, 1);
    lua_rawgeti(L, -1, 2); {var_name}.p.y = (float)lua_tonumber(L, -1); lua_pop(L, 1);
    lua_pop(L, 1);
    lua_rawgeti(L, {arg_index}, 2);
    lua_rawgeti(L, -1, 1); {var_name}.q.c = (float)lua_tonumber(L, -1); lua_pop(L, 1);
    lua_rawgeti(L, -1, 2); {var_name}.q.s = (float)lua_tonumber(L, -1); lua_pop(L, 1);
    lua_pop(L, 1);'''
        elif base_type == 'b2AABB':
            return f'''b2AABB {var_name};
    luaL_checktype(L, {arg_index}, LUA_TTABLE);
    lua_rawgeti(L, {arg_index}, 1);
    lua_rawgeti(L, -1, 1); {var_name}.lowerBound.x = (float)lua_tonumber(L, -1); lua_pop(L, 1);
    lua_rawgeti(L, -1, 2); {var_name}.lowerBound.y = (float)lua_tonumber(L, -1); lua_pop(L, 1);
    lua_pop(L, 1);
    lua_rawgeti(L, {arg_index}, 2);
    lua_rawgeti(L, -1, 1); {var_name}.upperBound.x = (float)lua_tonumber(L, -1); lua_pop(L, 1);
    lua_rawgeti(L, -1, 2); {var_name}.upperBound.y = (float)lua_tonumber(L, -1); lua_pop(L, 1);
    lua_pop(L, 1);'''
        elif base_type == 'b2Plane':
            # Plane has {normal: b2Vec2, offset: float}
            return f'''b2Plane {var_name};
    luaL_checktype(L, {arg_index}, LUA_TTABLE);
    lua_rawgeti(L, {arg_index}, 1);
    lua_rawgeti(L, -1, 1); {var_name}.normal.x = (float)lua_tonumber(L, -1); lua_pop(L, 1);
    lua_rawgeti(L, -1, 2); {var_name}.normal.y = (float)lua_tonumber(L, -1); lua_pop(L, 1);
    lua_pop(L, 1);
    lua_rawgeti(L, {arg_index}, 2); {var_name}.offset = (float)lua_tonumber(L, -1); lua_pop(L, 1);'''
        elif self.is_struct_type(base_type):
            struct_name = as_pascal_case(base_type)
            return f'{base_type}* {var_name}_ptr = ({base_type}*)luaL_checkudata(L, {arg_index}, "b2d.{struct_name}");\n    {base_type} {var_name} = *{var_name}_ptr;'
        elif self.is_const_struct_ptr(type_str):
            inner_type = extract_ptr_type(type_str)
            struct_name = as_pascal_case(inner_type)
            return f'const {inner_type}* {var_name} = (const {inner_type}*)luaL_checkudata(L, {arg_index}, "b2d.{struct_name}");'
        elif self.is_struct_ptr(type_str):
            inner_type = extract_ptr_type(type_str)
            struct_name = as_pascal_case(inner_type)
            return f'{inner_type}* {var_name} = ({inner_type}*)luaL_checkudata(L, {arg_index}, "b2d.{struct_name}");'
        elif self.is_enum_type(base_type):
            return f'{base_type} {var_name} = ({base_type})luaL_checkinteger(L, {arg_index});'
        elif is_void_ptr(type_str):
            return f'void* {var_name} = lua_touserdata(L, {arg_index});'
        elif is_const_void_ptr(type_str):
            return f'const void* {var_name} = lua_touserdata(L, {arg_index});'
        else:
            return f'/* TODO: get {type_str} */ void* {var_name} = NULL;'

    def gen_func_wrapper(self, func):
        """Generate a Lua C API wrapper function."""
        func_name = func['name']
        lua_name = as_snake_case(func_name)
        if lua_name in LUA_KEYWORDS:
            lua_name += '_'
        result_type = self.get_return_type(func)

        lines = []
        lines.append(f'static int l_{func_name}(lua_State *L) {{')

        # Get parameters from Lua stack
        arg_names = []
        params = func.get('params', [])
        skip_next = False
        lua_arg_idx = 1  # Lua stack index (1-based)
        for i, param in enumerate(params):
            if skip_next:
                skip_next = False
                continue

            param_name = param['name']
            param_type = param['type']

            # Detect array pattern: const b2Vec2* + int count
            if (i < len(params) - 1 and
                param_type == 'const b2Vec2 *' and
                params[i+1]['type'] == 'int' and
                params[i+1]['name'] == 'count'):
                count_name = params[i+1]['name']
                lines.append(f'    luaL_checktype(L, {lua_arg_idx}, LUA_TTABLE);')
                lines.append(f'    int {count_name} = (int)lua_rawlen(L, {lua_arg_idx});')
                # Use alloca for MSVC compatibility (no VLA support)
                lines.append(f'    b2Vec2* {param_name} = (b2Vec2*)B2D_ALLOCA({count_name} * sizeof(b2Vec2));')
                lines.append(f'    for (int j = 0; j < {count_name}; j++) {{')
                lines.append(f'        lua_rawgeti(L, {lua_arg_idx}, j + 1);')
                lines.append(f'        lua_rawgeti(L, -1, 1); {param_name}[j].x = (float)lua_tonumber(L, -1); lua_pop(L, 1);')
                lines.append(f'        lua_rawgeti(L, -1, 2); {param_name}[j].y = (float)lua_tonumber(L, -1); lua_pop(L, 1);')
                lines.append(f'        lua_pop(L, 1);')
                lines.append(f'    }}')
                arg_names.append(param_name)
                arg_names.append(count_name)
                skip_next = True  # Skip count parameter
                lua_arg_idx += 1  # Only one Lua argument consumed
                continue

            to_code = self.get_lua_to_code(param_type, lua_arg_idx, param_name)
            lines.append(f'    {to_code}')
            arg_names.append(param_name)
            lua_arg_idx += 1

        # Call the C function
        args_str = ', '.join(arg_names)
        if result_type == 'void':
            lines.append(f'    {func_name}({args_str});')
            lines.append('    return 0;')
        else:
            lines.append(f'    {result_type} result = {func_name}({args_str});')
            push_code = self.get_lua_push_code(result_type, 'result')
            if push_code:
                lines.append(f'    {push_code}')
                lines.append('    return 1;')
            else:
                lines.append('    return 0;')

        lines.append('}')
        lines.append('')
        return lines

    def gen_struct_new(self, struct):
        """Generate constructor for a struct."""
        c_name = struct['name']
        lua_name = as_pascal_case(c_name)
        fields = struct.get('fields', [])

        lines = []
        lines.append(f'static int l_{c_name}_new(lua_State *L) {{')
        lines.append(f'    {c_name}* ud = ({c_name}*)lua_newuserdatauv(L, sizeof({c_name}), 0);')
        lines.append(f'    memset(ud, 0, sizeof({c_name}));')
        lines.append(f'    luaL_setmetatable(L, "b2d.{lua_name}");')
        lines.append('')
        lines.append('    /* Initialize from table if provided */')
        lines.append('    if (lua_istable(L, 1)) {')

        # Special handling for b2Vec2: support array form {x, y}
        if c_name == 'b2Vec2':
            lines.append('        /* Support array form {x, y} */')
            lines.append('        lua_rawgeti(L, 1, 1);')
            lines.append('        if (!lua_isnil(L, -1)) {')
            lines.append('            ud->x = (float)lua_tonumber(L, -1);')
            lines.append('            lua_pop(L, 1);')
            lines.append('            lua_rawgeti(L, 1, 2);')
            lines.append('            ud->y = (float)lua_tonumber(L, -1);')
            lines.append('            lua_pop(L, 1);')
            lines.append('        } else {')
            lines.append('            lua_pop(L, 1);')
            lines.append('            /* Named form {x=.., y=..} */')

        # Special handling for b2Rot: support array form {c, s}
        if c_name == 'b2Rot':
            lines.append('        /* Support array form {c, s} */')
            lines.append('        lua_rawgeti(L, 1, 1);')
            lines.append('        if (!lua_isnil(L, -1)) {')
            lines.append('            ud->c = (float)lua_tonumber(L, -1);')
            lines.append('            lua_pop(L, 1);')
            lines.append('            lua_rawgeti(L, 1, 2);')
            lines.append('            ud->s = (float)lua_tonumber(L, -1);')
            lines.append('            lua_pop(L, 1);')
            lines.append('        } else {')
            lines.append('            lua_pop(L, 1);')
            lines.append('            /* Named form {c=.., s=..} */')

        for field in fields:
            fname = field.get('name')
            if not fname:
                continue
            ftype = field['type']

            lines.append(f'        lua_getfield(L, 1, "{fname}");')
            lines.append(f'        if (!lua_isnil(L, -1)) {{')

            if ftype == 'bool':
                lines.append(f'            ud->{fname} = lua_toboolean(L, -1);')
            elif is_int_type(ftype):
                lines.append(f'            ud->{fname} = ({ftype})lua_tointeger(L, -1);')
            elif is_float_type(ftype):
                lines.append(f'            ud->{fname} = ({ftype})lua_tonumber(L, -1);')
            elif is_string_ptr(ftype):
                lines.append(f'            ud->{fname} = lua_tostring(L, -1);')
            elif self.is_struct_type(ftype):
                inner_name = as_pascal_case(ftype)
                lines.append(f'            if (lua_istable(L, -1)) {{')
                lines.append(f'                lua_pushcfunction(L, l_{ftype}_new);')
                lines.append(f'                lua_pushvalue(L, -2);')
                lines.append(f'                lua_call(L, 1, 1);')
                lines.append(f'                {ftype}* val = ({ftype}*)luaL_testudata(L, -1, "b2d.{inner_name}");')
                lines.append(f'                if (val) ud->{fname} = *val;')
                lines.append(f'                lua_pop(L, 1);')
                lines.append(f'            }} else {{')
                lines.append(f'                {ftype}* val = ({ftype}*)luaL_testudata(L, -1, "b2d.{inner_name}");')
                lines.append(f'                if (val) ud->{fname} = *val;')
                lines.append(f'            }}')
            elif self.is_enum_type(ftype):
                lines.append(f'            ud->{fname} = ({ftype})lua_tointeger(L, -1);')
            elif is_void_ptr(ftype) or is_const_void_ptr(ftype):
                lines.append(f'            ud->{fname} = lua_touserdata(L, -1);')
            elif is_array_type(ftype):
                # Handle arrays
                base_type = extract_array_type(ftype)
                size = extract_array_size(ftype)
                if is_float_type(base_type):
                    lines.append(f'            if (lua_istable(L, -1)) {{')
                    lines.append(f'                for (int i = 0; i < {size}; i++) {{')
                    lines.append(f'                    lua_rawgeti(L, -1, i + 1);')
                    lines.append(f'                    ud->{fname}[i] = ({base_type})lua_tonumber(L, -1);')
                    lines.append(f'                    lua_pop(L, 1);')
                    lines.append(f'                }}')
                    lines.append(f'            }}')
                elif is_int_type(base_type):
                    lines.append(f'            if (lua_istable(L, -1)) {{')
                    lines.append(f'                for (int i = 0; i < {size}; i++) {{')
                    lines.append(f'                    lua_rawgeti(L, -1, i + 1);')
                    lines.append(f'                    ud->{fname}[i] = ({base_type})lua_tointeger(L, -1);')
                    lines.append(f'                    lua_pop(L, 1);')
                    lines.append(f'                }}')
                    lines.append(f'            }}')
            else:
                lines.append(f'            /* TODO: init {ftype} */')

            lines.append('        }')
            lines.append('        lua_pop(L, 1);')

        # Close special handling else block
        if c_name in ('b2Vec2', 'b2Rot'):
            lines.append('        }')

        lines.append('    }')
        lines.append('    return 1;')
        lines.append('}')
        lines.append('')
        return lines

    def gen_struct_getter(self, struct, field):
        """Generate getter for a struct field."""
        c_name = struct['name']
        lua_name = as_pascal_case(c_name)
        fname = field['name']
        ftype = field['type']

        lines = []
        lines.append(f'static int l_{c_name}_get_{fname}(lua_State *L) {{')
        lines.append(f'    {c_name}* self = ({c_name}*)luaL_checkudata(L, 1, "b2d.{lua_name}");')

        if is_array_type(ftype):
            base_type = extract_array_type(ftype)
            size = extract_array_size(ftype)
            lines.append('    lua_newtable(L);')
            lines.append(f'    for (int i = 0; i < {size}; i++) {{')
            if is_float_type(base_type):
                lines.append(f'        lua_pushnumber(L, self->{fname}[i]);')
            elif is_int_type(base_type):
                lines.append(f'        lua_pushinteger(L, self->{fname}[i]);')
            elif self.is_struct_type(base_type):
                inner_name = as_pascal_case(base_type)
                lines.append(f'        {base_type}* ud = ({base_type}*)lua_newuserdatauv(L, sizeof({base_type}), 0);')
                lines.append(f'        *ud = self->{fname}[i];')
                lines.append(f'        luaL_setmetatable(L, "b2d.{inner_name}");')
            lines.append('        lua_rawseti(L, -2, i + 1);')
            lines.append('    }')
        else:
            push_code = self.get_lua_push_code(ftype, f'self->{fname}')
            if push_code:
                lines.append(f'    {push_code}')
            else:
                lines.append('    lua_pushnil(L);')

        lines.append('    return 1;')
        lines.append('}')
        lines.append('')
        return lines

    def gen_struct_setter(self, struct, field):
        """Generate setter for a struct field.
        Note: Called from __newindex where stack is (self, key, value), so value is at index 3.
        """
        c_name = struct['name']
        lua_name = as_pascal_case(c_name)
        fname = field['name']
        ftype = field['type']
        val_idx = 3  # __newindex passes (self, key, value)

        lines = []
        lines.append(f'static int l_{c_name}_set_{fname}(lua_State *L) {{')
        lines.append(f'    {c_name}* self = ({c_name}*)luaL_checkudata(L, 1, "b2d.{lua_name}");')

        # Special case: b2ChainDef.points - array of b2Vec2
        if c_name == 'b2ChainDef' and fname == 'points':
            lines.append(f'    luaL_checktype(L, {val_idx}, LUA_TTABLE);')
            lines.append(f'    int count = (int)lua_rawlen(L, {val_idx});')
            lines.append(f'    /* Free old points if any */')
            lines.append(f'    if (self->points) free((void*)self->points);')
            lines.append(f'    b2Vec2* points = (b2Vec2*)malloc(count * sizeof(b2Vec2));')
            lines.append(f'    for (int i = 0; i < count; i++) {{')
            lines.append(f'        lua_rawgeti(L, {val_idx}, i + 1);')
            lines.append(f'        lua_rawgeti(L, -1, 1); points[i].x = (float)lua_tonumber(L, -1); lua_pop(L, 1);')
            lines.append(f'        lua_rawgeti(L, -1, 2); points[i].y = (float)lua_tonumber(L, -1); lua_pop(L, 1);')
            lines.append(f'        lua_pop(L, 1);')
            lines.append(f'    }}')
            lines.append(f'    self->points = points;')
            lines.append(f'    self->count = count;')
        # Special case: b2ChainDef.materials - array of b2SurfaceMaterial
        elif c_name == 'b2ChainDef' and fname == 'materials':
            lines.append(f'    luaL_checktype(L, {val_idx}, LUA_TTABLE);')
            lines.append(f'    int count = (int)lua_rawlen(L, {val_idx});')
            lines.append(f'    /* Free old materials if any */')
            lines.append(f'    if (self->materials) free((void*)self->materials);')
            lines.append(f'    b2SurfaceMaterial* materials = (b2SurfaceMaterial*)malloc(count * sizeof(b2SurfaceMaterial));')
            lines.append(f'    for (int i = 0; i < count; i++) {{')
            lines.append(f'        lua_rawgeti(L, {val_idx}, i + 1);')
            lines.append(f'        b2SurfaceMaterial* mat = (b2SurfaceMaterial*)luaL_checkudata(L, -1, "b2d.SurfaceMaterial");')
            lines.append(f'        materials[i] = *mat;')
            lines.append(f'        lua_pop(L, 1);')
            lines.append(f'    }}')
            lines.append(f'    self->materials = materials;')
            lines.append(f'    self->materialCount = count;')
        elif ftype == 'bool':
            lines.append(f'    self->{fname} = lua_toboolean(L, {val_idx});')
        elif is_int_type(ftype):
            lines.append(f'    self->{fname} = ({ftype})luaL_checkinteger(L, {val_idx});')
        elif is_float_type(ftype):
            lines.append(f'    self->{fname} = ({ftype})luaL_checknumber(L, {val_idx});')
        elif is_string_ptr(ftype):
            lines.append(f'    self->{fname} = luaL_checkstring(L, {val_idx});')
        elif ftype == 'b2Vec2':
            # Accept both table {x, y} and userdata
            lines.append(f'    if (lua_istable(L, {val_idx})) {{')
            lines.append(f'        lua_rawgeti(L, {val_idx}, 1); self->{fname}.x = (float)lua_tonumber(L, -1); lua_pop(L, 1);')
            lines.append(f'        lua_rawgeti(L, {val_idx}, 2); self->{fname}.y = (float)lua_tonumber(L, -1); lua_pop(L, 1);')
            lines.append('    } else {')
            lines.append(f'        b2Vec2* val = (b2Vec2*)luaL_checkudata(L, {val_idx}, "b2d.Vec2");')
            lines.append(f'        self->{fname} = *val;')
            lines.append('    }')
        elif ftype == 'b2Rot':
            # Accept both table {c, s} and userdata
            lines.append(f'    if (lua_istable(L, {val_idx})) {{')
            lines.append(f'        lua_rawgeti(L, {val_idx}, 1); self->{fname}.c = (float)lua_tonumber(L, -1); lua_pop(L, 1);')
            lines.append(f'        lua_rawgeti(L, {val_idx}, 2); self->{fname}.s = (float)lua_tonumber(L, -1); lua_pop(L, 1);')
            lines.append('    } else {')
            lines.append(f'        b2Rot* val = (b2Rot*)luaL_checkudata(L, {val_idx}, "b2d.Rot");')
            lines.append(f'        self->{fname} = *val;')
            lines.append('    }')
        elif self.is_struct_type(ftype):
            inner_name = as_pascal_case(ftype)
            lines.append(f'    {ftype}* val = ({ftype}*)luaL_checkudata(L, {val_idx}, "b2d.{inner_name}");')
            lines.append(f'    self->{fname} = *val;')
        elif self.is_enum_type(ftype):
            lines.append(f'    self->{fname} = ({ftype})luaL_checkinteger(L, {val_idx});')
        elif is_void_ptr(ftype) or is_const_void_ptr(ftype):
            lines.append(f'    self->{fname} = lua_touserdata(L, {val_idx});')
        elif is_array_type(ftype):
            base_type = extract_array_type(ftype)
            size = extract_array_size(ftype)
            lines.append(f'    luaL_checktype(L, {val_idx}, LUA_TTABLE);')
            lines.append(f'    for (int i = 0; i < {size}; i++) {{')
            lines.append(f'        lua_rawgeti(L, {val_idx}, i + 1);')
            if is_float_type(base_type):
                lines.append(f'        self->{fname}[i] = ({base_type})lua_tonumber(L, -1);')
            elif is_int_type(base_type):
                lines.append(f'        self->{fname}[i] = ({base_type})lua_tointeger(L, -1);')
            lines.append('        lua_pop(L, 1);')
            lines.append('    }')
        else:
            lines.append(f'    /* TODO: set {ftype} */')

        lines.append('    return 0;')
        lines.append('}')
        lines.append('')
        return lines

    def gen_jointdef_base_accessors(self, struct):
        """Generate flattened accessors for all b2JointDef base fields."""
        c_name = struct['name']
        lua_name = as_pascal_case(c_name)
        lines = []

        for field in self.joint_def_fields:
            fname = field['name']
            ftype = field['type']

            # Generate getter
            lines.append(f'static int l_{c_name}_get_{fname}(lua_State *L) {{')
            lines.append(f'    {c_name}* self = ({c_name}*)luaL_checkudata(L, 1, "b2d.{lua_name}");')

            push_code = self.get_lua_push_code(ftype, f'self->base.{fname}')
            if push_code:
                lines.append(f'    {push_code}')
                lines.append('    return 1;')
            else:
                lines.append('    lua_pushnil(L);')
                lines.append('    return 1;')

            lines.append('}')
            lines.append('')

            # Generate setter
            lines.append(f'static int l_{c_name}_set_{fname}(lua_State *L) {{')
            lines.append(f'    {c_name}* self = ({c_name}*)luaL_checkudata(L, 1, "b2d.{lua_name}");')

            if ftype == 'bool':
                lines.append(f'    self->base.{fname} = lua_toboolean(L, 3);')
            elif is_int_type(ftype):
                lines.append(f'    self->base.{fname} = ({ftype})luaL_checkinteger(L, 3);')
            elif is_float_type(ftype):
                lines.append(f'    self->base.{fname} = ({ftype})luaL_checknumber(L, 3);')
            elif is_void_ptr(ftype) or is_const_void_ptr(ftype):
                lines.append(f'    self->base.{fname} = lua_touserdata(L, 3);')
            elif self.is_struct_type(ftype):
                inner_name = as_pascal_case(ftype)
                lines.append(f'    {ftype}* val = ({ftype}*)luaL_checkudata(L, 3, "b2d.{inner_name}");')
                lines.append(f'    self->base.{fname} = *val;')
            else:
                lines.append(f'    /* TODO: set {ftype} */')

            lines.append('    return 0;')
            lines.append('}')
            lines.append('')

        return lines

    def gen_struct_index(self, struct):
        """Generate __index metamethod."""
        c_name = struct['name']
        lua_name = as_pascal_case(c_name)
        fields = [f for f in struct.get('fields', []) if f.get('name')]

        lines = []
        lines.append(f'static int l_{c_name}__index(lua_State *L) {{')
        lines.append('    const char* key = luaL_checkstring(L, 2);')
        for field in fields:
            fname = field['name']
            lines.append(f'    if (strcmp(key, "{fname}") == 0) return l_{c_name}_get_{fname}(L);')
        # Add flattened base field accessors for JointDef structs
        if c_name in JOINT_DEF_STRUCTS:
            for field in self.joint_def_fields:
                fname = field['name']
                lines.append(f'    if (strcmp(key, "{fname}") == 0) return l_{c_name}_get_{fname}(L);')
        lines.append('    return 0;')
        lines.append('}')
        lines.append('')
        return lines

    def gen_struct_newindex(self, struct):
        """Generate __newindex metamethod."""
        c_name = struct['name']
        lua_name = as_pascal_case(c_name)
        fields = [f for f in struct.get('fields', []) if f.get('name')]

        lines = []
        lines.append(f'static int l_{c_name}__newindex(lua_State *L) {{')
        lines.append('    const char* key = luaL_checkstring(L, 2);')
        for field in fields:
            fname = field['name']
            lines.append(f'    if (strcmp(key, "{fname}") == 0) return l_{c_name}_set_{fname}(L);')
        # Add flattened base field accessors for JointDef structs
        if c_name in JOINT_DEF_STRUCTS:
            for field in self.joint_def_fields:
                fname = field['name']
                lines.append(f'    if (strcmp(key, "{fname}") == 0) return l_{c_name}_set_{fname}(L);')
        lines.append('    return luaL_error(L, "unknown field: %s", key);')
        lines.append('}')
        lines.append('')
        return lines

    def gen_enum_registration(self, enum):
        """Generate enum constants registration."""
        c_name = enum['name']
        lua_name = as_pascal_case(c_name)

        lines = []
        lines.append(f'static void register_{c_name}(lua_State *L) {{')
        lines.append('    lua_newtable(L);')

        for item in enum.get('items', []):
            item_name = item['name']
            # Convert b2_bodyTypeDynamic to DYNAMIC, etc.
            short = item_name
            if short.startswith('b2_'):
                short = short[3:]
            # Find enum name prefix and remove it
            enum_base = c_name.lower().replace('b2', '')
            if short.lower().startswith(enum_base):
                short = short[len(enum_base):]
            short = short.upper()
            if not short:
                short = item_name.upper()

            if 'value' in item:
                lines.append(f'    lua_pushinteger(L, {item["value"]});')
            else:
                lines.append(f'    lua_pushinteger(L, {item_name});')
            lines.append(f'    lua_setfield(L, -2, "{short}");')

        lines.append(f'    lua_setfield(L, -2, "{lua_name}");')
        lines.append('}')
        lines.append('')
        return lines

    def generate(self):
        """Generate the complete binding file."""
        self.emit('/* Auto-generated Box2D Lua bindings */')
        self.emit(f'/* Generated on {datetime.now().isoformat()} */')
        self.emit('/* Do not edit manually! */')
        self.emit('')
        self.emit('#include <lua.h>')
        self.emit('#include <lauxlib.h>')
        self.emit('#include <lualib.h>')
        self.emit('')
        self.emit('/* Platform-specific alloca */')
        self.emit('#ifdef _WIN32')
        self.emit('  #include <malloc.h>')
        self.emit('  #define B2D_ALLOCA(size) _alloca(size)')
        self.emit('#else')
        self.emit('  #include <alloca.h>')
        self.emit('  #define B2D_ALLOCA(size) alloca(size)')
        self.emit('#endif')
        self.emit('#include <string.h>')
        self.emit('#include <stdlib.h>')
        self.emit('#include <box2d/box2d.h>')
        self.emit('')
        self.emit('#ifndef MANE3D_API')
        self.emit('  #ifdef _WIN32')
        self.emit('    #ifdef MANE3D_EXPORTS')
        self.emit('      #define MANE3D_API __declspec(dllexport)')
        self.emit('    #else')
        self.emit('      #define MANE3D_API __declspec(dllimport)')
        self.emit('    #endif')
        self.emit('  #else')
        self.emit('    #define MANE3D_API')
        self.emit('  #endif')
        self.emit('#endif')
        self.emit('')

        # Deduplicate structs by name
        seen_struct_names = set()
        unique_structs = []
        for struct in self.structs:
            if struct['name'] not in seen_struct_names:
                seen_struct_names.add(struct['name'])
                unique_structs.append(struct)

        # Forward declare struct constructors (needed for nested struct init)
        for struct in unique_structs:
            if self.should_skip_struct(struct):
                continue
            c_name = struct['name']
            self.emit(f'static int l_{c_name}_new(lua_State *L);')
        self.emit('')

        # Generate struct bindings
        generated_structs = []
        for struct in unique_structs:
            if self.should_skip_struct(struct):
                continue
            c_name = struct['name']
            fields = [f for f in struct.get('fields', []) if f.get('name')]

            # Getters and setters
            for field in fields:
                for line in self.gen_struct_getter(struct, field):
                    self.emit(line)
                for line in self.gen_struct_setter(struct, field):
                    self.emit(line)

            # Flattened base field accessors for JointDef structs
            if c_name in JOINT_DEF_STRUCTS:
                for line in self.gen_jointdef_base_accessors(struct):
                    self.emit(line)

            # Index/newindex
            for line in self.gen_struct_index(struct):
                self.emit(line)
            for line in self.gen_struct_newindex(struct):
                self.emit(line)

            # Constructor
            for line in self.gen_struct_new(struct):
                self.emit(line)

            generated_structs.append(struct)

        # Generate function wrappers
        generated_funcs = []
        for func in self.funcs:
            if self.should_skip_func(func):
                continue
            try:
                for line in self.gen_func_wrapper(func):
                    self.emit(line)
                generated_funcs.append(func)
            except Exception as e:
                self.emit(f'/* Error generating {func["name"]}: {e} */')
                self.emit('')

        # Generate enum registrations
        for enum in self.enums:
            if not enum.get('name'):
                continue
            for line in self.gen_enum_registration(enum):
                self.emit(line)

        # Generate __gc for b2ChainDef to free allocated memory
        self.emit('static int l_b2ChainDef__gc(lua_State *L) {')
        self.emit('    b2ChainDef* self = (b2ChainDef*)luaL_checkudata(L, 1, "b2d.ChainDef");')
        self.emit('    if (self->points) free((void*)self->points);')
        self.emit('    if (self->materials) free((void*)self->materials);')
        self.emit('    return 0;')
        self.emit('}')
        self.emit('')

        # Generate metatable registration
        self.emit('static void register_metatables(lua_State *L) {')
        for struct in generated_structs:
            c_name = struct['name']
            lua_name = as_pascal_case(c_name)
            self.emit(f'    luaL_newmetatable(L, "b2d.{lua_name}");')
            self.emit(f'    lua_pushcfunction(L, l_{c_name}__index);')
            self.emit(f'    lua_setfield(L, -2, "__index");')
            self.emit(f'    lua_pushcfunction(L, l_{c_name}__newindex);')
            self.emit(f'    lua_setfield(L, -2, "__newindex");')
            # Add __gc for b2ChainDef
            if c_name == 'b2ChainDef':
                self.emit(f'    lua_pushcfunction(L, l_{c_name}__gc);')
                self.emit(f'    lua_setfield(L, -2, "__gc");')
            self.emit('    lua_pop(L, 1);')
            self.emit('')
        self.emit('}')
        self.emit('')

        # Declare external helper functions (defined in box2d_task.c)
        self.emit('/* External helper functions */')
        self.emit('extern int l_b2d_create_revolute_joint_at(lua_State *L);')
        self.emit('')

        # Generate luaL_Reg table
        self.emit('static const luaL_Reg b2d_funcs[] = {')
        for func in generated_funcs:
            func_name = func['name']
            lua_name = as_snake_case(func_name)
            if lua_name in LUA_KEYWORDS:
                lua_name += '_'
            self.emit(f'    {{"{lua_name}", l_{func_name}}},')
        for struct in generated_structs:
            c_name = struct['name']
            lua_name = as_pascal_case(c_name)
            self.emit(f'    {{"{lua_name}", l_{c_name}_new}},')
        # Add external helper functions
        self.emit('    {"create_revolute_joint_at", l_b2d_create_revolute_joint_at},')
        self.emit('    {NULL, NULL}')
        self.emit('};')
        self.emit('')

        # Generate luaopen function
        self.emit('MANE3D_API int luaopen_b2d(lua_State *L) {')
        self.emit('    register_metatables(L);')
        self.emit('    luaL_newlib(L, b2d_funcs);')
        for enum in self.enums:
            if not enum.get('name'):
                continue
            c_name = enum['name']
            self.emit(f'    register_{c_name}(L);')
        self.emit('    return 1;')
        self.emit('}')

        return '\n'.join(self.out_lines)


class LuaCATSGenerator:
    """Generate LuaCATS type definitions."""

    def __init__(self, ir_data, binding_gen):
        self.ir = ir_data
        self.binding_gen = binding_gen
        self.out_lines = []

    def emit(self, line=''):
        self.out_lines.append(line)

    def lua_type(self, c_type):
        """Convert C type to Lua type annotation."""
        c_type = c_type.strip()
        if c_type == 'void':
            return 'nil'
        if c_type == 'bool':
            return 'boolean'
        if is_int_type(c_type):
            return 'integer'
        if is_float_type(c_type):
            return 'number'
        if is_string_ptr(c_type):
            return 'string'
        if self.binding_gen.is_struct_type(c_type):
            return f'b2d.{as_pascal_case(c_type)}'
        if self.binding_gen.is_enum_type(c_type):
            return f'b2d.{as_pascal_case(c_type)}'
        if self.binding_gen.is_struct_ptr(c_type) or self.binding_gen.is_const_struct_ptr(c_type):
            inner = extract_ptr_type(c_type)
            return f'b2d.{as_pascal_case(inner)}'
        if is_void_ptr(c_type) or is_const_void_ptr(c_type):
            return 'lightuserdata?'
        if is_array_type(c_type):
            base = extract_array_type(c_type)
            inner = self.lua_type(base)
            return f'{inner}[]'
        return 'any'

    def generate(self):
        """Generate complete LuaCATS file."""
        self.emit('---@meta')
        self.emit('-- LuaCATS type definitions for b2d (Box2D)')
        self.emit('-- Auto-generated, do not edit')
        self.emit('')

        # Struct types
        for struct in self.binding_gen.structs:
            if self.binding_gen.should_skip_struct(struct):
                continue
            lua_name = as_pascal_case(struct['name'])
            self.emit(f'---@class b2d.{lua_name}')
            for field in struct.get('fields', []):
                fname = field.get('name')
                if not fname:
                    continue
                ftype = self.lua_type(field['type'])
                self.emit(f'---@field {fname}? {ftype}')
            self.emit('')

        # Module class
        self.emit('---@class b2d')
        for struct in self.binding_gen.structs:
            if self.binding_gen.should_skip_struct(struct):
                continue
            lua_name = as_pascal_case(struct['name'])
            self.emit(f'---@field {lua_name} fun(t?: b2d.{lua_name}): b2d.{lua_name}')
        self.emit('local b2d = {}')
        self.emit('')

        # Enum types
        for enum in self.binding_gen.enums:
            if not enum.get('name'):
                continue
            lua_name = as_pascal_case(enum['name'])
            self.emit(f'---@enum b2d.{lua_name}')
            self.emit(f'b2d.{lua_name} = {{')
            for item in enum.get('items', []):
                item_name = item['name']
                short = item_name
                if short.startswith('b2_'):
                    short = short[3:]
                short = short.upper()
                value = item.get('value', 0)
                self.emit(f'    {short} = {value},')
            self.emit('}')
            self.emit('')

        # Functions
        for func in self.binding_gen.funcs:
            if self.binding_gen.should_skip_func(func):
                continue
            lua_name = as_snake_case(func['name'])
            if lua_name in LUA_KEYWORDS:
                lua_name += '_'

            params = func.get('params', [])
            for param in params:
                pname = param['name']
                ptype = self.lua_type(param['type'])
                self.emit(f'---@param {pname} {ptype}')

            ret_type = self.binding_gen.get_return_type(func)
            if ret_type != 'void':
                self.emit(f'---@return {self.lua_type(ret_type)}')

            param_names = ', '.join(p['name'] for p in params)
            self.emit(f'function b2d.{lua_name}({param_names}) end')
            self.emit('')

        self.emit('return b2d')
        return '\n'.join(self.out_lines)


def main():
    script_dir = os.path.dirname(os.path.abspath(__file__))
    root_dir = os.path.abspath(os.path.join(script_dir, '..'))
    gen_dir = os.path.join(root_dir, 'gen')

    # Find box2d.h
    box2d_h = os.path.join(root_dir, 'deps', 'box2d', 'include', 'box2d', 'box2d.h')
    if len(sys.argv) > 1:
        box2d_h = sys.argv[1]

    if not os.path.exists(box2d_h):
        print(f"Error: {box2d_h} not found")
        sys.exit(1)

    print(f"Generating Box2D IR from {box2d_h}...")
    ir_data = ir.gen_box2d(box2d_h, 'b2d', output_dir=gen_dir)

    num_funcs = len([d for d in ir_data['decls'] if d['kind'] == 'func'])
    num_structs = len([d for d in ir_data['decls'] if d['kind'] == 'struct'])
    num_enums = len([d for d in ir_data['decls'] if d['kind'] in ('enum', 'consts')])
    print(f"Found {num_funcs} functions, {num_structs} structs, {num_enums} enums")

    print("Generating bindings...")
    gen = Box2DBindingGenerator(ir_data)
    code = gen.generate()

    output_path = os.path.join(gen_dir, 'bindings', 'b2d.c')
    os.makedirs(os.path.dirname(output_path), exist_ok=True)
    with open(output_path, 'w', newline='\n') as f:
        f.write(code)
    print(f"Generated {output_path}")

    print("Generating type definitions...")
    types_gen = LuaCATSGenerator(ir_data, gen)
    types_code = types_gen.generate()

    types_path = os.path.join(gen_dir, 'types', 'b2d.lua')
    os.makedirs(os.path.dirname(types_path), exist_ok=True)
    with open(types_path, 'w', newline='\n') as f:
        f.write(types_code)
    print(f"Generated {types_path}")

    print("Done!")


if __name__ == '__main__':
    main()
