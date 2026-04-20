import 'package:equatable/equatable.dart';
import '../models/gorgias_models.dart';

abstract class GorgiasState extends Equatable {
  const GorgiasState();
  @override
  List<Object?> get props => [];
}

// Initial state
class GorgiasInitial extends GorgiasState {
  const GorgiasInitial();
}

// Loading states
class GorgiasLoading extends GorgiasState {
  final String? loadingType;
  
  const GorgiasLoading({this.loadingType});
  
  @override
  List<Object?> get props => [loadingType];
}

class TicketsLoading extends GorgiasState {
  final bool isRefresh;
  
  const TicketsLoading({this.isRefresh = false});
  
  @override
  List<Object?> get props => [isRefresh];
}

class TicketDetailsLoading extends GorgiasState {
  const TicketDetailsLoading();
}

class MessagesLoading extends GorgiasState {
  const MessagesLoading();
}

class SendingMessage extends GorgiasState {
  const SendingMessage();
}

class UpdatingTicket extends GorgiasState {
  const UpdatingTicket();
}

// Success states
class TicketsLoaded extends GorgiasState {
  final List<Ticket> tickets;
  final int totalCount;
  final int currentPage;
  final bool hasMore;
  final String? currentFilter;
  final String? searchQuery;
  final DateTime lastUpdated;
  
  const TicketsLoaded({
    required this.tickets,
    required this.totalCount,
    this.currentPage = 1,
    this.hasMore = false,
    this.currentFilter,
    this.searchQuery,
    required this.lastUpdated,
  });
  
  @override
  List<Object?> get props => [
    tickets,
    totalCount,
    currentPage,
    hasMore,
    currentFilter,
    searchQuery,
    lastUpdated,
  ];
  
  TicketsLoaded copyWith({
    List<Ticket>? tickets,
    int? totalCount,
    int? currentPage,
    bool? hasMore,
    String? currentFilter,
    String? searchQuery,
    DateTime? lastUpdated,
  }) {
    return TicketsLoaded(
      tickets: tickets ?? this.tickets,
      totalCount: totalCount ?? this.totalCount,
      currentPage: currentPage ?? this.currentPage,
      hasMore: hasMore ?? this.hasMore,
      currentFilter: currentFilter ?? this.currentFilter,
      searchQuery: searchQuery ?? this.searchQuery,
      lastUpdated: lastUpdated ?? this.lastUpdated,
    );
  }
}

class TicketDetailsLoaded extends GorgiasState {
  final Ticket ticket;
  final List<Message> messages;
  final DateTime lastUpdated;
  
  const TicketDetailsLoaded({
    required this.ticket,
    required this.messages,
    required this.lastUpdated,
  });
  
  @override
  List<Object?> get props => [ticket, messages, lastUpdated];
}

class MessageSent extends GorgiasState {
  final dynamic message;
  
  const MessageSent(this.message);
  
  @override
  List<Object?> get props => [message];
}

class TicketUpdated extends GorgiasState {
  final dynamic ticket;
  final String updateType;
  
  const TicketUpdated({
    required this.ticket,
    required this.updateType,
  });
  
  @override
  List<Object?> get props => [ticket, updateType];
}

// Error states
class GorgiasError extends GorgiasState {
  final String message;
  final String? errorType;
  final dynamic error;
  
  const GorgiasError({
    required this.message,
    this.errorType,
    this.error,
  });
  
  @override
  List<Object?> get props => [message, errorType, error];
}

class TicketsError extends GorgiasState {
  final String message;
  final bool canRetry;
  
  const TicketsError({
    required this.message,
    this.canRetry = true,
  });
  
  @override
  List<Object?> get props => [message, canRetry];
}

class TicketDetailsError extends GorgiasState {
  final String message;
  final String ticketId;
  
  const TicketDetailsError({
    required this.message,
    required this.ticketId,
  });
  
  @override
  List<Object?> get props => [message, ticketId];
}

class MessageSendError extends GorgiasState {
  final String message;
  final String ticketId;
  
  const MessageSendError({
    required this.message,
    required this.ticketId,
  });
  
  @override
  List<Object?> get props => [message, ticketId];
}

// Network states
class GorgiasOffline extends GorgiasState {
  final List<Ticket>? cachedTickets;
  
  const GorgiasOffline({this.cachedTickets});
  
  @override
  List<Object?> get props => [cachedTickets];
}

// Debug states
class GorgiasDebugInfo extends GorgiasState {
  final Map<String, dynamic> debugInfo;
  final DateTime timestamp;
  
  const GorgiasDebugInfo({
    required this.debugInfo,
    required this.timestamp,
  });
  
  @override
  List<Object?> get props => [debugInfo, timestamp];
}

class GorgiasCredentialsRefreshed extends GorgiasState {
  const GorgiasCredentialsRefreshed();
}

// Ticket stats states
class TicketStatsLoading extends GorgiasState {
  const TicketStatsLoading();
}

class TicketStatsLoaded extends GorgiasState {
  final TicketStats stats;
  final DateTime lastUpdated;
  
  const TicketStatsLoaded({
    required this.stats,
    required this.lastUpdated,
  });
  
  @override
  List<Object?> get props => [stats, lastUpdated];
}

class TicketStatsError extends GorgiasState {
  final String message;
  
  const TicketStatsError({required this.message});
  
  @override
  List<Object?> get props => [message];
}