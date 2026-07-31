import os
import re

lib_dir = r"d:\project\mobile_apps\frontends\hirenest\lib"

# We will look for: Text('Error: $error'...) or Text('Error loading...: $error'...) or Text(error.toString())
# in any .dart file and replace the string literal with ErrorHandler.getUserFacingMessage(...)
# Note: we need to handle the variable name (e, err, error, snapshot.error)

def add_import(content, level_count):
    import_path = "../" * level_count + "core/utils/error_handler.dart"
    if "core/utils/error_handler.dart" not in content:
        # insert after the last import
        import_stmt = f"import '{import_path}';\n"
        if "import 'package:flutter/material.dart';" in content:
            content = content.replace("import 'package:flutter/material.dart';", f"import 'package:flutter/material.dart';\n{import_stmt}")
        else:
            # find first import
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
            
            original_content = content
            
            # Text('Error: $error') or similar
            # Regex to find Text('...$error...') where error is e, err, error
            content, n = re.subn(r"Text\(\s*'[^']*?\$(e|err|error)[^']*'\s*(?:,[^)]*)?\)", r"Text(ErrorHandler.getUserFacingMessage(\1))", content)
            
            # Text('Error: ${snapshot.error}')
            content, n2 = re.subn(r"Text\(\s*'[^']*?\$\{([^}]+)\}[^']*'\s*(?:,[^)]*)?\)", r"Text(ErrorHandler.getUserFacingMessage(\1))", content)

            # Text(error.toString())
            content, n3 = re.subn(r"Text\(\s*(e|err|error)\.toString\(\)\s*(?:,[^)]*)?\)", r"Text(ErrorHandler.getUserFacingMessage(\1))", content)

            if n > 0 or n2 > 0 or n3 > 0:
                rel_path = os.path.relpath(path, lib_dir)
                level_count = len(rel_path.split(os.sep)) - 1
                content = add_import(content, level_count)
                
                with open(path, "w", encoding="utf-8") as f:
                    f.write(content)
                count += 1
                print(f"Fixed {path}")

print(f"Total files fixed: {count}")
