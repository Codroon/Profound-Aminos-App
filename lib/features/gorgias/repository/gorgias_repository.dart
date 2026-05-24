import 'dart:convert';
import '../../../core/network/network_info.dart';
import '../../../core/storage/cache_manager.dart';
import '../../../core/services/api_credential_service.dart';
import '../../../core/services/gorgias_service.dart';
import '../../../core/services/gorgias_debug_service.dart';

// Abstract repository interface
abstract class GorgiasRepository {
  Future<Map<String, dynamic>> getTickets({
    String? status,
    String? assignedTo,
    String? channel,
    int page = 1,
    int perPage = 20,
  });

  Future<Map<String, dynamic>> getTicketDetails(String ticketId);
  Future<List<dynamic>> getTicketMessages(String ticketId);

  Future<dynamic> sendMessage({
    required String ticketId,
    required String message,
    bool isInternal = false,
  });

  Future<dynamic> updateTicketStatus({
    required String ticketId,
    required String status,
  });

  Future<dynamic> updateTicket({
    required String ticketId,
    required Map<String, dynamic> updates,
  });

  Future<dynamic> assignTicket({required String ticketId, String? assigneeId});

  Future<Map<String, dynamic>> searchTickets(String query);
  Future<List<dynamic>> getUsers();
  Future<Map<String, dynamic>> getCurrentUser();
  Future<Map<String, dynamic>> getTicketStats();
  Future<void> clearCache();
  
  // Real-time updates
  Stream<Map<String, dynamic>> getRealtimeUpdates();
}

// Repository implementation
class GorgiasRepositoryImpl implements GorgiasRepository {
  final NetworkInfo _networkInfo;
  final CacheManager _cacheManager;
  final ApiService _apiService;
  final GorgiasService _gorgiasService;

  // Cache keys
  static const String _ticketsCacheKey = 'gorgias_tickets';
  static const String _ticketDetailsCacheKey = 'gorgias_ticket_details';
  static const String _usersCacheKey = 'gorgias_users';
  static const String _statsCacheKey = 'gorgias_stats';

  // Cache duration
  static const Duration _cacheTimeout = Duration(minutes: 5);
  static const Duration _usersCacheTimeout = Duration(hours: 1);
  static const Duration _statsCacheTimeout = Duration(minutes: 10);

  GorgiasRepositoryImpl({
    required NetworkInfo networkInfo,
    required CacheManager cacheManager,
    required ApiService apiService,
    required GorgiasService gorgiasService,
  }) : _networkInfo = networkInfo,
       _cacheManager = cacheManager,
       _apiService = apiService,
       _gorgiasService = gorgiasService;

  @override
  Future<Map<String, dynamic>> getTickets({
    String? status,
    String? assignedTo,
    String? channel,
    int page = 1,
    int perPage = 20,
  }) async {
    final cacheKey =
        '${_ticketsCacheKey}_${status ?? 'all'}_${assignedTo ?? 'all'}_${channel ?? 'all'}_${page}_$perPage';

    // Try to get from cache first
    if (await _networkInfo.isConnected) {
      try {
        final cachedData = await _cacheManager.getData(cacheKey);
        if (cachedData != null) {
          final cacheTime = DateTime.parse(cachedData['timestamp']);
          if (DateTime.now().difference(cacheTime) < _cacheTimeout) {
            return Map<String, dynamic>.from(cachedData['data']);
          }
        }
      } catch (e) {
        // Cache error, continue to network call
      }
    }

    // Check network connectivity
    if (!await _networkInfo.isConnected) {
      // Return cached data if available, even if expired
      try {
        final cachedData = await _cacheManager.getData(cacheKey);
        if (cachedData != null) {
          return Map<String, dynamic>.from(cachedData['data']);
        }
      } catch (e) {
        // No cached data available
      }
      throw Exception('No internet connection and no cached data available');
    }

    try {
      // Build query parameters using cursor-based pagination
      final queryParams = <String, String>{
        'limit': perPage.toString(),
      };
      
      // Note: Gorgias now uses cursor-based pagination instead of page/per_page
      // For now, we'll use limit only. Cursor support can be added later for better performance

      // Note: Gorgias API doesn't support 'status' as a query parameter
      // Status filtering should be done client-side after fetching tickets
      // if (status != null && status.isNotEmpty) {
      //   queryParams['status'] = status;
      // }

      if (assignedTo != null && assignedTo.isNotEmpty) {
        queryParams['assigned_user_id'] = assignedTo;
      }

      // Make API call through ApiService
      print('[GorgiasRepo] Making request to /tickets with params: $queryParams');
      
      final response = await _apiService.makeGorgiasRequest(
        endpoint: '/tickets',
        method: 'GET',
        queryParams: queryParams,
      );
      
      print('[GorgiasRepo] Response received - Success: ${response['success']}, Status: ${response['statusCode']}');
      
      // Handle authentication and credential errors
      if (response['statusCode'] == 401) {
        print('[GorgiasRepo] 401 error detected, running debug...');
        await GorgiasDebugService.debugGorgiasCredentials();
      } else if (response['statusCode'] == 400) {
        print('[GorgiasRepo] 400 error detected - Bad request. This usually indicates missing or invalid credentials.');
        await GorgiasDebugService.debugGorgiasCredentials();
      }

      if (response['success'] == true) {
        final data = response['data'];
        var tickets = data['data'] ?? [];
        final meta = data['meta'] ?? {};

        // Apply client-side status filtering if status is specified
        if (status != null && status.isNotEmpty && status != 'all') {
          tickets = tickets.where((ticket) {
            final ticketStatus = ticket['status']?.toString().toLowerCase();
            return ticketStatus == status.toLowerCase();
          }).toList();
        }

        // Apply client-side channel filtering if channel is specified
        if (channel != null && channel.isNotEmpty && channel != 'all') {
          tickets = tickets.where((ticket) {
            final ticketChannel = ticket['channel']?.toString().toLowerCase();
            return ticketChannel == channel.toLowerCase();
          }).toList();
        }

        final result = {
          'tickets': tickets,
          'totalCount': tickets.length, // Update count after filtering
          'currentPage': meta['current_page'] ?? page,
          'totalPages': meta['total_pages'] ?? 1,
        };

        // Cache the result
        await _cacheManager.cacheData(cacheKey, {
          'data': result,
          'timestamp': DateTime.now().toIso8601String(),
        });

        return result;
      } else {
        // Provide more specific error messages based on status code
        String errorMessage;
        switch (response['statusCode']) {
          case 400:
            errorMessage = 'Bad request: Please check your Gorgias credentials and configuration.';
            break;
          case 401:
            errorMessage = 'Unauthorized: Your Gorgias credentials are invalid or expired.';
            break;
          case 403:
            errorMessage = 'Forbidden: You do not have permission to access this resource.';
            break;
          case 404:
            errorMessage = 'Not found: The requested resource could not be found.';
            break;
          case 429:
            errorMessage = 'Rate limit exceeded: Too many requests. Please try again later.';
            break;
          case 500:
            errorMessage = 'Server error: Gorgias API is experiencing issues.';
            break;
          default:
            errorMessage = response['message'] ?? 'Failed to fetch tickets';
        }
        throw Exception(errorMessage);
      }
    } catch (e) {
      // Try to return cached data on error
      try {
        final cachedData = await _cacheManager.getData(cacheKey);
        if (cachedData != null) {
          return Map<String, dynamic>.from(cachedData['data']);
        }
      } catch (cacheError) {
        // Ignore cache error
      }

      throw Exception('Failed to fetch tickets: ${e.toString()}');
    }
  }

  @override
  Future<Map<String, dynamic>> getTicketDetails(String ticketId) async {
    final cacheKey = '${_ticketDetailsCacheKey}_$ticketId';

    // Try cache first
    if (await _networkInfo.isConnected) {
      try {
        final cachedData = await _cacheManager.getData(cacheKey);
        if (cachedData != null) {
          final cacheTime = DateTime.parse(cachedData['timestamp']);
          if (DateTime.now().difference(cacheTime) < _cacheTimeout) {
            return Map<String, dynamic>.from(cachedData['data']);
          }
        }
      } catch (e) {
        // Continue to network call
      }
    }

    if (!await _networkInfo.isConnected) {
      try {
        final cachedData = await _cacheManager.getData(cacheKey);
        if (cachedData != null) {
          return Map<String, dynamic>.from(cachedData['data']);
        }
      } catch (e) {
        // No cached data
      }
      throw Exception('No internet connection and no cached data available');
    }

    try {
      final response = await _apiService.makeGorgiasRequest(
        endpoint: '/tickets/$ticketId',
        method: 'GET',
      );

      if (response['success'] == true) {
        final ticket = response['data'];

        // Also fetch messages for this ticket
        final messagesResponse = await _apiService.makeGorgiasRequest(
          endpoint: '/tickets/$ticketId/messages',
          method: 'GET',
        );

        final messages =
            messagesResponse['success'] == true
                ? messagesResponse['data']['data'] ?? []
                : [];

        final result = {'ticket': ticket, 'messages': messages};

        // Cache the result
        await _cacheManager.cacheData(cacheKey, {
          'data': result,
          'timestamp': DateTime.now().toIso8601String(),
        });

        return result;
      } else {
        throw Exception(
          response['message'] ?? 'Failed to fetch ticket details',
        );
      }
    } catch (e) {
      // Try cached data
      try {
        final cachedData = await _cacheManager.getData(cacheKey);
        if (cachedData != null) {
          return Map<String, dynamic>.from(cachedData['data']);
        }
      } catch (cacheError) {
        // Ignore
      }

      throw Exception('Failed to fetch ticket details: ${e.toString()}');
    }
  }

  @override
  Future<List<dynamic>> getTicketMessages(String ticketId) async {
    if (!await _networkInfo.isConnected) {
      throw Exception('No internet connection');
    }

    try {
      final response = await _apiService.makeGorgiasRequest(
        endpoint: '/tickets/$ticketId/messages',
        method: 'GET',
      );

      if (response['success'] == true) {
        return response['data']['data'] ?? [];
      } else {
        throw Exception(response['message'] ?? 'Failed to fetch messages');
      }
    } catch (e) {
      throw Exception('Failed to fetch messages: ${e.toString()}');
    }
  }

  @override
  Future<dynamic> sendMessage({
    required String ticketId,
    required String message,
    bool isInternal = false,
  }) async {
    if (!await _networkInfo.isConnected) {
      throw Exception('No internet connection');
    }

    try {
      // Get current user information from Gorgias API
      String? userEmail;
      try {
        final currentUserResponse = await _gorgiasService.getCurrentUser();
        if (currentUserResponse['success'] == true && currentUserResponse['data'] != null) {
          // Handle wrapped response structure
          userEmail = currentUserResponse['data']['email'];
        } else if (currentUserResponse['email'] != null) {
          // Handle direct response structure from /account endpoint
          userEmail = currentUserResponse['email'];
        }
      } catch (e) {
        // If getting current user fails, continue without email
        print('Warning: Could not fetch current user email: $e');
      }

      // Get ticket details to fetch customer email
      String? customerEmail;
      try {
        final ticketResponse = await _gorgiasService.getTicketById(ticketId);
        if (ticketResponse['success'] == true && ticketResponse['data'] != null) {
          final ticketData = ticketResponse['data'];
          customerEmail = ticketData['customer']?['email'];
        }
      } catch (e) {
        print('Warning: Could not fetch customer email from ticket: $e');
      }

      final body = {
        'body_text': message,
        'channel': isInternal ? 'internal-note' : 'email',
        'from_agent': true,
        'via': 'api',
        'source': {
          'from': {
            'address': userEmail ?? 'support@profoundaminos.com',
          },
          'to': [
            {
              'address': customerEmail ?? 'customer@example.com',
            }
          ],
        },
      };

      // Debug logging
      print('[SendMessage] Request body: ${json.encode(body)}');
      print('[SendMessage] from email: ${userEmail ?? 'support@profoundaminos.com'}');
      print('[SendMessage] to email: ${customerEmail ?? 'customer@example.com'}');

      final response = await _apiService.makeGorgiasRequest(
        endpoint: '/tickets/$ticketId/messages',
        method: 'POST',
        body: body,
      );

      if (response['success'] == true) {
        // Clear ticket details cache to force refresh
        final cacheKey = '${_ticketDetailsCacheKey}_$ticketId';
        await _cacheManager.removeData(cacheKey);

        return response['data'];
      } else {
        throw Exception(response['message'] ?? 'Failed to send message');
      }
    } catch (e) {
      throw Exception('Failed to send message: ${e.toString()}');
    }
  }

  @override
  Future<dynamic> updateTicketStatus({
    required String ticketId,
    required String status,
  }) async {
    if (!await _networkInfo.isConnected) {
      throw Exception('No internet connection');
    }

    try {
      final body = {'status': status};

      final response = await _apiService.makeGorgiasRequest(
        endpoint: '/tickets/$ticketId',
        method: 'PUT',
        body: body,
      );

      if (response['success'] == true) {
        // Clear relevant caches
        await _clearTicketCaches(ticketId);

        return response['data'];
      } else {
        throw Exception(
          response['message'] ?? 'Failed to update ticket status',
        );
      }
    } catch (e) {
      throw Exception('Failed to update ticket status: ${e.toString()}');
    }
  }

  @override
  Future<dynamic> updateTicket({
    required String ticketId,
    required Map<String, dynamic> updates,
  }) async {
    if (!await _networkInfo.isConnected) {
      throw Exception('No internet connection');
    }

    try {
      final response = await _apiService.makeGorgiasRequest(
        endpoint: '/tickets/$ticketId',
        method: 'PUT',
        body: updates,
      );

      if (response['success'] == true) {
        // Clear relevant caches
        await _clearTicketCaches(ticketId);

        return response['data'];
      } else {
        throw Exception(
          response['message'] ?? 'Failed to update ticket',
        );
      }
    } catch (e) {
      throw Exception('Failed to update ticket: ${e.toString()}');
    }
  }

  @override
  Future<dynamic> assignTicket({
    required String ticketId,
    String? assigneeId,
  }) async {
    if (!await _networkInfo.isConnected) {
      throw Exception('No internet connection');
    }

    try {
      final body = {'assignee_user_id': assigneeId};

      final response = await _apiService.makeGorgiasRequest(
        endpoint: '/tickets/$ticketId',
        method: 'PUT',
        body: body,
      );

      if (response['success'] == true) {
        // Clear relevant caches
        await _clearTicketCaches(ticketId);

        return response['data'];
      } else {
        throw Exception(response['message'] ?? 'Failed to assign ticket');
      }
    } catch (e) {
      throw Exception('Failed to assign ticket: ${e.toString()}');
    }
  }

  @override
  Future<Map<String, dynamic>> searchTickets(String query) async {
    if (!await _networkInfo.isConnected) {
      throw Exception('No internet connection');
    }

    try {
      final queryParams = {'query': query, 'limit': '50'};

      final response = await _apiService.makeGorgiasRequest(
        endpoint: '/tickets/search',
        method: 'GET',
        queryParams: queryParams,
      );

      if (response['success'] == true) {
        final data = response['data'];
        return {
          'tickets': data['data'] ?? [],
          'totalCount': data['meta']?['total_count'] ?? 0,
        };
      } else {
        throw Exception(response['message'] ?? 'Failed to search tickets');
      }
    } catch (e) {
      throw Exception('Failed to search tickets: ${e.toString()}');
    }
  }

  @override
  Future<List<dynamic>> getUsers() async {
    // Try cache first
    try {
      final cachedData = await _cacheManager.getData(_usersCacheKey);
      if (cachedData != null) {
        final cacheTime = DateTime.parse(cachedData['timestamp']);
        if (DateTime.now().difference(cacheTime) < _usersCacheTimeout) {
          return List<dynamic>.from(cachedData['data']);
        }
      }
    } catch (e) {
      // Continue to network call
    }

    if (!await _networkInfo.isConnected) {
      try {
        final cachedData = await _cacheManager.getData(_usersCacheKey);
        if (cachedData != null) {
          return List<dynamic>.from(cachedData['data']);
        }
      } catch (e) {
        // No cached data
      }
      throw Exception('No internet connection and no cached data available');
    }

    try {
      final response = await _apiService.makeGorgiasRequest(
        endpoint: '/users',
        method: 'GET',
      );

      if (response['success'] == true) {
        final users = response['data']['data'] ?? [];

        // Cache the result
        await _cacheManager.cacheData(_usersCacheKey, {
          'data': users,
          'timestamp': DateTime.now().toIso8601String(),
        });

        return users;
      } else {
        throw Exception(response['message'] ?? 'Failed to fetch users');
      }
    } catch (e) {
      // Try cached data
      try {
        final cachedData = await _cacheManager.getData(_usersCacheKey);
        if (cachedData != null) {
          return List<dynamic>.from(cachedData['data']);
        }
      } catch (cacheError) {
        // Ignore
      }

      throw Exception('Failed to fetch users: ${e.toString()}');
    }
  }

  @override
  Future<Map<String, dynamic>> getCurrentUser() async {
    if (!await _networkInfo.isConnected) {
      throw Exception('No internet connection');
    }

    try {
      final response = await _gorgiasService.getCurrentUser();
      
      if (response['success'] == true) {
        return response['data'] ?? {};
      } else {
        throw Exception(response['message'] ?? 'Failed to fetch current user');
      }
    } catch (e) {
      throw Exception('Failed to fetch current user: ${e.toString()}');
    }
  }

  @override
  Future<Map<String, dynamic>> getTicketStats() async {
    print('[GorgiasRepository] getTicketStats called');
    // Try cache first
    try {
      final cachedData = await _cacheManager.getData(_statsCacheKey);
      if (cachedData != null) {
        final cacheTime = DateTime.parse(cachedData['timestamp']);
        if (DateTime.now().difference(cacheTime) < _statsCacheTimeout) {
          print('[GorgiasRepository] Returning cached data');
          return Map<String, dynamic>.from(cachedData['data']);
        }
      }
    } catch (e) {
      print('[GorgiasRepository] Cache error: $e');
      // Continue to network call
    }

    if (!await _networkInfo.isConnected) {
      try {
        final cachedData = await _cacheManager.getData(_statsCacheKey);
        if (cachedData != null) {
          return Map<String, dynamic>.from(cachedData['data']);
        }
      } catch (e) {
        // No cached data
      }
      throw Exception('No internet connection and no cached data available');
    }

    try {
      print('[GorgiasRepository] Making API call to /tickets for stats calculation');
      final response = await _apiService.makeGorgiasRequest(
        endpoint: '/tickets',
        method: 'GET',
        // queryParams: {'limit': '100'}, // Temporarily removed to test basic endpoint
      );
      print('[GorgiasRepository] API response: $response');

      if (response['success'] == true) {
        final ticketsData = response['data'] ?? {};
        final tickets = ticketsData['data'] as List<dynamic>? ?? [];
        print('[GorgiasRepository] Processing ${tickets.length} tickets for stats');
        
        // Calculate statistics from tickets
        final stats = _calculateStatsFromTickets(tickets);
        print('[GorgiasRepository] Calculated stats: $stats');

        // Cache the result
        await _cacheManager.cacheData(_statsCacheKey, {
          'data': stats,
          'timestamp': DateTime.now().toIso8601String(),
        });
        print('[GorgiasRepository] Data cached successfully');

        return stats;
      } else {
        throw Exception(response['message'] ?? 'Failed to fetch stats');
      }
    } catch (e) {
      // Try cached data
      try {
        final cachedData = await _cacheManager.getData(_statsCacheKey);
        if (cachedData != null) {
          return Map<String, dynamic>.from(cachedData['data']);
        }
      } catch (cacheError) {
        // Ignore
      }

      throw Exception('Failed to fetch stats: ${e.toString()}');
    }
  }

  @override
  Future<void> clearCache() async {
    try {
      // Clear all Gorgias-related cache
      await _cacheManager.clearCacheByPrefix('gorgias_');
    } catch (e) {
      // Ignore cache clear errors
    }
  }

  Future<void> _clearTicketCaches(String ticketId) async {
    try {
      // Clear ticket details cache
      final detailsCacheKey = '${_ticketDetailsCacheKey}_$ticketId';
      await _cacheManager.removeData(detailsCacheKey);

      // Clear tickets list cache (all variations)
      await _cacheManager.clearCacheByPrefix(_ticketsCacheKey);

      // Clear stats cache
      await _cacheManager.removeData(_statsCacheKey);
    } catch (e) {
      // Ignore cache clear errors
    }
  }

  /// Calculate statistics from a list of tickets
  Map<String, dynamic> _calculateStatsFromTickets(List<dynamic> tickets) {
    if (tickets.isEmpty) {
      return {
        'total_tickets': 0,
        'open_tickets': 0,
        'closed_tickets': 0,
        'pending_tickets': 0,
        'unassigned_tickets': 0,
        'avg_response_time': 0.0,
        'avg_resolution_time': 0.0,
        'today_tickets': 0,
        'week_tickets': 0,
        'month_tickets': 0,
        'tickets_by_status': <String, int>{},
        'tickets_by_priority': <String, int>{},
        'tickets_by_channel': <String, int>{},
        'trends': <Map<String, dynamic>>[],
      };
    }

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final weekAgo = now.subtract(const Duration(days: 7));
    final monthAgo = DateTime(now.year, now.month - 1, now.day);

    int totalTickets = tickets.length;
    int openTickets = 0;
    int closedTickets = 0;
    int pendingTickets = 0;
    int unassignedTickets = 0;
    int todayTickets = 0;
    int weekTickets = 0;
    int monthTickets = 0;

    Map<String, int> ticketsByStatus = {};
    Map<String, int> ticketsByPriority = {};
    Map<String, int> ticketsByChannel = {};

    for (final ticket in tickets) {
      final status = ticket['status']?.toString().toLowerCase() ?? 'unknown';
      final priority = ticket['priority']?.toString().toLowerCase() ?? 'normal';
      final channel = ticket['channel']?.toString().toLowerCase() ?? 'unknown';
      final assigneeUser = ticket['assignee_user'];
      
      // Parse created_datetime if available
      DateTime? createdDate;
      try {
        final createdStr = ticket['created_datetime']?.toString();
        if (createdStr != null) {
          createdDate = DateTime.parse(createdStr);
        }
      } catch (e) {
        // Ignore parsing errors
      }

      // Count by status
      switch (status) {
        case 'open':
          openTickets++;
          break;
        case 'closed':
          closedTickets++;
          break;
        case 'pending':
          pendingTickets++;
          break;
      }

      // Count unassigned tickets
      if (assigneeUser == null) {
        unassignedTickets++;
      }

      // Count time-based tickets
      if (createdDate != null) {
        if (createdDate.isAfter(today)) {
          todayTickets++;
        }
        if (createdDate.isAfter(weekAgo)) {
          weekTickets++;
        }
        if (createdDate.isAfter(monthAgo)) {
          monthTickets++;
        }
      }

      // Group by status, priority, and channel
      ticketsByStatus[status] = (ticketsByStatus[status] ?? 0) + 1;
      ticketsByPriority[priority] = (ticketsByPriority[priority] ?? 0) + 1;
      ticketsByChannel[channel] = (ticketsByChannel[channel] ?? 0) + 1;
    }

    return {
      'total_tickets': totalTickets,
      'open_tickets': openTickets,
      'closed_tickets': closedTickets,
      'pending_tickets': pendingTickets,
      'unassigned_tickets': unassignedTickets,
      'avg_response_time': 2.5, // Mock average response time in hours
      'avg_resolution_time': 24.0, // Mock average resolution time in hours
      'today_tickets': todayTickets,
      'week_tickets': weekTickets,
      'month_tickets': monthTickets,
      'tickets_by_status': ticketsByStatus,
      'tickets_by_priority': ticketsByPriority,
      'tickets_by_channel': ticketsByChannel,
      'trends': <Map<String, dynamic>>[], // Empty trends for now
    };
  }
  
  @override
  Stream<Map<String, dynamic>> getRealtimeUpdates() {
    return _gorgiasService.ticketUpdates;
  }
}
