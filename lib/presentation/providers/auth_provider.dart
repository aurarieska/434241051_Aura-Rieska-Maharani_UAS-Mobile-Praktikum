import 'dart:io';
import 'package:flutter/material.dart';
import '../../data/models/user_model.dart';
import '../../data/repositories/auth_repository.dart';

class AuthProvider extends ChangeNotifier {
  final AuthRepository _repo = AuthRepository();
  UserModel? _currentUser;
  bool _isLoading = false;

  UserModel? get currentUser => _currentUser;
  bool get isLoggedIn => _currentUser != null;
  bool get isLoading => _isLoading;
  AuthRepository get repository => _repo;

  Future<bool> checkSession() async {
    final authUser = _repo.authUser;
    if (authUser == null) return false;
    _currentUser = await _repo.getProfile(authUser.id);
    notifyListeners();
    return _currentUser != null;
  }

  Future<bool> login(String email, String password) async {
    _isLoading = true;
    notifyListeners();
    try {
      _currentUser = await _repo.login(email, password);
      return _currentUser != null;
    } catch (e) {
      debugPrint('Login error: $e');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> logout() async {
    await _repo.logout();
    _currentUser = null;
    notifyListeners();
  }

  Future<bool> register({
    required String username,
    required String email,
    required String password,
    required String fullName,
    String? phone,
  }) async {
    _isLoading = true;
    notifyListeners();
    try {
      final user = await _repo.register(
        username: username,
        email: email,
        password: password,
        fullName: fullName,
        phone: phone,
      );
      return user != null;
    } catch (e) {
      debugPrint('Register error: $e');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<Map<String, dynamic>> resetPassword({
    required String email,
    required String oldPassword,
    required String newPassword,
  }) async {
    return await _repo.resetPasswordWithOld(
      email: email,
      oldPassword: oldPassword,
      newPassword: newPassword,
    );
  }

  Future<bool> updateProfile({
    String? fullName,
    String? email,
    String? phone,
    File? photoFile,
  }) async {
    if (_currentUser == null) return false;
    try {
      String? photoUrl;
      if (photoFile != null) {
        photoUrl = await _repo.uploadAvatar(_currentUser!.id, photoFile);
      }
      _currentUser = await _repo.updateProfile(
        userId: _currentUser!.id,
        fullName: fullName,
        email: email,
        phone: phone,
        photoUrl: photoUrl,
      );
      notifyListeners();
      return _currentUser != null;
    } catch (e) {
      debugPrint('Update profile error: $e');
      return false;
    }
  }

  Future<bool> changePassword(String newPassword) async {
    return await _repo.changePassword(newPassword);
  }

  Future<List<UserModel>> getAllUsers() async {
    return await _repo.getAllUsers();
  }

  Future<bool> updateUserRole({
    required String userId,
    required String newRole,
  }) async {
    return await _repo.updateUserRole(
      userId: userId,
      newRole: newRole,
    );
  }
}