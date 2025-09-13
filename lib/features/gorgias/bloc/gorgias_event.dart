import 'package:equatable/equatable.dart';
import '../models/gorgias_models.dart';

abstract class GorgiasEvent extends Equatable {
  const GorgiasEvent();
  @override
  List<Object?> get props => [];
}

// Fetch all tickets
class FetchTickets extends GorgiasEvent {
  final String? status;
  final String? assignedTo;
  final int page;
  final int perPage;
  final TicketFilter? filter;
  
  const FetchTickets({
    this.status,
    this.assignedTo,
    this.page = 1,
    this.perPage = 20,
    this.filter,
  });
  
  @override
  List<Object?> get props => [status, assignedTo, page, perPage, filter];
}

// Fetch single ticket details
class FetchTicketDetails extends GorgiasEvent {
  final String ticketId;
  
  const FetchTicketDetails(this.ticketId);
  
  @override
  List<Object?> get props => [ticketId];
}

// Fetch messages for a ticket
class FetchTicketMessages extends GorgiasEvent {
  final String ticketId;
  
  const FetchTicketMessages(this.ticketId);
  
  @override
  List<Object?> get props => [ticketId];
}

// Send message
class SendMessage extends GorgiasEvent {
  final String ticketId;
  final String message;
  final bool isInternal;
  
  const SendMessage({
    required this.ticketId,
    required this.message,
    this.isInternal = false,
  });
  
  @override
  List<Object?> get props => [ticketId, message, isInternal];
}

// Update ticket status
class UpdateTicketStatus extends GorgiasEvent {
  final String ticketId;
  final String? status;
  final Map<String, dynamic>? updates;
  
  const UpdateTicketStatus({
    required this.ticketId,
    this.status,
    this.updates,
  });
  
  @override
  List<Object?> get props => [ticketId, status, updates];
}

// Assign ticket
class AssignTicket extends GorgiasEvent {
  final String ticketId;
  final String? assigneeId;
  
  const AssignTicket({
    required this.ticketId,
    this.assigneeId,
  });
  
  @override
  List<Object?> get props => [ticketId, assigneeId];
}

// Search tickets
class SearchTickets extends GorgiasEvent {
  final String query;
  
  const SearchTickets(this.query);
  
  @override
  List<Object?> get props => [query];
}

// Real-time update events
class StartRealtimeUpdates extends GorgiasEvent {
  const StartRealtimeUpdates();
}

class StopRealtimeUpdates extends GorgiasEvent {
  const StopRealtimeUpdates();
}

class TicketUpdatedRealtime extends GorgiasEvent {
  final String ticketId;
  final Map<String, dynamic> data;
  
  const TicketUpdatedRealtime({
    required this.ticketId,
    required this.data,
  });
  
  @override
  List<Object?> get props => [ticketId, data];
}

class NewMessageRealtime extends GorgiasEvent {
  final String ticketId;
  final Map<String, dynamic> message;
  
  const NewMessageRealtime({
    required this.ticketId,
    required this.message,
  });
  
  @override
  List<Object?> get props => [ticketId, message];
}

// Filter tickets
class FilterTickets extends GorgiasEvent {
  final String filterType;
  
  const FilterTickets(this.filterType);
  
  @override
  List<Object?> get props => [filterType];
}

// Refresh tickets
class RefreshTickets extends GorgiasEvent {
  final TicketFilter? filter;
  
  const RefreshTickets({this.filter});
  
  @override
  List<Object?> get props => [filter];
}

// Clear ticket cache
class ClearTicketCache extends GorgiasEvent {
  const ClearTicketCache();
}

// Debug Gorgias credentials
class DebugGorgiasCredentials extends GorgiasEvent {
  const DebugGorgiasCredentials();
}

// Refresh Gorgias credentials
class RefreshGorgiasCredentials extends GorgiasEvent {
  const RefreshGorgiasCredentials();
}

// Fetch ticket statistics
class FetchTicketStats extends GorgiasEvent {
  const FetchTicketStats();
}