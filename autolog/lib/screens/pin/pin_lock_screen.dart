import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../providers/pin_provider.dart';
import '../../router.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_theme.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Constants
// ─────────────────────────────────────────────────────────────────────────────

const _kMaxAttempts = 5;
const _kLockoutSeconds = 60;
const _kPinLength = 4;

// ─────────────────────────────────────────────────────────────────────────────
// PinLockScreen
// ─────────────────────────────────────────────────────────────────────────────

/// Full-screen PIN entry gate shown when the user has enabled PIN protection.
///
/// Features:
/// - 4 dot indicators (filled / empty) that track entry progress
/// - Numeric keypad (1–9, 0, backspace)
/// - Auto-verifies when the 4th digit is entered
/// - Shakes dots and shows "Incorrect PIN" on a wrong entry
/// - Locks input for 60 s after 5 consecutive wrong attempts
/// - Navigates to `/home` on success
class PinLockScreen extends ConsumerStatefulWidget {
  const PinLockScreen({super.key});

  @override
  ConsumerState<PinLockScreen> createState() => _PinLockScreenState();
}

class _PinLockScreenState extends ConsumerState<PinLockScreen>
    with SingleTickerProviderStateMixin {
  // ── State ──────────────────────────────────────────────────────────────────

  final List<int> _digits = [];
  int _attempts = 0;
  bool _locked = false;
  int _lockoutRemaining = 0;
  String? _errorMessage;

  Timer? _lockoutTimer;

  // ── Animation ──────────────────────────────────────────────────────────────

  late final AnimationController _shakeController;
  late final Animation<double> _shakeAnimation;

  // ── Lifecycle ──────────────────────────────────────────────────────────────

  @override
  void initState() {
    super.initState();

    _shakeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );

    _shakeAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0, end: -12), weight: 1),
      TweenSequenceItem(tween: Tween(begin: -12, end: 12), weight: 2),
      TweenSequenceItem(tween: Tween(begin: 12, end: -8), weight: 2),
      TweenSequenceItem(tween: Tween(begin: -8, end: 8), weight: 2),
      TweenSequenceItem(tween: Tween(begin: 8, end: 0), weight: 1),
    ]).animate(CurvedAnimation(
      parent: _shakeController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _shakeController.dispose();
    _lockoutTimer?.cancel();
    super.dispose();
  }

  // ── Input handling ─────────────────────────────────────────────────────────

  void _onDigit(int digit) {
    if (_locked || _digits.length >= _kPinLength) return;

    HapticFeedback.lightImpact();

    setState(() {
      _digits.add(digit);
      _errorMessage = null;
    });

    if (_digits.length == _kPinLength) {
      // Small delay so the last dot fills before verification feedback
      Future.delayed(const Duration(milliseconds: 80), _verify);
    }
  }

  void _onBackspace() {
    if (_locked || _digits.isEmpty) return;

    HapticFeedback.selectionClick();

    setState(() {
      _digits.removeLast();
      _errorMessage = null;
    });
  }

  void _verify() {
    final pin = _digits.map((d) => d.toString()).join();
    final pinService = ref.read(pinServiceProvider);
    final correct = pinService.verifyPin(pin);

    if (correct) {
      HapticFeedback.mediumImpact();
      context.go(AppRoutes.home);
    } else {
      HapticFeedback.heavyImpact();
      _attempts++;

      if (_attempts >= _kMaxAttempts) {
        _startLockout();
      } else {
        setState(() {
          _errorMessage = 'Incorrect PIN';
          _digits.clear();
        });
        _shakeController.forward(from: 0);
      }
    }
  }

  void _startLockout() {
    setState(() {
      _locked = true;
      _lockoutRemaining = _kLockoutSeconds;
      _digits.clear();
      _errorMessage = null;
    });

    _shakeController.forward(from: 0);

    _lockoutTimer?.cancel();
    _lockoutTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      setState(() {
        _lockoutRemaining--;
      });
      if (_lockoutRemaining <= 0) {
        timer.cancel();
        setState(() {
          _locked = false;
          _attempts = 0;
          _errorMessage = null;
        });
      }
    });
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
            body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: AppSpacing.xxl),

            // ── Header ───────────────────────────────────────────────────────
            _buildHeader(),

            const SizedBox(height: AppSpacing.xxl),

            // ── PIN dots ─────────────────────────────────────────────────────
            _buildPinDots(),

            const SizedBox(height: AppSpacing.md),

            // ── Status message ───────────────────────────────────────────────
            _buildStatusMessage(),

            const Spacer(),

            // ── Keypad ───────────────────────────────────────────────────────
            _buildKeypad(),

            const SizedBox(height: AppSpacing.xl),
          ],
        ),
      ),
    );
  }

  // ── Sub-widgets ────────────────────────────────────────────────────────────

  Widget _buildHeader() {
    return Column(
      children: [
        // Lock icon
        Container(
          width: 72,
          height: 72,
          decoration: BoxDecoration(
            color: AppColors.darkSurface,
            shape: BoxShape.circle,
            border: Border.all(
              color: AppColors.darkDivider,
              width: 1.5,
            ),
          ),
          child: const Icon(
            Icons.lock_rounded,
            size: 36,
            color: AppColors.primaryBlue,
          ),
        ),

        const SizedBox(height: AppSpacing.md),

        // App title
        const Text(
          'AutoLog',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimaryDark,
            letterSpacing: 0.5,
          ),
        ),

        const SizedBox(height: AppSpacing.xs),

        Text(
          _locked ? 'Too many attempts' : 'Enter your PIN',
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w400,
            color: AppColors.textSecondaryDark,
          ),
        ),
      ],
    );
  }

  Widget _buildPinDots() {
    return AnimatedBuilder(
      animation: _shakeAnimation,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(_shakeAnimation.value, 0),
          child: child,
        );
      },
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(_kPinLength, (index) {
          final filled = index < _digits.length;
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              width: 18,
              height: 18,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: filled ? AppColors.primaryBlue : Colors.transparent,
                border: Border.all(
                  color: filled
                      ? AppColors.primaryBlue
                      : AppColors.textSecondaryDark,
                  width: 2,
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildStatusMessage() {
    if (_locked) {
      return Text(
        'Locked for ${_lockoutRemaining}s',
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: AppColors.error,
        ),
      );
    }

    if (_errorMessage != null) {
      return Text(
        _errorMessage!,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: AppColors.error,
        ),
      );
    }

    // Reserve space so layout doesn't jump
    return const SizedBox(height: 20);
  }

  Widget _buildKeypad() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
      child: Column(
        children: [
          // Row 1: 1 2 3
          _buildKeyRow([1, 2, 3]),
          const SizedBox(height: AppSpacing.md),
          // Row 2: 4 5 6
          _buildKeyRow([4, 5, 6]),
          const SizedBox(height: AppSpacing.md),
          // Row 3: 7 8 9
          _buildKeyRow([7, 8, 9]),
          const SizedBox(height: AppSpacing.md),
          // Row 4: empty, 0, backspace
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              // Empty placeholder
              const SizedBox(width: 72, height: 72),
              _buildDigitKey(0),
              _buildBackspaceKey(),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildKeyRow(List<int> digits) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: digits.map(_buildDigitKey).toList(),
    );
  }

  Widget _buildDigitKey(int digit) {
    final enabled = !_locked;

    return _KeypadButton(
      onTap: enabled ? () => _onDigit(digit) : null,
      child: Text(
        digit.toString(),
        style: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.w500,
          color: enabled
              ? AppColors.textPrimaryDark
              : AppColors.textDisabledDark,
        ),
      ),
    );
  }

  Widget _buildBackspaceKey() {
    final enabled = !_locked && _digits.isNotEmpty;

    return _KeypadButton(
      onTap: enabled ? _onBackspace : null,
      child: Icon(
        Icons.backspace_outlined,
        size: 24,
        color: enabled
            ? AppColors.textPrimaryDark
            : AppColors.textDisabledDark,
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _KeypadButton
// ─────────────────────────────────────────────────────────────────────────────

/// A circular tappable button used in the PIN keypad.
class _KeypadButton extends StatelessWidget {
  const _KeypadButton({
    required this.child,
    this.onTap,
  });

  final Widget child;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(36),
        splashColor: AppColors.primaryBlue.withAlpha(40),
        highlightColor: AppColors.primaryBlue.withAlpha(20),
        child: Container(
          width: 72,
          height: 72,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.darkSurface,
            border: Border.all(
              color: AppColors.darkDivider,
              width: 1,
            ),
          ),
          alignment: Alignment.center,
          child: child,
        ),
      ),
    );
  }
}
