import 'dart:convert';
import 'package:flutter/material.dart';
import '../../../../../../../../core/theme/app_colors.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

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
import '../../features/marketplace/presentation/pages/my_orders_page.dart';
import '../../features/marketplace/presentation/pages/my_sales_page.dart';
import '../../features/marketplace/presentation/pages/order_details_page.dart';
import '../../features/marketplace/presentation/pages/payment_page.dart';

// Chat
import '../../features/chat/presentation/pages/chat_list_page.dart';
import '../../features/chat/presentation/pages/chat_detail_page.dart';

// Profile
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
import '../../features/talent/presentation/pages/talent_profile_page.dart';

// Admin
import '../../features/admin/presentation/pages/admin_dashboard_page.dart';
import '../../features/admin/presentation/pages/admin_disputes_page.dart';
import '../../core/router/admin_guard.dart';

// Phase 6-12
import '../../features/profile/presentation/pages/gdpr_page.dart';
import '../../features/profile/presentation/pages/verification_page.dart';
import '../../features/profile/presentation/pages/saved_searches_page.dart';
import '../../features/profile/presentation/pages/subscription_page.dart';
import '../../features/jobs/presentation/pages/recommended_jobs_page.dart';
import '../../features/auth/presentation/pages/legal_acceptance_page.dart';

final GlobalKey<NavigatorState> rootNavigatorKey = GlobalKey<NavigatorState>();

/// Notifier that tells GoRouter to re-evaluate its redirect WITHOUT
/// recreating the entire GoRouter instance. This preserves the current
/// navigation location.
class _AuthChangeNotifier extends ChangeNotifier {
  _AuthChangeNotifier(Ref ref) {
    ref.listen(authStateProvider, (_, _) => notifyListeners());
    ref.listen(isAuthenticatedProvider, (_, _) => notifyListeners());
  }
}

final routerProvider = Provider<GoRouter>((ref) {
  final authNotifier = _AuthChangeNotifier(ref);

  return GoRouter(
    navigatorKey: rootNavigatorKey,
    initialLocation: '/splash',
    refreshListenable: authNotifier,

    // ========================
    // REDIRECT LOGIC
    // ========================
    redirect: (context, state) async {
      final isAuthRoute = state.matchedLocation.startsWith('/auth');
      final isOnboarding = state.matchedLocation == '/onboarding';
      final isSplash = state.matchedLocation == '/splash';

      // Use ref.read (not watch!) so we get current state without
      // triggering a GoRouter rebuild.
      final authState = ref.read(authStateProvider);
      final isAuthenticated = ref.read(isAuthenticatedProvider);

      return authState.when(
        data: (firebaseUser) {
          if (isSplash) return null;

          final loggedIn = isAuthenticated;

          if (!loggedIn && !isAuthRoute && !isOnboarding) {
            return '/auth/login';
          }

          if (loggedIn) {
            return () async {
              // Admin Redirect check
              const storage = FlutterSecureStorage();
              final userDataStr = await storage.read(key: 'user_data');
              if (userDataStr != null) {
                try {
                  final userData = jsonDecode(userDataStr);
                  if (userData['isAdmin'] == true) {
                    if (!state.matchedLocation.startsWith('/admin')) {
                      return '/admin/dashboard';
                    }
                    return null; // They are already on an admin route
                  }
                } catch (e) {
                  // ignore parsing errors
                }
              }
              
              if (isAuthRoute || isOnboarding) {
                return '/';
              }
              return null;
            }();
          }

          return null;
        },
        loading: () => (isSplash || isAuthRoute) ? null : '/splash',
        error: (err, stack) => '/auth/login',
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

      // ========================
      // ADMIN
      // ========================
      GoRoute(
        path: '/admin',
        redirect: (context, state) => '/admin/dashboard',
      ),
      GoRoute(
        path: '/admin/dashboard',
        builder: (context, state) => const AdminGuard(
          child: AdminDashboardScreen(),
        ),
      ),
      GoRoute(
        path: '/admin/users',
        builder: (context, state) => const AdminGuard(
          child: AdminUsersPage(),
        ),
      ),
      GoRoute(
        path: '/admin/disputes',
        builder: (context, state) => const AdminGuard(
          child: AdminDisputesPage(),
        ),
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
      GoRoute(
        path: '/talent/:id',
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          return TalentProfilePage(userId: id);
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
        path: '/marketplace/my-orders',
        builder: (context, state) => const MyOrdersPage(),
      ),
      GoRoute(
        path: '/marketplace/my-sales',
        builder: (context, state) => const MySalesPage(),
      ),
      GoRoute(
        path: '/marketplace/orders/:id',
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          return OrderDetailsPage(orderId: id);
        },
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
      GoRoute(
        path: '/marketplace/payment/:id',
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          return PaymentPage(productId: id);
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

      // ========================
      // PHASE 6-12 ROUTES
      // ========================
      GoRoute(
        path: '/gdpr',
        builder: (context, state) => const GdprPage(),
      ),
      GoRoute(
        path: '/verification',
        builder: (context, state) => const VerificationPage(),
      ),
      GoRoute(
        path: '/saved-searches',
        builder: (context, state) => const SavedSearchesPage(),
      ),
      GoRoute(
        path: '/subscription',
        builder: (context, state) => const SubscriptionPage(),
      ),
      GoRoute(
        path: '/recommended-jobs',
        builder: (context, state) => const RecommendedJobsPage(),
      ),
      GoRoute(
        path: '/legal-acceptance',
        builder: (context, state) => const LegalAcceptancePage(),
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
            const Icon(Icons.error_outline, size: 64, color: AppColors.error),
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
