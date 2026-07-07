import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/models/user_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/ticket_provider.dart';

class AssignTicketScreen extends StatefulWidget {
  final String ticketId;
  const AssignTicketScreen({super.key, required this.ticketId});

  @override
  State<AssignTicketScreen> createState() => _AssignTicketScreenState();
}

class _AssignTicketScreenState extends State<AssignTicketScreen> {
  String? _selectedHelpdeskId;
  List<UserModel> _helpdeskList = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final auth = context.read<AuthProvider>();
    _helpdeskList = await auth.repository.getHelpdeskList();
    if (mounted) setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Assign Tiket')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Pilih Helpdesk',
                style: TextStyle(
                    fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              initialValue: _selectedHelpdeskId,
              hint: const Text('Pilih helpdesk'),
              isExpanded: true,
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.person_search),
              ),
              items: _helpdeskList
                  .map((h) => DropdownMenuItem(
                  value: h.id, child: Text(h.fullName)))
                  .toList(),
              onChanged: (v) =>
                  setState(() => _selectedHelpdeskId = v),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _selectedHelpdeskId == null
                    ? null
                    : () async {
                  final helpdesk = _helpdeskList.firstWhere(
                          (h) => h.id == _selectedHelpdeskId);
                  final admin = context
                      .read<AuthProvider>()
                      .currentUser!;
                  await context
                      .read<TicketProvider>()
                      .assignTicket(
                    ticketId: widget.ticketId,
                    helpdeskId: helpdesk.id,
                    helpdeskName: helpdesk.fullName,
                    adminId: admin.id,
                  );
                  if (!context.mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                          'Tiket diassign ke ${helpdesk.fullName}'),
                      backgroundColor: AppTheme.statusResolvedColor,
                    ),
                  );
                  Navigator.pop(context);
                },
                icon: const Icon(Icons.check),
                label: const Text('Assign Tiket'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}