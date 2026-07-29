import os
import re

files = [r'd:\project\mobile_apps\frontends\hirenest\lib\features\admin\presentation\pages\admin_dashboard_page.dart',
         r'd:\project\mobile_apps\frontends\hirenest\lib\features\admin\presentation\pages\admin_disputes_page.dart',
         r'd:\project\mobile_apps\frontends\hirenest\lib\features\analytics\presentation\pages\analytics_page.dart']
for fp in files:
    with open(fp, 'r', encoding='utf-8') as f:
        content = f.read()
    
    # Remove duplicate lines
    lines = content.split('\n')
    new_lines = []
    seen_imports = set()
    for line in lines:
        if line.startswith('import '):
            if line in seen_imports:
                continue
            seen_imports.add(line)
        new_lines.append(line)
    
    with open(fp, 'w', encoding='utf-8') as f:
        f.write('\n'.join(new_lines))
