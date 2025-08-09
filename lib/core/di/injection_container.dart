import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:woo_management_app/core/storage/cache_manager.dart';
import 'package:woo_management_app/features/analytics/bloc/analytics_bloc.dart';
import 'package:woo_management_app/features/analytics/repository/analytics_repository.dart';
import 'package:woo_management_app/features/products/bloc/product_bloc.dart';
import 'package:woo_management_app/features/products/repository/product_repository.dart';

// Add these imports
import 'package:woo_management_app/features/word_press/bloc/wordpress_bloc.dart';
import 'package:woo_management_app/features/word_press/repository/word_press_repo.dart';
import '../services/wordpress_service.dart';
import '../network/network_info.dart';
import '../storage/local_storage.dart';

final sl = GetIt.instance;

Future<void> init() async {
  // BLoCs
  sl.registerFactory(() => AnalyticsBloc(repository: sl()));

  // Repositories
  sl.registerLazySingleton<AnalyticsRepository>(
    () => AnalyticsRepositoryImpl(networkInfo: sl(), cacheManager: sl()),
  );

  // Product Repository
  sl.registerLazySingleton<ProductRepository>(
    () => ProductRepositoryImpl(networkInfo: sl(), cacheManager: sl()),
  );

  // Product Bloc
  sl.registerFactory(() => ProductBloc(repository: sl()));

  // Core
  sl.registerLazySingleton<NetworkInfo>(() => NetworkInfoImpl());
  sl.registerLazySingleton<CacheManager>(() => CacheManager(sl()));
  sl.registerLazySingleton<LocalStorage>(() => LocalStorageImpl(sl()));

  // External
  final sharedPreferences = await SharedPreferences.getInstance();
  sl.registerLazySingleton(() => sharedPreferences);

  // WordPress Repository
  sl.registerLazySingleton<WordPressRepository>(
    () => WordPressRepositoryImpl(
      networkInfo: sl(),
      cacheManager: sl(),
      wordpressService: sl(),
    ),
  );

  // WordPress Bloc
  sl.registerFactory(() => WordPressBloc(repository: sl()));

  // WordPress Service
  sl.registerLazySingleton<WordpressService>(() => WordpressService());
}
