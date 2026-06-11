import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:woo_management_app/core/network/network_info.dart';
import 'package:woo_management_app/core/services/api_credential_service.dart';
import 'package:woo_management_app/core/services/crediential_storage_service.dart';
import 'package:woo_management_app/core/services/gorgias_service.dart';
import 'package:woo_management_app/core/services/wordpress_service.dart';
import 'package:woo_management_app/core/storage/cache_manager.dart';
import 'package:woo_management_app/core/storage/local_storage.dart';
import 'package:woo_management_app/features/analytics/bloc/analytics_bloc.dart';
import 'package:woo_management_app/features/analytics/repository/analytics_repository.dart';
import 'package:woo_management_app/features/gorgias/bloc/gorgias_bloc.dart';
import 'package:woo_management_app/features/gorgias/repository/gorgias_repository.dart';
import 'package:woo_management_app/features/products/bloc/product_bloc.dart';
import 'package:woo_management_app/features/products/bloc/product_performance/product_performance_bloc.dart';
import 'package:woo_management_app/features/products/repository/product_repository.dart';
import 'package:woo_management_app/features/shipping/bloc/shipping_bloc.dart';
import 'package:woo_management_app/features/word_press/bloc/wordpress_bloc.dart';
import 'package:woo_management_app/features/word_press/repository/word_press_repo.dart';
import 'package:woo_management_app/features/notifications/bloc/notifications_bloc.dart';
import 'package:woo_management_app/features/notifications/repository/notification_repository.dart';

final sl = GetIt.instance;

Future<void> init() async {
  // External
  final sharedPreferences = await SharedPreferences.getInstance();
  sl.registerLazySingleton(() => sharedPreferences);

  // Core
  sl.registerLazySingleton<NetworkInfo>(() => NetworkInfoImpl());
  sl.registerLazySingleton<CacheManager>(() => CacheManager(sl()));
  sl.registerLazySingleton<LocalStorage>(() => LocalStorageImpl(sl()));

  // Credential services — registered only, never called during init
  sl.registerLazySingleton<CredentialStorageService>(
    () => CredentialStorageService(),
  );
  sl.registerLazySingleton<ApiService>(() => ApiService(<String, String>{}));

  // Services
  sl.registerLazySingleton<WordpressService>(() => WordpressService());
  sl.registerLazySingleton<GorgiasService>(() => GorgiasService(sl()));
  sl.registerLazySingleton<NotificationRepository>(() => NotificationRepository());

  // Repositories
  sl.registerLazySingleton<AnalyticsRepository>(
    () => AnalyticsRepositoryImpl(networkInfo: sl(), cacheManager: sl()),
  );
  sl.registerLazySingleton<ProductRepository>(
    () => ProductRepositoryImpl(networkInfo: sl(), cacheManager: sl()),
  );
  sl.registerLazySingleton<WordPressRepository>(
    () => WordPressRepositoryImpl(
      networkInfo: sl(),
      cacheManager: sl(),
      wordpressService: sl(),
    ),
  );
  sl.registerLazySingleton<GorgiasRepository>(
    () => GorgiasRepositoryImpl(
      networkInfo: sl(),
      cacheManager: sl(),
      apiService: sl(),
      gorgiasService: sl(),
    ),
  );

  // BLoCs
  sl.registerFactory(() => AnalyticsBloc(repository: sl()));
  sl.registerFactory(() => ProductBloc(repository: sl()));
  sl.registerFactory(() => ProductPerformanceBloc(repository: sl()));
  sl.registerFactory(() => WordPressBloc(repository: sl()));
  sl.registerFactory(
    () => GorgiasBloc(repository: sl(), connectivity: Connectivity()),
  );
  sl.registerFactory(() => ShippingBloc());
  sl.registerLazySingleton(() => NotificationsBloc(sl()));
}