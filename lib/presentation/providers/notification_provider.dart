import 'package:flutter/material.dart';
import '../../data/models/notification_model.dart';
import '../../data/repositories/notification_repository.dart';

class NotificationProvider extends ChangeNotifier {
  final NotificationRepository _repo = NotificationRepository();
  List<NotificationModel> _notifications = [];
  int _unreadCount = 0;

  List<NotificationModel> get notifications => _notifications;
  int get unreadCount => _unreadCount;

  Future<void> loadNotifications(String userId) async {
    _notifications = await _repo.getNotifications(userId);
    _unreadCount = await _repo.unreadCount(userId);
    notifyListeners();
  }

  Future<void> markAsRead(String notificationId) async {
    await _repo.markAsRead(notificationId);
    notifyListeners();
  }
}