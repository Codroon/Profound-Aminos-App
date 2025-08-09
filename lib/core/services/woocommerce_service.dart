import 'dart:convert';
import 'package:dio/dio.dart';
import '../services/crediential_storage_service.dart';
import '../error/error_handler.dart';

class WooCommerceService {
  final Dio _dio;
  final CredentialStorageService _credentialStorage;

  String? _baseUrl;
  String? _consumerKey;
  String? _consumerSecret;

  WooCommerceService({Dio? dio, CredentialStorageService? credentialStorage})
      : _dio = dio ?? Dio(),
        _credentialStorage = credentialStorage ?? CredentialStorageService();

  Future<void> _loadCredentials() async {
    final creds = await _credentialStorage.getCredentials();
    _baseUrl = creds['wooUrl'];
    _consumerKey = creds['wooKey'];
    _consumerSecret = creds['wooSecret'];
  }

  Map<String, String> _basicAuthHeader() {
    final auth = base64Encode(utf8.encode('$_consumerKey:$_consumerSecret'));
    return {'Authorization': 'Basic $auth'};
  }

  Map<String, dynamic> _urlParams([Map<String, dynamic>? params]) {
    return {
      'consumer_key': _consumerKey,
      'consumer_secret': _consumerSecret,
      ...?params,
    };
  }

  Future<List<dynamic>> getProducts({int page = 1, int perPage = 20, String? searchTerm}) async {
    await _loadCredentials();
    try {
      final params = <String, dynamic>{'page': page, 'per_page': perPage};
      if (searchTerm != null && searchTerm.isNotEmpty) {
        params['search'] = searchTerm;
      }
      final response = await _dio.get(
        '$_baseUrl/wp-json/wc/v3/products',
        queryParameters: _urlParams(params),
        options: Options(headers: _basicAuthHeader()),
      );
      return response.data as List<dynamic>;
    } catch (e) {
      throw ErrorHandler.handleError(e);
    }
  }

  Future<Map<String, dynamic>> createProduct(Map<String, dynamic> data) async {
    await _loadCredentials();
    try {
      final response = await _dio.post(
        '$_baseUrl/wp-json/wc/v3/products',
        data: data,
        queryParameters: _urlParams(),
        options: Options(headers: _basicAuthHeader()),
      );
      return response.data as Map<String, dynamic>;
    } catch (e) {
      throw ErrorHandler.handleError(e);
    }
  }

  Future<Map<String, dynamic>> updateProduct(int id, Map<String, dynamic> data) async {
    await _loadCredentials();
    try {
      final response = await _dio.put(
        '$_baseUrl/wp-json/wc/v3/products/$id',
        data: data,
        queryParameters: _urlParams(),
        options: Options(headers: _basicAuthHeader()),
      );
      return response.data as Map<String, dynamic>;
    } catch (e) {
      throw ErrorHandler.handleError(e);
    }
  }

  Future<void> deleteProduct(int id) async {
    await _loadCredentials();
    try {
      await _dio.delete(
        '$_baseUrl/wp-json/wc/v3/products/$id',
        queryParameters: _urlParams({'force': true}),
        options: Options(headers: _basicAuthHeader()),
      );
    } catch (e) {
      throw ErrorHandler.handleError(e);
    }
  }

  Future<List<dynamic>> getOrders({int page = 1, int perPage = 20}) async {
    await _loadCredentials();
    try {
      final response = await _dio.get(
        '$_baseUrl/wp-json/wc/v3/orders',
        queryParameters: _urlParams({'page': page, 'per_page': perPage}),
        options: Options(headers: _basicAuthHeader()),
      );
      return response.data as List<dynamic>;
    } catch (e) {
      throw ErrorHandler.handleError(e);
    }
  }

  Future<List<dynamic>> getSalesReport({String? dateMin, String? dateMax}) async {
    await _loadCredentials();
    try {
      // Default to last 30 days if no dates provided
      final now = DateTime.now();
      final defaultDateMin = dateMin ?? DateTime(now.year, now.month - 1, now.day).toIso8601String().split('T')[0];
      final defaultDateMax = dateMax ?? now.toIso8601String().split('T')[0];
      
      final params = {
        'date_min': defaultDateMin,
        'date_max': defaultDateMax,
      };
      
      final response = await _dio.get(
        '$_baseUrl/wp-json/wc/v3/reports/sales',
        queryParameters: _urlParams(params),
        options: Options(headers: _basicAuthHeader()),
      );
      print('[WooCommerceService] salesReport response: ${response.data}');
      return response.data as List<dynamic>;
    } on DioException catch (e) {
      print('[WooCommerceService] DioException: ${e.response?.statusCode} ${e.response?.data}');
      throw ErrorHandler.handleDioError(e);
    } catch (e) {
      print('[WooCommerceService] Unexpected error: $e');
      throw ErrorHandler.handleError(e);
    }
  }
}