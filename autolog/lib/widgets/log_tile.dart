import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_theme.dart';

/// A list tile for displaying a log entry (fuel / service / expense / document).
class LogTile extends StatelessWidget {
  const LogTile({
    super.key,
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.date,
    this.amount,
    this.currencySymbol,
    this.onTap,
    this.onDelete,
  });

  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final String date;
  final String? amount;
  final String? currencySymbol;
  final VoidCallback? onTap;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    final tile = Card(
      margin: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.xs,
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Row(
            children: [
              // Icon
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: iconColor.withAlpha(30),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, size: 22, color: iconColor),
              ),
              const SizedBox(width: AppSpacing.md),
              // Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: AppTextStyles.titleSmall.copyWith(
                        color: AppColors.textPrimaryDark,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.textSecondaryDark,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              // Right side: amount + date
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  if (amount != null)
                    Text(
                      '${currencySymbol ?? '₹'}$amount',
                      style: AppTextStyles.titleSmall.copyWith(
                        color: AppColors.primaryBlue,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  Text(
                    date,
                    style: AppTextStyles.labelSmall.copyWith(
                      color: AppColors.textSecondaryDark,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );

    if (onDelete == null) return tile;

    return Dismissible(
      key: ValueKey(title + date),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: AppSpacing.lg),
        margin: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.xs,
        ),
        decoration: BoxDecoration(
          color: AppColors.error.withAlpha(200),
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Icon(Icons.delete_rounded, color: Colors.white, size: 28),
      ),
      confirmDismiss: (_) async => true,
      onDismissed: (_) => onDelete!(),
      child: tile,
    );
  }
}
