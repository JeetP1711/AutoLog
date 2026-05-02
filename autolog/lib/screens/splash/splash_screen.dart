import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../providers/providers.dart';
import '../../router.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_theme.dart';

/// Splash screen shown while the app initialises.
///
/// Displays the AutoLog logo with a fade+scale animation and "Track Every Mile"
/// tagline. After a minimum 1.5 s delay (max 3 s), navigates to the
/// appropriate screen based on onboarding and PIN settings.
class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fadeAnimation;
  late final Animation<double> _scaleAnimation;
  late final Animation<double> _textFadeAnimation;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    _scaleAnimation = Tween<double>(begin: 0.6, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.7, curve: Curves.easeOutBack),
      ),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.6, curve: Curves.easeIn),
      ),
    );

    _textFadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.4, 1.0, curve: Curves.easeIn),
      ),
    );

    _controller.forward();
    _navigate();
  }

  Future<void> _navigate() async {
    // Enforce minimum 1.5 s display time, maximum 3 s.
    await Future.wait([
      Future<void>.delayed(const Duration(milliseconds: 1500)),
      _controller.forward(),
    ]);

    if (!mounted) return;

    final settings = ref.read(settingsProvider);

    if (!settings.onboardingCompleted) {
      context.go(AppRoutes.onboarding);
    } else if (settings.pinEnabled) {
      context.go(AppRoutes.pin);
    } else {
      context.go(AppRoutes.home);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.darkBackground,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // ── Logo ──────────────────────────────────────────────────────────
            FadeTransition(
              opacity: _fadeAnimation,
              child: ScaleTransition(
                scale: _scaleAnimation,
                child: Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    color: AppColors.primaryBlue.withAlpha(26),
                    borderRadius: BorderRadius.circular(28),
                    border: Border.all(
                      color: AppColors.primaryBlue.withAlpha(77),
                      width: 1.5,
                    ),
                  ),
                  child: const Icon(
                    Icons.directions_car_rounded,
                    size: 52,
                    color: AppColors.primaryBlue,
                  ),
                ),
              ),
            ),

            const SizedBox(height: AppSpacing.lg),

            // ── App name ──────────────────────────────────────────────────────
            FadeTransition(
              opacity: _textFadeAnimation,
              child: Text(
                'AutoLog',
                style: AppTextStyles.headlineLarge.copyWith(
                  color: AppColors.textPrimaryDark,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.2,
                ),
              ),
            ),

            const SizedBox(height: AppSpacing.sm),

            // ── Tagline ───────────────────────────────────────────────────────
            FadeTransition(
              opacity: _textFadeAnimation,
              child: Text(
                'Track Every Mile',
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.textSecondaryDark,
                  letterSpacing: 0.8,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
