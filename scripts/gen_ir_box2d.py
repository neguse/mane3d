#-------------------------------------------------------------------------------
#   Generate an intermediate representation of a clang AST dump.
#   Extended from sokol/bindgen/gen_ir.py for Box2D support.
#-------------------------------------------------------------------------------
import os, re, json, sys, subprocess
from collections import defaultdict

def is_api_decl(decl, prefix):
    if 'name' in decl:
        return decl['name'].startswith(prefix)
    elif decl['kind'] == 'EnumDecl':
        # an anonymous enum, check if the items start with the prefix
        if 'inner' not in decl:
            return False
        first = get_first_non_comment(decl['inner'])
        if first is None:
            return False
        return first['name'].lower().startswith(prefix.lower())
    else:
        return False

def get_first_non_comment(items):
    for i in items:
        if i['kind'] != 'FullComment':
            return i
    return None

def strip_comments(items):
    return [i for i in items if i['kind'] != 'FullComment']

def extract_comment(comment, source):
    return source[comment['range']['begin']['offset']:comment['range']['end']['offset']+1].rstrip()

def is_dep_decl(decl, dep_prefixes):
    for prefix in dep_prefixes:
        if is_api_decl(decl, prefix):
            return True
    return False

def dep_prefix(decl, dep_prefixes):
    for prefix in dep_prefixes:
        if is_api_decl(decl, prefix):
            return prefix
    return None

def filter_types(str):
    return str.replace('_Bool', 'bool')

def parse_struct(decl, source):
    outp = {}
    outp['kind'] = 'struct'
    outp['name'] = decl['name']
    outp['fields'] = []
    if 'inner' not in decl:
        return outp
    for item_decl in decl['inner']:
        if item_decl['kind'] == 'FullComment':
            outp['comment'] = extract_comment(item_decl, source)
            continue
        if item_decl['kind'] != 'FieldDecl':
            # Skip non-field members (forward declarations, nested types, etc.)
            continue
        item = {}
        if 'name' in item_decl:
            item['name'] = item_decl['name']
        else:
            continue  # Skip anonymous fields
        item['type'] = filter_types(item_decl['type']['qualType'])
        outp['fields'].append(item)
    return outp

def find_constant_value(node):
    """Recursively find ConstantExpr with evaluated value."""
    if node.get('kind') == 'ConstantExpr' and 'value' in node:
        return node['value']
    # Also check for IntegerLiteral directly
    if node.get('kind') == 'IntegerLiteral' and 'value' in node:
        return node['value']
    for child in node.get('inner', []):
        val = find_constant_value(child)
        if val is not None:
            return val
    return None

def parse_enum(decl, source):
    outp = {}
    if 'name' in decl:
        outp['kind'] = 'enum'
        outp['name'] = decl['name']
        needs_value = False
    else:
        outp['kind'] = 'consts'
        needs_value = True
    outp['items'] = []
    if 'inner' not in decl:
        return outp
    next_value = 0  # Track auto-increment for enums without explicit values
    for item_decl in decl['inner']:
        if item_decl['kind'] == 'FullComment':
            outp['comment'] = extract_comment(item_decl, source)
            continue
        if item_decl['kind'] == 'EnumConstantDecl':
            item = {}
            item['name'] = item_decl['name']
            # Find evaluated value from ConstantExpr (handles complex expressions)
            value = find_constant_value(item_decl)
            if value is not None:
                item['value'] = value
                try:
                    next_value = int(value) + 1
                except ValueError:
                    next_value += 1
            else:
                # Auto-increment for enums without explicit value
                item['value'] = str(next_value)
                next_value += 1
            outp['items'].append(item)
    return outp

def is_callback_type(param_type):
    """Check if parameter type is a function pointer callback."""
    return '(*)' in param_type or 'Callback' in param_type or 'Fcn' in param_type

def parse_func(decl, source):
    outp = {}
    outp['kind'] = 'func'
    outp['name'] = decl['name']
    outp['type'] = filter_types(decl['type']['qualType'])
    outp['params'] = []

    # Skip variadic functions
    if '...' in outp['type']:
        return None

    if 'inner' in decl:
        for param in decl['inner']:
            if param['kind'] == 'FullComment':
                outp['comment'] = extract_comment(param, source)
                continue
            if param['kind'] != 'ParmVarDecl':
                # Skip non-parameter children
                continue
            outp_param = {}
            if 'name' in param:
                outp_param['name'] = param['name']
            else:
                outp_param['name'] = f'arg{len(outp["params"])}'  # Generate name for anonymous params
            outp_param['type'] = filter_types(param['type']['qualType'])

            # Skip functions with callback parameters
            if is_callback_type(outp_param['type']):
                return None

            outp['params'].append(outp_param)
    return outp

def parse_decl(decl, source):
    kind = decl['kind']
    if kind == 'RecordDecl':
        return parse_struct(decl, source)
    elif kind == 'EnumDecl':
        return parse_enum(decl, source)
    elif kind == 'FunctionDecl':
        return parse_func(decl, source)
    else:
        return None

def clang(csrc_path, include_paths=None, defines=None):
    """Run clang to get AST dump."""
    clang_cmd = os.environ.get('CLANG', 'clang')
    cmd = [clang_cmd, '-x', 'c', '-Xclang', '-ast-dump=json', '-c', csrc_path]

    if defines:
        for d in defines:
            cmd.extend(['-D', d])

    if include_paths:
        for path in include_paths:
            cmd.extend(['-I', path])

    return subprocess.check_output(cmd)

def gen(header_path, source_path, module, main_prefix, dep_prefixes,
        include_paths=None, defines=None, output_dir=None):
    """Generate IR from header file."""
    ast = clang(source_path, include_paths=include_paths, defines=defines)
    inp = json.loads(ast)
    outp = {}
    outp['module'] = module
    outp['prefix'] = main_prefix
    outp['dep_prefixes'] = dep_prefixes
    outp['decls'] = []

    with open(header_path, mode='r', newline='') as f:
        source = f.read()
        first_comment = re.search(r"/\*(.*?)\*/", source, re.S)
        if first_comment and "URL" in first_comment.group(1):
            outp['comment'] = first_comment.group(1)

        for decl in inp['inner']:
            is_dep = is_dep_decl(decl, dep_prefixes)
            if is_api_decl(decl, main_prefix) or is_dep:
                outp_decl = parse_decl(decl, source)
                if outp_decl is not None:
                    outp_decl['is_dep'] = is_dep
                    outp_decl['dep_prefix'] = dep_prefix(decl, dep_prefixes)
                    outp['decls'].append(outp_decl)

    # Determine output path
    if output_dir:
        os.makedirs(output_dir, exist_ok=True)
        json_path = os.path.join(output_dir, f'{module}.json')
    else:
        json_path = f'{module}.json'

    with open(json_path, 'w') as f:
        f.write(json.dumps(outp, indent=2))
    return outp

def gen_box2d(box2d_h_path, output_name='b2d', output_dir=None):
    """Generate IR specifically for Box2D."""
    import tempfile

    # Make paths absolute
    box2d_h_path = os.path.abspath(box2d_h_path)
    box2d_include_dir = os.path.dirname(os.path.dirname(box2d_h_path))  # box2d/include

    # Create temporary source file
    with tempfile.NamedTemporaryFile(mode='w', suffix='.c', delete=False) as f:
        f.write(f'#include "{box2d_h_path}"\n')
        temp_src = f.name

    try:
        outp = gen(
            header_path=box2d_h_path,
            source_path=temp_src,
            module=output_name,
            main_prefix='b2',  # b2World, b2Body, b2CreateWorld, etc.
            dep_prefixes=[],
            include_paths=[box2d_include_dir],
            defines=['B2_API=', 'B2_INLINE=static inline'],  # Define macros for static build
            output_dir=output_dir
        )
        return outp
    finally:
        os.unlink(temp_src)

if __name__ == '__main__':
    if len(sys.argv) < 2:
        print("Usage: gen_ir_box2d.py <box2d.h path> [output_name]")
        sys.exit(1)

    box2d_h = sys.argv[1]
    output_name = sys.argv[2] if len(sys.argv) > 2 else 'b2d'

    # Output to gen/ directory relative to script
    script_dir = os.path.dirname(os.path.abspath(__file__))
    root_dir = os.path.abspath(os.path.join(script_dir, '..'))
    gen_dir = os.path.join(root_dir, 'gen')

    ir_data = gen_box2d(box2d_h, output_name, output_dir=gen_dir)
    print(f"Generated gen/{output_name}.json with {len(ir_data['decls'])} declarations")
