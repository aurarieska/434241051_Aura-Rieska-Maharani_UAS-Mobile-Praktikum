import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/models/user_model.dart';
import '../../providers/auth_provider.dart';

class ManageUsersScreen extends StatefulWidget {
  const ManageUsersScreen({super.key});

  @override
  State<ManageUsersScreen> createState() => _ManageUsersScreenState();
}

class _ManageUsersScreenState extends State<ManageUsersScreen> {
  List<UserModel> _users = [];
  bool _isLoading = true;
  String _filter = 'All';
  final _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    _users = await context.read<AuthProvider>().getAllUsers();
    if (mounted) setState(() => _isLoading = false);
  }

  List<UserModel> get _filtered {
    var list = _users;
    if (_filter != 'All') {
      list = list.where((u) => u.role == _filter.toLowerCase()).toList();
    }
    final query = _searchCtrl.text.toLowerCase().trim();
    if (query.isNotEmpty) {
      list = list
          .where((u) =>
      u.fullName.toLowerCase().contains(query) ||
          u.email.toLowerCase().contains(query) ||
          u.username.toLowerCase().contains(query))
          .toList();
    }
    return list;
  }

  void _showRoleSheet(UserModel user) {
    final currentAdmin = context.read<AuthProvider>().currentUser!;

    // Prevent admin ubah role sendiri
    if (user.id == currentAdmin.id) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Tidak bisa mengubah role sendiri'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

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
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Ubah Role untuk ${user.fullName}',
                style: const TextStyle(
                    fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Text(
                'Role saat ini: ${user.role.toUpperCase()}',
                style: TextStyle(
                    fontSize: 12, color: Colors.grey.shade600),
              ),
              const SizedBox(height: 16),
              ...['user', 'helpdesk', 'admin'].map((role) {
                final isCurrentRole = user.role == role;
                return ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: _getRoleColor(role).withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      _getRoleIcon(role),
                      color: _getRoleColor(role),
                      size: 20,
                    ),
                  ),
                  title: Text(
                    role.toUpperCase(),
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  subtitle: Text(
                    _getRoleDesc(role),
                    style: const TextStyle(fontSize: 12),
                  ),
                  trailing: isCurrentRole
                      ? const Icon(Icons.check_circle,
                      color: AppTheme.statusResolvedColor)
                      : null,
                  onTap: isCurrentRole
                      ? null
                      : () async {
                    Navigator.pop(context);
                    await _updateRole(user, role);
                  },
                );
              }),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _updateRole(UserModel user, String newRole) async {
    // Konfirmasi
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape:
        RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Konfirmasi Ubah Role'),
        content: Text(
          'Ubah role ${user.fullName} dari ${user.role.toUpperCase()} menjadi ${newRole.toUpperCase()}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Ya, Ubah'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    final success = await context.read<AuthProvider>().updateUserRole(
      userId: user.id,
      newRole: newRole,
    );

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          success
              ? 'Role ${user.fullName} berhasil diubah'
              : 'Gagal mengubah role',
        ),
        backgroundColor:
        success ? AppTheme.statusResolvedColor : Colors.red,
        behavior: SnackBarBehavior.floating,
        shape:
        RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );

    if (success) await _load();
  }

  Color _getRoleColor(String role) {
    switch (role) {
      case 'admin':
        return Colors.red.shade600;
      case 'helpdesk':
        return AppTheme.statusInProgressColor;
      default:
        return AppTheme.primaryBlue;
    }
  }

  IconData _getRoleIcon(String role) {
    switch (role) {
      case 'admin':
        return Icons.admin_panel_settings;
      case 'helpdesk':
        return Icons.support_agent;
      default:
        return Icons.person;
    }
  }

  String _getRoleDesc(String role) {
    switch (role) {
      case 'admin':
        return 'Akses penuh, kelola tiket & user';
      case 'helpdesk':
        return 'Menangani tiket yang di-assign';
      default:
        return 'Membuat tiket & pelaporan';
    }
  }

  @override
  Widget build(BuildContext context) {
    final filteredUsers = _filtered;

    // Hitung statistik
    final totalUsers = _users.where((u) => u.role == 'user').length;
    final totalHelpdesk = _users.where((u) => u.role == 'helpdesk').length;
    final totalAdmin = _users.where((u) => u.role == 'admin').length;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Kelola User'),
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        child: Column(
          children: [
            // Statistik role
            Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppTheme.primaryBlue, AppTheme.secondaryBlue],
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.primaryBlue.withValues(alpha: 0.3),
                    blurRadius: 15,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: _statBox(
                        Icons.person, 'User', totalUsers.toString()),
                  ),
                  Container(
                      width: 1, height: 40, color: Colors.white24),
                  Expanded(
                    child: _statBox(Icons.support_agent, 'Helpdesk',
                        totalHelpdesk.toString()),
                  ),
                  Container(
                      width: 1, height: 40, color: Colors.white24),
                  Expanded(
                    child: _statBox(Icons.admin_panel_settings, 'Admin',
                        totalAdmin.toString()),
                  ),
                ],
              ),
            ),
            // Search bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: TextField(
                controller: _searchCtrl,
                onChanged: (_) => setState(() {}),
                decoration: InputDecoration(
                  hintText: 'Cari nama, email, username...',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: _searchCtrl.text.isNotEmpty
                      ? IconButton(
                    icon: const Icon(Icons.clear),
                    onPressed: () {
                      _searchCtrl.clear();
                      setState(() {});
                    },
                  )
                      : null,
                ),
              ),
            ),
            const SizedBox(height: 12),
            // Filter chips
            SizedBox(
              height: 42,
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                scrollDirection: Axis.horizontal,
                children: ['All', 'User', 'Helpdesk', 'Admin'].map((s) {
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(s),
                      selected: _filter == s,
                      onSelected: (_) => setState(() => _filter = s),
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 8),
            // User list
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : filteredUsers.isEmpty
                  ? ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: const [
                  SizedBox(height: 80),
                  Icon(Icons.person_off,
                      size: 80, color: Colors.grey),
                  SizedBox(height: 12),
                  Center(
                    child: Text(
                      'Tidak ada user',
                      style: TextStyle(color: Colors.grey),
                    ),
                  ),
                ],
              )
                  : ListView.builder(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                itemCount: filteredUsers.length,
                itemBuilder: (context, i) {
                  final u = filteredUsers[i];
                  final roleColor = _getRoleColor(u.role);
                  final currentAdmin = context
                      .read<AuthProvider>()
                      .currentUser!;
                  final isMe = u.id == currentAdmin.id;

                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    child: InkWell(
                      onTap: () => _showRoleSheet(u),
                      borderRadius: BorderRadius.circular(20),
                      child: Padding(
                        padding: const EdgeInsets.all(14),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(3),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    roleColor,
                                    roleColor
                                        .withValues(alpha: 0.6),
                                  ],
                                ),
                                shape: BoxShape.circle,
                              ),
                              child: CircleAvatar(
                                radius: 24,
                                backgroundColor: Colors.white,
                                backgroundImage: u.photoUrl !=
                                    null
                                    ? NetworkImage(u.photoUrl!)
                                    : null,
                                child: u.photoUrl == null
                                    ? Text(
                                  u.fullName.isNotEmpty
                                      ? u.fullName[0]
                                      .toUpperCase()
                                      : '?',
                                  style: TextStyle(
                                    color: roleColor,
                                    fontWeight:
                                    FontWeight.bold,
                                    fontSize: 18,
                                  ),
                                )
                                    : null,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment:
                                CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Flexible(
                                        child: Text(
                                          u.fullName,
                                          style: const TextStyle(
                                            fontWeight:
                                            FontWeight.bold,
                                            fontSize: 15,
                                          ),
                                          overflow: TextOverflow
                                              .ellipsis,
                                        ),
                                      ),
                                      if (isMe) ...[
                                        const SizedBox(width: 6),
                                        Container(
                                          padding:
                                          const EdgeInsets
                                              .symmetric(
                                              horizontal: 6,
                                              vertical: 2),
                                          decoration:
                                          BoxDecoration(
                                            color: AppTheme
                                                .softBlue,
                                            borderRadius:
                                            BorderRadius
                                                .circular(6),
                                          ),
                                          child: const Text(
                                            'Anda',
                                            style: TextStyle(
                                              fontSize: 9,
                                              color: AppTheme
                                                  .primaryBlue,
                                              fontWeight:
                                              FontWeight
                                                  .bold,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    u.email,
                                    style: TextStyle(
                                      fontSize: 12,
                                      color:
                                      Colors.grey.shade600,
                                    ),
                                    overflow:
                                    TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 6),
                                  Container(
                                    padding: const EdgeInsets
                                        .symmetric(
                                        horizontal: 8,
                                        vertical: 3),
                                    decoration: BoxDecoration(
                                      color: roleColor
                                          .withValues(
                                          alpha: 0.15),
                                      borderRadius:
                                      BorderRadius.circular(
                                          8),
                                    ),
                                    child: Row(
                                      mainAxisSize:
                                      MainAxisSize.min,
                                      children: [
                                        Icon(
                                          _getRoleIcon(u.role),
                                          size: 11,
                                          color: roleColor,
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          u.role.toUpperCase(),
                                          style: TextStyle(
                                            fontSize: 10,
                                            color: roleColor,
                                            fontWeight:
                                            FontWeight.bold,
                                            letterSpacing: 0.5,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const Icon(
                              Icons.edit_outlined,
                              color: AppTheme.textSecondary,
                              size: 20,
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _statBox(IconData icon, String label, String value) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: Colors.white, size: 20),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: const TextStyle(color: Colors.white70, fontSize: 11),
        ),
      ],
    );
  }
}