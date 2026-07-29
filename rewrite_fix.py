import os
import re

files_to_process = [
    r"d:\project\mobile_apps\frontends\hirenest\lib\features\admin\presentation\pages\admin_dashboard_page.dart",
    r"d:\project\mobile_apps\frontends\hirenest\lib\features\admin\presentation\pages\admin_disputes_page.dart",
    r"d:\project\mobile_apps\frontends\hirenest\lib\features\analytics\presentation\pages\analytics_page.dart",
]

def process_file(filepath):
    with open(filepath, 'r', encoding='utf-8') as f:
        content = f.read()

    # Fix const AppColors.backgroundLight
    content = content.replace('const AppColors.backgroundLight', 'AppColors.backgroundLight')
    
    # Fix AppColors.surfaceLight70
    content = content.replace('AppColors.surfaceLight70', 'AppColors.surfaceLight.withValues(alpha: 0.7)')
    
    # Fix AppAppColors
    content = content.replace('AppAppColors.', 'AppColors.')
    
    # Check for remaining Colors.red, Colors.green, etc.
    content = content.replace('Colors.red', 'AppColors.error')
    content = content.replace('Colors.blue', 'AppColors.primary')
    content = content.replace('Colors.green', 'AppColors.success')
    content = content.replace('Colors.orange', 'AppColors.warning')
    content = content.replace('Colors.grey', 'AppColors.borderLight')
    content = content.replace('Colors.transparent', 'AppColors.transparent')
    content = content.replace('Colors.black', 'AppColors.black')
    content = content.replace('Colors.white', 'AppColors.surfaceLight')

    with open(filepath, 'w', encoding='utf-8') as f:
        f.write(content)

for fp in files_to_process:
    if os.path.exists(fp):
        process_file(fp)
        print(f"Processed {fp}")
    else:
        print(f"File not found: {fp}")

