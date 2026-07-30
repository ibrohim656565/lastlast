import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart' as ph;

import '../../../core/constants/app_config.dart';
import '../../../core/constants/incident_constants.dart';
import '../../../core/localization/l10n_extensions.dart';
import '../../../core/offline/queued_report.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/loading_primary_button.dart';
import 'report_form_controller.dart';

class ReportIncidentScreen extends ConsumerWidget {
  const ReportIncidentScreen({super.key, required this.initialType});

  final IncidentType initialType;

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

  /// `image_picker` can trigger the native photo-library / camera prompt on
  /// its own, but we ask via `permission_handler` first (same as location)
  /// so a denial surfaces a consistent, localized message instead of
  /// image_picker's platform-default (and English-only) system dialog text.
  Future<bool> _ensureMediaPermission(BuildContext context) async {
    final ph.PermissionStatus status = await ph.Permission.photos.request();
    if (status.isGranted || status.isLimited) return true;
    if (!context.mounted) return false;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(context.l10n.reportPermissionCameraDenied)),
    );
    return false;
  }

  Future<void> _pickPhotos(BuildContext context, WidgetRef ref, IncidentType type) async {
    if (!await _ensureMediaPermission(context)) return;
    final ImagePicker picker = ImagePicker();
    final List<XFile> files = await picker.pickMultiImage(limit: AppConfig.maxMediaPerReport);
    if (files.isEmpty) return;
    ref.read(reportFormControllerProvider(type).notifier).addMedia(
          files.map((f) => QueuedMediaFile(path: f.path, type: MediaType.photo)).toList(),
        );
  }

  Future<void> _pickVideo(BuildContext context, WidgetRef ref, IncidentType type) async {
    if (!await _ensureMediaPermission(context)) return;
    final ImagePicker picker = ImagePicker();
    final XFile? file = await picker.pickVideo(source: ImageSource.gallery);
    if (file == null) return;
    ref.read(reportFormControllerProvider(type).notifier).addMedia(
          [QueuedMediaFile(path: file.path, type: MediaType.video)],
        );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final ReportFormState formState = ref.watch(reportFormControllerProvider(initialType));
    final ReportFormController controller =
        ref.read(reportFormControllerProvider(initialType).notifier);

    ref.listen<ReportFormState>(reportFormControllerProvider(initialType), (previous, next) {
      if (next.errorMessage != null && next.errorMessage != previous?.errorMessage) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(next.errorMessage!), backgroundColor: AppColors.tjRed),
        );
      }
    });

    Future<void> handleSubmit() async {
      final ReportSubmitOutcome outcome = await controller.submit();
      if (!context.mounted) return;
      switch (outcome) {
        case ReportSubmitOutcome.submittedOnline:
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(l10n.reportSubmitOnlineSuccess),
              backgroundColor: AppColors.success,
            ),
          );
          Navigator.of(context).pop();
        case ReportSubmitOutcome.queuedOffline:
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(l10n.reportSubmitQueuedOffline),
              backgroundColor: AppColors.warning,
              duration: const Duration(seconds: 5),
            ),
          );
          Navigator.of(context).pop();
        case ReportSubmitOutcome.failed:
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                formState.locationError
                    ? l10n.reportLocationUnavailable
                    : l10n.reportSubmitError,
              ),
              backgroundColor: AppColors.tjRed,
            ),
          );
      }
    }

    return Scaffold(
      appBar: AppBar(title: Text(l10n.reportTitle(_typeLabel(context, formState.type)))),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _LocationCard(formState: formState, onRetry: controller.fetchLocation),
          const SizedBox(height: 16),
          _TypeSelector(
            selected: formState.type,
            onChanged: controller.setType,
            typeLabel: (t) => _typeLabel(context, t),
          ),
          const SizedBox(height: 16),
          Text(l10n.reportDescriptionLabel, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          TextField(
            maxLines: 4,
            onChanged: controller.setDescription,
            decoration: InputDecoration(hintText: l10n.reportDescriptionHint),
          ),
          const SizedBox(height: 16),
          _InjuredCountStepper(
            label: l10n.reportInjuredCount,
            value: formState.injuredCount,
            onChanged: controller.setInjuredCount,
          ),
          const SizedBox(height: 16),
          Card(
            child: SwitchListTile(
              title: Text(l10n.reportRoadBlocked),
              value: formState.roadBlocked,
              onChanged: controller.setRoadBlocked,
            ),
          ),
          const SizedBox(height: 16),
          Text(l10n.reportAttachMedia, style: Theme.of(context).textTheme.titleMedium),
          Text(
            l10n.reportMediaLimit(AppConfig.maxMediaPerReport),
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 8),
          _MediaGrid(
            media: formState.media,
            onRemove: controller.removeMediaAt,
            onAddPhoto: () => _pickPhotos(context, ref, initialType),
            onAddVideo: () => _pickVideo(context, ref, initialType),
            canAddMore: formState.media.length < AppConfig.maxMediaPerReport,
          ),
          const SizedBox(height: 28),
          LoadingPrimaryButton(
            label: l10n.reportSubmit,
            isLoading: formState.isSubmitting,
            color: AppColors.tjRed,
            onPressed: handleSubmit,
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

class _LocationCard extends StatelessWidget {
  const _LocationCard({required this.formState, required this.onRetry});

  final ReportFormState formState;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Card(
      child: ListTile(
        leading: Icon(
          formState.locationError ? Icons.location_off : Icons.my_location,
          color: formState.locationError
              ? AppColors.tjRed
              : Theme.of(context).colorScheme.primary,
        ),
        title: Text(l10n.reportLocation),
        subtitle: Text(
          formState.isFetchingLocation
              ? l10n.reportLocationFetching
              : formState.locationError
                  ? l10n.reportLocationUnavailable
                  : '${formState.position!.latitude.toStringAsFixed(5)}, '
                      '${formState.position!.longitude.toStringAsFixed(5)}',
        ),
        trailing: formState.isFetchingLocation
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : IconButton(icon: const Icon(Icons.refresh), onPressed: onRetry),
      ),
    );
  }
}

class _TypeSelector extends StatelessWidget {
  const _TypeSelector({
    required this.selected,
    required this.onChanged,
    required this.typeLabel,
  });

  final IncidentType selected;
  final ValueChanged<IncidentType> onChanged;
  final String Function(IncidentType) typeLabel;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(l10n.reportType, style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: IncidentType.values.map((type) {
            final bool isSelected = type == selected;
            return ChoiceChip(
              label: Text(typeLabel(type)),
              avatar: Icon(type.icon, size: 18, color: isSelected ? Colors.white : type.color),
              selected: isSelected,
              selectedColor: type.color,
              labelStyle: TextStyle(color: isSelected ? Colors.white : null),
              onSelected: (_) => onChanged(type),
            );
          }).toList(),
        ),
      ],
    );
  }
}

class _InjuredCountStepper extends StatelessWidget {
  const _InjuredCountStepper({
    required this.label,
    required this.value,
    required this.onChanged,
  });

  final String label;
  final int value;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          children: [
            Expanded(child: Text(label, style: Theme.of(context).textTheme.titleMedium)),
            IconButton(
              icon: const Icon(Icons.remove_circle_outline),
              onPressed: () => onChanged(value - 1),
            ),
            Text('$value', style: Theme.of(context).textTheme.titleLarge),
            IconButton(
              icon: const Icon(Icons.add_circle_outline),
              onPressed: () => onChanged(value + 1),
            ),
          ],
        ),
      ),
    );
  }
}

class _MediaGrid extends StatelessWidget {
  const _MediaGrid({
    required this.media,
    required this.onRemove,
    required this.onAddPhoto,
    required this.onAddVideo,
    required this.canAddMore,
  });

  final List<QueuedMediaFile> media;
  final ValueChanged<int> onRemove;
  final VoidCallback onAddPhoto;
  final VoidCallback onAddVideo;
  final bool canAddMore;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (int i = 0; i < media.length; i++) _MediaThumb(file: media[i], onRemove: () => onRemove(i)),
        if (canAddMore) ...[
          _AddTile(icon: Icons.add_a_photo, onTap: onAddPhoto),
          _AddTile(icon: Icons.videocam, onTap: onAddVideo),
        ],
      ],
    );
  }
}

class _MediaThumb extends StatelessWidget {
  const _MediaThumb({required this.file, required this.onRemove});

  final QueuedMediaFile file;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: file.type == MediaType.photo
              ? Image.file(File(file.path), width: 88, height: 88, fit: BoxFit.cover)
              : Container(
                  width: 88,
                  height: 88,
                  color: Colors.black87,
                  child: const Icon(Icons.play_circle_fill, color: Colors.white, size: 32),
                ),
        ),
        Positioned(
          top: -6,
          right: -6,
          child: IconButton(
            icon: const Icon(Icons.cancel, color: AppColors.tjRed),
            onPressed: onRemove,
          ),
        ),
      ],
    );
  }
}

class _AddTile extends StatelessWidget {
  const _AddTile({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: 88,
        height: 88,
        decoration: BoxDecoration(
          border: Border.all(color: Theme.of(context).colorScheme.outline),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: Theme.of(context).colorScheme.primary),
      ),
    );
  }
}
