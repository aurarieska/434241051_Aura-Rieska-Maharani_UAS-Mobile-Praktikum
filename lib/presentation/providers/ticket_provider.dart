import 'dart:io';
import 'package:flutter/material.dart';
import '../../data/models/ticket_model.dart';
import '../../data/repositories/ticket_repository.dart';

class TicketProvider extends ChangeNotifier {
  final TicketRepository _repo = TicketRepository();
  List<TicketModel> _tickets = [];
  Map<String, int> _stats = {};
  bool _isLoading = false;

  List<TicketModel> get tickets => _tickets;
  Map<String, int> get stats => _stats;
  bool get isLoading => _isLoading;

  Future<void> loadTickets(String userId, String role) async {
    _isLoading = true;
    notifyListeners();
    try {
      if (role == 'admin') {
        _tickets = await _repo.getAllTickets();
      } else if (role == 'helpdesk') {
        _tickets = await _repo.getTicketsByHelpdesk(userId);
      } else {
        _tickets = await _repo.getTicketsByUser(userId);
      }
      _stats = await _repo.getStatistics(userId, role);
    } catch (e) {
      debugPrint('Load tickets error: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<TicketModel?> getTicketById(String id) => _repo.getTicketById(id);

  Future<bool> createTicket({
    required String title,
    required String description,
    required String category,
    required String priority,
    required String createdBy,
    File? attachmentFile,
  }) async {
    try {
      String? attachmentUrl;
      if (attachmentFile != null) {
        attachmentUrl = await _repo.uploadAttachment(createdBy, attachmentFile);
      }
      final t = await _repo.createTicket(
        title: title,
        description: description,
        category: category,
        priority: priority,
        createdBy: createdBy,
        attachmentUrl: attachmentUrl,
      );
      return t != null;
    } catch (e) {
      debugPrint('🔥 Create ticket error: $e');
      return false;
    }
  }

  Future<void> assignTicket({
    required String ticketId,
    required String helpdeskId,
    required String helpdeskName,
    required String adminId,
  }) async {
    await _repo.assignTicket(
      ticketId: ticketId,
      helpdeskId: helpdeskId,
      helpdeskName: helpdeskName,
      adminId: adminId,
    );
    notifyListeners();
  }

  Future<void> updateStatus({
    required String ticketId,
    required String newStatus,
    required String oldStatus,
    required String userId,
  }) async {
    await _repo.updateStatus(
      ticketId: ticketId,
      newStatus: newStatus,
      oldStatus: oldStatus,
      userId: userId,
    );
    notifyListeners();
  }

  Future<void> addComment({
    required String ticketId,
    required String userId,
    required String message,
  }) async {
    await _repo.addComment(
      ticketId: ticketId,
      userId: userId,
      message: message,
    );
    notifyListeners();
  }
}