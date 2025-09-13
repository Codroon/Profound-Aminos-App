class Ticket {
  final String id;
  final String subject;
  final String status;
  final String priority;
  final DateTime createdAt;
  final DateTime updatedAt;
  final Customer customer;
  final User? assignee;
  final List<String> tags;
  final int messageCount;
  final DateTime? lastMessageAt;
  final String? lastMessagePreview;
  final bool isUnread;
  final String channel;
  final String? language;
  final Map<String, dynamic>? customFields;

  const Ticket({
    required this.id,
    required this.subject,
    required this.status,
    required this.priority,
    required this.createdAt,
    required this.updatedAt,
    required this.customer,
    this.assignee,
    required this.tags,
    required this.messageCount,
    this.lastMessageAt,
    this.lastMessagePreview,
    required this.isUnread,
    required this.channel,
    this.language,
    this.customFields,
  });

  // Getter methods for backward compatibility
  User? get assignedUser => assignee;
  String? get assignedUserId => assignee?.id;

  factory Ticket.fromJson(Map<String, dynamic> json) {
    return Ticket(
      id: json['id']?.toString() ?? '',
      subject: json['subject'] ?? '',
      status: json['status'] ?? 'open',
      priority: json['priority'] ?? 'normal',
      createdAt: DateTime.tryParse(json['created_datetime'] ?? '') ?? DateTime.now(),
      updatedAt: DateTime.tryParse(json['updated_datetime'] ?? '') ?? DateTime.now(),
      customer: Customer.fromJson(json['customer'] ?? {}),
      assignee: json['assignee_user'] != null 
          ? User.fromJson(json['assignee_user']) 
          : null,
      tags: (json['tags'] as List<dynamic>?)?.map((tag) => 
          tag is Map ? (tag['name'] ?? '').toString() : tag.toString()
      ).toList() ?? [],
      messageCount: json['messages_count'] ?? 0,
      lastMessageAt: json['last_message_datetime'] != null 
          ? DateTime.tryParse(json['last_message_datetime']) 
          : null,
      lastMessagePreview: json['last_message_body_text'],
      isUnread: json['is_unread'] ?? false,
      channel: json['channel'] ?? 'email',
      language: json['language'],
      customFields: json['custom_fields'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'subject': subject,
      'status': status,
      'priority': priority,
      'created_datetime': createdAt.toIso8601String(),
      'updated_datetime': updatedAt.toIso8601String(),
      'customer': customer.toJson(),
      'assignee_user': assignee?.toJson(),
      'tags': tags.map((tag) => {'name': tag}).toList(),
      'messages_count': messageCount,
      'last_message_datetime': lastMessageAt?.toIso8601String(),
      'last_message_body_text': lastMessagePreview,
      'is_unread': isUnread,
      'channel': channel,
      'language': language,
      'custom_fields': customFields,
    };
  }

  Ticket copyWith({
    String? id,
    String? subject,
    String? status,
    String? priority,
    DateTime? createdAt,
    DateTime? updatedAt,
    Customer? customer,
    User? assignee,
    List<String>? tags,
    int? messageCount,
    DateTime? lastMessageAt,
    String? lastMessagePreview,
    bool? isUnread,
    String? channel,
    String? language,
    Map<String, dynamic>? customFields,
  }) {
    return Ticket(
      id: id ?? this.id,
      subject: subject ?? this.subject,
      status: status ?? this.status,
      priority: priority ?? this.priority,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      customer: customer ?? this.customer,
      assignee: assignee ?? this.assignee,
      tags: tags ?? this.tags,
      messageCount: messageCount ?? this.messageCount,
      lastMessageAt: lastMessageAt ?? this.lastMessageAt,
      lastMessagePreview: lastMessagePreview ?? this.lastMessagePreview,
      isUnread: isUnread ?? this.isUnread,
      channel: channel ?? this.channel,
      language: language ?? this.language,
      customFields: customFields ?? this.customFields,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Ticket && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'Ticket(id: $id, subject: $subject, status: $status)';
  }

  // Helper methods
  bool get isOpen => status == 'open';
  bool get isClosed => status == 'closed';
  bool get isPending => status == 'pending';
  bool get isSpam => status == 'spam';
  
  bool get isHighPriority => priority == 'high' || priority == 'urgent';
  bool get isLowPriority => priority == 'low';
  
  String get statusDisplayName {
    switch (status.toLowerCase()) {
      case 'open':
        return 'Open';
      case 'closed':
        return 'Closed';
      case 'pending':
        return 'Pending';
      case 'spam':
        return 'Spam';
      default:
        return status;
    }
  }
  
  String get priorityDisplayName {
    switch (priority.toLowerCase()) {
      case 'low':
        return 'Low';
      case 'normal':
        return 'Normal';
      case 'high':
        return 'High';
      case 'urgent':
        return 'Urgent';
      default:
        return priority;
    }
  }
}

class Customer {
  final String id;
  final String name;
  final String email;
  final String? phone;
  final String? avatar;
  final DateTime? createdAt;
  final Map<String, dynamic>? customFields;

  const Customer({
    required this.id,
    required this.name,
    required this.email,
    this.phone,
    this.avatar,
    this.createdAt,
    this.customFields,
  });

  factory Customer.fromJson(Map<String, dynamic> json) {
    return Customer(
      id: json['id']?.toString() ?? '',
      name: json['name'] ?? json['email'] ?? 'Unknown Customer',
      email: json['email'] ?? '',
      phone: json['phone'],
      avatar: json['avatar'],
      createdAt: json['created_datetime'] != null 
          ? DateTime.tryParse(json['created_datetime']) 
          : null,
      customFields: json['custom_fields'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'phone': phone,
      'avatar': avatar,
      'created_datetime': createdAt?.toIso8601String(),
      'custom_fields': customFields,
    };
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Customer && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'Customer(id: $id, name: $name, email: $email)';
  }
}

class User {
  final String id;
  final String name;
  final String email;
  final String? avatar;
  final String role;
  final bool isActive;
  final DateTime? createdAt;

  const User({
    required this.id,
    required this.name,
    required this.email,
    this.avatar,
    required this.role,
    required this.isActive,
    this.createdAt,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id']?.toString() ?? '',
      name: json['name'] ?? json['firstname'] ?? 'Unknown User',
      email: json['email'] ?? '',
      avatar: json['avatar'],
      role: json['role'] ?? 'agent',
      isActive: json['active'] ?? true,
      createdAt: json['created_datetime'] != null 
          ? DateTime.tryParse(json['created_datetime']) 
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'avatar': avatar,
      'role': role,
      'active': isActive,
      'created_datetime': createdAt?.toIso8601String(),
    };
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is User && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'User(id: $id, name: $name, email: $email)';
  }

  // Helper methods
  bool get isAdmin => role == 'admin';
  bool get isAgent => role == 'agent';
  bool get isOwner => role == 'owner';
  
  String get displayName => name.isNotEmpty ? name : email;
  String get initials {
    final parts = name.split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    } else if (parts.isNotEmpty && parts[0].isNotEmpty) {
      return parts[0][0].toUpperCase();
    } else {
      return email.isNotEmpty ? email[0].toUpperCase() : '?';
    }
  }
}