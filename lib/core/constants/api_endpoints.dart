// Complete API Endpoints - Matching Backend Exactly
// lib/core/constants/api_endpoints.dart

import 'package:flutter_dotenv/flutter_dotenv.dart';

class ApiEndpoints {
  static String get baseUrl => dotenv.env['API_BASE_URL'] ?? '';

  // ==================== AUTH ====================
  static const String login = '/auth/login';
  static const String register = '/auth/register';
  static const String logout = '/auth/logout';
  static const String refreshToken = '/auth/refresh';
  static const String forgotPassword = '/auth/forgot-password';
  static const String resetPassword = '/auth/reset-password';
  static const String verifyEmail = '/auth/verify-email';

  // ==================== USER ====================
  static const String me = '/users/me';
  static const String updateProfile = '/users/me';
  static const String uploadAvatar = '/users/me/avatar';
  static const String changePassword = '/users/me/password';
  static const String deleteAccount = '/users/me';
  static const String talent = '/users/talent';
  static String publicProfile(String id) => '/users/$id/public-profile';
  static String userById(String id) => '/users/$id';

  // ==================== JOBS ====================
  // Backend: app.use('/api/v1/jobs', jobRoutes)
  static const String jobs = '/jobs';
  static const String featuredJobs = '/jobs/featured';
  static const String jobCategories = '/jobs/categories';

  // Job by ID
  static String job(String id) => '/jobs/$id'; // Used for GET, PUT (Update), and DELETE
  static String similarJobs(String id) => '/jobs/$id/similar';

  // Employer routes (special route in job.routes.js)

  static const String myJobs = '/jobs/my-jobs'; // Fixed
  static String updateJobStatus(String id) => '/jobs/$id/status';
  static String jobApplicants(String id) => '/jobs/$id/applicants';

  // ==================== MARKETPLACE ====================
  // Backend: app.use('/api/v1/marketplace', marketplaceRoutes)
  static const String products = '/marketplace/products';
  static const String nearbyProducts = '/marketplace/products/nearby';
  static const String categories = '/marketplace/categories';

  // Product by ID
  static String product(String id) => '/marketplace/products/$id';

  // My products
  static const String myProducts = '/marketplace/my-products';

  // Product by seller
  static String productsBySeller(String sellerId) =>
      '/marketplace/products/seller/$sellerId';

  // Product actions
  static String markProductSold(String id) =>
      '/marketplace/products/$id/mark-sold';
  static String reportProduct(String id) =>
      '/marketplace/products/$id/report';

  // ==================== ORDERS & DELIVERY ====================
  // Backend: app.use('/api/v1/orders', deliveryRoutes)
  static String order(String id) => '/orders/$id';
  static const String myOrders = '/orders/my-orders';
  static const String mySales = '/orders/my-sales';
  
  // Delivery
  static String orderDeliveryOtp(String id) => '/orders/$id/delivery/otp';
  static String verifyDeliveryOtp(String id) => '/orders/$id/delivery/verify-otp';
  static String rejectDelivery(String id) => '/orders/$id/delivery/reject';
  static String shipOrder(String id) => '/orders/$id/ship';
  static String nudgeSeller(String id) => '/orders/$id/nudge-seller';

  // ==================== APPLICATIONS ====================

  // ✅ OPTIMIZED EMPLOYER ENDPOINTS (ADD THESE)
  static const String employerApplications = '/applications/employer-applications';
  static const String employerApplicationStats = '/applications/employer-stats';

  // Job Seeker routes
  static const String myApplications = '/applications/my-applications';
  static String applyJob(String jobId) => '/applications/jobs/$jobId/apply';
  static String withdrawApplication(String id) =>
      '/applications/applications/$id/withdraw';

  // Shared routes
  static const String applicationStats = '/applications/applications/stats';
  static String application(String id) => '/applications/applications/$id';

  // Employer routes

  static String updateApplicationStatus(String id) =>
      '/applications/applications/$id/status';
  static String scheduleInterview(String id) =>
      '/applications/applications/$id/interview';
  static String rejectApplication(String id) =>
      '/applications/applications/$id/reject';
  static String shortlistApplication(String id) =>
      '/applications/applications/$id/shortlist';

  // ==================== CHAT ====================
  // Backend: app.use('/api/v1/chats', chatRoutes)
  static const String chats = '/chats';
  static String chat(String id) => '/chats/$id';
  static String chatMessages(String id) => '/chats/$id/messages';
  static String startChat(String productId) => '/chats/product/$productId';
  static String sendMessage(String chatId) => '/chats/$chatId/messages';
  static String markAsRead(String chatId) => '/chats/$chatId/read';
  static String deleteMessage(String messageId) => '/chats/messages/$messageId';

  // ==================== COMPANIES ====================
  // Backend: app.use('/api/v1/companies', companyRoutes)
  static const String companies = '/companies';
  static String company(String id) => '/companies/$id';
  static const String myCompany = '/companies/my-company';
  static const String searchUsers = '/users/search';
  // Admin endpoints
  static String companyAdmins(String companyId) => '/companies/$companyId/admins';
  static String removeCompanyAdmin(String companyId, String adminId) =>
      '/companies/$companyId/admins/$adminId';

  // ==================== PAYMENTS ====================
  // Backend: app.use('/api/v1/payments', paymentRoutes)
  static const String createPayment = '/payments/create';
  static String paymentStatus(String orderId) => '/payments/status/$orderId';
  static const String balance = '/payments/balance';
  static const String payout = '/payments/payout';
  static const String transactions = '/payments/transactions';
  static const String paymentMethods = '/payments/methods';

  // ==================== ANALYTICS ====================
  // Backend: app.use('/api/v1/analytics', analyticsRoutes)
  static const String analytics = '/analytics';
  static const String dashboardStats = '/analytics/user'; // Matches your router.get('/user')
  static const String userAnalytics = '/analytics/users';
  static const String jobAnalytics = '/analytics/jobs';
  static const String marketplaceAnalytics = '/analytics/marketplace';

  // ==================== ADMIN ====================
  // Backend: app.use('/api/v1/admin', adminRoutes)
  // ==================== ADMIN ====================
  static const String adminDashboard = '/admin/dashboard';
  static const String adminUsers = '/admin/users';
  static String adminUser(String id) => '/admin/users/$id';
  static String toggleUserBlock(String id) => '/admin/users/$id/toggle-block';
  static String deleteUser(String id) => '/admin/users/$id';
  static String moderateJob(String id) => '/admin/jobs/$id/moderate';
  static String moderateProduct(String id) => '/admin/products/$id/moderate';
  static const String adminReported = '/admin/reported';
  static const String adminDisputes = '/admin/disputes';
  static String resolveAdminDispute(String id) => '/admin/disputes/$id/resolve';

// ==================== REVIEWS ====================
  // ==================== REVIEWS ====================
  static const String reviews = '/reviews';
  static String userReviews(String userId) => '/reviews/user/$userId';
  static String jobReviews(String jobId) => '/reviews/job/$jobId';

  // ✅ NEW: Check if user has reviewed a specific reviewee for a job
  static String checkReview(String jobId, String revieweeId) =>
      '/reviews/check/$jobId/$revieweeId';

  // ==================== GDPR / ACCOUNT (Phase 6) ====================
  static const String exportMyData = '/account/export';
  static const String deleteMyAccount = '/account/delete';

  // ==================== VERIFICATION (Phase 7) ====================
  static const String submitVerification = '/verifications';
  static const String myVerifications = '/verifications/mine';
  static const String pendingVerifications = '/verifications/pending';
  static String reviewVerification(String id) => '/verifications/$id/review';

  // ==================== SAVED SEARCHES (Phase 8) ====================
  static const String savedSearches = '/saved-searches';
  static String savedSearch(String id) => '/saved-searches/$id';

  // ==================== SUBSCRIPTIONS (Phase 9) ====================
  static const String plans = '/subscriptions/plans';
  static const String subscribe = '/subscriptions/subscribe';
  static const String mySubscription = '/subscriptions/mine';
  static const String cancelSubscription = '/subscriptions/cancel';
  static const String boostListing = '/subscriptions/boost';

  // ==================== MATCHING (Phase 10) ====================
  static const String recommendedJobs = '/matching/jobs';
  static String recommendedCandidates(String jobId) => '/matching/candidates/$jobId';

  // ==================== FEATURE FLAGS (Phase 11) ====================
  static const String myFeatureFlags = '/feature-flags/mine';
  static const String featureFlags = '/feature-flags';
  static String featureFlag(String id) => '/feature-flags/$id';

  // ==================== LEGAL (Phase 12) ====================
  static const String legalStatus = '/legal/status';
  static const String acceptLegal = '/legal/accept';

}

// Helper extension for building full URLs
extension ApiEndpointsExtension on ApiEndpoints {
  static String fullUrl(String endpoint) {
    return '${ApiEndpoints.baseUrl}$endpoint';
  }
}