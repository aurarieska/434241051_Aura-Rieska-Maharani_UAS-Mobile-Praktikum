import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/config/supabase_config.dart';
import '../models/ticket_model.dart';

class TicketRepository {
  final SupabaseClient _supabase = Supabase.instance.client;

  String get _ticketSelect => '''
    *,
    creator:profiles!tickets_created_by_fkey(id, full_name, role),
    assignee:profiles!tickets_assigned_to_fkey(id, full_name, role)
  ''';

  // ============== GET TICKETS ==============
  Future<List<TicketModel>> getAllTickets() async {
    final data = await _supabase
        .from('tickets')
        .select(_ticketSelect)
        .order('created_at', ascending: false);
    return (data as List).map((j) => TicketModel.fromJson(j)).toList();
  }

  Future<List<TicketModel>> getTicketsByUser(String userId) async {
    final data = await _supabase
        .from('tickets')
        .select(_ticketSelect)
        .eq('created_by', userId)
        .order('created_at', ascending: false);
    return (data as List).map((j) => TicketModel.fromJson(j)).toList();
  }

  Future<List<TicketModel>> getTicketsByHelpdesk(String helpdeskId) async {
    final data = await _supabase
        .from('tickets')
        .select(_ticketSelect)
        .eq('assigned_to', helpdeskId)
        .order('created_at', ascending: false);
    return (data as List).map((j) => TicketModel.fromJson(j)).toList();
  }

  // ============== GET BY ID ==============
  Future<TicketModel?> getTicketById(String id) async {
    final ticketData = await _supabase
        .from('tickets')
        .select(_ticketSelect)
        .eq('id', id)
        .maybeSingle();
    if (ticketData == null) return null;

    final commentsData = await _supabase
        .from('ticket_comments')
        .select('*, profiles:user_id(full_name, role)')
        .eq('ticket_id', id)
        .order('created_at');

    final historyData = await _supabase
        .from('ticket_history')
        .select('*, profiles:user_id(full_name, role)')
        .eq('ticket_id', id)
        .order('created_at');

    ticketData['ticket_comments'] = commentsData;
    ticketData['ticket_history'] = historyData;

    return TicketModel.fromJson(ticketData);
  }

  // ============== CREATE TICKET ==============
  Future<TicketModel?> createTicket({
    required String title,
    required String description,
    required String category,
    required String priority,
    required String createdBy,
    String? attachmentUrl,
  }) async {
    try {
      final inserted = await _supabase
          .from('tickets')
          .insert({
        'title': title,
        'description': description,
        'category': category,
        'priority': priority,
        'created_by': createdBy,
        'attachment_url': attachmentUrl,
      })
          .select(_ticketSelect)
          .single();

      await _supabase.from('ticket_history').insert({
        'ticket_id': inserted['id'],
        'user_id': createdBy,
        'action': 'Created',
        'description': 'Tiket dibuat',
      });

      final admins =
      await _supabase.from('profiles').select('id').eq('role', 'admin');
      final notifs = (admins as List)
          .map((a) => {
        'user_id': a['id'],
        'title': 'Tiket Baru',
        'message': 'Tiket ${inserted['ticket_number']} dibuat',
        'ticket_id': inserted['id'],
      })
          .toList();
      if (notifs.isNotEmpty) {
        await _supabase.from('notifications').insert(notifs);
      }

      return TicketModel.fromJson(inserted);
    } catch (e, stack) {
      // ignore: avoid_print
      print('❌ createTicket ERROR: $e');
      // ignore: avoid_print
      print('Stack: $stack');
      rethrow;
    }
  }

  // ============== UPLOAD ATTACHMENT ==============
  Future<String?> uploadAttachment(String userId, File file) async {
    try {
      final ext = p.extension(file.path);
      final filePath =
          '$userId/attachment_${DateTime.now().millisecondsSinceEpoch}$ext';

      await _supabase.storage
          .from(SupabaseConfig.attachmentsBucket)
          .upload(filePath, file);

      return _supabase.storage
          .from(SupabaseConfig.attachmentsBucket)
          .getPublicUrl(filePath);
    } catch (e) {
      // ignore: avoid_print
      print('❌ uploadAttachment ERROR: $e');
      rethrow;
    }
  }

  // ============== ASSIGN ==============
  Future<void> assignTicket({
    required String ticketId,
    required String helpdeskId,
    required String helpdeskName,
    required String adminId,
  }) async {
    await _supabase.from('tickets').update({
      'assigned_to': helpdeskId,
      'status': 'Assigned',
    }).eq('id', ticketId);

    await _supabase.from('ticket_history').insert({
      'ticket_id': ticketId,
      'user_id': adminId,
      'action': 'Assigned',
      'description': 'Tiket diassign ke $helpdeskName',
    });

    final ticket = await _supabase
        .from('tickets')
        .select('ticket_number, created_by')
        .eq('id', ticketId)
        .single();

    await _supabase.from('notifications').insert([
      {
        'user_id': helpdeskId,
        'title': 'Tiket Baru Diassign',
        'message': 'Anda mendapat tiket ${ticket['ticket_number']}',
        'ticket_id': ticketId,
      },
      {
        'user_id': ticket['created_by'],
        'title': 'Tiket Diassign',
        'message': 'Tiket ${ticket['ticket_number']} diassign ke $helpdeskName',
        'ticket_id': ticketId,
      },
    ]);
  }

  // ============== UPDATE STATUS ==============
  Future<void> updateStatus({
    required String ticketId,
    required String newStatus,
    required String userId,
    required String oldStatus,
  }) async {
    await _supabase.from('tickets').update({
      'status': newStatus,
    }).eq('id', ticketId);

    await _supabase.from('ticket_history').insert({
      'ticket_id': ticketId,
      'user_id': userId,
      'action': 'Status Changed',
      'description': 'Status diubah dari $oldStatus menjadi $newStatus',
    });

    final ticket = await _supabase
        .from('tickets')
        .select('ticket_number, created_by')
        .eq('id', ticketId)
        .single();

    await _supabase.from('notifications').insert({
      'user_id': ticket['created_by'],
      'title': 'Status Tiket Diupdate',
      'message': 'Tiket ${ticket['ticket_number']} status: $newStatus',
      'ticket_id': ticketId,
    });
  }

  // ============== ADD COMMENT ==============
  Future<void> addComment({
    required String ticketId,
    required String userId,
    required String message,
  }) async {
    await _supabase.from('ticket_comments').insert({
      'ticket_id': ticketId,
      'user_id': userId,
      'message': message,
    });

    await _supabase.from('ticket_history').insert({
      'ticket_id': ticketId,
      'user_id': userId,
      'action': 'Commented',
      'description': 'Menambahkan komentar',
    });
  }

  // ============== STATISTICS ==============
  Future<Map<String, int>> getStatistics(String userId, String role) async {
    List<TicketModel> tickets;
    if (role == 'admin') {
      tickets = await getAllTickets();
    } else if (role == 'helpdesk') {
      tickets = await getTicketsByHelpdesk(userId);
    } else {
      tickets = await getTicketsByUser(userId);
    }

    return {
      'total': tickets.length,
      'open': tickets.where((t) => t.status == 'Open').length,
      'assigned': tickets.where((t) => t.status == 'Assigned').length,
      'inProgress': tickets.where((t) => t.status == 'In Progress').length,
      'resolved': tickets.where((t) => t.status == 'Resolved').length,
      'closed': tickets.where((t) => t.status == 'Closed').length,
    };
  }
}