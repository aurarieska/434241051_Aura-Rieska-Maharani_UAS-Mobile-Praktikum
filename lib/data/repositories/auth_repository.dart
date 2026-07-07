import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/config/supabase_config.dart';
import '../models/user_model.dart';

class AuthRepository {
  final SupabaseClient _supabase = Supabase.instance.client;

  User? get authUser => _supabase.auth.currentUser;

  // ============== LOGIN ==============
  Future<UserModel?> login(String email, String password) async {
    final response = await _supabase.auth.signInWithPassword(
      email: email,
      password: password,
    );
    if (response.user == null) return null;
    return await getProfile(response.user!.id);
  }

  // ============== LOGOUT ==============
  Future<void> logout() async {
    await _supabase.auth.signOut();
  }

  // ============== REGISTER ==============
  Future<UserModel?> register({
    required String username,
    required String email,
    required String password,
    required String fullName,
    String? phone,
  }) async {
    final response = await _supabase.auth.signUp(
      email: email,
      password: password,
      data: {
        'username': username,
        'full_name': fullName,
        'phone': phone ?? '',
        'role': 'user',
      },
    );
    if (response.user == null) return null;

    // Wait sebentar agar trigger jalan
    await Future.delayed(const Duration(milliseconds: 800));

    return await getProfile(response.user!.id);
  }

  // ============== RESET PASSWORD (dengan verifikasi password lama) ==============
  Future<Map<String, dynamic>> resetPasswordWithOld({
    required String email,
    required String oldPassword,
    required String newPassword,
  }) async {
    try {
      final response = await _supabase.rpc(
        'reset_password_with_old',
        params: {
          'user_email': email.toLowerCase().trim(),
          'old_password': oldPassword,
          'new_password': newPassword,
        },
      );
      return Map<String, dynamic>.from(response as Map);
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  // ============== GET PROFILE ==============
  Future<UserModel?> getProfile(String userId) async {
    try {
      final data = await _supabase
          .from('profiles')
          .select()
          .eq('id', userId)
          .maybeSingle();
      if (data == null) return null;
      return UserModel.fromJson(data);
    } catch (e) {
      return null;
    }
  }

  // ============== UPDATE PROFILE ==============
  Future<UserModel?> updateProfile({
    required String userId,
    String? fullName,
    String? email,
    String? phone,
    String? photoUrl,
  }) async {
    final updates = <String, dynamic>{};
    if (fullName != null) updates['full_name'] = fullName;
    if (email != null) updates['email'] = email;
    if (phone != null) updates['phone'] = phone;
    if (photoUrl != null) updates['photo_url'] = photoUrl;

    await _supabase.from('profiles').update(updates).eq('id', userId);
    return await getProfile(userId);
  }

  // ============== UPLOAD AVATAR ==============
  Future<String?> uploadAvatar(String userId, File file) async {
    final ext = p.extension(file.path);
    final filePath = '$userId/avatar_${DateTime.now().millisecondsSinceEpoch}$ext';

    await _supabase.storage
        .from(SupabaseConfig.avatarsBucket)
        .upload(filePath, file, fileOptions: const FileOptions(upsert: true));

    return _supabase.storage
        .from(SupabaseConfig.avatarsBucket)
        .getPublicUrl(filePath);
  }

  // ============== CHANGE PASSWORD ==============
  Future<bool> changePassword(String newPassword) async {
    try {
      await _supabase.auth.updateUser(
        UserAttributes(password: newPassword),
      );
      return true;
    } catch (e) {
      return false;
    }
  }

  // ============== GET ALL HELPDESK ==============
  Future<List<UserModel>> getHelpdeskList() async {
    final data = await _supabase
        .from('profiles')
        .select()
        .eq('role', 'helpdesk');
    return (data as List).map((j) => UserModel.fromJson(j)).toList();
  }

  // ============== GET ALL USERS (untuk admin) ==============
  Future<List<UserModel>> getAllUsers() async {
    final data = await _supabase
        .from('profiles')
        .select()
        .order('created_at', ascending: false);
    return (data as List).map((j) => UserModel.fromJson(j)).toList();
  }

  // ============== UPDATE ROLE (admin only) ==============
  Future<bool> updateUserRole({
    required String userId,
    required String newRole,
  }) async {
    try {
      await _supabase
          .from('profiles')
          .update({'role': newRole})
          .eq('id', userId);
      return true;
    } catch (e) {
      // ignore: avoid_print
      print('❌ updateUserRole ERROR: $e');
      return false;
    }
  }
}