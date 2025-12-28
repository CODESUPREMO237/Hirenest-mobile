// ============================================================================
// NOTIFICATION PREFERENCES MODEL
// lib/features/profile/data/models/notification_preferences_model.dart
// ============================================================================

class NotificationPreferences {
  final bool email;
  final bool push;
  final bool sms;
  final bool jobAlerts;
  final bool chatMessages;
  final bool marketingEmails;

  NotificationPreferences({
    required this.email,
    required this.push,
    required this.sms,
    required this.jobAlerts,
    required this.chatMessages,
    required this.marketingEmails,
  });

  factory NotificationPreferences.fromJson(Map<String, dynamic> json) {
    return NotificationPreferences(
      email: json['email'] ?? true,
      push: json['push'] ?? true,
      sms: json['sms'] ?? false,
      jobAlerts: json['jobAlerts'] ?? true,
      chatMessages: json['chatMessages'] ?? true,
      marketingEmails: json['marketingEmails'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'email': email,
      'push': push,
      'sms': sms,
      'jobAlerts': jobAlerts,
      'chatMessages': chatMessages,
      'marketingEmails': marketingEmails,
    };
  }

  NotificationPreferences copyWith({
    bool? email,
    bool? push,
    bool? sms,
    bool? jobAlerts,
    bool? chatMessages,
    bool? marketingEmails,
  }) {
    return NotificationPreferences(
      email: email ?? this.email,
      push: push ?? this.push,
      sms: sms ?? this.sms,
      jobAlerts: jobAlerts ?? this.jobAlerts,
      chatMessages: chatMessages ?? this.chatMessages,
      marketingEmails: marketingEmails ?? this.marketingEmails,
    );
  }
}