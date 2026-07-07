import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/validators.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_text_field.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _fullNameCtrl;
  late TextEditingController _emailCtrl;
  late TextEditingController _phoneCtrl;
  File? _newPhotoFile;
  String? _currentPhotoUrl;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    final user = context.read<AuthProvider>().currentUser!;
    _fullNameCtrl = TextEditingController(text: user.fullName);
    _emailCtrl = TextEditingController(text: user.email);
    _phoneCtrl = TextEditingController(text: user.phone ?? '');
    _currentPhotoUrl = user.photoUrl;
  }

  @override
  void dispose() {
    _fullNameCtrl.dispose();
    _emailCtrl.dispose();
    _phoneCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: source, imageQuality: 75);
    if (picked != null) {
      setState(() => _newPhotoFile = File(picked.path));
    }
  }

  void _showSourceSheet() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt,
                  color: AppTheme.primaryBlue),
              title: const Text('Ambil dari Kamera'),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library,
                  color: AppTheme.primaryBlue),
              title: const Text('Pilih dari Galeri'),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.gallery);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    final success = await context.read<AuthProvider>().updateProfile(
      fullName: _fullNameCtrl.text.trim(),
      email: _emailCtrl.text.trim(),
      phone: _phoneCtrl.text.trim(),
      photoFile: _newPhotoFile,
    );
    if (!mounted) return;
    setState(() => _isLoading = false);
    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Profile berhasil diupdate'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Gagal update profile')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Edit Profile')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              Center(
                child: Stack(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(colors: [
                          AppTheme.primaryBlue,
                          AppTheme.secondaryBlue,
                        ]),
                        shape: BoxShape.circle,
                      ),
                      child: CircleAvatar(
                        radius: 55,
                        backgroundColor: Colors.white,
                        backgroundImage: _newPhotoFile != null
                            ? FileImage(_newPhotoFile!) as ImageProvider
                            : (_currentPhotoUrl != null
                            ? NetworkImage(_currentPhotoUrl!)
                            : null),
                        child: (_newPhotoFile == null &&
                            _currentPhotoUrl == null)
                            ? const Icon(Icons.person,
                            size: 60, color: AppTheme.primaryBlue)
                            : null,
                      ),
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: GestureDetector(
                        onTap: _showSourceSheet,
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppTheme.primaryBlue,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 3),
                          ),
                          child: const Icon(Icons.camera_alt,
                              color: Colors.white, size: 18),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              CustomTextField(
                controller: _fullNameCtrl,
                label: 'Nama Lengkap',
                prefixIcon: Icons.person_outline,
                validator: (v) => Validators.validateRequired(v, 'Nama'),
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
                validator: (v) =>
                    Validators.validateRequired(v, 'Nomor HP'),
              ),
              const SizedBox(height: 24),
              CustomButton(
                text: 'Simpan Perubahan',
                onPressed: _save,
                isLoading: _isLoading,
                icon: Icons.save_outlined,
              ),
            ],
          ),
        ),
      ),
    );
  }
}