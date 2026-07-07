import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/ticket_provider.dart';
import '../../widgets/ticket_card.dart';
import 'create_ticket_screen.dart';
import 'ticket_detail_screen.dart';

class TicketListScreen extends StatefulWidget {
  const TicketListScreen({super.key});

  @override
  State<TicketListScreen> createState() => _TicketListScreenState();
}

class _TicketListScreenState extends State<TicketListScreen> {
  String _filter = 'All';
  final ScrollController _scrollCtrl = ScrollController();
  int _itemsToShow = 10;

  @override
  void initState() {
    super.initState();
    _scrollCtrl.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    final user = context.read<AuthProvider>().currentUser!;
    await context.read<TicketProvider>().loadTickets(user.id, user.role);
  }

  void _onScroll() {
    if (_scrollCtrl.position.pixels >=
        _scrollCtrl.position.maxScrollExtent - 100) {
      setState(() => _itemsToShow += 10);
    }
  }

  @override
  void dispose() {
    _scrollCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().currentUser!;
    final ticketProv = context.watch<TicketProvider>();
    var tickets = ticketProv.tickets;
    if (_filter != 'All') {
      tickets = tickets.where((t) => t.status == _filter).toList();
    }
    final displayed = tickets.take(_itemsToShow).toList();

    return Scaffold(
      appBar: AppBar(title: const Text('Daftar Tiket')),
      body: Column(
        children: [
          SizedBox(
            height: 50,
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              scrollDirection: Axis.horizontal,
              children: [
                'All',
                'Open',
                'Assigned',
                'In Progress',
                'Resolved',
                'Closed',
              ].map((s) {
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(s),
                    selected: _filter == s,
                    onSelected: (_) => setState(() {
                      _filter = s;
                      _itemsToShow = 10;
                    }),
                  ),
                );
              }).toList(),
            ),
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: _load,
              child: ticketProv.isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : displayed.isEmpty
                  ? ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: [
                  const SizedBox(height: 100),
                  const Icon(Icons.inbox,
                      size: 80, color: Colors.grey),
                  const SizedBox(height: 12),
                  const Center(
                    child: Text(
                      'Belum ada tiket',
                      style: TextStyle(color: Colors.grey),
                    ),
                  ),
                ],
              )
                  : ListView.builder(
                controller: _scrollCtrl,
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                itemCount: displayed.length +
                    (displayed.length < tickets.length ? 1 : 0),
                itemBuilder: (context, index) {
                  if (index >= displayed.length) {
                    return const Padding(
                      padding: EdgeInsets.all(16),
                      child: Center(
                          child: CircularProgressIndicator()),
                    );
                  }
                  final t = displayed[index];
                  return TicketCard(
                    ticket: t,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              TicketDetailScreen(ticketId: t.id),
                        ),
                      ).then((_) => _load());
                    },
                  );
                },
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: user.role == 'user'
          ? FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
                builder: (_) => const CreateTicketScreen()),
          ).then((_) => _load());
        },
        icon: const Icon(Icons.add),
        label: const Text('Buat Tiket'),
      )
          : null,
    );
  }
}