import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/utils/validators.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_text_field.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usernameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _fullNameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();

  @override
  void dispose() {
    _usernameCtrl.dispose();
    _emailCtrl.dispose();
    _fullNameCtrl.dispose();
    _phoneCtrl.dispose();
    _passwordCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;
    if (_passwordCtrl.text != _confirmCtrl.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Password tidak cocok')),
      );
      return;
    }
    final success = await context.read<AuthProvider>().register(
      username: _usernameCtrl.text.trim(),
      email: _emailCtrl.text.trim(),
      password: _passwordCtrl.text,
      fullName: _fullNameCtrl.text.trim(),
      phone: _phoneCtrl.text.trim(),
    );
    if (!mounted) return;
    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Registrasi berhasil! Silahkan login'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Registrasi gagal. Email mungkin sudah terdaftar.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = context.watch<AuthProvider>().isLoading;
    return Scaffold(
      appBar: AppBar(title: const Text('Daftar Akun')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              CustomTextField(
                controller: _fullNameCtrl,
                label: 'Nama Lengkap',
                prefixIcon: Icons.person_outline,
                validator: (v) => Validators.validateRequired(v, 'Nama'),
              ),
              const SizedBox(height: 14),
              CustomTextField(
                controller: _usernameCtrl,
                label: 'Username',
                prefixIcon: Icons.account_circle_outlined,
                validator: Validators.validateUsername,
              ),
              const SizedBox(height: 14),
              CustomTextField(
                controller: _emailCtrl,
                label: 'Email',
                prefixIcon: Icons.email_outlined,
                keyboardType: TextInputType.emailAddress,
                validator: Validators.validateEmail,
              ),
              const SizedBox(height: 14),
              CustomTextField(
                controller: _phoneCtrl,
                label: 'Nomor HP',
                prefixIcon: Icons.phone_outlined,
                keyboardType: TextInputType.phone,
                validator: (v) => Validators.validateRequired(v, 'Nomor HP'),
              ),
              const SizedBox(height: 14),
              CustomTextField(
                controller: _passwordCtrl,
                label: 'Password',
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
                text: 'Daftar',
                onPressed: _register,
                isLoading: isLoading,
                icon: Icons.app_registration,
              ),
            ],
          ),
        ),
      ),
    );
  }
}