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

    # Imports
    import_regex = re.compile(r"import 'package:flutter/material.dart';")
    if "import '../../../../core/theme/app_spacing.dart';" not in content:
        content = import_regex.sub("import 'package:flutter/material.dart';\nimport '../../../../core/theme/app_colors.dart';\nimport '../../../../core/theme/app_spacing.dart';", content, count=1)
    
    # Remove duplicate app_colors if any
    content = re.sub(r"(import '../../../../core/theme/app_colors.dart';\n)+", r"import '../../../../core/theme/app_colors.dart';\n", content)
    
    # Opacity
    content = content.replace(".withOpacity(", ".withValues(alpha: ")
    
    # Border Radius
    content = re.sub(r'BorderRadius\.circular\((?:8|10)\)', 'AppSpacing.roundedSm', content)
    content = re.sub(r'BorderRadius\.circular\((?:12|14)\)', 'AppSpacing.roundedMd', content)
    content = re.sub(r'BorderRadius\.circular\(16\)', 'AppSpacing.roundedLg', content)
    content = re.sub(r'BorderRadius\.circular\(24\)', 'AppSpacing.roundedXl', content)
    content = re.sub(r'BorderRadius\.circular\(6\)', 'AppSpacing.roundedSm', content)
    
    # Colors
    content = re.sub(r'AppColors\.grey500?', 'AppColors.borderLight', content)
    content = re.sub(r'AppColors\.grey100', 'AppColors.backgroundLight', content)
    content = re.sub(r'AppColors\.grey200', 'AppColors.borderLight', content)
    content = re.sub(r'AppColors\.grey300', 'AppColors.borderLight', content)
    content = re.sub(r'AppColors\.grey400', 'AppColors.textMutedLight', content)
    content = re.sub(r'AppColors\.grey600', 'AppColors.textSecondaryLight', content)
    content = re.sub(r'AppColors\.grey700', 'AppColors.textSecondaryLight', content)
    content = re.sub(r'AppColors\.textPrimary(?!Light)', 'AppColors.textPrimaryLight', content)
    content = re.sub(r'AppColors\.textSecondary(?!Light)', 'AppColors.textSecondaryLight', content)
    content = re.sub(r'AppColors\.textMuted(?!Light)', 'AppColors.textMutedLight', content)
    content = re.sub(r'AppColors\.cta(?!Light)', 'AppColors.accent', content)
    
    # BoxShadows
    content = re.sub(r'boxShadow: \[.*?BoxShadow.*?\]', 'boxShadow: AppSpacing.cardShadow', content, flags=re.DOTALL)
    
    # Theme.of
    content = re.sub(r'style: const TextStyle\(\s*fontSize: 18,\s*fontWeight: FontWeight.w700,\s*color: AppColors.textPrimaryLight,\s*letterSpacing: -0.3,\s*\)', 'style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)', content)

    # Some hardcoded colors
    content = content.replace('Color(0xFFF0F2F5)', 'AppColors.backgroundLight')
    content = content.replace('Colors.white', 'AppColors.surfaceLight')
    
    with open(filepath, 'w', encoding='utf-8') as f:
        f.write(content)

for fp in files_to_process:
    if os.path.exists(fp):
        process_file(fp)
        print(f"Processed {fp}")
    else:
        print(f"File not found: {fp}")

