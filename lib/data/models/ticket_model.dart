class TicketComment {
  final String id;
  final String ticketId;
  final String userId;
  final String userName;
  final String userRole;
  final String message;
  final DateTime createdAt;

  TicketComment({
    required this.id,
    required this.ticketId,
    required this.userId,
    required this.userName,
    required this.userRole,
    required this.message,
    required this.createdAt,
  });

  factory TicketComment.fromJson(Map<String, dynamic> json) {
    final profile = json['profiles'] as Map<String, dynamic>?;
    return TicketComment(
      id: json['id'] as String,
      ticketId: json['ticket_id'] as String,
      userId: json['user_id'] as String,
      userName: profile?['full_name'] as String? ?? 'Unknown',
      userRole: profile?['role'] as String? ?? 'user',
      message: json['message'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }
}

class TicketHistory {
  final String id;
  final String ticketId;
  final String userId;
  final String userName;
  final String action;
  final String description;
  final DateTime timestamp;

  TicketHistory({
    required this.id,
    required this.ticketId,
    required this.userId,
    required this.userName,
    required this.action,
    required this.description,
    required this.timestamp,
  });

  factory TicketHistory.fromJson(Map<String, dynamic> json) {
    final profile = json['profiles'] as Map<String, dynamic>?;
    return TicketHistory(
      id: json['id'] as String,
      ticketId: json['ticket_id'] as String,
      userId: json['user_id'] as String,
      userName: profile?['full_name'] as String? ?? 'Unknown',
      action: json['action'] as String,
      description: json['description'] as String,
      timestamp: DateTime.parse(json['created_at'] as String),
    );
  }
}

class TicketModel {
  final String id;
  final String ticketNumber;
  final String title;
  final String description;
  final String category;
  final String priority;
  final String status;
  final String createdBy;
  final String createdByName;
  final String? assignedTo;
  final String? assignedToName;
  final String? attachmentUrl;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<TicketComment> comments;
  final List<TicketHistory> history;

  TicketModel({
    required this.id,
    required this.ticketNumber,
    required this.title,
    required this.description,
    required this.category,
    required this.priority,
    required this.status,
    required this.createdBy,
    required this.createdByName,
    this.assignedTo,
    this.assignedToName,
    this.attachmentUrl,
    required this.createdAt,
    required this.updatedAt,
    this.comments = const [],
    this.history = const [],
  });

  factory TicketModel.fromJson(Map<String, dynamic> json) {
    final creator = json['creator'] as Map<String, dynamic>?;
    final assignee = json['assignee'] as Map<String, dynamic>?;

    return TicketModel(
      id: json['id'] as String,
      ticketNumber: json['ticket_number'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      category: json['category'] as String,
      priority: json['priority'] as String,
      status: json['status'] as String,
      createdBy: json['created_by'] as String,
      createdByName: creator?['full_name'] as String? ?? 'Unknown',
      assignedTo: json['assigned_to'] as String?,
      assignedToName: assignee?['full_name'] as String?,
      attachmentUrl: json['attachment_url'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      comments: (json['ticket_comments'] as List?)
          ?.map((c) => TicketComment.fromJson(c as Map<String, dynamic>))
          .toList() ??
          [],
      history: (json['ticket_history'] as List?)
          ?.map((h) => TicketHistory.fromJson(h as Map<String, dynamic>))
          .toList() ??
          [],
    );
  }
}