import os

lib_dir = r"d:\project\mobile_apps\frontends\hirenest\lib"

def get_balanced_end(text, start_idx):
    stack = []
    for i in range(start_idx, len(text)):
        char = text[i]
        if char in "({[":
            stack.append(char)
        elif char in ")}]":
            if not stack:
                return i
            last = stack.pop()
            if (last == '(' and char != ')') or \
               (last == '{' and char != '}') or \
               (last == '[' and char != ']'):
                # Mismatch
                return i
            if not stack:
                return i
    return -1

def fix_custom_error_widget(content):
    content = content.replace("message: error.toString()", "error: error")
    content = content.replace("message: e.toString()", "error: e")
    content = content.replace("message: err.toString()", "error: err")
    return content

def fix_when_error_blocks(content):
    import re
    # Find all occurrences of "error: (IDENT, IDENT) => "
    # But wait, it could be `error: (error, stack) { return ...; }`
    # Let's handle `error: (error, stack) =>` first
    pattern = re.compile(r"error:\s*\(\s*([a-zA-Z0-9_]+)\s*,\s*([a-zA-Z0-9_]+)\s*\)\s*=>")
    
    offset = 0
    while True:
        match = pattern.search(content, offset)
        if not match:
            break
        
        var_err = match.group(1)
        var_stack = match.group(2)
        start_body = match.end()
        
        # We need to find the end of the lambda expression.
        # Usually it ends at the comma before the closing parenthesis of .when(
        # Wait, balancing parenthesis starting from match.end() might just hit the end of the first widget?
        # A lambda `=> Widget(..),` ends at the comma, but there might be commas inside `Widget(.., ..)`.
        # So we should parse from start_body, skip spaces, then balance whatever widget it is.
        # Actually, it's easier to find the end of the `.when(` ? No.
        
        # Let's find the first character of the expression
        i = start_body
        while i < len(content) and content[i].isspace():
            i += 1
            
        if i >= len(content):
            break
            
        if content[i:i+17] == "CustomErrorWidget":
            offset = i + 17
            continue
            
        # Parse the widget
        start_idx = i
        end_idx = -1
        
        # If it starts with a known widget like Center, Padding, Text, SliverFillRemaining
        if content[start_idx:start_idx+6] == "Center" or \
           content[start_idx:start_idx+7] == "Padding" or \
           content[start_idx:start_idx+4] == "Text" or \
           content[start_idx:start_idx+19] == "SliverFillRemaining" or \
           content[start_idx:start_idx+6] == "Column":
            
            # Find the first opening parenthesis for the widget
            paren_start = content.find("(", start_idx)
            if paren_start != -1:
                end_paren = get_balanced_end(content, paren_start)
                if end_paren != -1:
                    # Replacement string
                    is_sliver = "SliverFillRemaining" in content[start_idx:paren_start]
                    
                    if is_sliver:
                        replacement = f"SliverFillRemaining(child: CustomErrorWidget(error: {var_err}))"
                    else:
                        replacement = f"CustomErrorWidget(error: {var_err})"
                        
                    content = content[:start_idx] + replacement + content[end_paren+1:]
                    offset = start_idx + len(replacement)
                    continue
        
        offset = start_body + 1
        
    return content

def add_import(content, level_count):
    import_path = "../" * level_count + "core/widgets/error_widget.dart"
    if "core/widgets/error_widget.dart" not in content:
        import_stmt = f"import '{import_path}';\n"
        if "import 'package:flutter/material.dart';" in content:
            content = content.replace("import 'package:flutter/material.dart';", f"import 'package:flutter/material.dart';\n{import_stmt}")
        else:
            import re
            match = re.search(r"import '.*';\n", content)
            if match:
                content = content[:match.end()] + import_stmt + content[match.end():]
    return content

count = 0
for root, _, files in os.walk(lib_dir):
    for file in files:
        if file.endswith(".dart"):
            path = os.path.join(root, file)
            with open(path, "r", encoding="utf-8") as f:
                content = f.read()
                
            orig = content
            content = fix_custom_error_widget(content)
            content = fix_when_error_blocks(content)
            
            if content != orig:
                rel_path = os.path.relpath(path, lib_dir)
                level_count = len(rel_path.split(os.sep)) - 1
                content = add_import(content, level_count)
                with open(path, "w", encoding="utf-8") as f:
                    f.write(content)
                count += 1
                print(f"Updated {path}")
                
print(f"Total updated: {count}")
