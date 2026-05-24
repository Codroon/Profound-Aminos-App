import 'package:dio/dio.dart';
import '../error/error_handler.dart';
import 'dart:convert';
import './crediential_storage_service.dart';

class WooCommerceService {
  final Dio _dio = Dio();
  String _baseUrl = '';
  String _consumerKey = '';
  String _consumerSecret = '';

  Future<void> _loadCredentials() async {
    final storage = CredentialStorageService();
    final creds = await storage.getCredentials();
    _baseUrl = creds['wooUrl'] ?? '';
    _consumerKey = creds['wooKey'] ?? '';
    _consumerSecret = creds['wooSecret'] ?? '';
  }

  Map<String, String> _basicAuthHeader() {
    String basicAuth =
        'Basic ${base64Encode(utf8.encode('$_consumerKey:$_consumerSecret'))}';
    return {'Authorization': basicAuth};
  }

  Map<String, dynamic> _urlParams(Map<String, dynamic> params) {
    return params;
  }

  Future<List<dynamic>> getProducts({int page = 1, int perPage = 20, String? searchTerm}) async {
    await _loadCredentials();
    try {
      final Map<String, dynamic> params = {'page': page, 'per_page': perPage};
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

  Future<List<dynamic>> getOrdersByDateRange({
    required String after,
    required String before,
    int page = 1,
    int perPage = 10,
  }) async {
    await _loadCredentials();
    try {
      final response = await _dio.get(
        '$_baseUrl/wp-json/wc/v3/orders',
        queryParameters: _urlParams({
          'after': after,
          'before': before,
          'page': page,
          'per_page': perPage,
          'orderby': 'date',
          'order': 'desc',
        }),
        options: Options(headers: _basicAuthHeader()),
      );
      return response.data as List<dynamic>;
    } catch (e) {
      throw ErrorHandler.handleError(e);
    }
  }

  Future<int> getOrdersTotalCount({String? after, String? before}) async {
    await _loadCredentials();
    try {
      final params = _urlParams({'page': 1, 'per_page': 1});
      if (after != null) params['after'] = after;
      if (before != null) params['before'] = before;

      final response = await _dio.get(
        '$_baseUrl/wp-json/wc/v3/orders',
        queryParameters: params,
        options: Options(headers: _basicAuthHeader()),
      );
      final total = response.headers.value('x-wp-total');
      return int.tryParse(total ?? '0') ?? 0;
    } catch (e) {
      throw ErrorHandler.handleError(e);
    }
  }

  Future<int> getProductsTotalCount() async {
    await _loadCredentials();
    try {
      final response = await _dio.get(
        '$_baseUrl/wp-json/wc/v3/products',
        queryParameters: _urlParams({'page': 1, 'per_page': 1}),
        options: Options(headers: _basicAuthHeader()),
      );
      final total = response.headers.value('x-wp-total');
      return int.tryParse(total ?? '0') ?? 0;
    } catch (e) {
      throw ErrorHandler.handleError(e);
    }
  }

  Future<List<dynamic>> getSalesReport({
    String? dateMin,
    String? dateMax,
    String? period,
  }) async {
    await _loadCredentials();
    try {
      final params = _urlParams({});
      if (dateMin != null) params['date_min'] = dateMin;
      if (dateMax != null) params['date_max'] = dateMax;
      if (period != null) params['period'] = period;

      final response = await _dio.get(
        '$_baseUrl/wp-json/wc/v3/reports/sales',
        queryParameters: params,
        options: Options(headers: _basicAuthHeader()),
      );
      return response.data as List<dynamic>;
    } on DioException catch (e) {
      throw ErrorHandler.handleDioError(e);
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
        queryParameters: {'force': true},
        options: Options(headers: _basicAuthHeader()),
      );
    } catch (e) {
      throw ErrorHandler.handleError(e);
    }
  }

  Future<Map<String, dynamic>> getRevenueStats({
    String? after,
    String? before,
    String? interval,
  }) async {
    await _loadCredentials();
    try {
      final Map<String, dynamic> params = {};
      if (after != null) params['after'] = after;
      if (before != null) params['before'] = before;
      if (interval != null) params['interval'] = interval;

      final response = await _dio.get(
        '$_baseUrl/wp-json/wc-analytics/reports/revenue/stats',
        queryParameters: _urlParams(params),
        options: Options(headers: _basicAuthHeader()),
      );
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw ErrorHandler.handleDioError(e);
    } catch (e) {
      throw ErrorHandler.handleError(e);
    }
  }
}