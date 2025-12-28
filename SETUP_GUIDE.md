# JobConnect Marketplace - Complete Setup Guide

## 🚀 Quick Start (5 Minutes)

### Step 1: Create Flutter Project
```bash
flutter create jobconnect_marketplace
cd jobconnect_marketplace
```

### Step 2: Replace Files
1. Replace `pubspec.yaml` with the provided version
2. Create `.env` file from template
3. Run `flutter pub get`

### Step 3: Firebase Setup
```bash
# Install FlutterFire CLI
dart pub global activate flutterfire_cli

# Configure Firebase
flutterfire configure
```

### Step 4: Run the App
```bash
flutter run
```

---

## 📋 Detailed Implementation Steps

### Phase 1: Project Foundation (Day 1-2)

#### 1.1 Setup Environment
```bash
# Check Flutter version
flutter doctor -v

# Should see:
# ✓ Flutter (Channel stable, 3.x.x)
# ✓ Android toolchain
# ✓ Xcode (for iOS)
# ✓ VS Code / Android Studio
```

#### 1.2 Configure Git
```bash
# .gitignore additions
.env
*.jks
*.keystore
ios/Runner/GoogleService-Info.plist
android/app/google-services.json
```

#### 1.3 Setup CI/CD (Optional)
```yaml
# .github/workflows/flutter.yml
name: Flutter CI

on:
  push:
    branches: [ main, develop ]
  pull_request:
    branches: [ main ]

jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - uses: subosito/flutter-action@v2
        with:
          flutter-version: '3.16.0'
      - run: flutter pub get
      - run: flutter analyze
      - run: flutter test
      - run: flutter build apk --release
```

---

### Phase 2: Core Implementation (Day 3-5)

#### 2.1 Create Folder Structure
```bash
# Create all necessary folders
mkdir -p lib/core/{config,constants,network,router,services,theme,utils,widgets}
mkdir -p lib/features/{auth,marketplace,jobs,chat,profile,home}/{data,domain,presentation}
mkdir -p assets/{images,icons,lottie,fonts}
```

#### 2.2 Implement Core Services

**File: `lib/core/utils/logger.dart`**
```dart
import 'package:logger/logger.dart';
import '../config/app_config.dart';

class AppLogger {
  static late Logger _logger;

  static void init() {
    _logger = Logger(
      filter: ProductionFilter(),
      printer: PrettyPrinter(
        methodCount: 2,
        errorMethodCount: 8,
        lineLength: 120,
        colors: true,
        printEmojis: true,
        printTime: true,
      ),
      level: AppConfig.isDevelopment ? Level.debug : Level.warning,
    );
  }

  static void debug(String message) => _logger.d(message);
  static void info(String message) => _logger.i(message);
  static void warning(String message) => _logger.w(message);
  static void error(String message, {Object? error, StackTrace? stackTrace}) {
    _logger.e(message, error: error, stackTrace: stackTrace);
  }
}
```

**File: `lib/core/constants/api_endpoints.dart`**
```dart
class ApiEndpoints {
  // Auth
  static const String login = '/auth/login';
  static const String register = '/auth/register';
  static const String logout = '/auth/logout';
  
  // User
  static const String me = '/users/me';
  static const String updateProfile = '/users/me';
  static const String uploadAvatar = '/users/me/avatar';
  
  // Marketplace
  static const String products = '/marketplace/products';
  static String product(String id) => '/marketplace/products/$id';
  static const String myProducts = '/marketplace/my-products';
  static const String categories = '/marketplace/categories';
  
  // Jobs
  static const String jobs = '/jobs';
  static String job(String id) => '/jobs/$id';
  static const String myJobs = '/my-jobs';
  static String jobApplicants(String id) => '/jobs/$id/applicants';
  
  // Applications
  static String applyJob(String id) => '/applications/jobs/$id/apply';
  static const String myApplications = '/my-applications';
  static String application(String id) => '/applications/$id';
  
  // Chat
  static const String chats = '/chats';
  static String chat(String id) => '/chats/$id';
  static String chatMessages(String id) => '/chats/$id/messages';
  static String startChat(String productId) => '/chats/product/$productId';
  
  // Payments
  static const String createPayment = '/payments/create';
  static String paymentStatus(String orderId) => '/payments/status/$orderId';
  static const String balance = '/payments/balance';
  static const String payout = '/payments/payout';
  static const String transactions = '/payments/transactions';
}
```

#### 2.3 Implement Models

**File: `lib/features/marketplace/data/models/product_model.dart`**
```dart
import 'package:json_annotation/json_annotation.dart';

part 'product_model.g.dart';

@JsonSerializable()
class ProductModel {
  final String id;
  final String name;
  final String description;
  final String category;
  final PriceModel price;
  final String condition;
  final List<String> images;
  final LocationModel location;
  final StockModel stock;
  final SellerModel seller;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String status;

  ProductModel({
    required this.id,
    required this.name,
    required this.description,
    required this.category,
    required this.price,
    required this.condition,
    required this.images,
    required this.location,
    required this.stock,
    required this.seller,
    required this.createdAt,
    required this.updatedAt,
    required this.status,
  });

  factory ProductModel.fromJson(Map<String, dynamic> json) =>
      _$ProductModelFromJson(json);

  Map<String, dynamic> toJson() => _$ProductModelToJson(this);
}

@JsonSerializable()
class PriceModel {
  final double amount;
  final String currency;
  final bool negotiable;

  PriceModel({
    required this.amount,
    required this.currency,
    required this.negotiable,
  });

  factory PriceModel.fromJson(Map<String, dynamic> json) =>
      _$PriceModelFromJson(json);

  Map<String, dynamic> toJson() => _$PriceModelToJson(this);
}

@JsonSerializable()
class LocationModel {
  final String city;
  final String? state;
  final String country;
  final bool canShip;
  final bool pickupAvailable;
  final CoordinatesModel? coordinates;

  LocationModel({
    required this.city,
    this.state,
    required this.country,
    required this.canShip,
    required this.pickupAvailable,
    this.coordinates,
  });

  factory LocationModel.fromJson(Map<String, dynamic> json) =>
      _$LocationModelFromJson(json);

  Map<String, dynamic> toJson() => _$LocationModelToJson(this);
}

@JsonSerializable()
class CoordinatesModel {
  final double latitude;
  final double longitude;

  CoordinatesModel({
    required this.latitude,
    required this.longitude,
  });

  factory CoordinatesModel.fromJson(Map<String, dynamic> json) =>
      _$CoordinatesModelFromJson(json);

  Map<String, dynamic> toJson() => _$CoordinatesModelToJson(this);
}

@JsonSerializable()
class StockModel {
  final bool available;
  final int quantity;

  StockModel({
    required this.available,
    required this.quantity,
  });

  factory StockModel.fromJson(Map<String, dynamic> json) =>
      _$StockModelFromJson(json);

  Map<String, dynamic> toJson() => _$StockModelToJson(this);
}

@JsonSerializable()
class SellerModel {
  final String id;
  final String name;
  final String? avatar;
  final double? rating;
  final int? reviewCount;

  SellerModel({
    required this.id,
    required this.name,
    this.avatar,
    this.rating,
    this.reviewCount,
  });

  factory SellerModel.fromJson(Map<String, dynamic> json) =>
      _$SellerModelFromJson(json);

  Map<String, dynamic> toJson() => _$SellerModelToJson(this);
}
```

**Generate code:**
```bash
flutter pub run build_runner build --delete-conflicting-outputs
```

---

### Phase 3: Feature Implementation (Day 6-14)

#### 3.1 Authentication UI

**File: `lib/features/auth/presentation/pages/login_page.dart`**
```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/auth_provider.dart';

class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key});

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      await ref.read(authProvider.notifier).signIn(
            email: _emailController.text.trim(),
            password: _passwordController.text,
          );

      if (mounted) {
        context.go('/');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString())),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 48),
                
                // Logo
                Icon(
                  Icons.work_outline,
                  size: 64,
                  color: Theme.of(context).primaryColor,
                ),
                const SizedBox(height: 24),
                
                // Title
                Text(
                  'Welcome Back!',
                  style: Theme.of(context).textTheme.displaySmall,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  'Sign in to continue',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: Colors.grey,
                      ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 48),
                
                // Email Field
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                    labelText: 'Email',
                    prefixIcon: Icon(Icons.email_outlined),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your email';
                    }
                    if (!value.contains('@')) {
                      return 'Please enter a valid email';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                
                // Password Field
                TextFormField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  decoration: InputDecoration(
                    labelText: 'Password',
                    prefixIcon: const Icon(Icons.lock_outline),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                      ),
                      onPressed: () {
                        setState(() => _obscurePassword = !_obscurePassword);
                      },
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your password';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 24),
                
                // Login Button
                ElevatedButton(
                  onPressed: _isLoading ? null : _handleLogin,
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Sign In'),
                ),
                const SizedBox(height: 16),
                
                // Register Link
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text("Don't have an account? "),
                    TextButton(
                      onPressed: () => context.go('/auth/register'),
                      child: const Text('Sign Up'),
                    ),
                  ],
                ),
                
                // Forgot Password
                TextButton(
                  onPressed: () {
                    // Navigate to forgot password
                  },
                  child: const Text('Forgot Password?'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
```

#### 3.2 Marketplace Implementation

**File: `lib/features/marketplace/presentation/pages/marketplace_page.dart`**
```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/PaginatedProductsNotifier.dart';
import '../widgets/product_card.dart';
import '../widgets/product_filter.dart';

class MarketplacePage extends ConsumerStatefulWidget {
  const MarketplacePage({super.key});

  @override
  ConsumerState<MarketplacePage> createState() => _MarketplacePageState();
}

class _MarketplacePageState extends ConsumerState<MarketplacePage> {
  final _searchController = TextEditingController();
  String? _selectedCategory;

  @override
  Widget build(BuildContext context) {
    final productsAsync = ref.watch(productsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Marketplace'),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: () {
              _showFilterSheet();
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search products...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          setState(() {});
                        },
                      )
                    : null,
              ),
              onChanged: (value) {
                // Trigger search
                setState(() {});
              },
            ),
          ),

          // Products Grid
          Expanded(
            child: productsAsync.when(
              data: (products) {
                if (products.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.shopping_bag_outlined,
                          size: 64,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No products found',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                      ],
                    ),
                  );
                }

                return GridView.builder(
                  padding: const EdgeInsets.all(16),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 0.75,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                  ),
                  itemCount: products.length,
                  itemBuilder: (context, index) {
                    return ProductCard(
                      product: products[index],
                      onTap: () {
                        context.push('/marketplace/product/${products[index].id}');
                      },
                    );
                  },
                );
              },
              loading: () => const Center(
                child: CircularProgressIndicator(),
              ),
              error: (error, stack) => Center(
                child: Text('Error: $error'),
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          context.push('/marketplace/create');
        },
        icon: const Icon(Icons.add),
        label: const Text('Sell'),
      ),
    );
  }

  void _showFilterSheet() {
    showModalBottomSheet(
      context: context,
      builder: (context) => ProductFilter(
        onApply: (filters) {
          // Apply filters
          Navigator.pop(context);
        },
      ),
    );
  }
}
```

---

### Phase 4: MeSomb Payment Integration (Day 15-17)

#### 4.1 Payment Service

**File: `lib/core/services/payment_service.dart`**
```dart
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../config/app_config.dart';
import '../network/api_client.dart';
import '../constants/api_endpoints.dart';

final paymentServiceProvider = Provider<PaymentService>((ref) {
  return PaymentService(ref.read(dioProvider));
});

class PaymentService {
  final Dio dio;

  PaymentService(this.dio);

  Future<PaymentResponse> createPayment({
    required String productId,
    required String phoneNumber,
    required String paymentMethod, // 'mesomb_mtn' or 'mesomb_orange'
  }) async {
    try {
      final response = await dio.post(
        ApiEndpoints.createPayment,
        data: {
          'productId': productId,
          'phoneNumber': phoneNumber,
          'paymentMethod': paymentMethod,
        },
      );

      return PaymentResponse.fromJson(response.data);
    } catch (e) {
      throw _handleError(e);
    }
  }

  Future<PaymentStatus> checkPaymentStatus(String orderId) async {
    try {
      final response = await dio.get(
        ApiEndpoints.paymentStatus(orderId),
      );

      return PaymentStatus.fromJson(response.data);
    } catch (e) {
      throw _handleError(e);
    }
  }

  Future<BalanceResponse> getBalance() async {
    try {
      final response = await dio.get(ApiEndpoints.balance);
      return BalanceResponse.fromJson(response.data);
    } catch (e) {
      throw _handleError(e);
    }
  }

  Future<PayoutResponse> requestPayout({
    required double amount,
    required String phoneNumber,
  }) async {
    try {
      final response = await dio.post(
        ApiEndpoints.payout,
        data: {
          'amount': amount,
          'phoneNumber': phoneNumber,
        },
      );

      return PayoutResponse.fromJson(response.data);
    } catch (e) {
      throw _handleError(e);
    }
  }

  String _handleError(dynamic error) {
    if (error is DioException) {
      return error.error?.toString() ?? 'Payment error occurred';
    }
    return error.toString();
  }
}

// Models
class PaymentResponse {
  final String orderId;
  final String orderNumber;
  final String status;
  final String mesombReference;

  PaymentResponse({
    required this.orderId,
    required this.orderNumber,
    required this.status,
    required this.mesombReference,
  });

  factory PaymentResponse.fromJson(Map<String, dynamic> json) {
    final data = json['data'];
    final order = data['order'];
    return PaymentResponse(
      orderId: order['_id'],
      orderNumber: order['orderNumber'],
      status: order['status'],
      mesombReference: data['mesombReference'],
    );
  }
}

class PaymentStatus {
  final String status;
  final String paymentStatus;

  PaymentStatus({
    required this.status,
    required this.paymentStatus,
  });

  factory PaymentStatus.fromJson(Map<String, dynamic> json) {
    final data = json['data'];
    return PaymentStatus(
      status: data['order']['status'],
      paymentStatus: data['paymentStatus'],
    );
  }
}

class BalanceResponse {
  final double totalEarnings;
  final double availableForWithdrawal;
  final double pendingEarnings;
  final String currency;

  BalanceResponse({
    required this.totalEarnings,
    required this.availableForWithdrawal,
    required this.pendingEarnings,
    required this.currency,
  });

  factory BalanceResponse.fromJson(Map<String, dynamic> json) {
    final balance = json['data']['balance'];
    return BalanceResponse(
      totalEarnings: balance['totalEarnings'].toDouble(),
      availableForWithdrawal: balance['availableForWithdrawal'].toDouble(),
      pendingEarnings: balance['pendingEarnings'].toDouble(),
      currency: balance['currency'],
    );
  }
}

class PayoutResponse {
  final String status;
  final String reference;

  PayoutResponse({
    required this.status,
    required this.reference,
  });

  factory PayoutResponse.fromJson(Map<String, dynamic> json) {
    final transaction = json['data']['transaction'];
    return PayoutResponse(
      status: transaction['status'],
      reference: transaction['reference'],
    );
  }
}
```

---

### Phase 5: Testing & Deployment (Day 18-21)

#### 5.1 Write Tests

**File: `test/unit/services/auth_service_test.dart`**
```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:firebase_auth/firebase_auth.dart';

void main() {
  group('AuthService Tests', () {
    test('should sign in user successfully', () async {
      // Test implementation
    });

    test('should handle invalid credentials', () async {
      // Test implementation
    });
  });
}
```

#### 5.2 Build Release

```bash
# Android
flutter build appbundle --release --obfuscate --split-debug-info=build/debug-info

# iOS
flutter build ipa --release --obfuscate --split-debug-info=build/debug-info
```

---

## ✅ Checklist

### Pre-Production
- [ ] All environment variables configured
- [ ] Firebase project setup complete
- [ ] API endpoints tested
- [ ] Error handling implemented
- [ ] Loading states added
- [ ] Form validation working
- [ ] Image upload/compression working
- [ ] Payment flow tested
- [ ] Chat functionality working

### Testing
- [ ] Unit tests written (60%+ coverage)
- [ ] Widget tests for key screens
- [ ] Integration tests for user flows
- [ ] Manual testing on devices
- [ ] Performance profiling done

### Security
- [ ] SSL pinning enabled
- [ ] Input validation everywhere
- [ ] Secure storage for tokens
- [ ] No sensitive data in logs
- [ ] ProGuard rules configured

### Deployment
- [ ] App icons created
- [ ] Splash screen added
- [ ] Privacy policy added
- [ ] Terms of service added
- [ ] App store listing prepared
- [ ] Screenshots ready

---

## 🎯 Success Metrics

After deployment, monitor:
- Crash-free rate (target: >99%)
- App load time (target: <2s)
- API response time (target: <500ms)
- User retention (D1, D7, D30)
- Payment success rate (target: >95%)

---

## 🆘 Troubleshooting

### Common Issues

**Build fails:**
```bash
flutter clean
flutter pub get
flutter pub run build_runner build --delete-conflicting-outputs
```

**Firebase not working:**
```bash
flutterfire configure
```

**Environment variables not loading:**
- Check `.env` file exists
- Verify it's in root directory
- Run `flutter clean` and rebuild

---

Ready to build! 🚀