// Export all Gorgias models
export 'ticket.dart';
export 'message.dart';
import 'ticket.dart';
import 'message.dart';
// Additional models for Gorgias feature
class TicketStats {
  final int totalTickets;
  final int openTickets;
  final int closedTickets;
  final int pendingTickets;
  final int unassignedTickets;
  final double averageResponseTime; // in hours
  final double averageResolutionTime; // in hours
  final int todayTickets;
  final int weekTickets;
  final int monthTickets;
  final Map<String, int> ticketsByStatus;
  final Map<String, int> ticketsByPriority;
  final Map<String, int> ticketsByChannel;
  final List<TicketTrend> trends;

  const TicketStats({
    required this.totalTickets,
    required this.openTickets,
    required this.closedTickets,
    required this.pendingTickets,
    required this.unassignedTickets,
    required this.averageResponseTime,
    required this.averageResolutionTime,
    required this.todayTickets,
    required this.weekTickets,
    required this.monthTickets,
    required this.ticketsByStatus,
    required this.ticketsByPriority,
    required this.ticketsByChannel,
    required this.trends,
  });

  factory TicketStats.fromJson(Map<String, dynamic> json) {
    return TicketStats(
      totalTickets: json['total_tickets'] ?? 0,
      openTickets: json['open_tickets'] ?? 0,
      closedTickets: json['closed_tickets'] ?? 0,
      pendingTickets: json['pending_tickets'] ?? 0,
      unassignedTickets: json['unassigned_tickets'] ?? 0,
      averageResponseTime: (json['avg_response_time'] ?? 0).toDouble(),
      averageResolutionTime: (json['avg_resolution_time'] ?? 0).toDouble(),
      todayTickets: json['today_tickets'] ?? 0,
      weekTickets: json['week_tickets'] ?? 0,
      monthTickets: json['month_tickets'] ?? 0,
      ticketsByStatus: Map<String, int>.from(json['tickets_by_status'] ?? {}),
      ticketsByPriority: Map<String, int>.from(json['tickets_by_priority'] ?? {}),
      ticketsByChannel: Map<String, int>.from(json['tickets_by_channel'] ?? {}),
      trends: (json['trends'] as List<dynamic>?)?.map((trend) => 
          TicketTrend.fromJson(trend)
      ).toList() ?? [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'total_tickets': totalTickets,
      'open_tickets': openTickets,
      'closed_tickets': closedTickets,
      'pending_tickets': pendingTickets,
      'unassigned_tickets': unassignedTickets,
      'avg_response_time': averageResponseTime,
      'avg_resolution_time': averageResolutionTime,
      'today_tickets': todayTickets,
      'week_tickets': weekTickets,
      'month_tickets': monthTickets,
      'tickets_by_status': ticketsByStatus,
      'tickets_by_priority': ticketsByPriority,
      'tickets_by_channel': ticketsByChannel,
      'trends': trends.map((trend) => trend.toJson()).toList(),
    };
  }

  // Helper methods
  double get closureRate {
    if (totalTickets == 0) return 0.0;
    return (closedTickets / totalTickets) * 100;
  }

  double get responseTimeInMinutes => averageResponseTime * 60;
  double get resolutionTimeInHours => averageResolutionTime;
  
  String get responseTimeFormatted {
    if (averageResponseTime < 1) {
      return '${(averageResponseTime * 60).toInt()} min';
    } else if (averageResponseTime < 24) {
      return '${averageResponseTime.toStringAsFixed(1)} hrs';
    } else {
      return '${(averageResponseTime / 24).toStringAsFixed(1)} days';
    }
  }
  
  String get resolutionTimeFormatted {
    if (averageResolutionTime < 24) {
      return '${averageResolutionTime.toStringAsFixed(1)} hrs';
    } else {
      return '${(averageResolutionTime / 24).toStringAsFixed(1)} days';
    }
  }
}

class TicketTrend {
  final DateTime date;
  final int count;
  final String type; // 'created', 'closed', 'resolved'

  const TicketTrend({
    required this.date,
    required this.count,
    required this.type,
  });

  factory TicketTrend.fromJson(Map<String, dynamic> json) {
    return TicketTrend(
      date: DateTime.tryParse(json['date'] ?? '') ?? DateTime.now(),
      count: json['count'] ?? 0,
      type: json['type'] ?? 'created',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'date': date.toIso8601String().split('T')[0],
      'count': count,
      'type': type,
    };
  }
}

class TicketFilter {
  final String? status;
  final String? priority;
  final String? assigneeId;
  final String? channel;
  final List<String>? tags;
  final DateTime? createdAfter;
  final DateTime? createdBefore;
  final DateTime? updatedAfter;
  final DateTime? updatedBefore;
  final String? customerId;
  final String? searchQuery;
  final String? sortBy;
  final String? sortOrder;
  final int page;
  final int perPage;

  const TicketFilter({
    this.status,
    this.priority,
    this.assigneeId,
    this.channel,
    this.tags,
    this.createdAfter,
    this.createdBefore,
    this.updatedAfter,
    this.updatedBefore,
    this.customerId,
    this.searchQuery,
    this.sortBy,
    this.sortOrder,
    this.page = 1,
    this.perPage = 20,
  });

  static const Object _sentinel = Object();

  TicketFilter copyWith({
    Object? status = _sentinel,
    Object? priority = _sentinel,
    Object? assigneeId = _sentinel,
    Object? channel = _sentinel,
    Object? tags = _sentinel,
    Object? createdAfter = _sentinel,
    Object? createdBefore = _sentinel,
    Object? updatedAfter = _sentinel,
    Object? updatedBefore = _sentinel,
    Object? customerId = _sentinel,
    Object? searchQuery = _sentinel,
    Object? sortBy = _sentinel,
    Object? sortOrder = _sentinel,
    int? page,
    int? perPage,
  }) {
    return TicketFilter(
      status: status == _sentinel ? this.status : (status as String?),
      priority: priority == _sentinel ? this.priority : (priority as String?),
      assigneeId: assigneeId == _sentinel ? this.assigneeId : (assigneeId as String?),
      channel: channel == _sentinel ? this.channel : (channel as String?),
      tags: tags == _sentinel ? this.tags : (tags as List<String>?),
      createdAfter: createdAfter == _sentinel ? this.createdAfter : (createdAfter as DateTime?),
      createdBefore: createdBefore == _sentinel ? this.createdBefore : (createdBefore as DateTime?),
      updatedAfter: updatedAfter == _sentinel ? this.updatedAfter : (updatedAfter as DateTime?),
      updatedBefore: updatedBefore == _sentinel ? this.updatedBefore : (updatedBefore as DateTime?),
      customerId: customerId == _sentinel ? this.customerId : (customerId as String?),
      searchQuery: searchQuery == _sentinel ? this.searchQuery : (searchQuery as String?),
      sortBy: sortBy == _sentinel ? this.sortBy : (sortBy as String?),
      sortOrder: sortOrder == _sentinel ? this.sortOrder : (sortOrder as String?),
      page: page ?? this.page,
      perPage: perPage ?? this.perPage,
    );
  }

  Map<String, String> toQueryParams() {
    final params = <String, String>{
      'page': page.toString(),
      'per_page': perPage.toString(),
    };

    if (status != null && status!.isNotEmpty && status != 'all') {
      params['status'] = status!;
    }
    if (priority != null && priority!.isNotEmpty) {
      params['priority'] = priority!;
    }
    if (assigneeId != null && assigneeId!.isNotEmpty) {
      params['assigned_user_id'] = assigneeId!;
    }
    if (channel != null && channel!.isNotEmpty) {
      params['channel'] = channel!;
    }
    if (tags != null && tags!.isNotEmpty) {
      params['tags'] = tags!.join(',');
    }
    if (createdAfter != null) {
      params['created_after'] = createdAfter!.toIso8601String();
    }
    if (createdBefore != null) {
      params['created_before'] = createdBefore!.toIso8601String();
    }
    if (updatedAfter != null) {
      params['updated_after'] = updatedAfter!.toIso8601String();
    }
    if (updatedBefore != null) {
      params['updated_before'] = updatedBefore!.toIso8601String();
    }
    if (customerId != null && customerId!.isNotEmpty) {
      params['customer_id'] = customerId!;
    }
    if (searchQuery != null && searchQuery!.isNotEmpty) {
      params['query'] = searchQuery!;
    }
    if (sortBy != null && sortBy!.isNotEmpty) {
      params['order_by'] = sortBy!;
      params['order'] = sortOrder ?? 'desc';
    }

    return params;
  }

  bool get hasActiveFilters {
    return status != null && status != 'all' ||
           priority != null ||
           assigneeId != null ||
           channel != null ||
           tags != null && tags!.isNotEmpty ||
           createdAfter != null ||
           createdBefore != null ||
           updatedAfter != null ||
           updatedBefore != null ||
           customerId != null ||
           searchQuery != null && searchQuery!.isNotEmpty;
  }

  TicketFilter clearFilters() {
    return const TicketFilter();
  }
}

class TicketListResponse {
  final List<Ticket> tickets;
  final int totalCount;
  final int currentPage;
  final int totalPages;
  final bool hasNextPage;
  final bool hasPreviousPage;
  final TicketFilter filter;

  const TicketListResponse({
    required this.tickets,
    required this.totalCount,
    required this.currentPage,
    required this.totalPages,
    required this.hasNextPage,
    required this.hasPreviousPage,
    required this.filter,
  });

  factory TicketListResponse.fromJson(
    Map<String, dynamic> json, 
    TicketFilter filter,
  ) {
    final data = json['data'] as List<dynamic>? ?? [];
    final tickets = data.map((ticket) => Ticket.fromJson(ticket)).toList();
    
    final totalCount = json['meta']?['total_count'] ?? json['total'] ?? tickets.length;
    final currentPage = json['meta']?['current_page'] ?? json['page'] ?? filter.page;
    final totalPages = json['meta']?['total_pages'] ?? 
        ((totalCount / filter.perPage).ceil());
    
    return TicketListResponse(
      tickets: tickets,
      totalCount: totalCount,
      currentPage: currentPage,
      totalPages: totalPages,
      hasNextPage: currentPage < totalPages,
      hasPreviousPage: currentPage > 1,
      filter: filter,
    );
  }

  TicketListResponse copyWith({
    List<Ticket>? tickets,
    int? totalCount,
    int? currentPage,
    int? totalPages,
    bool? hasNextPage,
    bool? hasPreviousPage,
    TicketFilter? filter,
  }) {
    return TicketListResponse(
      tickets: tickets ?? this.tickets,
      totalCount: totalCount ?? this.totalCount,
      currentPage: currentPage ?? this.currentPage,
      totalPages: totalPages ?? this.totalPages,
      hasNextPage: hasNextPage ?? this.hasNextPage,
      hasPreviousPage: hasPreviousPage ?? this.hasPreviousPage,
      filter: filter ?? this.filter,
    );
  }

  // Helper methods
  bool get isEmpty => tickets.isEmpty;
  bool get isNotEmpty => tickets.isNotEmpty;
  int get length => tickets.length;
  
  TicketListResponse nextPage() {
    if (!hasNextPage) return this;
    return copyWith(
      filter: filter.copyWith(page: currentPage + 1),
    );
  }
  
  TicketListResponse previousPage() {
    if (!hasPreviousPage) return this;
    return copyWith(
      filter: filter.copyWith(page: currentPage - 1),
    );
  }
}

class MessageListResponse {
  final List<Message> messages;
  final String ticketId;
  final int totalCount;
  final bool hasMore;

  const MessageListResponse({
    required this.messages,
    required this.ticketId,
    required this.totalCount,
    required this.hasMore,
  });

  factory MessageListResponse.fromJson(
    Map<String, dynamic> json,
    String ticketId,
  ) {
    final data = json['data'] as List<dynamic>? ?? [];
    final messages = data.map((message) => Message.fromJson(message)).toList();
    
    return MessageListResponse(
      messages: messages,
      ticketId: ticketId,
      totalCount: json['meta']?['total_count'] ?? json['total'] ?? messages.length,
      hasMore: json['meta']?['has_more'] ?? false,
    );
  }

  MessageListResponse copyWith({
    List<Message>? messages,
    String? ticketId,
    int? totalCount,
    bool? hasMore,
  }) {
    return MessageListResponse(
      messages: messages ?? this.messages,
      ticketId: ticketId ?? this.ticketId,
      totalCount: totalCount ?? this.totalCount,
      hasMore: hasMore ?? this.hasMore,
    );
  }

  // Helper methods
  bool get isEmpty => messages.isEmpty;
  bool get isNotEmpty => messages.isNotEmpty;
  int get length => messages.length;
  
  Message? get latestMessage => messages.isNotEmpty ? messages.last : null;
  Message? get firstMessage => messages.isNotEmpty ? messages.first : null;
  
  List<Message> get customerMessages => 
      messages.where((message) => !message.fromAgent).toList();
  
  List<Message> get agentMessages => 
      messages.where((message) => message.fromAgent && !message.isInternal).toList();
  
  List<Message> get internalNotes => 
      messages.where((message) => message.isInternal).toList();
}

// Utility classes for UI state management
class GorgiasUIState {
  final bool isLoading;
  final String? error;
  final DateTime? lastUpdated;
  final Map<String, dynamic>? metadata;

  const GorgiasUIState({
    this.isLoading = false,
    this.error,
    this.lastUpdated,
    this.metadata,
  });

  GorgiasUIState copyWith({
    bool? isLoading,
    String? error,
    DateTime? lastUpdated,
    Map<String, dynamic>? metadata,
  }) {
    return GorgiasUIState(
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
      lastUpdated: lastUpdated ?? this.lastUpdated,
      metadata: metadata ?? this.metadata,
    );
  }

  bool get hasError => error != null;
  bool get isSuccess => !isLoading && !hasError;
}

// Constants for Gorgias feature
class GorgiasConstants {
  static const List<String> ticketStatuses = [
    'open',
    'closed',
  ];

  static const List<String> ticketPriorities = [
    'low',
    'normal',
    'high',
    'urgent',
  ];

  static const List<String> ticketChannels = [
    'email',
    'chat',
    'sms',
    'facebook',
    'twitter',
    'instagram',
    'phone',
  ];

  static const List<String> sortOptions = [
    'created_datetime',
    'updated_datetime',
    'last_message_datetime',
    'priority',
    'status',
  ];

  static const List<String> sortOrders = [
    'asc',
    'desc',
  ];

  static const int defaultPerPage = 20;
  static const int maxPerPage = 100;
  static const int cacheExpirationMinutes = 5;
  static const int realTimeUpdateIntervalSeconds = 30;
}