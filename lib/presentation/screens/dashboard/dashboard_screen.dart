import '../admin/manage_users_screen.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../providers/auth_provider.dart';
import '../../providers/notification_provider.dart';
import '../../providers/ticket_provider.dart';
import '../../widgets/stat_card.dart';
import '../../widgets/ticket_card.dart';
import '../notification/notification_screen.dart';
import '../tickets/create_ticket_screen.dart';
import '../tickets/ticket_detail_screen.dart';
import '../tickets/ticket_list_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadData());
  }

  Future<void> _loadData() async {
    final user = context.read<AuthProvider>().currentUser;
    if (user == null) return;
    await context.read<TicketProvider>().loadTickets(user.id, user.role);
    await context.read<NotificationProvider>().loadNotifications(user.id);
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final ticketProv = context.watch<TicketProvider>();
    final notifProv = context.watch<NotificationProvider>();
    final user = auth.currentUser!;
    final stats = ticketProv.stats;
    final unread = notifProv.unreadCount;
    final latestTickets = ticketProv.tickets.take(3).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('LaporKuy'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: Stack(
              alignment: Alignment.center,
              children: [
                Container(
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardColor,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.notifications_outlined),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const NotificationScreen()),
                      ).then((_) => _loadData());
                    },
                  ),
                ),
                if (unread > 0)
                  Positioned(
                    right: 6,
                    top: 6,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                      constraints:
                      const BoxConstraints(minWidth: 18, minHeight: 18),
                      child: Text(
                        '$unread',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadData,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppTheme.primaryBlue, AppTheme.secondaryBlue],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.primaryBlue.withValues(alpha: 0.3),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(3),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.3),
                        shape: BoxShape.circle,
                      ),
                      child: CircleAvatar(
                        radius: 30,
                        backgroundColor: Colors.white,
                        backgroundImage: user.photoUrl != null
                            ? NetworkImage(user.photoUrl!)
                            : null,
                        child: user.photoUrl == null
                            ? const Icon(Icons.person,
                            size: 34, color: AppTheme.primaryBlue)
                            : null,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Selamat datang 👋',
                              style: TextStyle(
                                  color: Colors.white70, fontSize: 13)),
                          const SizedBox(height: 2),
                          Text(
                            user.fullName,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 3),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.25),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              user.role.toUpperCase(),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              const Text('Statistik Tiket',
                  style:
                  TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 2,
                childAspectRatio: 1.15,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                children: [
                  StatCard(
                    title: 'Total Tiket',
                    value: '${stats['total'] ?? 0}',
                    icon: Icons.confirmation_number_outlined,
                    color: AppTheme.primaryBlue,
                  ),
                  StatCard(
                    title: 'Open',
                    value: '${stats['open'] ?? 0}',
                    icon: Icons.inbox_outlined,
                    color: AppTheme.statusOpenColor,
                  ),
                  StatCard(
                    title: 'In Progress',
                    value: '${stats['inProgress'] ?? 0}',
                    icon: Icons.sync,
                    color: AppTheme.statusInProgressColor,
                  ),
                  StatCard(
                    title: 'Resolved',
                    value: '${stats['resolved'] ?? 0}',
                    icon: Icons.check_circle_outline,
                    color: AppTheme.statusResolvedColor,
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  if (user.role == 'user')
                    Expanded(
                      child: _actionCard(
                        context,
                        icon: Icons.add_circle_outline,
                        title: 'Buat Tiket',
                        color: AppTheme.primaryBlue,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) => const CreateTicketScreen()),
                          ).then((_) => _loadData());
                        },
                      ),
                    ),
                  if (user.role == 'user') const SizedBox(width: 12),
                  if (user.role == 'admin')
                    Expanded(
                      child: _actionCard(
                        context,
                        icon: Icons.manage_accounts_outlined,
                        title: 'Kelola User',
                        color: Colors.red.shade600,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) => const ManageUsersScreen()),
                          );
                        },
                      ),
                    ),
                  if (user.role == 'admin') const SizedBox(width: 12),
                  Expanded(
                    child: _actionCard(
                      context,
                      icon: Icons.list_alt_outlined,
                      title: 'Daftar Tiket',
                      color: AppTheme.statusInProgressColor,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const TicketListScreen()),
                        ).then((_) => _loadData());
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _actionCard(
      BuildContext context, {
        required IconData icon,
        required String title,
        required Color color,
        required VoidCallback onTap,
      }) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: color, size: 28),
              ),
              const SizedBox(height: 10),
              Text(title,
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 14)),
            ],
          ),
        ),
      ),
    );
  }
}