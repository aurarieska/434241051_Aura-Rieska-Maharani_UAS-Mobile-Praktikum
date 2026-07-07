import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/validators.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_text_field.dart';

class ResetPasswordScreen extends StatefulWidget {
  const ResetPasswordScreen({super.key});

  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _oldPasswordCtrl = TextEditingController();
  final _newPasswordCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _oldPasswordCtrl.dispose();
    _newPasswordCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  Future<void> _reset() async {
    if (!_formKey.currentState!.validate()) return;

    if (_newPasswordCtrl.text != _confirmCtrl.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Konfirmasi password tidak cocok'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (_oldPasswordCtrl.text == _newPasswordCtrl.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Password baru harus berbeda dari password lama'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);
    final result = await context.read<AuthProvider>().resetPassword(
      email: _emailCtrl.text.trim(),
      oldPassword: _oldPasswordCtrl.text,
      newPassword: _newPasswordCtrl.text,
    );
    if (!mounted) return;
    setState(() => _isLoading = false);

    final success = result['success'] == true;
    final message = result['message']?.toString() ??
        (success ? 'Password berhasil direset' : 'Gagal reset password');

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: success ? Colors.green : Colors.red,
      ),
    );

    if (success) {
      await Future.delayed(const Duration(milliseconds: 500));
      if (mounted) Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Reset Password')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              const Icon(Icons.lock_reset,
                  size: 80, color: AppTheme.primaryBlue),
              const SizedBox(height: 16),
              const Text(
                'Reset Password',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                'Verifikasi dengan password lama untuk reset',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey.shade600),
              ),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppTheme.softBlue,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.shield_outlined,
                        color: AppTheme.primaryBlue, size: 22),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Kamu butuh password lama untuk verifikasi keamanan',
                        style: TextStyle(fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              CustomTextField(
                controller: _emailCtrl,
                label: 'Email',
                hint: 'email@example.com',
                prefixIcon: Icons.email_outlined,
                keyboardType: TextInputType.emailAddress,
                validator: Validators.validateEmail,
              ),
              const SizedBox(height: 14),
              CustomTextField(
                controller: _oldPasswordCtrl,
                label: 'Password Lama',
                prefixIcon: Icons.lock_outline,
                obscureText: true,
                validator: Validators.validatePassword,
              ),
              const SizedBox(height: 14),
              CustomTextField(
                controller: _newPasswordCtrl,
                label: 'Password Baru',
                prefixIcon: Icons.lock_reset,
                obscureText: true,
                validator: Validators.validatePassword,
              ),
              const SizedBox(height: 14),
              CustomTextField(
                controller: _confirmCtrl,
                label: 'Konfirmasi Password Baru',
                prefixIcon: Icons.lock_reset,
                obscureText: true,
                validator: Validators.validatePassword,
              ),
              const SizedBox(height: 24),
              CustomButton(
                text: 'Reset Password',
                onPressed: _reset,
                isLoading: _isLoading,
                icon: Icons.refresh,
              ),
            ],
          ),
        ),
      ),
    );
  }
}