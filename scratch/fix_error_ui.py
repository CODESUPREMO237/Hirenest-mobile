import os
import re

lib_dir = r"d:\project\mobile_apps\frontends\hirenest\lib"

# 1. Fix jobs_page.dart
jobs_file = os.path.join(lib_dir, "features", "jobs", "presentation", "pages", "jobs_page.dart")
with open(jobs_file, "r", encoding="utf-8") as f:
    jobs_code = f.read()

jobs_code = re.sub(
    r"error: \(error, stack\) => Center\(\s*child: Padding\(\s*padding: const EdgeInsets.all\(AppSpacing.xl\),\s*child: Column\(\s*mainAxisAlignment: MainAxisAlignment.center,\s*children: \[\s*const Icon\(Icons.error_outline, size: 64, color: AppColors.error\),\s*const SizedBox\(height: AppSpacing.md\),\s*Text\('Oops! Something went wrong', style: AppTextStyles.textTheme.titleMedium\),\s*const SizedBox\(height: AppSpacing.sm\),\s*Text\(error.toString\(\), textAlign: TextAlign.center, style: AppTextStyles.textTheme.bodyMedium\?\.copyWith\(color: AppColors.textMutedLight\)\),\s*\],\s*\),\s*\),\s*\),",
    r"error: (error, stack) => CustomErrorWidget(error: error, onRetry: () => ref.refresh(jobsProvider)),",
    jobs_code
)
# Make sure CustomErrorWidget is imported
if "import '../../../../core/widgets/error_widget.dart';" not in jobs_code:
    jobs_code = jobs_code.replace("import '../../../../core/theme/app_text_styles.dart';", "import '../../../../core/theme/app_text_styles.dart';\nimport '../../../../core/widgets/error_widget.dart';")
with open(jobs_file, "w", encoding="utf-8") as f:
    f.write(jobs_code)


# 2. Fix chat_list_page.dart
chat_file = os.path.join(lib_dir, "features", "chat", "presentation", "pages", "chat_list_page.dart")
with open(chat_file, "r", encoding="utf-8") as f:
    chat_code = f.read()

chat_code = re.sub(
    r"error: \(error, stack\) => Center\(\s*child: Column\(\s*mainAxisAlignment: MainAxisAlignment.center,\s*children: \[\s*Container\(\s*padding: const EdgeInsets.all\(AppSpacing.lg\),\s*decoration: BoxDecoration\(\s*color: AppColors.error\.withOpacity\(0.1\),\s*shape: BoxShape.circle,\s*\),\s*child: const Icon\(\s*Icons.error_outline,\s*color: AppColors.error,\s*size: 32,\s*\),\s*\),\s*const SizedBox\(height: AppSpacing.md\),\s*const Text\(\s*'Error loading chats',\s*style: TextStyle\(\s*fontWeight: FontWeight.bold,\s*fontSize: 16,\s*\),\s*\),\s*const SizedBox\(height: AppSpacing.sm\),\s*Text\(\s*error.toString\(\),\s*textAlign: TextAlign.center,\s*style: const TextStyle\(\s*color: AppColors.textSecondaryLight,\s*fontSize: 14,\s*\),\s*\),\s*const SizedBox\(height: AppSpacing.lg\),\s*ElevatedButton.icon\(\s*onPressed: \(\) => ref.refresh\(conversationsProvider\),\s*icon: const Icon\(Icons.refresh\),\s*label: const Text\('Retry'\),\s*style: ElevatedButton.styleFrom\(\s*backgroundColor: AppColors.primary,\s*foregroundColor: AppColors.white,\s*\),\s*\),\s*\],\s*\),\s*\),",
    r"error: (error, stack) => CustomErrorWidget(error: error, onRetry: () => ref.refresh(conversationsProvider)),",
    chat_code
)
if "import '../../../../core/widgets/error_widget.dart';" not in chat_code:
    chat_code = chat_code.replace("import '../../../../core/theme/app_spacing.dart';", "import '../../../../core/theme/app_spacing.dart';\nimport '../../../../core/widgets/error_widget.dart';")
with open(chat_file, "w", encoding="utf-8") as f:
    f.write(chat_code)


# 3. Fix profile_page.dart
profile_file = os.path.join(lib_dir, "features", "profile", "presentation", "pages", "profile_page.dart")
with open(profile_file, "r", encoding="utf-8") as f:
    profile_code = f.read()

profile_code = re.sub(
    r"error: \(error, stack\) => Center\(\s*child: Column\(\s*mainAxisAlignment: MainAxisAlignment.center,\s*children: \[\s*const Icon\(Icons.error_outline, size: 64, color: AppColors.error\),\s*const SizedBox\(height: AppSpacing.md\),\s*Text\('Error: \$error'\),\s*const SizedBox\(height: AppSpacing.md\),\s*ElevatedButton\(\s*onPressed: \(\) => ref.refresh\(profileProvider\),\s*child: const Text\('Retry'\),\s*\),\s*\],\s*\),\s*\),",
    r"error: (error, stack) => CustomErrorWidget(error: error, onRetry: () => ref.refresh(profileProvider)),",
    profile_code
)
if "import '../../../../core/widgets/error_widget.dart';" not in profile_code:
    profile_code = profile_code.replace("import '../../../../core/theme/app_spacing.dart';", "import '../../../../core/theme/app_spacing.dart';\nimport '../../../../core/widgets/error_widget.dart';")
with open(profile_file, "w", encoding="utf-8") as f:
    f.write(profile_code)


# 4. Fix home_page.dart
home_file = os.path.join(lib_dir, "features", "home", "presentation", "pages", "home_page.dart")
with open(home_file, "r", encoding="utf-8") as f:
    home_code = f.read()

home_code = re.sub(
    r"error: \(error, _\) => const Padding\(\s*padding: EdgeInsets.all\(AppSpacing.xl\),\s*child: Center\(child: Text\('Error loading jobs'\)\),\s*\),",
    r"error: (error, _) => Padding(padding: const EdgeInsets.all(AppSpacing.xl), child: Center(child: Text(ErrorHandler.getUserFacingMessage(error)))),",
    home_code
)
home_code = re.sub(
    r"error: \(error, _\) => const Padding\(\s*padding: EdgeInsets.all\(AppSpacing.xl\),\s*child: Center\(child: Text\('Error loading products'\)\),\s*\),",
    r"error: (error, _) => Padding(padding: const EdgeInsets.all(AppSpacing.xl), child: Center(child: Text(ErrorHandler.getUserFacingMessage(error)))),",
    home_code
)
if "import '../../../../core/utils/error_handler.dart';" not in home_code:
    home_code = home_code.replace("import '../../../../core/theme/app_spacing.dart';", "import '../../../../core/theme/app_spacing.dart';\nimport '../../../../core/utils/error_handler.dart';")
with open(home_file, "w", encoding="utf-8") as f:
    f.write(home_code)

print("Fixes applied successfully")
