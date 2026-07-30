import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/localization/l10n_extensions.dart';
import '../domain/app_notification.dart';
import 'notifications_controller.dart';

class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final List<AppNotification> notifications = ref.watch(notificationsControllerProvider);
    final DateFormat formatter = DateFormat('MMM d, HH:mm');

    return Scaffold(
      appBar: AppBar(title: Text(l10n.notificationsTitle)),
      body: notifications.isEmpty
          ? Center(child: Text(l10n.notificationsEmpty))
          : ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: notifications.length,
              itemBuilder: (context, index) {
                final AppNotification notification = notifications[index];
                return Card(
                  child: ListTile(
                    leading: const Icon(Icons.campaign, color: Colors.red),
                    title: Text(notification.title),
                    subtitle: Text(notification.body),
                    trailing: Text(
                      formatter.format(notification.receivedAt.toLocal()),
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ),
                );
              },
            ),
    );
  }
}
