import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../models/models.dart';
import '../../providers/pin_provider.dart';
import '../../providers/settings_provider.dart';
import '../../providers/vehicle_provider.dart';
import '../../router.dart';
import '../../services/backup_service.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_theme.dart';
import '../../theme/theme_controller.dart';
import '../../utils/validators.dart';
import '../../widgets/confirm_dialog.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final themeMode = ref.watch(themeControllerProvider);

    return Scaffold(
            appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        children: [
          // ── Appearance ───────────────────────────────────────────────────
          _SectionHeader(title: 'Appearance'),
          SwitchListTile(
            secondary: const Icon(Icons.dark_mode_rounded,
                color: AppColors.primaryBlue),
            title: const Text('Dark Mode'),
            value: themeMode == ThemeMode.dark,
            onChanged: (v) => ref
                .read(themeControllerProvider.notifier)
                .setTheme(v ? ThemeMode.dark : ThemeMode.light),
            activeColor: AppColors.primaryBlue,
          ),

          // ── Units & Currency ─────────────────────────────────────────────
          _SectionHeader(title: 'Units & Currency'),
          ListTile(
            leading: const Icon(Icons.attach_money_rounded,
                color: AppColors.primaryBlue),
            title: const Text('Currency'),
            trailing: Text(
              settings.currencySymbol,
              style: AppTextStyles.titleMedium
                  .copyWith(color: AppColors.primaryBlue),
            ),
            onTap: () => _showCurrencyPicker(context, ref, settings.currencySymbol),
          ),
          SwitchListTile(
            secondary: const Icon(Icons.speed_rounded,
                color: AppColors.primaryBlue),
            title: const Text('Use Miles'),
            subtitle: const Text('Toggle between km and miles'),
            value: settings.distanceUnit == DistanceUnit.miles,
            onChanged: (v) => ref
                .read(settingsProvider.notifier)
                .setDistanceUnit(
                    v ? DistanceUnit.miles : DistanceUnit.km),
            activeColor: AppColors.primaryBlue,
          ),

          // ── Security ─────────────────────────────────────────────────────
          _SectionHeader(title: 'Security'),
          SwitchListTile(
            secondary: const Icon(Icons.lock_rounded,
                color: AppColors.primaryBlue),
            title: const Text('App Lock (PIN)'),
            subtitle: Text(settings.pinEnabled ? 'PIN is enabled' : 'PIN is disabled'),
            value: settings.pinEnabled,
            onChanged: (v) => v
                ? _showSetPinDialog(context, ref)
                : _disablePin(context, ref),
            activeColor: AppColors.primaryBlue,
          ),
          if (settings.pinEnabled)
            ListTile(
              leading: const Icon(Icons.edit_rounded,
                  color: AppColors.primaryBlue),
              title: const Text('Change PIN'),
              onTap: () => _showSetPinDialog(context, ref),
            ),

          // ── Backup ───────────────────────────────────────────────────────
          _SectionHeader(title: 'Backup & Restore'),
          ListTile(
            leading: const Icon(Icons.upload_rounded,
                color: AppColors.success),
            title: const Text('Export Backup'),
            subtitle: const Text('Save all data as JSON file'),
            onTap: () => _exportBackup(context, ref),
          ),
          ListTile(
            leading: const Icon(Icons.download_rounded,
                color: AppColors.info),
            title: const Text('Import Backup'),
            subtitle: const Text('Restore data from JSON file'),
            onTap: () => _importBackup(context, ref),
          ),

          // ── Danger zone ──────────────────────────────────────────────────
          _SectionHeader(title: 'Danger Zone'),
          ListTile(
            leading: const Icon(Icons.delete_forever_rounded,
                color: AppColors.error),
            title: const Text('Reset All Data',
                style: TextStyle(color: AppColors.error)),
            subtitle: const Text('Permanently delete all vehicles and logs'),
            onTap: () => _resetAllData(context, ref),
          ),

          // ── About ────────────────────────────────────────────────────────
          _SectionHeader(title: 'About'),
          ListTile(
            leading: const Icon(Icons.info_outline_rounded,
                color: AppColors.primaryBlue),
            title: const Text('About AutoLog'),
            trailing: const Icon(Icons.chevron_right_rounded,
                color: AppColors.textSecondaryDark),
            onTap: () => context.push(AppRoutes.about),
          ),
        ],
      ),
    );
  }

  void _showCurrencyPicker(
      BuildContext context, WidgetRef ref, String current) {
    const currencies = ['₹', '\$', '€', '£', '¥'];
    showModalBottomSheet(
      context: context,
      builder: (ctx) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Text('Select Currency',
                style: AppTextStyles.titleMedium
                    .copyWith(color: AppColors.textPrimaryDark)),
          ),
          ...currencies.map((c) => ListTile(
                title: Text(c),
                trailing: c == current
                    ? const Icon(Icons.check_rounded,
                        color: AppColors.primaryBlue)
                    : null,
                onTap: () {
                  ref
                      .read(settingsProvider.notifier)
                      .setCurrencySymbol(c);
                  Navigator.pop(ctx);
                },
              )),
          const SizedBox(height: AppSpacing.md),
        ],
      ),
    );
  }

  Future<void> _showSetPinDialog(BuildContext context, WidgetRef ref) async {
    final pinCtrl = TextEditingController();
    final confirmCtrl = TextEditingController();
    final formKey = GlobalKey<FormState>();

    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Set PIN'),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: pinCtrl,
                obscureText: true,
                keyboardType: TextInputType.number,
                maxLength: 4,
                validator: Validators.pin,
                decoration: const InputDecoration(labelText: 'New PIN (4 digits)'),
              ),
              const SizedBox(height: AppSpacing.md),
              TextFormField(
                controller: confirmCtrl,
                obscureText: true,
                keyboardType: TextInputType.number,
                maxLength: 4,
                validator: (v) => Validators.confirmPin(v, pinCtrl.text),
                decoration: const InputDecoration(labelText: 'Confirm PIN'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              if (formKey.currentState!.validate()) {
                Navigator.pop(ctx, true);
              }
            },
            child: const Text('Set PIN'),
          ),
        ],
      ),
    );

    if (result == true && context.mounted) {
      await ref.read(pinServiceProvider).setPin(pinCtrl.text.trim());
      await ref.read(settingsProvider.notifier).setPinEnabled(true);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('PIN set successfully'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _disablePin(BuildContext context, WidgetRef ref) async {
    final confirmed = await showConfirmDialog(
      context,
      title: 'Disable PIN',
      message: 'Remove the PIN lock?',
      confirmLabel: 'Disable',
      isDestructive: false,
    );
    if (confirmed == true) {
      await ref.read(pinServiceProvider).clearPin();
      await ref.read(settingsProvider.notifier).setPinEnabled(false);
    }
  }

  Future<void> _exportBackup(BuildContext context, WidgetRef ref) async {
    try {
      final service = BackupService(
        vehicleRepo: ref.read(vehicleRepositoryProvider),
        fuelLogRepo: ref.read(fuelLogRepositoryProvider),
        serviceLogRepo: ref.read(serviceLogRepositoryProvider),
        expenseLogRepo: ref.read(expenseLogRepositoryProvider),
        documentRepo: ref.read(documentRepositoryProvider),
        reminderRepo: ref.read(reminderRepositoryProvider),
      );      final path = await service.exportToJson();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Backup saved to $path'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Export failed: $e'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _importBackup(BuildContext context, WidgetRef ref) async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['json'],
    );
    if (result == null || result.files.single.path == null) return;

    final service = BackupService(
      vehicleRepo: ref.read(vehicleRepositoryProvider),
      fuelLogRepo: ref.read(fuelLogRepositoryProvider),
      serviceLogRepo: ref.read(serviceLogRepositoryProvider),
      expenseLogRepo: ref.read(expenseLogRepositoryProvider),
      documentRepo: ref.read(documentRepositoryProvider),
      reminderRepo: ref.read(reminderRepositoryProvider),
    );

    final backupResult =
        await service.importFromJson(result.files.single.path!);

    if (context.mounted) {
      if (backupResult.success) {
        ref.invalidate(vehicleProvider);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Backup restored successfully'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Import failed: ${backupResult.errorMessage}'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _resetAllData(BuildContext context, WidgetRef ref) async {
    final confirmed = await showConfirmDialog(
      context,
      title: 'Reset All Data',
      message:
          'This will permanently delete ALL vehicles, logs, documents, and reminders. This cannot be undone.',
      confirmLabel: 'Reset Everything',
    );
    if (confirmed == true) {
      await ref.read(settingsProvider.notifier).resetAll();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('All data has been reset'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title});
  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
          AppSpacing.md, AppSpacing.lg, AppSpacing.md, AppSpacing.xs),
      child: Text(
        title.toUpperCase(),
        style: AppTextStyles.labelSmall.copyWith(
          color: AppColors.textSecondaryDark,
          letterSpacing: 1.2,
        ),
      ),
    );
  }
}
