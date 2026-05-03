import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../providers/providers.dart';
import '../../router.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_theme.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Data model for a single onboarding slide
// ─────────────────────────────────────────────────────────────────────────────

class _OnboardingSlide {
  const _OnboardingSlide({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;
}

// ─────────────────────────────────────────────────────────────────────────────
// Slide definitions
// ─────────────────────────────────────────────────────────────────────────────

const List<_OnboardingSlide> _slides = [
  _OnboardingSlide(
    icon: Icons.directions_car_rounded,
    title: 'Manage All Vehicles',
    subtitle:
        'Track cars, bikes, scooters, trucks — all in one place',
  ),
  _OnboardingSlide(
    icon: Icons.account_balance_wallet_rounded,
    title: 'Track Expenses',
    subtitle:
        'Monitor fuel costs, service bills, and every rupee spent',
  ),
  _OnboardingSlide(
    icon: Icons.notifications_active_rounded,
    title: 'Never Miss Service Dates',
    subtitle:
        'Get reminders for insurance, PUC, and service due dates',
  ),
];

// ─────────────────────────────────────────────────────────────────────────────
// OnboardingScreen
// ─────────────────────────────────────────────────────────────────────────────

/// Full-screen onboarding flow shown on first launch.
///
/// Three slides with a [PageView], dot indicators, Skip / Next / Get Started
/// buttons. On completion, marks onboarding as done and navigates to `/home`.
class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen>
    with SingleTickerProviderStateMixin {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  // Per-page animation controller — rebuilds on page change.
  late AnimationController _slideAnimController;
  late Animation<double> _iconFade;
  late Animation<double> _iconScale;
  late Animation<double> _textFade;
  late Animation<Offset> _textSlide;

  @override
  void initState() {
    super.initState();
    _slideAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _buildAnimations();
    _slideAnimController.forward();
  }

  void _buildAnimations() {
    _iconFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _slideAnimController,
        curve: const Interval(0.0, 0.6, curve: Curves.easeIn),
      ),
    );
    _iconScale = Tween<double>(begin: 0.7, end: 1.0).animate(
      CurvedAnimation(
        parent: _slideAnimController,
        curve: const Interval(0.0, 0.7, curve: Curves.easeOutBack),
      ),
    );
    _textFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _slideAnimController,
        curve: const Interval(0.3, 1.0, curve: Curves.easeIn),
      ),
    );
    _textSlide = Tween<Offset>(
      begin: const Offset(0, 0.15),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _slideAnimController,
        curve: const Interval(0.3, 1.0, curve: Curves.easeOut),
      ),
    );
  }

  Future<void> _goToPage(int page) async {
    await _pageController.animateToPage(
      page,
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeInOut,
    );
  }

  Future<void> _completeOnboarding() async {
    await ref
        .read(settingsProvider.notifier)
        .setOnboardingCompleted(true);
    if (mounted) {
      context.go(AppRoutes.home);
    }
  }

  void _onPageChanged(int page) {
    setState(() => _currentPage = page);
    _slideAnimController.reset();
    _slideAnimController.forward();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _slideAnimController.dispose();
    super.dispose();
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final isLastPage = _currentPage == _slides.length - 1;

    return Scaffold(
            body: SafeArea(
        child: Column(
          children: [
            // ── Skip button ─────────────────────────────────────────────────
            Align(
              alignment: Alignment.topRight,
              child: Padding(
                padding: const EdgeInsets.only(
                  top: AppSpacing.sm,
                  right: AppSpacing.md,
                ),
                child: TextButton(
                  onPressed: _completeOnboarding,
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.textSecondaryDark,
                  ),
                  child: Text(
                    'Skip',
                    style: AppTextStyles.labelLarge.copyWith(
                      color: AppColors.textSecondaryDark,
                    ),
                  ),
                ),
              ),
            ),

            // ── Page view ───────────────────────────────────────────────────
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                onPageChanged: _onPageChanged,
                itemCount: _slides.length,
                itemBuilder: (context, index) {
                  return _SlidePage(
                    slide: _slides[index],
                    iconFade: _iconFade,
                    iconScale: _iconScale,
                    textFade: _textFade,
                    textSlide: _textSlide,
                  );
                },
              ),
            ),

            // ── Dot indicators ──────────────────────────────────────────────
            _DotIndicator(
              count: _slides.length,
              current: _currentPage,
            ),

            const SizedBox(height: AppSpacing.xl),

            // ── Action button ───────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
              child: SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: isLastPage
                      ? _completeOnboarding
                      : () => _goToPage(_currentPage + 1),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryBlue,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: Text(
                    isLastPage ? 'Get Started' : 'Next',
                    style: AppTextStyles.labelLarge.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
            ),

            const SizedBox(height: AppSpacing.xl),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _SlidePage — content for a single onboarding page
// ─────────────────────────────────────────────────────────────────────────────

class _SlidePage extends StatelessWidget {
  const _SlidePage({
    required this.slide,
    required this.iconFade,
    required this.iconScale,
    required this.textFade,
    required this.textSlide,
  });

  final _OnboardingSlide slide;
  final Animation<double> iconFade;
  final Animation<double> iconScale;
  final Animation<double> textFade;
  final Animation<Offset> textSlide;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Icon in a rounded container
          FadeTransition(
            opacity: iconFade,
            child: ScaleTransition(
              scale: iconScale,
              child: Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: AppColors.primaryBlue.withAlpha(26),
                  borderRadius: BorderRadius.circular(32),
                  border: Border.all(
                    color: AppColors.primaryBlue.withAlpha(77),
                    width: 1.5,
                  ),
                ),
                child: Icon(
                  slide.icon,
                  size: 60,
                  color: AppColors.primaryBlue,
                ),
              ),
            ),
          ),

          const SizedBox(height: AppSpacing.xxl),

          // Title + subtitle
          FadeTransition(
            opacity: textFade,
            child: SlideTransition(
              position: textSlide,
              child: Column(
                children: [
                  Text(
                    slide.title,
                    textAlign: TextAlign.center,
                    style: AppTextStyles.headlineSmall.copyWith(
                      color: AppColors.textPrimaryDark,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    slide.subtitle,
                    textAlign: TextAlign.center,
                    style: AppTextStyles.bodyLarge.copyWith(
                      color: AppColors.textSecondaryDark,
                      height: 1.6,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _DotIndicator — page progress dots
// ─────────────────────────────────────────────────────────────────────────────

class _DotIndicator extends StatelessWidget {
  const _DotIndicator({required this.count, required this.current});

  final int count;
  final int current;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(count, (index) {
        final isActive = index == current;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeInOut,
          margin: const EdgeInsets.symmetric(horizontal: 4),
          width: isActive ? 24 : 8,
          height: 8,
          decoration: BoxDecoration(
            color: isActive
                ? AppColors.primaryBlue
                : AppColors.primaryBlue.withAlpha(77),
            borderRadius: BorderRadius.circular(4),
          ),
        );
      }),
    );
  }
}
