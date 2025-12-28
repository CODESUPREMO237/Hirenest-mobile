import 'dart:io';

/// Map of directories to files that should exist inside them
final Map<String, List<String>> structure = {
  // CORE
  'lib/core/config': ['app_config.dart', 'firebase_options.dart'],
  'lib/core/constants': ['api_endpoints.dart', 'app_constants.dart', 'storage_keys.dart'],
  'lib/core/network': ['api_client.dart', 'api_interceptors.dart', 'socket_client.dart'],
  'lib/core/router': ['app_router.dart'],
  'lib/core/services': [
    'auth_service.dart',
    'storage_service.dart',
    'payment_service.dart',
    'cache_service.dart',
    'notification_service.dart',
    'analytics_service.dart',
  ],
  'lib/core/theme': ['app_theme.dart', 'app_colors.dart', 'app_text_styles.dart'],
  'lib/core/utils': ['logger.dart', 'validators.dart', 'formatters.dart', 'extensions.dart', 'helpers.dart'],
  'lib/core/widgets': [
    'custom_app_bar.dart',
    'loading_indicator.dart',
    'error_widget.dart',
    'empty_state.dart',
    'custom_button.dart',
    'cached_image.dart',
    'image_viewer.dart',
  ],

  // AUTH
  'lib/features/auth/data/models': ['user_model.dart'],
  'lib/features/auth/data/repositories': ['auth_repository.dart'],
  'lib/features/auth/presentation/providers': ['auth_provider.dart'],
  'lib/features/auth/presentation/pages': [
    'splash_screen.dart',
    'onboarding_page.dart',
    'login_page.dart',
    'register_page.dart',
  ],
  'lib/features/auth/presentation/widgets': ['auth_form_field.dart'],

  // HOME
  'lib/features/home/presentation/pages': [
    'main_page.dart',
    'home_page.dart',
    'employer_dashboard.dart',
    'guest_dashboard.dart',
  ],

  // MARKETPLACE
  'lib/features/marketplace/data/models': [
    'product_model.dart',
    'category_model.dart',
    'order_model.dart',
  ],
  'lib/features/marketplace/data/repositories': ['marketplace_repository.dart'],
  'lib/features/marketplace/presentation/providers': [
    'PaginatedProductsNotifier.dart',
    'product_detail_provider.dart',
    'my_products_provider.dart',
    'categories_provider.dart',
  ],
  'lib/features/marketplace/presentation/pages': [
    'marketplace_page.dart',
    'product_detail_page.dart',
    'create_product_page.dart',
    'edit_product_page.dart',
    'my_products_page.dart',
    'payment_page.dart',
  ],
  'lib/features/marketplace/presentation/widgets': [
    'product_card.dart',
    'product_grid.dart',
    'product_filter_sheet.dart',
    'category_chips.dart',
    'image_gallery.dart',
    'seller_info_card.dart',
    'image_picker_widget.dart',
    'payment_method_selector.dart',
    'payment_status_dialog.dart',
  ],

  // JOBS
  'lib/features/jobs/data/models': ['job_model.dart', 'application_model.dart'],
  'lib/features/jobs/data/repositories': ['jobs_repository.dart'],
  'lib/features/jobs/presentation/providers': [
    'jobs_provider.dart',
    'job_detail_provider.dart',
    'application_actions_notifier.dart',
    'my_jobs_provider.dart',
  ],
  'lib/features/jobs/presentation/pages': [
    'jobs_page.dart',
    'job_detail_page.dart',
    'create_job_page.dart',
    'apply_job_page.dart',
    'my_jobs_page.dart',
    'applications_page.dart',
  ],
  'lib/features/jobs/presentation/widgets': [
    'job_card.dart',
    'job_filter_sheet.dart',
    'application_card.dart',
    'job_details_section.dart',
    'apply_form.dart',
  ],

  // CHAT
  'lib/features/chat/data/models': ['chat_model.dart', 'message_model.dart'],
  'lib/features/chat/data/repositories': ['chat_repository.dart'],
  'lib/features/chat/presentation/providers': [
    'chats_provider.dart',
    'messages_provider.dart',
    'socket_provider.dart',
  ],
  'lib/features/chat/presentation/pages': ['chat_list_page.dart', 'chat_detail_page.dart'],
  'lib/features/chat/presentation/widgets': [
    'chat_tile.dart',
    'message_bubble.dart',
    'chat_input.dart',
    'typing_indicator.dart',
    'online_status.dart',
  ],

  // PROFILE
  'lib/features/profile/data/models': ['profile_model.dart'],
  'lib/features/profile/data/repositories': ['profile_repository.dart'],
  'lib/features/profile/presentation/providers': ['profile_provider.dart', 'balance_provider.dart'],
  'lib/features/profile/presentation/pages': [
    'profile_page.dart',
    'edit_profile_page.dart',
    'complete_profile_page.dart',
    'balance_page.dart',
    'payout_page.dart',
    'settings_page.dart',
  ],
  'lib/features/profile/presentation/widgets': [
    'profile_header.dart',
    'profile_stats.dart',
    'balance_card.dart',
    'settings_tile.dart',
  ],

  // ASSETS
  'assets/images/onboarding': [],
  'assets/icons': [],
  'assets/lottie': ['loading.json', 'success.json', 'empty.json'],

  // TESTS
  'test/unit': [],
  'test/widget': [],
  'test/integration': [],
};

void main() {
  for (final entry in structure.entries) {
    final dir = Directory(entry.key);

    if (!dir.existsSync()) {
      dir.createSync(recursive: true);
      print('📁 Created directory: ${entry.key}');
    }

    for (final fileName in entry.value) {
      final file = File('${entry.key}/$fileName');

      if (!file.existsSync()) {
        file.createSync(recursive: true);

        if (fileName.endsWith('.dart')) {
          file.writeAsStringSync(
            '''/// ${_toTitle(fileName)}
/// TODO: Implement this file

''',
          );
        } else if (fileName.endsWith('.json')) {
          file.writeAsStringSync('{}');
        }

        print('📄 Created file: ${file.path}');
      }
    }
  }

  // Ensure main.dart exists
  final mainFile = File('lib/main.dart');
  if (!mainFile.existsSync()) {
    mainFile.createSync(recursive: true);
    mainFile.writeAsStringSync('void main() => print("JobConnect Marketplace");');
    print('🚀 Created lib/main.dart');
  }

  print('\n✅ Structure sync complete!');
}

String _toTitle(String fileName) {
  return fileName
      .replaceAll('.dart', '')
      .split('_')
      .map((e) => e[0].toUpperCase() + e.substring(1))
      .join(' ');
}
