import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/constants/incident_constants.dart';
import '../../../core/localization/l10n_extensions.dart';
import '../../../core/theme/app_colors.dart';
import '../domain/emergency_contact.dart';
import 'emergency_contacts_controller.dart';

class EmergencyContactsScreen extends ConsumerWidget {
  const EmergencyContactsScreen({super.key});

  String _categoryLabel(BuildContext context, EmergencyContactCategory category) {
    final l10n = context.l10n;
    switch (category) {
      case EmergencyContactCategory.police:
        return l10n.contactsCategoryPolice;
      case EmergencyContactCategory.ambulance:
        return l10n.contactsCategoryAmbulance;
      case EmergencyContactCategory.fire:
        return l10n.contactsCategoryFire;
      case EmergencyContactCategory.gas:
        return l10n.contactsCategoryGas;
      case EmergencyContactCategory.rescueService:
        return l10n.contactsCategoryRescueService;
      case EmergencyContactCategory.other:
        return l10n.contactsCategoryOther;
    }
  }

  Future<void> _call(String phone) async {
    final Uri uri = Uri(scheme: 'tel', path: phone);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final EmergencyContactsState state = ref.watch(emergencyContactsControllerProvider);

    final Map<EmergencyContactCategory, List<EmergencyContact>> grouped = {};
    for (final EmergencyContact contact in state.contacts) {
      grouped.putIfAbsent(contact.category, () => []).add(contact);
    }

    return Scaffold(
      appBar: AppBar(title: Text(l10n.contactsTitle)),
      body: state.isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                if (state.isFallback)
                  Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.warning.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.warning.withValues(alpha: 0.4)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.info_outline, color: AppColors.warning),
                        const SizedBox(width: 8),
                        Expanded(child: Text(l10n.contactsFallbackNotice)),
                      ],
                    ),
                  ),
                for (final MapEntry<EmergencyContactCategory, List<EmergencyContact>> entry
                    in grouped.entries) ...[
                  Padding(
                    padding: const EdgeInsets.only(top: 8, bottom: 4),
                    child: Text(
                      _categoryLabel(context, entry.key),
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ),
                  ...entry.value.map((contact) => _ContactTile(
                        contact: contact,
                        onCall: () => _call(contact.phone),
                        callLabel: l10n.actionCall,
                      )),
                ],
              ],
            ),
    );
  }
}

class _ContactTile extends StatelessWidget {
  const _ContactTile({required this.contact, required this.onCall, required this.callLabel});

  final EmergencyContact contact;
  final VoidCallback onCall;
  final String callLabel;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: CircleAvatar(
          backgroundColor: AppColors.tjRed.withValues(alpha: 0.15),
          child: Icon(contact.category.icon, color: AppColors.tjRed),
        ),
        title: Text(contact.name, style: Theme.of(context).textTheme.titleMedium),
        subtitle: Text(contact.phone, style: Theme.of(context).textTheme.bodyLarge),
        trailing: FilledButton.icon(
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.tjRed,
            minimumSize: const Size(0, 48),
          ),
          onPressed: onCall,
          icon: const Icon(Icons.call, size: 18),
          label: Text(callLabel),
        ),
      ),
    );
  }
}
