import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/validators.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_text_field.dart';

class ChangePasswordScreen extends StatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _newCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _newCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_newCtrl.text != _confirmCtrl.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Konfirmasi tidak cocok')),
      );
      return;
    }
    setState(() => _isLoading = true);
    final success =
    await context.read<AuthProvider>().changePassword(_newCtrl.text);
    if (!mounted) return;
    setState(() => _isLoading = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(success
            ? 'Password berhasil diubah'
            : 'Gagal mengubah password'),
        backgroundColor: success ? Colors.green : Colors.red,
      ),
    );
    if (success) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Ubah Password')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppTheme.softBlue,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.info_outline, color: AppTheme.primaryBlue),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Password baru minimal 6 karakter',
                        style: TextStyle(fontSize: 13),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              CustomTextField(
                controller: _newCtrl,
                label: 'Password Baru',
                prefixIcon: Icons.lock_outline,
                obscureText: true,
                validator: Validators.validatePassword,
              ),
              const SizedBox(height: 14),
              CustomTextField(
                controller: _confirmCtrl,
                label: 'Konfirmasi Password',
                prefixIcon: Icons.lock_outline,
                obscureText: true,
                validator: Validators.validatePassword,
              ),
              const SizedBox(height: 24),
              CustomButton(
                text: 'Ubah Password',
                onPressed: _save,
                isLoading: _isLoading,
                icon: Icons.check,
              ),
            ],
          ),
        ),
      ),
    );
  }
}