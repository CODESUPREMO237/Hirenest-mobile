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

color_map = {
    'grey50': 'backgroundLight',
    'grey100': 'backgroundLight',
    'grey200': 'borderLight',
    'grey300': 'borderLight',
    'grey400': 'textMutedLight',
    'grey500': 'textMutedLight',
    'grey600': 'textSecondaryLight',
    'grey700': 'textPrimaryLight',
    'grey800': 'textPrimaryLight',
    'grey900': 'textPrimaryLight',
    'info': 'primaryDark',  # info wasn't defined, replace with primaryDark
    'textLight': 'textSecondaryLight',
}

for fpath in files:
    if not os.path.exists(fpath):
        continue
    with open(fpath, 'r', encoding='utf-8') as f:
        content = f.read()

    # Apply color map
    for old_color, new_color in color_map.items():
        content = re.sub(r'AppColors\.' + old_color + r'(?!\w)', f'AppColors.{new_color}', content)

    # Use Theme.of(context) instead of basic TextStyle for common cases in gdpr, etc
    # We will just write it generally but it's tricky to remove const if present.
    # It's better to just regex replace `const TextStyle` to `TextStyle` first, 
    # but let's just stick to fixing the colors. I will handle Theme.of in a separate pass if really needed.

    with open(fpath, 'w', encoding='utf-8') as f:
        f.write(content)
