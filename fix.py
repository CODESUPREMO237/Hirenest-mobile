import os
import re

files = [
    r'lib\features\marketplace\presentation\pages\my_products_page.dart',
    r'lib\features\marketplace\presentation\pages\order_details_page.dart',
    r'lib\features\marketplace\presentation\widgets\image_gallery.dart',
    r'lib\features\marketplace\presentation\widgets\image_picker_widget.dart',
    r'lib\features\marketplace\presentation\widgets\payment_method_selector.dart',
    r'lib\features\marketplace\presentation\widgets\payment_status_dialog.dart',
    r'lib\features\profile\presentation\pages\gdpr_page.dart',
    r'lib\features\profile\presentation\pages\licenses_page.dart',
    r'lib\features\profile\presentation\pages\privacy_policy_page.dart',
    r'lib\features\profile\presentation\pages\privacy_security_page.dart',
    r'lib\features\profile\presentation\pages\terms_of_service_page.dart',
    r'lib\features\jobs\presentation\pages\apply_job_page.dart'
]

for fpath in files:
    if not os.path.exists(fpath):
        continue
    with open(fpath, 'r', encoding='utf-8') as f:
        content = f.read()
    
    match = re.search(r'import\s+\'([./]+)core/theme/app_colors\.dart\';', content)
    if match:
        relative_path = match.group(1)
        content = re.sub(r'import\s+\'[^\']*app_spacing\.dart\';\n?', '', content)
        content = content.replace(match.group(0), match.group(0) + "\nimport '" + relative_path + "core/theme/app_spacing.dart';")

    # Replace .withOpacity(x) if missed due to syntax
    content = content.replace('.withOpacity(', '.withValues(alpha: ')

    with open(fpath, 'w', encoding='utf-8') as f:
        f.write(content)
