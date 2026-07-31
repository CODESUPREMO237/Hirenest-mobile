import os
import re

lib_dir = r"d:\project\mobile_apps\frontends\hirenest\lib"

def add_import(content, level_count):
    import_path = "../" * level_count + "core/utils/error_handler.dart"
    if "core/utils/error_handler.dart" not in content:
        import_stmt = f"import '{import_path}';\n"
        if "import 'package:flutter/material.dart';" in content:
            content = content.replace("import 'package:flutter/material.dart';", f"import 'package:flutter/material.dart';\n{import_stmt}")
        else:
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
            
            # NOTE: (error|err|e) ensures longer matches are checked first
            # 1. Match exactly $error, $err, $e
            content, n1 = re.subn(
                r"Text\(\s*'[^']*?\$(error|err|e)[^']*'", 
                r"Text(ErrorHandler.getUserFacingMessage(\1)", 
                content
            )
            
            # 2. Match exactly ${error}, ${err}, ${e}, ${snapshot.error}
            content, n2 = re.subn(
                r"Text\(\s*'[^']*?\$\{(snapshot\.error|error|err|e)\}[^']*'", 
                r"Text(ErrorHandler.getUserFacingMessage(\1)", 
                content
            )

            # 3. Match error.toString()
            content, n3 = re.subn(
                r"Text\(\s*(error|err|e)\.toString\(\)", 
                r"Text(ErrorHandler.getUserFacingMessage(\1)", 
                content
            )

            # 4. Match state.error!
            content, n4 = re.subn(
                r"Text\(\s*state\.error!", 
                r"Text(ErrorHandler.getUserFacingMessage(state.error!)", 
                content
            )

            # Fix specific unused imports based on flutter analyze output
            if path.endswith(r"lib\features\chat\presentation\pages\chat_list_page.dart"):
                content = content.replace("import '../../../../core/widgets/error_widget.dart';", "")
            if path.endswith(r"lib\features\home\presentation\pages\home_page.dart"):
                content = content.replace("import '../../../../core/utils/error_handler.dart';", "")

            if content != original_content:
                if n1 > 0 or n2 > 0 or n3 > 0 or n4 > 0:
                    rel_path = os.path.relpath(path, lib_dir)
                    level_count = len(rel_path.split(os.sep)) - 1
                    content = add_import(content, level_count)
                
                with open(path, "w", encoding="utf-8") as f:
                    f.write(content)
                count += 1
                print(f"Fixed {path}")

print(f"Total files fixed: {count}")
