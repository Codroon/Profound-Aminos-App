import 'dart:convert';
import 'dart:developer';
import 'dart:io';
import 'package:dio/dio.dart';
import '../error/error_handler.dart';
import './crediential_storage_service.dart';

class WordpressService {
  final Dio _dio = Dio();
  String _baseUrl = '';
  String _consumerKey = '';
  String _consumerSecret = '';
  String _wpUser = '';
  String _wpPass = '';

  Future<void> _loadCredentials() async {
    final storage = CredentialStorageService();
    final creds = await storage.getCredentials();
    _baseUrl = creds['wooUrl'] ?? '';
    _consumerKey = creds['wooKey'] ?? '';
    _consumerSecret = creds['wooSecret'] ?? '';
    _wpUser = creds['wpUser'] ?? '';   // WordPress username
    _wpPass = creds['wpPass'] ?? '';   // WordPress application password
  }

  // For WooCommerce REST API
  Map<String, String> _basicAuthHeader() {
    String basicAuth =
        'Basic ${base64Encode(utf8.encode('$_consumerKey:$_consumerSecret'))}';
    return {'Authorization': basicAuth};
  }

  // For WordPress REST API (media upload)
  Map<String, String> _wpAuthHeader() {
    String basicAuth =
        'Basic ${base64Encode(utf8.encode('$_wpUser:$_wpPass'))}';
    return {'Authorization': basicAuth};
  }

  Future<List<dynamic>> getPosts({required int page, required int perPage}) async {
    await _loadCredentials();
    try {
      final response = await _dio.get(
        '$_baseUrl/wp-json/wp/v2/posts',
        queryParameters: {'page': page, 'per_page': perPage},
        options: Options(headers: _wpAuthHeader()),
      );
      return response.data as List<dynamic>;
    } on DioException catch (e) {
      log('getPosts DioException: ${e.response?.statusCode} ${e.response?.data}', name: 'WordpressService');
      throw ErrorHandler.handleDioError(e);
    } catch (e) {
      throw ErrorHandler.handleError(e);
    }
  }

  Future<Map<String, dynamic>> createPost({
    required String title,
    required String content,
    required bool published,
    String? excerpt,
    List<String>? tags,
    List<String>? categories,
  }) async {
    await _loadCredentials();
    try {
      final response = await _dio.post(
        '$_baseUrl/wp-json/wp/v2/posts',
        data: {
          'title': title,
          'content': content,
          'status': published ? 'publish' : 'draft',
          if (excerpt != null) 'excerpt': excerpt,
          if (tags != null) 'tags': tags,
          if (categories != null) 'categories': categories,
        },
        options: Options(headers: _wpAuthHeader()),
      );
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      log('createPost DioException: ${e.response?.statusCode} ${e.response?.data}', name: 'WordpressService');
      throw ErrorHandler.handleDioError(e);
    } catch (e) {
      throw ErrorHandler.handleError(e);
    }
  }

  Future<Map<String, dynamic>> updatePost({
    required int postId,
    String? title,
    String? content,
    String? excerpt,
    bool? published,
    List<String>? tags,
    List<String>? categories,
  }) async {
    await _loadCredentials();
    try {
      final response = await _dio.put(
        '$_baseUrl/wp-json/wp/v2/posts/$postId',
        data: {
          if (title != null) 'title': title,
          if (content != null) 'content': content,
          if (excerpt != null) 'excerpt': excerpt,
          if (published != null) 'status': published ? 'publish' : 'draft',
          if (tags != null) 'tags': tags,
          if (categories != null) 'categories': categories,
        },
        options: Options(headers: _wpAuthHeader()),
      );
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      log('updatePost DioException: ${e.response?.statusCode} ${e.response?.data}', name: 'WordpressService');
      throw ErrorHandler.handleDioError(e);
    } catch (e) {
      throw ErrorHandler.handleError(e);
    }
  }

  Future<void> deletePost(int postId) async {
    await _loadCredentials();
    try {
      await _dio.delete(
        '$_baseUrl/wp-json/wp/v2/posts/$postId',
        options: Options(headers: _wpAuthHeader()),
      );
    } on DioException catch (e) {
      log('deletePost DioException: ${e.response?.statusCode} ${e.response?.data}', name: 'WordpressService');
      throw ErrorHandler.handleDioError(e);
    } catch (e) {
      throw ErrorHandler.handleError(e);
    }
  }

  Future<List<String>> uploadImagesToMediaLibrary(List<File> images) async {
    await _loadCredentials();

    if (_baseUrl.isEmpty) throw Exception('WordPress URL not configured');
    if (_wpUser.isEmpty || _wpPass.isEmpty) throw Exception('WordPress credentials not configured');

    final List<String> imageUrls = [];

    for (final file in images) {
      try {
        if (!await file.exists()) {
          log('File does not exist: ${file.path}', name: 'WordpressService');
          continue;
        }

        final fileName = file.path.split('/').last;
        final bytes = await file.readAsBytes();

        String contentType = 'image/jpeg';
        if (fileName.toLowerCase().endsWith('.png')) {
          contentType = 'image/png';
        } else if (fileName.toLowerCase().endsWith('.gif')) {
          contentType = 'image/gif';
        } else if (fileName.toLowerCase().endsWith('.webp')) {
          contentType = 'image/webp';
        }

        log('Uploading: $fileName ($contentType) ${bytes.length} bytes', name: 'WordpressService');

        final response = await _dio.post(
          '$_baseUrl/wp-json/wp/v2/media',
          data: bytes,
          options: Options(
            headers: {
              ..._wpAuthHeader(), // ✅ WordPress auth, not WooCommerce
              'Content-Type': contentType,
              'Content-Disposition': 'attachment; filename="$fileName"',
            },
          ),
        );

        log('Upload response status: ${response.statusCode}', name: 'WordpressService');

        if (response.statusCode == 201) {
          final responseData = response.data as Map<String, dynamic>;
          final sourceUrl = responseData['source_url'] as String?;
          if (sourceUrl != null) {
            imageUrls.add(sourceUrl);
            log('Uploaded successfully: $sourceUrl', name: 'WordpressService');
          }
        }
      } on DioException catch (e) {
        log('Upload DioException: ${e.response?.statusCode}', name: 'WordpressService');
        log('Upload error response: ${e.response?.data}', name: 'WordpressService');
        throw ErrorHandler.handleDioError(e);
      } catch (e) {
        log('Upload unexpected error: $e', name: 'WordpressService');
        throw ErrorHandler.handleError(e);
      }
    }

    return imageUrls;
  }
}