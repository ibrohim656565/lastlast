import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';

import '../../../core/constants/incident_constants.dart';
import '../../../core/localization/l10n_extensions.dart';
import '../../../core/providers/core_providers.dart';
import '../../../core/widgets/error_retry_view.dart';
import '../../../core/widgets/status_badge.dart';
import '../../report_incident/domain/incident.dart';
import 'incident_map_controller.dart';

const LatLng _dushanbeCenter = LatLng(38.5598, 68.7870);

class IncidentMapScreen extends ConsumerStatefulWidget {
  const IncidentMapScreen({super.key});

  @override
  ConsumerState<IncidentMapScreen> createState() => _IncidentMapScreenState();
}

class _IncidentMapScreenState extends ConsumerState<IncidentMapScreen> {
  final MapController _mapController = MapController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadAroundUser());
  }

  Future<void> _loadAroundUser() async {
    final position = await ref.read(locationServiceProvider).getCurrentPosition();
    if (!mounted) return;
    if (position != null) {
      _mapController.move(LatLng(position.latitude, position.longitude), 12);
    }
    ref.read(incidentMapControllerProvider.notifier).load(
          lat: position?.latitude,
          lng: position?.longitude,
        );
  }

  String _typeLabel(IncidentType type) {
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

  String _statusLabel(IncidentStatus status) {
    final l10n = context.l10n;
    switch (status) {
      case IncidentStatus.new_:
        return l10n.incidentStatusNew;
      case IncidentStatus.verified:
        return l10n.incidentStatusVerified;
      case IncidentStatus.dispatched:
        return l10n.incidentStatusDispatched;
      case IncidentStatus.resolved:
        return l10n.incidentStatusResolved;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final IncidentMapState state = ref.watch(incidentMapControllerProvider);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.mapTitle)),
      body: Column(
        children: [
          _FilterBar(
            state: state,
            typeLabel: _typeLabel,
            statusLabel: _statusLabel,
          ),
          Expanded(
            child: state.errorMessage != null
                ? ErrorRetryView(
                    message: l10n.mapLoadError,
                    onRetry: _loadAroundUser,
                    retryLabel: l10n.actionRetry,
                  )
                : Stack(
                    children: [
                      FlutterMap(
                        mapController: _mapController,
                        options: const MapOptions(
                          initialCenter: _dushanbeCenter,
                          initialZoom: 11,
                        ),
                        children: [
                          TileLayer(
                            urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                            userAgentPackageName: 'tj.safetj.mobile',
                          ),
                          MarkerLayer(
                            markers: state.incidents.map((incident) {
                              return Marker(
                                point: LatLng(incident.location.lat, incident.location.lng),
                                width: 44,
                                height: 44,
                                child: GestureDetector(
                                  onTap: () => _showIncidentSheet(incident),
                                  child: Icon(
                                    incident.type.icon,
                                    color: incident.type.color,
                                    size: 34,
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                        ],
                      ),
                      if (state.isLoading)
                        const Positioned(
                          top: 12,
                          left: 0,
                          right: 0,
                          child: Center(child: CircularProgressIndicator()),
                        ),
                      if (!state.isLoading && state.incidents.isEmpty)
                        Positioned(
                          bottom: 16,
                          left: 16,
                          right: 16,
                          child: Card(
                            child: Padding(
                              padding: const EdgeInsets.all(12),
                              child: Text(l10n.mapNoIncidents, textAlign: TextAlign.center),
                            ),
                          ),
                        ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  void _showIncidentSheet(Incident incident) {
    final l10n = context.l10n;
    showModalBottomSheet<void>(
      context: context,
      builder: (context) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(incident.type.icon, color: incident.type.color),
                const SizedBox(width: 8),
                Text(_typeLabel(incident.type), style: Theme.of(context).textTheme.titleLarge),
                const Spacer(),
                StatusBadge(status: incident.status, label: _statusLabel(incident.status)),
              ],
            ),
            const SizedBox(height: 12),
            if (incident.description.isNotEmpty) Text(incident.description),
            const SizedBox(height: 8),
            if (incident.roadBlocked)
              Text(l10n.reportRoadBlocked, style: const TextStyle(fontWeight: FontWeight.w600)),
            if (incident.injuredCount > 0)
              Text('${l10n.reportInjuredCount}: ${incident.injuredCount}'),
          ],
        ),
      ),
    );
  }
}

class _FilterBar extends ConsumerWidget {
  const _FilterBar({
    required this.state,
    required this.typeLabel,
    required this.statusLabel,
  });

  final IncidentMapState state;
  final String Function(IncidentType) typeLabel;
  final String Function(IncidentStatus) statusLabel;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final controller = ref.read(incidentMapControllerProvider.notifier);

    return SizedBox(
      height: 56,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        children: [
          Center(
            child: Text(
              '${l10n.mapFilterType}:',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
          const SizedBox(width: 8),
          FilterChip(
            label: Text(l10n.mapAllTypes),
            selected: state.filters.type == null,
            onSelected: (_) => controller.setTypeFilter(null),
          ),
          const SizedBox(width: 8),
          ...IncidentType.values.map((type) {
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: FilterChip(
                label: Text(typeLabel(type)),
                selected: state.filters.type == type,
                onSelected: (_) => controller.setTypeFilter(type),
              ),
            );
          }),
          const SizedBox(width: 16),
          Center(
            child: Text(
              '${l10n.mapFilterStatus}:',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
          const SizedBox(width: 8),
          FilterChip(
            label: Text(l10n.mapAllStatuses),
            selected: state.filters.status == null,
            onSelected: (_) => controller.setStatusFilter(null),
          ),
          const SizedBox(width: 8),
          ...IncidentStatus.values.map((status) {
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: FilterChip(
                label: Text(statusLabel(status)),
                selected: state.filters.status == status,
                onSelected: (_) => controller.setStatusFilter(status),
              ),
            );
          }),
        ],
      ),
    );
  }
}
