import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/utils/validators.dart';
import '../../providers/auth_provider.dart';
import '../../providers/ticket_provider.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_text_field.dart';

class CreateTicketScreen extends StatefulWidget {
  const CreateTicketScreen({super.key});

  @override
  State<CreateTicketScreen> createState() => _CreateTicketScreenState();
}

class _CreateTicketScreenState extends State<CreateTicketScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  String _category = AppConstants.categories.first;
  String _priority = 'Medium';
  File? _attachment;
  bool _isLoading = false;

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: source, imageQuality: 75);
    if (picked != null) {
      setState(() => _attachment = File(picked.path));
    }
  }

  void _showImageSourceSheet() {
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
              leading: const Icon(Icons.camera_alt),
              title: const Text('Ambil dari Kamera'),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
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

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    final user = context.read<AuthProvider>().currentUser!;
    final success = await context.read<TicketProvider>().createTicket(
      title: _titleCtrl.text.trim(),
      description: _descCtrl.text.trim(),
      category: _category,
      priority: _priority,
      createdBy: user.id,
      attachmentFile: _attachment,
    );
    if (!mounted) return;
    setState(() => _isLoading = false);
    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Tiket berhasil dibuat'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Gagal membuat tiket')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Buat Tiket Baru')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CustomTextField(
                controller: _titleCtrl,
                label: 'Judul Tiket',
                hint: 'Contoh: Laptop tidak bisa menyala',
                prefixIcon: Icons.title,
                validator: (v) => Validators.validateRequired(v, 'Judul'),
              ),
              const SizedBox(height: 14),
              CustomTextField(
                controller: _descCtrl,
                label: 'Deskripsi',
                hint: 'Jelaskan masalah Anda secara detail',
                maxLines: 4,
                validator: (v) =>
                    Validators.validateRequired(v, 'Deskripsi'),
              ),
              const SizedBox(height: 14),
              const Text('Kategori',
                  style: TextStyle(
                      fontWeight: FontWeight.w600, fontSize: 14)),
              const SizedBox(height: 6),
              DropdownButtonFormField<String>(
                initialValue: _category,
                items: AppConstants.categories
                    .map((c) =>
                    DropdownMenuItem(value: c, child: Text(c)))
                    .toList(),
                onChanged: (v) => setState(() => _category = v!),
                decoration:
                const InputDecoration(prefixIcon: Icon(Icons.category)),
              ),
              const SizedBox(height: 14),
              const Text('Prioritas',
                  style: TextStyle(
                      fontWeight: FontWeight.w600, fontSize: 14)),
              const SizedBox(height: 6),
              DropdownButtonFormField<String>(
                initialValue: _priority,
                items: ['Low', 'Medium', 'High']
                    .map((p) =>
                    DropdownMenuItem(value: p, child: Text(p)))
                    .toList(),
                onChanged: (v) => setState(() => _priority = v!),
                decoration:
                const InputDecoration(prefixIcon: Icon(Icons.flag)),
              ),
              const SizedBox(height: 14),
              const Text('Lampiran (Opsional)',
                  style: TextStyle(
                      fontWeight: FontWeight.w600, fontSize: 14)),
              const SizedBox(height: 6),
              InkWell(
                onTap: _showImageSourceSheet,
                child: Container(
                  height: 150,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardColor,
                    border: Border.all(color: Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: _attachment == null
                      ? const Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.cloud_upload,
                          size: 40, color: Colors.grey),
                      SizedBox(height: 6),
                      Text('Tap untuk upload gambar',
                          style: TextStyle(color: Colors.grey)),
                    ],
                  )
                      : ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child: Image.file(_attachment!,
                        fit: BoxFit.cover),
                  ),
                ),
              ),
              if (_attachment != null)
                TextButton.icon(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  label: const Text('Hapus',
                      style: TextStyle(color: Colors.red)),
                  onPressed: () => setState(() => _attachment = null),
                ),
              const SizedBox(height: 24),
              CustomButton(
                text: 'Kirim Tiket',
                onPressed: _submit,
                isLoading: _isLoading,
                icon: Icons.send,
              ),
            ],
          ),
        ),
      ),
    );
  }
}