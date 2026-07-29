import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_animations.dart';

class OnboardingPage extends StatefulWidget {
  const OnboardingPage({super.key});

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<OnboardingData> _pages = [
    OnboardingData(
      imagePath: 'assets/images/onboarding_1.png',
      icon: Icons.work_outline,
      title: 'Find Your Dream Job',
      description: 'Browse thousands of job opportunities from top companies',
      color: AppColors.primary,
    ),
    OnboardingData(
      imagePath: 'assets/images/onboarding_2.png',
      icon: Icons.shopping_bag,
      title: 'Buy & Sell Products',
      description: 'Trade products safely with our secure marketplace and mobile money payment',
      color: AppColors.success,
    ),
    OnboardingData(
      imagePath: 'assets/images/onboarding_3.png',
      icon: Icons.chat_bubble_outline,
      title: 'Connect & Chat',
      description: 'Chat with employers and sellers in real-time to get the best deals',
      color: AppColors.accent,
    ),
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      body: SafeArea(
        child: Column(
          children: [
            // Skip Button
            Align(
              alignment: Alignment.topRight,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
                child: TextButton(
                  onPressed: () => context.go('/auth/login'),
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.textMutedLight,
                  ),
                  child: const Text('Skip', style: TextStyle(fontWeight: FontWeight.w600)),
                ),
              ),
            ),

            // Page View
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                onPageChanged: (index) {
                  setState(() => _currentPage = index);
                },
                itemCount: _pages.length,
                itemBuilder: (context, index) {
                  return _OnboardingPageContent(data: _pages[index], isActive: index == _currentPage);
                },
              ),
            ),

            // Page Indicators
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                _pages.length,
                (index) => AnimatedContainer(
                  duration: AppAnimations.medium,
                  curve: Curves.easeInOut,
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  width: _currentPage == index ? 24 : 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: _currentPage == index
                        ? AppColors.primary
                        : AppColors.borderLight,
                    borderRadius: AppSpacing.roundedFull,
                  ),
                ),
              ),
            ),

            const SizedBox(height: AppSpacing.xxl),

            // Continue/Get Started Button
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
              child: ElevatedButton(
                onPressed: () {
                  if (_currentPage < _pages.length - 1) {
                    _pageController.nextPage(
                      duration: AppAnimations.medium,
                      curve: Curves.easeInOut,
                    );
                  } else {
                    context.go('/auth/login');
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: AppColors.white,
                  minimumSize: const Size(double.infinity, 56),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: AppSpacing.roundedLg,
                  ),
                ),
                child: Text(
                  _currentPage < _pages.length - 1 ? 'Continue' : 'Get Started',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),

            const SizedBox(height: AppSpacing.xxl),
          ],
        ),
      ),
    );
  }
}

class _OnboardingPageContent extends StatefulWidget {
  final OnboardingData data;
  final bool isActive;

  const _OnboardingPageContent({required this.data, required this.isActive});

  @override
  State<_OnboardingPageContent> createState() => _OnboardingPageContentState();
}

class _OnboardingPageContentState extends State<_OnboardingPageContent> with SingleTickerProviderStateMixin {
  late final AnimationController _animController;
  late final Animation<Offset> _titleSlide;
  late final Animation<double> _titleFade;
  late final Animation<double> _descFade;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: AppAnimations.slow,
    );

    _titleSlide = Tween<Offset>(begin: const Offset(0, 0.2), end: Offset.zero).animate(
      CurvedAnimation(
        parent: _animController,
        curve: const Interval(0.0, 0.6, curve: AppAnimations.enter),
      ),
    );

    _titleFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animController,
        curve: const Interval(0.0, 0.6, curve: Curves.easeIn),
      ),
    );

    _descFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animController,
        curve: const Interval(0.4, 1.0, curve: Curves.easeIn),
      ),
    );

    if (widget.isActive) {
      _animController.forward();
    }
  }

  @override
  void didUpdateWidget(covariant _OnboardingPageContent oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isActive && !oldWidget.isActive) {
      _animController.forward(from: 0.0);
    } else if (!widget.isActive && oldWidget.isActive) {
      _animController.reverse();
    }
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Illustration / Icon
          Expanded(
            flex: 3,
            child: Center(
              child: Image.asset(
                widget.data.imagePath,
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) => Container(
                  width: 200,
                  height: 200,
                  decoration: BoxDecoration(
                    color: widget.data.color.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    widget.data.icon,
                    size: 80,
                    color: widget.data.color,
                  ),
                ),
              ),
            ),
          ),
          
          Expanded(
            flex: 2,
            child: Column(
              children: [
                const SizedBox(height: AppSpacing.xl),
                // Title
                SlideTransition(
                  position: _titleSlide,
                  child: FadeTransition(
                    opacity: _titleFade,
                    child: Text(
                      widget.data.title,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimaryLight,
                      ) ?? const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimaryLight,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.md),

                // Description
                FadeTransition(
                  opacity: _descFade,
                  child: Text(
                    widget.data.description,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: AppColors.textSecondaryLight,
                      height: 1.5,
                    ) ?? const TextStyle(
                      fontSize: 16,
                      color: AppColors.textSecondaryLight,
                      height: 1.5,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class OnboardingData {
  final String imagePath;
  final IconData icon;
  final String title;
  final String description;
  final Color color;

  OnboardingData({
    required this.imagePath,
    required this.icon,
    required this.title,
    required this.description,
    required this.color,
  });
}