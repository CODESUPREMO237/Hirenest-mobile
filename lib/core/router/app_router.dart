import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

// Auth
import '../../features/analytics/presentation/pages/analytics_page.dart';
import '../../features/applications/data/models/application_model.dart';
import '../../features/applications/presentation/pages/applicant_details_page.dart';
import '../../features/auth/presentation/pages/login_page.dart';
import '../../features/auth/presentation/pages/register_page.dart';
import '../../features/auth/presentation/pages/onboarding_page.dart';
import '../../features/auth/presentation/pages/splash_screen.dart';
import '../../features/auth/presentation/providers/auth_provider.dart';

// Home
import '../../features/company/presentation/pages/company_dashboard_page.dart';
import '../../features/company/presentation/pages/company_detail_page.dart';
import '../../features/company/presentation/pages/create_company_page.dart';
import '../../features/company/presentation/pages/edit_company_page.dart';
import '../../features/company/presentation/pages/manage_admins_page.dart';
import '../../features/home/presentation/pages/main_page.dart';
import '../../features/home/presentation/pages/guest_dashboard.dart';

// Jobs
import '../../features/jobs/presentation/pages/edit_job_page.dart';
import '../../features/jobs/presentation/pages/job_applicants_page.dart';
import '../../features/jobs/presentation/pages/jobs_page.dart';
import '../../features/jobs/presentation/pages/job_detail_page.dart';
import '../../features/jobs/presentation/pages/create_job_page.dart';
import '../../features/jobs/presentation/pages/apply_job_page.dart';
import '../../features/applications/presentation/pages/applications_page.dart';

// Marketplace
import '../../features/marketplace/presentation/pages/marketplace_page.dart';
import '../../features/marketplace/presentation/pages/product_detail_page.dart';
import '../../features/marketplace/presentation/pages/create_product_page.dart';
import '../../features/marketplace/presentation/pages/edit_product_page.dart';
import '../../features/marketplace/presentation/pages/my_products_page.dart';

// Chat
import '../../features/chat/presentation/pages/chat_list_page.dart';
import '../../features/chat/presentation/pages/chat_detail_page.dart';

// Profile
import '../../features/profile/presentation/pages/deposit_page.dart';
import '../../features/profile/presentation/pages/licenses_page.dart';
import '../../features/profile/presentation/pages/privacy_policy_page.dart';
import '../../features/profile/presentation/pages/profile_page.dart';
import '../../features/profile/presentation/pages/edit_profile_page.dart';
import '../../features/profile/presentation/pages/settings_page.dart';
import '../../features/profile/presentation/pages/balance_page.dart';
import '../../features/profile/presentation/pages/payout_page.dart';
import '../../features/profile/presentation/pages/terms_of_service_page.dart';
import '../../features/profile/presentation/pages/transactions_page.dart';
import '../../features/profile/presentation/pages/notifications_page.dart';
import '../../features/profile/presentation/pages/privacy_security_page.dart';
import '../../features/profile/presentation/pages/help_support_page.dart';
import '../../features/profile/presentation/pages/about_page.dart';
import '../../features/profile/presentation/pages/user_profile_page.dart';


final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authStateProvider);

  return GoRouter(
    initialLocation: '/splash',

    // ========================
    // REDIRECT LOGIC
    // ========================
    redirect: (context, state) {
      final isAuthRoute = state.matchedLocation.startsWith('/auth');
      final isOnboarding = state.matchedLocation == '/onboarding';
      final isSplash = state.matchedLocation == '/splash';

      return authState.when(
        data: (user) {
          if (isSplash) return null;

          if (user == null && !isAuthRoute && !isOnboarding) {
            return '/auth/login';
          }

          if (user != null && (isAuthRoute || isOnboarding)) {
            return '/';
          }

          return null;
        },
        loading: () => isSplash ? null : '/splash',
        error: (_, __) => '/auth/login',
      );
    },

    // ========================
    // ROUTES
    // ========================
    routes: [
      // Splash
      GoRoute(
        path: '/splash',
        builder: (context, state) => const SplashScreen(),
      ),

      // Onboarding
      GoRoute(
        path: '/onboarding',
        builder: (context, state) => const OnboardingPage(),
      ),

      // Auth
      GoRoute(
        path: '/auth/login',
        builder: (context, state) => const LoginPage(),
      ),
      GoRoute(
        path: '/auth/register',
        builder: (context, state) => const RegisterPage(),
      ),

      // Guest
      GoRoute(
        path: '/guest',
        builder: (context, state) => const GuestDashboard(),
      ),

      // Home / Main
      GoRoute(
        path: '/',
        builder: (context, state) => const MainPage(),
      ),

      // ========================
      // JOBS
      // ========================
      GoRoute(
        path: '/jobs',
        builder: (context, state) => const JobsPage(),
        routes: [
          GoRoute(
            path: 'create',
            builder: (context, state) => const CreateJobPage(),
          ),
          GoRoute(
            path: ':id',
            builder: (context, state) {
              final id = state.pathParameters['id']!;
              return JobDetailPage(jobId: id);
            },
            routes: [
              GoRoute(
                path: 'apply',
                builder: (context, state) {
                  final id = state.pathParameters['id']!;
                  return ApplyJobPage(jobId: id);
                },
              ),


              // Path: /jobs/:id/edit
              GoRoute(
                path: 'edit',
                builder: (context, state) {
                  // We get the id from the parent parameter ':id'
                  final jobId = state.pathParameters['id']!;
                  return EditJobScreen(jobId: jobId);
                },
              ),
              GoRoute(
                path: 'applicants',
                builder: (context, state) {
                  final jobId = state.pathParameters['id']!;
                  final jobTitle = state.extra as String? ?? 'Job Applicants';

                  return JobApplicantsPage(
                    jobId: jobId,
                    jobTitle: jobTitle,
                  );
                },
                routes: [
                  GoRoute(
                    path: ':applicationId',
                    builder: (context, state) {
                      final application = state.extra as ApplicationModel;

                      return ApplicantDetailsPage(
                        application: application,
                        jobId: state.pathParameters['id']!,
                      );
                    },
                  ),
                ],
              ),
            ],
          ),
        ],
      ),

      // Applications (standalone route)
      GoRoute(
        path: '/applications',
        builder: (context, state) => const ApplicationsPage(),
      ),

      // ========================
      // PROFILE
      // ========================
      GoRoute(
        path: '/profile',
        builder: (context, state) => const ProfilePage(),
      ),
      GoRoute(
        path: '/profile/edit',
        builder: (context, state) => const EditProfilePage(),
      ),
      GoRoute(
        path: '/profile/settings',
        builder: (context, state) => const SettingsPage(),
      ),
      GoRoute(
        path: '/profile/balance',
        builder: (context, state) => const BalancePage(),
      ),
      GoRoute(
        path: '/profile/payout',
        builder: (context, state) => const PayoutPage(),
      ),
      GoRoute(
        path: '/profile/deposit',
        builder: (context, state) => const DepositPage(),
      ),
      GoRoute(
        path: '/profile/transactions',
        builder: (context, state) => const TransactionsPage(),
      ),
      GoRoute(
        path: '/profile/notifications',
        builder: (context, state) => const NotificationsPage(),
      ),
      GoRoute(
        path: '/profile/privacy-security',
        builder: (context, state) => const PrivacySecurityPage(),
      ),
      GoRoute(
        path: '/profile/help-support',
        builder: (context, state) => const HelpSupportPage(),
      ),
      GoRoute(
        path: '/profile/about',
        builder: (context, state) => const AboutPage(),
      ),
      GoRoute(
        path: '/profile/legal/privacy',
        builder: (context, state) => const PrivacyPolicyPage(),
      ),
      GoRoute(
        path: '/profile/legal/terms',
        builder: (context, state) => const TermsOfServicePage(),
      ),
      GoRoute(
        path: '/profile/legal/licenses',
        builder: (context, state) => const LicensesPage(),
      ),
      GoRoute(
        path: '/profile/:userId',
        builder: (context, state) {
          final userId = state.pathParameters['userId']!;
          return UserProfilePage(userId: userId);
        },
      ),

      // ========================
      // MARKETPLACE
      // ========================
      GoRoute(
        path: '/marketplace',
        builder: (context, state) => const MarketplacePage(),
      ),
      GoRoute(
        path: '/marketplace/create',
        builder: (context, state) => const CreateProductPage(),
      ),
      GoRoute(
        path: '/marketplace/my-products',
        builder: (context, state) => const MyProductsPage(),
      ),
      GoRoute(
        path: '/marketplace/:id/edit',
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          return EditProductPage(productId: id);
        },
      ),
      GoRoute(
        path: '/marketplace/products/:id',
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          return ProductDetailPage(productId: id);
        },
      ),

      // ========================
      // CHAT
      // ========================
      GoRoute(
        path: '/chats',
        builder: (context, state) => const ChatListPage(),
      ),
      GoRoute(
        path: '/chats/:id',
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          return ChatDetailPage(chatId: id);
        },
      ),

      // ========================
      // COMPANY
      // ========================
      GoRoute(
        path: '/company/dashboard',
        builder: (context, state) => const CompanyDashboardPage(),
      ),
      // ADD THIS ROUTE HERE:
      GoRoute(
        path: '/company/manage-admins',
        builder: (context, state) => const ManageAdminsPage(),
      ),
      GoRoute(
        path: '/company/create',
        builder: (context, state) => const CreateCompanyPage(),
      ),
      GoRoute(
        path: '/company/edit',
        builder: (context, state) => const EditCompanyPage(),
      ),
      GoRoute(
        path: '/company/:id',
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          return CompanyDetailPage(companyId: id);
        },
      ),

      // ========================
      // ANALYTICS
      // ========================
      GoRoute(
        path: '/analytics',
        builder: (context, state) => const AnalyticsPage(),
      ),
    ],

    // ========================
    // ERROR PAGE
    // ========================
    errorBuilder: (context, state) => Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text('Page not found: ${state.matchedLocation}'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => context.go('/'),
              child: const Text('Go Home'),
            ),
          ],
        ),
      ),
    ),
  );
});