import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/incident_constants.dart';
import '../../../core/localization/l10n_extensions.dart';
import '../../../core/localization/locale_provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/theme_provider.dart';
import '../../auth/presentation/auth_controller.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final AuthState authState = ref.watch(authControllerProvider);
    final Locale locale = ref.watch(localeControllerProvider);
    final ThemeMode themeMode = ref.watch(themeModeControllerProvider);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.settingsTitle)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(l10n.settingsProfile, style: Theme.of(context).textTheme.titleMedium),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.person_outline),
                  title: Text(l10n.settingsName),
                  subtitle: Text(authState.user?.name.isNotEmpty == true
                      ? authState.user!.name
                      : '—'),
                  trailing: const Icon(Icons.edit, size: 18),
                  onTap: () => _editName(context, ref, authState.user?.name ?? ''),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.phone_outlined),
                  title: Text(l10n.settingsPhone),
                  subtitle: Text(authState.user?.phone ?? '—'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Text(l10n.settingsLanguage, style: Theme.of(context).textTheme.titleMedium),
          Card(
            child: Column(
              children: AppLanguage.values.map((language) {
                return RadioListTile<String>(
                  title: Text(language.nativeLabel),
                  value: language.wireValue,
                  groupValue: locale.languageCode,
                  onChanged: (_) =>
                      ref.read(localeControllerProvider.notifier).setLanguage(language),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 24),
          Text(l10n.settingsTheme, style: Theme.of(context).textTheme.titleMedium),
          Card(
            child: Column(
              children: [
                RadioListTile<ThemeMode>(
                  title: Text(l10n.settingsThemeSystem),
                  value: ThemeMode.system,
                  groupValue: themeMode,
                  onChanged: (mode) =>
                      ref.read(themeModeControllerProvider.notifier).setThemeMode(mode!),
                ),
                RadioListTile<ThemeMode>(
                  title: Text(l10n.settingsThemeLight),
                  value: ThemeMode.light,
                  groupValue: themeMode,
                  onChanged: (mode) =>
                      ref.read(themeModeControllerProvider.notifier).setThemeMode(mode!),
                ),
                RadioListTile<ThemeMode>(
                  title: Text(l10n.settingsThemeDark),
                  value: ThemeMode.dark,
                  groupValue: themeMode,
                  onChanged: (mode) =>
                      ref.read(themeModeControllerProvider.notifier).setThemeMode(mode!),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
          OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.tjRed,
              side: const BorderSide(color: AppColors.tjRed),
            ),
            icon: const Icon(Icons.logout),
            label: Text(l10n.settingsSignOut),
            onPressed: () => _confirmSignOut(context, ref),
          ),
        ],
      ),
    );
  }

  Future<void> _editName(BuildContext context, WidgetRef ref, String currentName) async {
    final l10n = context.l10n;
    final TextEditingController controller = TextEditingController(text: currentName);
    final String? newName = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.settingsName),
        content: TextField(controller: controller, autofocus: true),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(l10n.actionCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(controller.text.trim()),
            child: Text(l10n.actionSave),
          ),
        ],
      ),
    );
    if (newName == null || newName.isEmpty) return;
    final user = await ref.read(authRepositoryProvider).updateMe(name: newName);
    ref.read(authControllerProvider.notifier).setUser(user);
  }

  Future<void> _confirmSignOut(BuildContext context, WidgetRef ref) async {
    final l10n = context.l10n;
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.settingsSignOut),
        content: Text(l10n.settingsSignOutConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(l10n.actionCancel),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.tjRed),
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(l10n.settingsSignOut),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await ref.read(authControllerProvider.notifier).signOut();
    }
  }
}
