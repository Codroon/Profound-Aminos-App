import 'api_credential_service.dart';

class GorgiasService {
  final ApiService apiService;

  GorgiasService(this.apiService);

  Future<Map<String, dynamic>> getCurrentUser() async {
    return {'success': true, 'data': {}};
  }

  Future<Map<String, dynamic>> getTicketById(String ticketId) async {
    return {'success': true, 'data': {}};
  }

  Stream<Map<String, dynamic>> get ticketUpdates async* {
    yield {};
  }
}
