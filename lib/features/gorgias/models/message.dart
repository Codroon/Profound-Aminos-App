class Message {
  final String id;
  final String ticketId;
  final String bodyText;
  final String? bodyHtml;
  final bool fromAgent;
  final String channel;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final MessageSender sender;
  final List<MessageAttachment> attachments;
  final bool isInternal;
  final String? via;
  final Map<String, dynamic>? metadata;
  final MessageStatus status;

  const Message({
    required this.id,
    required this.ticketId,
    required this.bodyText,
    this.bodyHtml,
    required this.fromAgent,
    required this.channel,
    required this.createdAt,
    this.updatedAt,
    required this.sender,
    required this.attachments,
    required this.isInternal,
    this.via,
    this.metadata,
    required this.status,
  });

  // Getter for formatted time
  String get formattedTime {
    final now = DateTime.now();
    final difference = now.difference(createdAt);
    
    if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }

  factory Message.fromJson(Map<String, dynamic> json) {
    return Message(
      id: json['id']?.toString() ?? '',
      ticketId: json['ticket_id']?.toString() ?? '',
      bodyText: json['body_text'] ?? '',
      bodyHtml: json['body_html'],
      fromAgent: json['from_agent'] ?? false,
      channel: json['channel'] ?? 'email',
      createdAt: DateTime.tryParse(json['created_datetime'] ?? '') ?? DateTime.now(),
      updatedAt: json['updated_datetime'] != null 
          ? DateTime.tryParse(json['updated_datetime']) 
          : null,
      sender: MessageSender.fromJson(json['sender'] ?? {}),
      attachments: (json['attachments'] as List<dynamic>?)?.map((attachment) => 
          MessageAttachment.fromJson(attachment)
      ).toList() ?? [],
      isInternal: json['channel'] == 'internal-note' || json['is_internal'] == true,
      via: json['via'],
      metadata: json['meta'],
      status: MessageStatus.fromString(json['status'] ?? 'sent'),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'ticket_id': ticketId,
      'body_text': bodyText,
      'body_html': bodyHtml,
      'from_agent': fromAgent,
      'channel': channel,
      'created_datetime': createdAt.toIso8601String(),
      'updated_datetime': updatedAt?.toIso8601String(),
      'sender': sender.toJson(),
      'attachments': attachments.map((attachment) => attachment.toJson()).toList(),
      'is_internal': isInternal,
      'via': via,
      'meta': metadata,
      'status': status.toString(),
    };
  }

  Message copyWith({
    String? id,
    String? ticketId,
    String? bodyText,
    String? bodyHtml,
    bool? fromAgent,
    String? channel,
    DateTime? createdAt,
    DateTime? updatedAt,
    MessageSender? sender,
    List<MessageAttachment>? attachments,
    bool? isInternal,
    String? via,
    Map<String, dynamic>? metadata,
    MessageStatus? status,
  }) {
    return Message(
      id: id ?? this.id,
      ticketId: ticketId ?? this.ticketId,
      bodyText: bodyText ?? this.bodyText,
      bodyHtml: bodyHtml ?? this.bodyHtml,
      fromAgent: fromAgent ?? this.fromAgent,
      channel: channel ?? this.channel,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      sender: sender ?? this.sender,
      attachments: attachments ?? this.attachments,
      isInternal: isInternal ?? this.isInternal,
      via: via ?? this.via,
      metadata: metadata ?? this.metadata,
      status: status ?? this.status,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Message && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'Message(id: $id, ticketId: $ticketId, fromAgent: $fromAgent)';
  }

  // Helper methods
  bool get isFromCustomer => !fromAgent;
  bool get hasAttachments => attachments.isNotEmpty;
  bool get isEmail => channel == 'email';
  bool get isChat => channel == 'chat';
  bool get isSms => channel == 'sms';
  bool get isNote => channel == 'internal-note' || isInternal;
  
  String get displayText {
    if (bodyText.length > 100) {
      return '${bodyText.substring(0, 100)}...';
    }
    return bodyText;
  }
  
  String get channelDisplayName {
    switch (channel.toLowerCase()) {
      case 'email':
        return 'Email';
      case 'chat':
        return 'Chat';
      case 'sms':
        return 'SMS';
      case 'internal-note':
        return 'Internal Note';
      case 'facebook':
        return 'Facebook';
      case 'twitter':
        return 'Twitter';
      case 'instagram':
        return 'Instagram';
      default:
        return channel;
    }
  }
}

class MessageSender {
  final String id;
  final String name;
  final String email;
  final String? avatar;
  final String type; // 'customer', 'agent', 'system'

  const MessageSender({
    required this.id,
    required this.name,
    required this.email,
    this.avatar,
    required this.type,
  });

  factory MessageSender.fromJson(Map<String, dynamic> json) {
    return MessageSender(
      id: json['id']?.toString() ?? '',
      name: json['name'] ?? json['email'] ?? 'Unknown',
      email: json['email'] ?? '',
      avatar: json['avatar'],
      type: json['type'] ?? 'customer',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'avatar': avatar,
      'type': type,
    };
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is MessageSender && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'MessageSender(id: $id, name: $name, type: $type)';
  }

  // Helper methods
  bool get isAgent => type == 'agent';
  bool get isCustomer => type == 'customer';
  bool get isSystem => type == 'system';
  
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

class MessageAttachment {
  final String id;
  final String name;
  final String url;
  final String contentType;
  final int size;
  final DateTime? createdAt;

  const MessageAttachment({
    required this.id,
    required this.name,
    required this.url,
    required this.contentType,
    required this.size,
    this.createdAt,
  });

  factory MessageAttachment.fromJson(Map<String, dynamic> json) {
    return MessageAttachment(
      id: json['id']?.toString() ?? '',
      name: json['name'] ?? 'attachment',
      url: json['url'] ?? '',
      contentType: json['content_type'] ?? 'application/octet-stream',
      size: json['size'] ?? 0,
      createdAt: json['created_datetime'] != null 
          ? DateTime.tryParse(json['created_datetime']) 
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'url': url,
      'content_type': contentType,
      'size': size,
      'created_datetime': createdAt?.toIso8601String(),
    };
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is MessageAttachment && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'MessageAttachment(id: $id, name: $name, size: $size)';
  }

  // Helper methods
  bool get isImage => contentType.startsWith('image/');
  bool get isDocument => contentType.startsWith('application/');
  bool get isVideo => contentType.startsWith('video/');
  bool get isAudio => contentType.startsWith('audio/');
  
  String get sizeFormatted {
    if (size < 1024) {
      return '${size}B';
    } else if (size < 1024 * 1024) {
      return '${(size / 1024).toStringAsFixed(1)}KB';
    } else {
      return '${(size / (1024 * 1024)).toStringAsFixed(1)}MB';
    }
  }
  
  String get fileExtension {
    final parts = name.split('.');
    return parts.length > 1 ? parts.last.toLowerCase() : '';
  }
}

enum MessageStatus {
  draft,
  sending,
  sent,
  delivered,
  failed,
  bounced;

  static MessageStatus fromString(String status) {
    switch (status.toLowerCase()) {
      case 'draft':
        return MessageStatus.draft;
      case 'sending':
        return MessageStatus.sending;
      case 'sent':
        return MessageStatus.sent;
      case 'delivered':
        return MessageStatus.delivered;
      case 'failed':
        return MessageStatus.failed;
      case 'bounced':
        return MessageStatus.bounced;
      default:
        return MessageStatus.sent;
    }
  }

  @override
  String toString() {
    switch (this) {
      case MessageStatus.draft:
        return 'draft';
      case MessageStatus.sending:
        return 'sending';
      case MessageStatus.sent:
        return 'sent';
      case MessageStatus.delivered:
        return 'delivered';
      case MessageStatus.failed:
        return 'failed';
      case MessageStatus.bounced:
        return 'bounced';
    }
  }

  String get displayName {
    switch (this) {
      case MessageStatus.draft:
        return 'Draft';
      case MessageStatus.sending:
        return 'Sending';
      case MessageStatus.sent:
        return 'Sent';
      case MessageStatus.delivered:
        return 'Delivered';
      case MessageStatus.failed:
        return 'Failed';
      case MessageStatus.bounced:
        return 'Bounced';
    }
  }

  bool get isSuccessful => this == MessageStatus.sent || this == MessageStatus.delivered;
  bool get isFailed => this == MessageStatus.failed || this == MessageStatus.bounced;
  bool get isPending => this == MessageStatus.draft || this == MessageStatus.sending;
}