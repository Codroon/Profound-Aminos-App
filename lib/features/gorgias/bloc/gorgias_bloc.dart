import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../repository/gorgias_repository.dart';
import '../models/gorgias_models.dart';
import 'gorgias_event.dart';
import 'gorgias_state.dart';
import '../../../core/services/gorgias_debug_service.dart';
import '../../../core/services/credential_initialization_service.dart';


class GorgiasBloc extends Bloc<GorgiasEvent, GorgiasState> {
  final GorgiasRepository _repository;
  final Connectivity _connectivity;
  
  // Cache management
  static const Duration _cacheTimeout = Duration(minutes: 5);
  final Map<String, dynamic> _ticketCache = {};
  DateTime? _lastTicketsFetch;
  Timer? _cacheTimer;
  
  // Pagination state
  int _currentPage = 1;
  bool _hasMoreTickets = true;
  List<Ticket> _allTickets = [];
  
  // Real-time updates
  StreamSubscription<Map<String, dynamic>>? _realtimeSubscription;
  
  GorgiasBloc({
    required GorgiasRepository repository,
    Connectivity? connectivity,
  }) : _repository = repository,
       _connectivity = connectivity ?? Connectivity(),
       super(const GorgiasInitial()) {
    
    // Register event handlers
    on<FetchTickets>(_onFetchTickets);
    on<FetchTicketDetails>(_onFetchTicketDetails);
    on<FetchTicketMessages>(_onFetchTicketMessages);
    on<SendMessage>(_onSendMessage);
    on<UpdateTicketStatus>(_onUpdateTicketStatus);
    on<AssignTicket>(_onAssignTicket);
    on<SearchTickets>(_onSearchTickets);
    on<FilterTickets>(_onFilterTickets);
    on<RefreshTickets>(_onRefreshTickets);
    on<ClearTicketCache>(_onClearTicketCache);
    
    // Debug and credential refresh handlers
    on<DebugGorgiasCredentials>(_onDebugGorgiasCredentials);
    on<RefreshGorgiasCredentials>(_onRefreshGorgiasCredentials);
    on<FetchTicketStats>(_onFetchTicketStats);
    
    // Real-time update handlers
    on<StartRealtimeUpdates>(_onStartRealtimeUpdates);
    on<StopRealtimeUpdates>(_onStopRealtimeUpdates);
    on<TicketUpdatedRealtime>(_onTicketUpdatedRealtime);
    on<NewMessageRealtime>(_onNewMessageRealtime);
    
    // Initialize cache cleanup timer
    _cacheTimer = Timer.periodic(const Duration(minutes: 10), (_) {
      _cleanupExpiredCache();
    });
  }
  
  void _cleanupExpiredCache() {
    if (_lastTicketsFetch != null &&
        DateTime.now().difference(_lastTicketsFetch!) > _cacheTimeout) {
      _ticketCache.clear();
      _lastTicketsFetch = null;
    }
  }
  
  Future<void> _onFetchTickets(
    FetchTickets event,
    Emitter<GorgiasState> emit,
  ) async {
    try {
      // Use filter if provided, otherwise use individual parameters
      final filter = event.filter ?? TicketFilter(
        status: event.status,
        assigneeId: event.assignedTo,
        page: event.page,
        perPage: event.perPage,
      );
      
      // Check if we should use cache FIRST to avoid loading flash
      final statusKey = filter.status ?? 'all';
      final assigneeKey = filter.assigneeId ?? 'none';
      final channelKey = filter.channel ?? 'all';
      final searchKey = filter.searchQuery ?? '';
      final cacheKey = 'tickets_${statusKey}_${assigneeKey}_${channelKey}_${searchKey}_${filter.page}';
      final now = DateTime.now();
      
      if (_lastTicketsFetch != null &&
          now.difference(_lastTicketsFetch!) < _cacheTimeout &&
          _ticketCache.containsKey(cacheKey)) {
        final cachedData = _ticketCache[cacheKey];
        final cachedTickets = (cachedData['tickets'] as List<dynamic>)
            .map((ticketData) => ticketData is Ticket 
                ? ticketData 
                : Ticket.fromJson(ticketData as Map<String, dynamic>))
            .toList();
        emit(TicketsLoaded(
          tickets: cachedTickets,
          totalCount: cachedData['totalCount'],
          currentPage: filter.page,
          hasMore: cachedData['hasMore'],
          currentFilter: filter.status,
          searchQuery: filter.searchQuery,
          lastUpdated: _lastTicketsFetch!,
        ));
        return;
      }
      
      // Check connectivity
      final connectivityResult = await _connectivity.checkConnectivity();
      if (connectivityResult == ConnectivityResult.none) {
        emit(GorgiasOffline(cachedTickets: _allTickets));
        return;
      }
      
      // Show loading state only when we need to fetch from network
      if (filter.page == 1) {
        emit(const TicketsLoading());
        _allTickets.clear();
        _currentPage = 1;
      } else {
        emit(const TicketsLoading(isRefresh: true));
      }
      
      // Fetch tickets from repository
      Map<String, dynamic> result;
      if (filter.searchQuery != null && filter.searchQuery!.isNotEmpty) {
        result = await _repository.searchTickets(filter.searchQuery!);
      } else {
        result = await _repository.getTickets(
          status: filter.status,
          assignedTo: filter.assigneeId,
          channel: filter.channel,
          page: filter.page,
          perPage: filter.perPage,
        );
      }
      
      var ticketsData = result['tickets'] as List<dynamic>;
      var totalCount = result['totalCount'] as int;

      if (filter.searchQuery != null && filter.searchQuery!.isNotEmpty) {
        // Apply client-side status filtering if status is specified
        if (filter.status != null && filter.status!.isNotEmpty && filter.status != 'all') {
          ticketsData = ticketsData.where((ticket) {
            final ticketStatus = ticket['status']?.toString().toLowerCase();
            return ticketStatus == filter.status!.toLowerCase();
          }).toList();
        }

        // Apply client-side channel filtering if channel is specified
        if (filter.channel != null && filter.channel!.isNotEmpty && filter.channel != 'all') {
          ticketsData = ticketsData.where((ticket) {
            final ticketChannel = ticket['channel']?.toString().toLowerCase();
            return ticketChannel == filter.channel!.toLowerCase();
          }).toList();
        }
        totalCount = ticketsData.length;
      }
      
      // Convert Map objects to Ticket objects
      final tickets = ticketsData.map((ticketMap) => 
        Ticket.fromJson(ticketMap as Map<String, dynamic>)
      ).toList();
      
      // Update pagination state
      if (filter.page == 1) {
        _allTickets = List<Ticket>.from(tickets);
      } else {
        _allTickets.addAll(tickets);
      }
      
      _currentPage = filter.page;
      _hasMoreTickets = _allTickets.length < totalCount;
      
      // Cache the result
      _ticketCache[cacheKey] = {
        'tickets': List<Ticket>.from(_allTickets),
        'totalCount': totalCount,
        'hasMore': _hasMoreTickets,
      };
      _lastTicketsFetch = now;
      
      emit(TicketsLoaded(
        tickets: _allTickets,
        totalCount: totalCount,
        currentPage: _currentPage,
        hasMore: _hasMoreTickets,
        currentFilter: filter.status,
        searchQuery: filter.searchQuery,
        lastUpdated: now,
      ));
      
    } catch (error) {
      String errorMessage = error.toString();
      bool canRetry = true;
      
      // Handle specific error types
      if (errorMessage.contains('credentials') || 
          errorMessage.contains('Unauthorized') ||
          errorMessage.contains('Bad request')) {
        errorMessage = 'Please check your Gorgias credentials in Settings and try again.';
        canRetry = false; // Don't allow retry until credentials are fixed
      } else if (errorMessage.contains('No internet connection')) {
        errorMessage = 'No internet connection. Please check your network and try again.';
      } else if (errorMessage.contains('Rate limit exceeded')) {
        errorMessage = 'Too many requests. Please wait a moment before trying again.';
      } else if (errorMessage.contains('Server error')) {
        errorMessage = 'Gorgias server is experiencing issues. Please try again later.';
      } else {
        errorMessage = 'Failed to fetch tickets: $errorMessage';
      }
      
      emit(TicketsError(
        message: errorMessage,
        canRetry: canRetry,
      ));
    }
  }
  
  Future<void> _onFetchTicketDetails(
    FetchTicketDetails event,
    Emitter<GorgiasState> emit,
  ) async {
    try {
      emit(const TicketDetailsLoading());
      
      final result = await _repository.getTicketDetails(event.ticketId);
      
      // Convert ticket Map to Ticket object
      final ticketData = result['ticket'] as Map<String, dynamic>;
      final ticket = Ticket.fromJson(ticketData);
      
      // Convert messages from Map objects to Message objects
      final messagesData = result['messages'] as List<dynamic>? ?? [];
      final messages = messagesData.map((messageData) => 
          Message.fromJson(messageData as Map<String, dynamic>)
      ).toList();
      
      emit(TicketDetailsLoaded(
        ticket: ticket,
        messages: messages,
        lastUpdated: DateTime.now(),
      ));
      
    } catch (error) {
      emit(TicketDetailsError(
        message: 'Failed to fetch ticket details: ${error.toString()}',
        ticketId: event.ticketId,
      ));
    }
  }
  
  Future<void> _onFetchTicketMessages(
    FetchTicketMessages event,
    Emitter<GorgiasState> emit,
  ) async {
    try {
      emit(const MessagesLoading());
      
      final messagesData = await _repository.getTicketMessages(event.ticketId);
      
      // Convert messages from Map objects to Message objects
      final messages = messagesData.map((messageData) => 
          Message.fromJson(messageData as Map<String, dynamic>)
      ).toList();
      
      // Update current state if it's TicketDetailsLoaded
      if (state is TicketDetailsLoaded) {
        final currentState = state as TicketDetailsLoaded;
        emit(TicketDetailsLoaded(
          ticket: currentState.ticket,
          messages: messages,
          lastUpdated: DateTime.now(),
        ));
      }
      
    } catch (error) {
      emit(GorgiasError(
        message: 'Failed to fetch messages: ${error.toString()}',
        errorType: 'messages',
      ));
    }
  }
  
  Future<void> _onSendMessage(
    SendMessage event,
    Emitter<GorgiasState> emit,
  ) async {
    try {
      emit(const SendingMessage());
      
      final message = await _repository.sendMessage(
        ticketId: event.ticketId,
        message: event.message,
        isInternal: event.isInternal,
      );
      
      emit(MessageSent(message));
      
      // Refresh ticket details to show new message
      add(FetchTicketDetails(event.ticketId));
      
    } catch (error) {
      emit(MessageSendError(
        message: 'Failed to send message: ${error.toString()}',
        ticketId: event.ticketId,
      ));
    }
  }
  
  Future<void> _onUpdateTicketStatus(
    UpdateTicketStatus event,
    Emitter<GorgiasState> emit,
  ) async {
    try {
      emit(const UpdatingTicket());
      
      dynamic updatedTicket;
      
      if (event.updates != null && event.updates!.isNotEmpty) {
        // Handle multiple updates
        updatedTicket = await _repository.updateTicket(
          ticketId: event.ticketId,
          updates: event.updates!,
        );
      } else if (event.status != null) {
        // Handle single status update for backward compatibility
        updatedTicket = await _repository.updateTicketStatus(
          ticketId: event.ticketId,
          status: event.status!,
        );
      } else {
        throw Exception('No updates provided');
      }
      
      emit(TicketUpdated(
        ticket: updatedTicket,
        updateType: event.updates != null ? 'multiple' : 'status',
      ));
      
      // Clear cache to force refresh
      _ticketCache.clear();
      _lastTicketsFetch = null;
      
    } catch (error) {
      emit(GorgiasError(
        message: 'Failed to update ticket: ${error.toString()}',
        errorType: 'update_ticket',
      ));
    }
  }
  
  Future<void> _onAssignTicket(
    AssignTicket event,
    Emitter<GorgiasState> emit,
  ) async {
    try {
      final updatedTicket = await _repository.assignTicket(
        ticketId: event.ticketId,
        assigneeId: event.assigneeId,
      );
      
      emit(TicketUpdated(
        ticket: updatedTicket,
        updateType: 'assignment',
      ));
      
      // Clear cache to force refresh
      _ticketCache.clear();
      _lastTicketsFetch = null;
      
    } catch (error) {
      emit(GorgiasError(
        message: 'Failed to assign ticket: ${error.toString()}',
        errorType: 'assign',
      ));
    }
  }
  
  Future<void> _onSearchTickets(
    SearchTickets event,
    Emitter<GorgiasState> emit,
  ) async {
    try {
      emit(const TicketsLoading());
      
      final result = await _repository.searchTickets(event.query);
      
      // Convert Map objects to Ticket objects
      final ticketsData = result['tickets'] as List<dynamic>;
      final tickets = ticketsData.map((ticketMap) => 
        Ticket.fromJson(ticketMap as Map<String, dynamic>)
      ).toList();
      
      emit(TicketsLoaded(
        tickets: tickets,
        totalCount: result['totalCount'],
        currentPage: 1,
        hasMore: false,
        searchQuery: event.query,
        lastUpdated: DateTime.now(),
      ));
      
    } catch (error) {
      emit(TicketsError(
        message: 'Failed to search tickets: ${error.toString()}',
      ));
    }
  }
  
  Future<void> _onFilterTickets(
    FilterTickets event,
    Emitter<GorgiasState> emit,
  ) async {
    // Clear cache and fetch with new filter
    _ticketCache.clear();
    _lastTicketsFetch = null;
    
    add(FetchTickets(status: event.filterType));
  }
  
  Future<void> _onRefreshTickets(
    RefreshTickets event,
    Emitter<GorgiasState> emit,
  ) async {
    // Clear cache and fetch fresh data
    _ticketCache.clear();
    _lastTicketsFetch = null;
    _allTickets.clear();
    
    add(FetchTickets(filter: event.filter));
  }
  
  Future<void> _onClearTicketCache(
    ClearTicketCache event,
    Emitter<GorgiasState> emit,
  ) async {
    _ticketCache.clear();
    _lastTicketsFetch = null;
  }
  
  // Real-time update handlers
  Future<void> _onStartRealtimeUpdates(
    StartRealtimeUpdates event,
    Emitter<GorgiasState> emit,
  ) async {
    try {
      // Cancel existing subscription if any
      await _realtimeSubscription?.cancel();
      
      // Subscribe to real-time updates
      _realtimeSubscription = _repository.getRealtimeUpdates().listen(
        (update) {
          final type = update['type'] as String?;
          final ticketId = update['ticketId'] as String?;
          final data = update['data'] as Map<String, dynamic>?;
          
          if (type != null && ticketId != null && data != null) {
            switch (type) {
              case 'ticket_updated':
                add(TicketUpdatedRealtime(ticketId: ticketId, data: data));
                break;
              case 'new_message':
                add(NewMessageRealtime(ticketId: ticketId, message: data));
                break;
            }
          }
        },
        onError: (error) {
          // Handle real-time update errors silently
          // Could emit a state to show connection issues if needed
        },
      );
    } catch (e) {
      // Handle subscription errors
    }
  }
  
  Future<void> _onStopRealtimeUpdates(
    StopRealtimeUpdates event,
    Emitter<GorgiasState> emit,
  ) async {
    await _realtimeSubscription?.cancel();
    _realtimeSubscription = null;
  }
  
  Future<void> _onTicketUpdatedRealtime(
    TicketUpdatedRealtime event,
    Emitter<GorgiasState> emit,
  ) async {
    // Update ticket in cache if it exists
    if (_ticketCache.containsKey(event.ticketId)) {
      final cachedTicket = Map<String, dynamic>.from(_ticketCache[event.ticketId]);
      cachedTicket.addAll(event.data);
      _ticketCache[event.ticketId] = cachedTicket;
    }
    
    // Update ticket in current state if it's a ticket list
    if (state is TicketsLoaded) {
      final currentState = state as TicketsLoaded;
      final tickets = List<Ticket>.from(currentState.tickets);
      final ticketIndex = tickets.indexWhere((t) => t.id.toString() == event.ticketId);
      
      if (ticketIndex != -1) {
        // Update the ticket with new data
        final updatedTicketData = tickets[ticketIndex].toJson();
        updatedTicketData.addAll(event.data);
        tickets[ticketIndex] = Ticket.fromJson(updatedTicketData);
        emit(currentState.copyWith(tickets: tickets));
      }
    }
  }
  
  Future<void> _onNewMessageRealtime(
    NewMessageRealtime event,
    Emitter<GorgiasState> emit,
  ) async {
    // Update message cache for the ticket
    final messagesCacheKey = 'messages_${event.ticketId}';
    if (_ticketCache.containsKey(messagesCacheKey)) {
      final messages = List<Map<String, dynamic>>.from(_ticketCache[messagesCacheKey]);
      messages.insert(0, event.message); // Add new message at the beginning
      _ticketCache[messagesCacheKey] = messages;
    }
    
    // If currently viewing messages for this ticket, update the state
    if (state is TicketDetailsLoaded) {
      final currentState = state as TicketDetailsLoaded;
      final messages = List<Message>.from(currentState.messages);
      final newMessage = Message.fromJson(event.message);
      messages.insert(0, newMessage);
      emit(TicketDetailsLoaded(
        ticket: currentState.ticket,
        messages: messages,
        lastUpdated: DateTime.now(),
      ));
    }
  }
  
  // Debug credentials handler
  Future<void> _onDebugGorgiasCredentials(
    DebugGorgiasCredentials event,
    Emitter<GorgiasState> emit,
  ) async {
    try {
      emit(const GorgiasLoading());
      
      final debugInfo = await GorgiasDebugService.debugGorgiasCredentials();
      
      emit(GorgiasDebugInfo(
        debugInfo: debugInfo,
        timestamp: DateTime.now(),
      ));
      
    } catch (error) {
      emit(GorgiasError(
        message: 'Failed to debug credentials: ${error.toString()}',
        errorType: 'debug',
      ));
    }
  }
  
  // Refresh credentials handler
  Future<void> _onRefreshGorgiasCredentials(
    RefreshGorgiasCredentials event,
    Emitter<GorgiasState> emit,
  ) async {
    try {
      emit(const GorgiasLoading());
      
      await CredentialInitializationService.refreshGorgiasCredentials();
      
      emit(const GorgiasCredentialsRefreshed());
      
      // Clear cache after credential refresh
      _ticketCache.clear();
      _lastTicketsFetch = null;
      
    } catch (error) {
      emit(GorgiasError(
        message: 'Failed to refresh credentials: ${error.toString()}',
        errorType: 'refresh',
      ));
    }
  }
  
  Future<void> _onFetchTicketStats(
    FetchTicketStats event,
    Emitter<GorgiasState> emit,
  ) async {
    try {
      print('[GorgiasBloc] FetchTicketStats event received');
      emit(const TicketStatsLoading());
      print('[GorgiasBloc] Emitted TicketStatsLoading');
      
      final stats = await _repository.getTicketStats();
      print('[GorgiasBloc] Repository result: $stats');
      final ticketStats = TicketStats.fromJson(stats);
      print('[GorgiasBloc] Parsed stats: Open=${ticketStats.openTickets}, Closed=${ticketStats.closedTickets}');
      
      emit(TicketStatsLoaded(
        stats: ticketStats,
        lastUpdated: DateTime.now(),
      ));
      print('[GorgiasBloc] Emitted TicketStatsLoaded');
    } catch (error) {
      print('[GorgiasBloc] Error in _onFetchTicketStats: $error');
      emit(TicketStatsError(
        message: 'Failed to fetch ticket stats: ${error.toString()}',
      ));
    }
  }
  
  @override
  Future<void> close() {
    _cacheTimer?.cancel();
    _realtimeSubscription?.cancel();
    return super.close();
  }
}