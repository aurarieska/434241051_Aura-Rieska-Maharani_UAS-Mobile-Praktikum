import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../providers/auth_provider.dart';
import '../../providers/notification_provider.dart';
import '../tickets/ticket_detail_screen.dart';

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({super.key});

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    final user = context.read<AuthProvider>().currentUser!;
    await context.read<NotificationProvider>().loadNotifications(user.id);
  }

  @override
  Widget build(BuildContext context) {
    final notifProv = context.watch<NotificationProvider>();
    final notifications = notifProv.notifications;

    return Scaffold(
      appBar: AppBar(title: const Text('Notifikasi')),
      body: notifications.isEmpty
          ? const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.notifications_off,
                size: 80, color: Colors.grey),
            SizedBox(height: 12),
            Text('Belum ada notifikasi',
                style: TextStyle(color: Colors.grey)),
          ],
        ),
      )
          : RefreshIndicator(
        onRefresh: _load,
        child: ListView.builder(
          padding: const EdgeInsets.all(12),
          itemCount: notifications.length,
          itemBuilder: (context, i) {
            final n = notifications[i];
            return Card(
              color: n.isRead
                  ? null
                  : AppTheme.primaryBlue.withValues(alpha: 0.05),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: AppTheme.primaryBlue,
                  child: Icon(
                    n.isRead
                        ? Icons.notifications
                        : Icons.notifications_active,
                    color: Colors.white,
                  ),
                ),
                title: Text(n.title,
                    style: TextStyle(
                        fontWeight: n.isRead
                            ? FontWeight.normal
                            : FontWeight.bold)),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(n.message),
                    Text(
                      DateFormat('dd MMM yyyy HH:mm')
                          .format(n.createdAt),
                      style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey.shade600),
                    ),
                  ],
                ),
                onTap: () async {
                  await notifProv.markAsRead(n.id);
                  await _load();
                  if (n.ticketId != null && context.mounted) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => TicketDetailScreen(
                            ticketId: n.ticketId!),
                      ),
                    );
                  }
                },
              ),
            );
          },
        ),
      ),
    );
  }
}