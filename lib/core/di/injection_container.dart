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

// Gorgias imports
import 'package:woo_management_app/features/gorgias/bloc/gorgias_bloc.dart';
import 'package:woo_management_app/features/gorgias/repository/gorgias_repository.dart';
import '../services/gorgias_service.dart';
import '../services/api_credential_service.dart';
import '../services/crediential_storage_service.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

// ReachShip imports
import 'package:woo_management_app/features/reach_ship/repository/reach_ship_repository.dart';
import 'package:woo_management_app/features/reach_ship/bloc/bloc.dart';
import '../services/reach_ship_service.dart';

final sl = GetIt.instance;

Future<void> init() async {
  // Repositories
  sl.registerLazySingleton<AnalyticsRepository>(
    () => AnalyticsRepositoryImpl(networkInfo: sl(), cacheManager: sl()),
  );

  // Product Repository
  sl.registerLazySingleton<ProductRepository>(
    () => ProductRepositoryImpl(networkInfo: sl(), cacheManager: sl()),
  );

  // BLoCs
  sl.registerFactory(() => AnalyticsBloc(repository: sl()));
  sl.registerFactory(() => ProductBloc(repository: sl()));
  
  // Register DataPreloadService - commented out as we're handling preloading in App class
  // sl.registerLazySingleton<DataPreloadService>(() => DataPreloadService(
  //   analyticsBloc: sl<AnalyticsBloc>(),
  //   productBloc: sl<ProductBloc>(),
  // ));

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

  // Credential Storage Service
  sl.registerLazySingleton<CredentialStorageService>(
    () => CredentialStorageService(),
  );

  // Gorgias Services
  sl.registerLazySingleton<ApiService>(() {
    // For now, provide empty credentials - will be loaded at runtime
    return ApiService(<String, String>{});
  });
  sl.registerLazySingleton<GorgiasService>(() => GorgiasService(sl()));

  // Gorgias Repository
  sl.registerLazySingleton<GorgiasRepository>(
    () => GorgiasRepositoryImpl(
      networkInfo: sl(),
      cacheManager: sl(),
      apiService: sl(),
      gorgiasService: sl(),
    ),
  );

  // Gorgias Bloc
  sl.registerFactory(
    () => GorgiasBloc(repository: sl(), connectivity: Connectivity()),
  );

  // ReachShip Service Factory
  sl.registerLazySingleton<Future<ReachShipService>>(() {
    return ReachShipService.withCredentials(sl<CredentialStorageService>());
  });

  // ReachShip Repository
  sl.registerLazySingleton<ReachShipRepository>(
    () => ReachShipRepository(reachShipService: sl()),
  );

  // ReachShip Bloc
  sl.registerFactory(
    () => ReachShipBloc(repository: sl(), connectivity: Connectivity()),
  );
}
