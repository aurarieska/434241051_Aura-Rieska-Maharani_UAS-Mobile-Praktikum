import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/notification_model.dart';

class NotificationRepository {
  final SupabaseClient _supabase = Supabase.instance.client;

  Future<List<NotificationModel>> getNotifications(String userId) async {
    final data = await _supabase
        .from('notifications')
        .select()
        .eq('user_id', userId)
        .order('created_at', ascending: false);
    return (data as List).map((j) => NotificationModel.fromJson(j)).toList();
  }

  Future<int> unreadCount(String userId) async {
    final data = await _supabase
        .from('notifications')
        .select('id')
        .eq('user_id', userId)
        .eq('is_read', false);
    return (data as List).length;
  }

  Future<void> markAsRead(String notificationId) async {
    await _supabase
        .from('notifications')
        .update({'is_read': true})
        .eq('id', notificationId);
  }
}