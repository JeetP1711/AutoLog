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
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 120,
            floating: false,
            pinned: true,
            elevation: 0,
            backgroundColor: cs.surface,
            flexibleSpace: FlexibleSpaceBar(
              centerTitle: false,
              titlePadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              title: Text(
                'Settings',
                style: tt.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w900,
                  letterSpacing: -1,
                  color: cs.onSurface,
                ),
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 120),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                _buildSection(
                  context,
                  title: 'Appearance',
                  children: [
                    _SettingTile(
                      icon: Icons.dark_mode_rounded,
                      title: 'Dark Mode',
                      subtitle: 'Switch between light and dark themes',
                      trailing: Switch.adaptive(
                        value: themeMode == ThemeMode.dark,
                        onChanged: (v) => ref
                            .read(themeControllerProvider.notifier)
                            .setTheme(v ? ThemeMode.dark : ThemeMode.light),
                        activeColor: cs.primary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                _buildSection(
                  context,
                  title: 'Preferences',
                  children: [
                    _SettingTile(
                      icon: Icons.currency_rupee_rounded,
                      title: 'Currency',
                      subtitle: 'Used for fuel and service costs',
                      trailing: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: cs.primary.withAlpha(20),
                          borderRadius: BorderRadius.circular(100),
                        ),
                        child: Text(
                          settings.currencySymbol,
                          style: TextStyle(color: cs.primary, fontWeight: FontWeight.bold),
                        ),
                      ),
                      onTap: () => _showCurrencyPicker(context, ref, settings.currencySymbol),
                    ),
                    const Divider(height: 1, indent: 56),
                    _SettingTile(
                      icon: Icons.speed_rounded,
                      title: 'Distance Unit',
                      subtitle: settings.distanceUnit == DistanceUnit.km ? 'Currently Kilometers' : 'Currently Miles',
                      trailing: Switch.adaptive(
                        value: settings.distanceUnit == DistanceUnit.miles,
                        onChanged: (v) => ref
                            .read(settingsProvider.notifier)
                            .setDistanceUnit(v ? DistanceUnit.miles : DistanceUnit.km),
                        activeColor: cs.primary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                _buildSection(
                  context,
                  title: 'Security',
                  children: [
                    _SettingTile(
                      icon: Icons.lock_person_rounded,
                      title: 'App Lock',
                      subtitle: settings.pinEnabled ? 'PIN protection is active' : 'Enable PIN protection',
                      trailing: Switch.adaptive(
                        value: settings.pinEnabled,
                        onChanged: (v) => v ? _showSetPinDialog(context, ref) : _disablePin(context, ref),
                        activeColor: cs.primary,
                      ),
                    ),
                    if (settings.pinEnabled) ...[
                      const Divider(height: 1, indent: 56),
                      _SettingTile(
                        icon: Icons.password_rounded,
                        title: 'Change PIN',
                        subtitle: 'Update your 4-digit security code',
                        onTap: () => _showSetPinDialog(context, ref),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 24),
                _buildSection(
                  context,
                  title: 'Data Management',
                  children: [
                    _SettingTile(
                      icon: Icons.cloud_upload_rounded,
                      title: 'Export Backup',
                      subtitle: 'Save your data to a local file',
                      onTap: () => _exportBackup(context, ref),
                    ),
                    const Divider(height: 1, indent: 56),
                    _SettingTile(
                      icon: Icons.cloud_download_rounded,
                      title: 'Import Backup',
                      subtitle: 'Restore your data from a file',
                      onTap: () => _importBackup(context, ref),
                    ),
                    const Divider(height: 1, indent: 56),
                    _SettingTile(
                      icon: Icons.delete_forever_rounded,
                      title: 'Reset All Data',
                      subtitle: 'Permanently wipe everything',
                      textColor: cs.error,
                      iconColor: cs.error,
                      onTap: () => _resetAllData(context, ref),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                _buildSection(
                  context,
                  title: 'Info',
                  children: [
                    _SettingTile(
                      icon: Icons.info_rounded,
                      title: 'About AutoLog',
                      subtitle: 'Version 1.0.4 • Crafted with love',
                      onTap: () => context.push(AppRoutes.about),
                    ),
                  ],
                ),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection(BuildContext context, {required String title, required List<Widget> children}) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 8, bottom: 12),
          child: Text(
            title,
            style: tt.labelLarge?.copyWith(
              color: cs.primary,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.5,
            ),
          ),
        ),
        Container(
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            color: cs.surface,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: cs.outline.withAlpha(15)),
          ),
          child: Column(children: children),
        ),
      ],
    );
  }

  void _showCurrencyPicker(BuildContext context, WidgetRef ref, String current) {
    const currencies = ['₹', '$', '€', '£', '¥'];
    final cs = Theme.of(context).colorScheme;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: cs.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: cs.outline.withAlpha(40),
                borderRadius: BorderRadius.circular(100),
              ),
            ),
            const SizedBox(height: 24),
            Text('Select Currency', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 24),
            ...currencies.map((c) => ListTile(
                  title: Text(c, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  trailing: c == current ? Icon(Icons.check_circle_rounded, color: cs.primary) : null,
                  onTap: () {
                    ref.read(settingsProvider.notifier).setCurrencySymbol(c);
                    Navigator.pop(ctx);
                  },
                )),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Future<void> _showSetPinDialog(BuildContext context, WidgetRef ref) async {
    final pinCtrl = TextEditingController();
    final confirmCtrl = TextEditingController();
    final formKey = GlobalKey<FormState>();
    final cs = Theme.of(context).colorScheme;

    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        title: const Text('Security PIN', style: TextStyle(fontWeight: FontWeight.w900)),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Secure your logs with a 4-digit code.', style: TextStyle(fontSize: 13)),
              const SizedBox(height: 20),
              TextFormField(
                controller: pinCtrl,
                obscureText: true,
                keyboardType: TextInputType.number,
                maxLength: 4,
                validator: Validators.pin,
                decoration: const InputDecoration(labelText: 'New PIN', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: confirmCtrl,
                obscureText: true,
                keyboardType: TextInputType.number,
                maxLength: 4,
                validator: (v) => Validators.confirmPin(v, pinCtrl.text),
                decoration: const InputDecoration(labelText: 'Confirm PIN', border: OutlineInputBorder()),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              if (formKey.currentState!.validate()) Navigator.pop(ctx, true);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: cs.primary,
              foregroundColor: cs.onPrimary,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Save PIN'),
          ),
        ],
      ),
    );

    if (result == true && context.mounted) {
      await ref.read(pinServiceProvider).setPin(pinCtrl.text.trim());
      await ref.read(settingsProvider.notifier).setPinEnabled(true);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: const Text('PIN protected active'), behavior: SnackBarBehavior.floating, backgroundColor: cs.primary),
        );
      }
    }
  }

  Future<void> _disablePin(BuildContext context, WidgetRef ref) async {
    final confirmed = await showConfirmDialog(
      context,
      title: 'Disable App Lock',
      message: 'Are you sure you want to remove PIN protection?',
      confirmLabel: 'Disable',
      isDestructive: true,
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
      );
      final path = await service.exportToJson();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Backup exported to: $path'), behavior: SnackBarBehavior.floating),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Export failed: $e'), behavior: SnackBarBehavior.floating, backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _importBackup(BuildContext context, WidgetRef ref) async {
    final result = await FilePicker.platform.pickFiles(type: FileType.custom, allowedExtensions: ['json']);
    if (result == null || result.files.single.path == null) return;

    final service = BackupService(
      vehicleRepo: ref.read(vehicleRepositoryProvider),
      fuelLogRepo: ref.read(fuelLogRepositoryProvider),
      serviceLogRepo: ref.read(serviceLogRepositoryProvider),
      expenseLogRepo: ref.read(expenseLogRepositoryProvider),
      documentRepo: ref.read(documentRepositoryProvider),
      reminderRepo: ref.read(reminderRepositoryProvider),
    );

    final backupResult = await service.importFromJson(result.files.single.path!);

    if (context.mounted) {
      if (backupResult.success) {
        ref.invalidate(vehicleProvider);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Data restored successfully'), behavior: SnackBarBehavior.floating),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Restore failed: ${backupResult.errorMessage}'), behavior: SnackBarBehavior.floating, backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _resetAllData(BuildContext context, WidgetRef ref) async {
    final confirmed = await showConfirmDialog(
      context,
      title: 'Factory Reset',
      message: 'This will permanently delete all vehicles, logs, and documents. This cannot be undone.',
      confirmLabel: 'Delete All Data',
    );
    if (confirmed == true) {
      await ref.read(settingsProvider.notifier).resetAll();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('App has been reset'), behavior: SnackBarBehavior.floating),
        );
      }
    }
  }
}

class _SettingTile extends StatelessWidget {
  const _SettingTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.trailing,
    this.onTap,
    this.textColor,
    this.iconColor,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;
  final Color? textColor;
  final Color? iconColor;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      leading: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: (iconColor ?? cs.primary).withAlpha(15),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Icon(icon, color: iconColor ?? cs.primary, size: 22),
      ),
      title: Text(title, style: TextStyle(fontWeight: FontWeight.w700, color: textColor)),
      subtitle: Text(subtitle, style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant.withAlpha(180))),
      trailing: trailing ?? (onTap != null ? const Icon(Icons.chevron_right_rounded, size: 20) : null),
      onTap: onTap,
    );
  }
}
