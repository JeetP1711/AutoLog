import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../providers/providers.dart';
import '../../router.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_theme.dart';

/// Splash screen shown while the app initialises.
///
/// Displays the AutoLog logo with a fade+scale animation.
/// After a minimum 1.5 s delay, navigates based on onboarding and PIN state.
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

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );

    _scaleAnimation = Tween<double>(begin: 0.7, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutBack),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeIn),
    );

    _controller.forward();
    _navigate();
  }

  Future<void> _navigate() async {
    await Future.wait([
      Future<void>.delayed(const Duration(milliseconds: 1800)),
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
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: ScaleTransition(
            scale: _scaleAnimation,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // AutoLog logo image
                ClipRRect(
                  borderRadius: BorderRadius.circular(32),
                  child: Image.asset(
                    'assets/images/app_icon.png',
                    width: 160,
                    height: 160,
                    fit: BoxFit.cover,
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                Text(
                  'TRACK EVERY MILE',
                  style: AppTextStyles.labelMedium.copyWith(
                    color: AppColors.textSecondaryDark,
                    letterSpacing: 2.0,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
