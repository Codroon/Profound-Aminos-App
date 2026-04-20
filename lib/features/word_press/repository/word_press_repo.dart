import 'package:woo_management_app/core/network/network_info.dart';
import 'package:woo_management_app/core/storage/cache_manager.dart';
import '../../../core/constants/storage_constants.dart';
import '../../../core/services/wordpress_service.dart';

abstract class WordPressRepository {
  Future<List<dynamic>> getPosts({required int page, required int perPage});
  Future<Map<String, dynamic>> createPost({
    required String title, 
    required String content, 
    required bool published,
    String? excerpt,
    List<String>? tags,
    List<String>? categories,
  });
  Future<Map<String, dynamic>> updatePost({
    required int postId,
    String? title,
    String? content,
    String? excerpt,
    bool? published,
    List<String>? tags,
    List<String>? categories,
  });
  Future<void> deletePost(int postId);
  Future<void> clearPostsCache();
}

class WordPressRepositoryImpl implements WordPressRepository {
  final NetworkInfo networkInfo;
  final CacheManager cacheManager;
  final WordpressService wordpressService;

  WordPressRepositoryImpl({
    required this.networkInfo,
    required this.cacheManager,
    required this.wordpressService,
  });

  @override
  Future<List<dynamic>> getPosts({required int page, required int perPage}) async {
    final cacheKey = 'wp_posts_page_${page}_perPage_$perPage';
    if (await networkInfo.isConnected) {
      final posts = await wordpressService.getPosts(page: page, perPage: perPage);
      await cacheManager.cacheData(
        cacheKey,
        posts,
        duration: StorageConstants.shortCacheDuration,
      );
      return posts;
    } else {
      final cachedData = await cacheManager.getCachedData<List<dynamic>>(cacheKey);
      if (cachedData != null) {
        return cachedData;
      }
      throw Exception('No internet connection and no cached data available.');
    }
  }

  @override
  Future<Map<String, dynamic>> createPost({
    required String title,
    required String content,
    required bool published,
    String? excerpt,
    List<String>? tags,
    List<String>? categories,
  }) async {
    return await wordpressService.createPost(
      title: title,
      content: content,
      published: published,
      excerpt: excerpt,
      tags: tags,
      categories: categories,
    );
  }
  
  @override
  Future<Map<String, dynamic>> updatePost({
    required int postId,
    String? title,
    String? content,
    String? excerpt,
    bool? published,
    List<String>? tags,
    List<String>? categories,
  }) async {
    return await wordpressService.updatePost(
      postId: postId,
      title: title,
      content: content,
      excerpt: excerpt,
      published: published,
      tags: tags,
      categories: categories,
    );
  }
  
  @override
  Future<void> deletePost(int postId) async {
    await wordpressService.deletePost(postId);
    await clearPostsCache();
  }

  @override
  Future<void> clearPostsCache() async {
    await cacheManager.removeCachedData('wp_posts_page_1_perPage_10');
  }
}