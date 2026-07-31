import os
import re

lib_dir = r"d:\project\mobile_apps\frontends\hirenest\lib"

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
            
            # Text('Error: $error'...) -> Text(ErrorHandler.getUserFacingMessage(error)...
            # Match exactly: Text( followed by whitespace, then '...', containing $e, $err, or $error, then '
            content, n = re.subn(r"Text\(\s*'[^']*?\$(e|err|error)[^']*'", r"Text(ErrorHandler.getUserFacingMessage(\1)", content)
            
            # Text('Error: ${snapshot.error}'...)
            content, n2 = re.subn(r"Text\(\s*'[^']*?\$\{([^}]+)\}[^']*'", r"Text(ErrorHandler.getUserFacingMessage(\1)", content)

            # Text(error.toString()...)
            content, n3 = re.subn(r"Text\(\s*(e|err|error)\.toString\(\)", r"Text(ErrorHandler.getUserFacingMessage(\1)", content)

            # There's also Text(state.error!) in marketplace/presentation/pages/order_details_page.dart
            content, n4 = re.subn(r"Text\(\s*state\.error!", r"Text(ErrorHandler.getUserFacingMessage(state.error)", content)

            if n > 0 or n2 > 0 or n3 > 0 or n4 > 0:
                rel_path = os.path.relpath(path, lib_dir)
                level_count = len(rel_path.split(os.sep)) - 1
                content = add_import(content, level_count)
                
                with open(path, "w", encoding="utf-8") as f:
                    f.write(content)
                count += 1
                print(f"Fixed {path}")

print(f"Total files fixed: {count}")
