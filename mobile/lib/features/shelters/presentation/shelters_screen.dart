import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/constants/incident_constants.dart';
import '../../../core/localization/l10n_extensions.dart';
import '../../../core/widgets/error_retry_view.dart';
import '../domain/safe_point.dart';
import 'shelters_controller.dart';

class SheltersScreen extends ConsumerWidget {
  const SheltersScreen({super.key});

  String _typeTabLabel(BuildContext context, SafePointType type) {
    final l10n = context.l10n;
    switch (type) {
      case SafePointType.shelter:
        return l10n.sheltersTabShelter;
      case SafePointType.hospital:
        return l10n.sheltersTabHospital;
      case SafePointType.police:
        return l10n.sheltersTabPolice;
      case SafePointType.emergencyCenter:
        return l10n.sheltersTabEmergencyCenter;
    }
  }

  Future<void> _call(String phone) async {
    final Uri uri = Uri(scheme: 'tel', path: phone);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  Future<void> _openInMaps(SafePoint point) async {
    final Uri uri = Uri.parse(
      'https://www.openstreetmap.org/?mlat=${point.location.lat}&mlon=${point.location.lng}#map=17/${point.location.lat}/${point.location.lng}',
    );
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final SheltersState state = ref.watch(sheltersControllerProvider);
    final controller = ref.read(sheltersControllerProvider.notifier);

    return DefaultTabController(
      length: SafePointType.values.length,
      initialIndex: SafePointType.values.indexOf(state.selectedType),
      child: Scaffold(
        appBar: AppBar(
          title: Text(l10n.sheltersTitle),
          bottom: TabBar(
            isScrollable: true,
            onTap: (index) => controller.selectType(SafePointType.values[index]),
            tabs: SafePointType.values
                .map((type) => Tab(text: _typeTabLabel(context, type)))
                .toList(),
          ),
        ),
        body: state.errorMessage != null
            ? ErrorRetryView(
                message: l10n.sheltersLoadError,
                onRetry: controller.refresh,
                retryLabel: l10n.actionRetry,
              )
            : Column(
                children: [
                  SizedBox(
                    height: 220,
                    child: FlutterMap(
                      options: MapOptions(
                        initialCenter: state.position != null
                            ? LatLng(state.position!.latitude, state.position!.longitude)
                            : const LatLng(38.5598, 68.7870),
                        initialZoom: 11,
                      ),
                      children: [
                        TileLayer(
                          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                          userAgentPackageName: 'tj.safetj.mobile',
                        ),
                        MarkerLayer(
                          markers: state.safePoints
                              .map((p) => Marker(
                                    point: LatLng(p.location.lat, p.location.lng),
                                    width: 36,
                                    height: 36,
                                    child: Icon(p.type.icon, color: Colors.red[700]),
                                  ))
                              .toList(),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: state.isLoading
                        ? const Center(child: CircularProgressIndicator())
                        : state.safePoints.isEmpty
                            ? Center(child: Text(l10n.sheltersEmpty))
                            : RefreshIndicator(
                                onRefresh: controller.refresh,
                                child: ListView.builder(
                                  padding: const EdgeInsets.symmetric(vertical: 8),
                                  itemCount: state.safePoints.length,
                                  itemBuilder: (context, index) {
                                    final SafePoint point = state.safePoints[index];
                                    return Card(
                                      child: ListTile(
                                        leading: Icon(point.type.icon),
                                        title: Text(point.name),
                                        subtitle: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(point.address),
                                            if (point.distanceKm != null)
                                              Text(l10n.sheltersDistanceAway(
                                                  point.distanceKm!.toStringAsFixed(1))),
                                          ],
                                        ),
                                        isThreeLine: true,
                                        trailing: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            IconButton(
                                              tooltip: l10n.actionCall,
                                              icon: const Icon(Icons.call),
                                              onPressed: point.phone.isEmpty
                                                  ? null
                                                  : () => _call(point.phone),
                                            ),
                                            IconButton(
                                              tooltip: l10n.actionOpenInMaps,
                                              icon: const Icon(Icons.directions),
                                              onPressed: () => _openInMaps(point),
                                            ),
                                          ],
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ),
                  ),
                ],
              ),
      ),
    );
  }
}
