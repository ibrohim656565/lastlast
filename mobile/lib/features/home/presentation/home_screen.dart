import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/incident_constants.dart';
import '../../../core/localization/l10n_extensions.dart';
import '../../../core/router/app_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/emergency_button.dart';
import '../../auth/presentation/auth_controller.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  String _typeLabel(BuildContext context, IncidentType type) {
    final l10n = context.l10n;
    switch (type) {
      case IncidentType.flood:
        return l10n.incidentTypeFlood;
      case IncidentType.landslide:
        return l10n.incidentTypeLandslide;
      case IncidentType.earthquake:
        return l10n.incidentTypeEarthquake;
      case IncidentType.fire:
        return l10n.incidentTypeFire;
      case IncidentType.avalanche:
        return l10n.incidentTypeAvalanche;
      case IncidentType.other:
        return l10n.incidentTypeOther;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final AuthState authState = ref.watch(authControllerProvider);
    final String name = authState.user?.name.isNotEmpty == true
        ? authState.user!.name
        : authState.user?.phone ?? '';

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.homeTitle),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () => context.push(AppRoutes.notifications),
          ),
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => context.push(AppRoutes.settings),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (name.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Text(l10n.homeGreeting(name), style: Theme.of(context).textTheme.titleMedium),
            ),
          Text(l10n.homeSelectEmergencyType, style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 12),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 1.15,
            children: IncidentType.values.map((type) {
              return EmergencyButton(
                label: _typeLabel(context, type),
                icon: type.icon,
                color: type.color,
                onTap: () => context.push(AppRoutes.reportIncidentPath(type)),
              );
            }).toList(),
          ),
          const SizedBox(height: 28),
          Text(l10n.homeQuickAccess, style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 12),
          _QuickAccessRow(),
        ],
      ),
    );
  }
}

class _QuickAccessRow extends StatelessWidget {
  const _QuickAccessRow();

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final items = [
      (l10n.homeMap, Icons.map_outlined, AppRoutes.incidentMap),
      (l10n.homeShelters, Icons.home_work_outlined, AppRoutes.shelters),
      (l10n.homeEmergencyNumbers, Icons.phone_in_talk_outlined, AppRoutes.emergencyContacts),
      (l10n.homeAlerts, Icons.campaign_outlined, AppRoutes.notifications),
    ];
    return SizedBox(
      height: 96,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: items.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          final (label, icon, route) = items[index];
          return _QuickAccessTile(label: label, icon: icon, onTap: () => context.push(route));
        },
      ),
    );
  }
}

class _QuickAccessTile extends StatelessWidget {
  const _QuickAccessTile({required this.label, required this.icon, required this.onTap});

  final String label;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.tjBlue.withValues(alpha: 0.08),
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Container(
          width: 92,
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: AppColors.tjBlue),
              const SizedBox(height: 8),
              Text(
                label,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
