import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/models/ticket_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/ticket_provider.dart';
import 'assign_ticket_screen.dart';

class TicketDetailScreen extends StatefulWidget {
  final String ticketId;
  const TicketDetailScreen({super.key, required this.ticketId});

  @override
  State<TicketDetailScreen> createState() => _TicketDetailScreenState();
}

class _TicketDetailScreenState extends State<TicketDetailScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;
  final _commentCtrl = TextEditingController();
  TicketModel? _ticket;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 3, vsync: this);
    _load();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    _ticket = await context.read<TicketProvider>().getTicketById(widget.ticketId);
    if (mounted) setState(() => _isLoading = false);
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    _commentCtrl.dispose();
    super.dispose();
  }

  void _showStatusSheet() {
    final user = context.read<AuthProvider>().currentUser!;
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (_) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Update Status',
                  style:
                  TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              ...['Open', 'Assigned', 'In Progress', 'Resolved', 'Closed']
                  .map((s) {
                final color = AppTheme.getStatusColor(s);
                return ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                          color: color, shape: BoxShape.circle),
                    ),
                  ),
                  title: Text(s,
                      style: const TextStyle(fontWeight: FontWeight.w600)),
                  onTap: () async {
                    Navigator.pop(context);
                    await context.read<TicketProvider>().updateStatus(
                      ticketId: widget.ticketId,
                      newStatus: s,
                      oldStatus: _ticket!.status,
                      userId: user.id,
                    );
                    await _load();
                  },
                );
              }),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _sendComment() async {
    if (_commentCtrl.text.trim().isEmpty) return;
    final user = context.read<AuthProvider>().currentUser!;
    await context.read<TicketProvider>().addComment(
      ticketId: widget.ticketId,
      userId: user.id,
      message: _commentCtrl.text.trim(),
    );
    _commentCtrl.clear();
    FocusScope.of(context).unfocus();
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().currentUser!;
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (_ticket == null) {
      return const Scaffold(body: Center(child: Text('Tiket tidak ditemukan')));
    }
    final ticket = _ticket!;
    final statusColor = AppTheme.getStatusColor(ticket.status);

    return Scaffold(
      appBar: AppBar(
        title: Text(ticket.ticketNumber),
        actions: [
          if (user.role == 'admin' || user.role == 'helpdesk')
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert),
              onSelected: (v) async {
                if (v == 'status') _showStatusSheet();
                if (v == 'assign') {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => AssignTicketScreen(ticketId: ticket.id),
                    ),
                  );
                  await _load();
                }
              },
              itemBuilder: (_) => [
                const PopupMenuItem(
                  value: 'status',
                  child: ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Icon(Icons.update),
                    title: Text('Update Status'),
                  ),
                ),
                if (user.role == 'admin')
                  const PopupMenuItem(
                    value: 'assign',
                    child: ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: Icon(Icons.assignment_ind),
                      title: Text('Assign Tiket'),
                    ),
                  ),
              ],
            ),
        ],
      ),
      body: Column(
        children: [
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  statusColor.withValues(alpha: 0.15),
                  statusColor.withValues(alpha: 0.05),
                ],
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                  color: statusColor.withValues(alpha: 0.3), width: 1),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(ticket.title,
                          style: const TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold)),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: statusColor,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        ticket.status,
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.person_outline,
                        size: 14, color: Colors.grey.shade700),
                    const SizedBox(width: 4),
                    Text(ticket.createdByName,
                        style: TextStyle(
                            fontSize: 12, color: Colors.grey.shade700)),
                    const SizedBox(width: 12),
                    Icon(Icons.access_time,
                        size: 14, color: Colors.grey.shade700),
                    const SizedBox(width: 4),
                    Text(
                      DateFormat('dd MMM yyyy').format(ticket.createdAt),
                      style: TextStyle(
                          fontSize: 12, color: Colors.grey.shade700),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(16),
            ),
            child: TabBar(
              controller: _tabCtrl,
              indicator: BoxDecoration(
                color: AppTheme.primaryBlue,
                borderRadius: BorderRadius.circular(14),
              ),
              indicatorSize: TabBarIndicatorSize.tab,
              indicatorPadding: const EdgeInsets.all(4),
              labelColor: Colors.white,
              unselectedLabelColor: Colors.grey.shade600,
              dividerColor: Colors.transparent,
              labelStyle: const TextStyle(
                  fontWeight: FontWeight.bold, fontSize: 13),
              tabs: [
                const Tab(text: 'Detail'),
                const Tab(text: 'Riwayat'),
                Tab(text: 'Komentar (${ticket.comments.length})'),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: TabBarView(
              controller: _tabCtrl,
              children: [
                _DetailTab(ticket: ticket),
                _HistoryTab(ticket: ticket),
                _CommentTab(
                  ticket: ticket,
                  commentCtrl: _commentCtrl,
                  onSend: _sendComment,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DetailTab extends StatelessWidget {
  final TicketModel ticket;
  const _DetailTab({required this.ticket});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Deskripsi',
                      style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textSecondary)),
                  const SizedBox(height: 8),
                  Text(ticket.description,
                      style: const TextStyle(fontSize: 14, height: 1.5)),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _info('No. Tiket', ticket.ticketNumber),
                  const Divider(height: 20),
                  _info('Kategori', ticket.category),
                  const Divider(height: 20),
                  _info('Prioritas', ticket.priority),
                  const Divider(height: 20),
                  _info('Dibuat oleh', ticket.createdByName),
                  if (ticket.assignedToName != null) ...[
                    const Divider(height: 20),
                    _info('Ditangani oleh', ticket.assignedToName!),
                  ],
                  const Divider(height: 20),
                  _info('Tanggal Dibuat',
                      DateFormat('dd MMM yyyy, HH:mm').format(ticket.createdAt)),
                ],
              ),
            ),
          ),
          if (ticket.attachmentUrl != null) ...[
            const SizedBox(height: 12),
            const Text('Lampiran',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Image.network(
                ticket.attachmentUrl!,
                height: 200,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  height: 200,
                  color: Colors.grey.shade200,
                  child: const Icon(Icons.broken_image, size: 50),
                ),
              ),
            ),
          ],
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _info(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 2,
          child: Text(label,
              style: const TextStyle(
                  fontSize: 12, color: AppTheme.textSecondary)),
        ),
        Expanded(
          flex: 3,
          child: Text(value,
              style: const TextStyle(
                  fontSize: 13, fontWeight: FontWeight.w600)),
        ),
      ],
    );
  }
}

class _HistoryTab extends StatelessWidget {
  final TicketModel ticket;
  const _HistoryTab({required this.ticket});

  @override
  Widget build(BuildContext context) {
    if (ticket.history.isEmpty) {
      return const Center(child: Text('Belum ada riwayat'));
    }
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: ticket.history.length,
      itemBuilder: (context, i) {
        final h = ticket.history[i];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppTheme.softBlue,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(h.action,
                          style: const TextStyle(
                              color: AppTheme.primaryBlue,
                              fontWeight: FontWeight.bold,
                              fontSize: 11)),
                    ),
                    const Spacer(),
                    Text(
                      DateFormat('dd MMM HH:mm').format(h.timestamp),
                      style: TextStyle(
                          fontSize: 11, color: Colors.grey.shade600),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(h.description, style: const TextStyle(fontSize: 13)),
                const SizedBox(height: 6),
                Text('oleh ${h.userName}',
                    style: TextStyle(
                        fontSize: 11, color: Colors.grey.shade600)),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _CommentTab extends StatelessWidget {
  final TicketModel ticket;
  final TextEditingController commentCtrl;
  final VoidCallback onSend;
  const _CommentTab(
      {required this.ticket,
        required this.commentCtrl,
        required this.onSend});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: ticket.comments.isEmpty
              ? Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.chat_bubble_outline,
                    size: 60, color: Colors.grey.shade400),
                const SizedBox(height: 8),
                Text('Belum ada komentar',
                    style: TextStyle(color: Colors.grey.shade600)),
              ],
            ),
          )
              : ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: ticket.comments.length,
            itemBuilder: (context, i) {
              final c = ticket.comments[i];
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          CircleAvatar(
                            radius: 16,
                            backgroundColor: AppTheme.primaryBlue,
                            child: Text(
                              c.userName.isNotEmpty
                                  ? c.userName[0].toUpperCase()
                                  : '?',
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment:
                              CrossAxisAlignment.start,
                              children: [
                                Text(c.userName,
                                    style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 13)),
                                Text(
                                  '${c.userRole} • ${DateFormat('dd MMM HH:mm').format(c.createdAt)}',
                                  style: TextStyle(
                                      fontSize: 10,
                                      color: Colors.grey.shade600),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Text(c.message,
                          style: const TextStyle(height: 1.4)),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        Container(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
          decoration: BoxDecoration(color: Theme.of(context).cardColor),
          child: SafeArea(
            top: false,
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: commentCtrl,
                    decoration:
                    const InputDecoration(hintText: 'Tulis komentar...'),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  decoration: BoxDecoration(
                    color: AppTheme.primaryBlue,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.send, color: Colors.white),
                    onPressed: onSend,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}