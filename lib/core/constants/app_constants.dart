class AppConstants {
  static const String appName = 'LaporKuy';

  // User Roles
  static const String roleUser = 'user';
  static const String roleAdmin = 'admin';
  static const String roleHelpdesk = 'helpdesk';

  // Ticket Status
  static const String statusOpen = 'Open';
  static const String statusAssigned = 'Assigned';
  static const String statusInProgress = 'In Progress';
  static const String statusResolved = 'Resolved';
  static const String statusClosed = 'Closed';

  // Ticket Priority
  static const String priorityLow = 'Low';
  static const String priorityMedium = 'Medium';
  static const String priorityHigh = 'High';

  // Ticket Category
  static const List<String> categories = [
    'Hardware',
    'Software',
    'Network',
    'Account',
    'Other',
  ];
}