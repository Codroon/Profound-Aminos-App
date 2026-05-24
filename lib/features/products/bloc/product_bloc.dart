import 'dart:developer' as developer;
import 'package:flutter_bloc/flutter_bloc.dart';
import 'product_event.dart';
import 'product_state.dart';
import '../repository/product_repository.dart';

class ProductBloc extends Bloc<ProductEvent, ProductState> {
  final ProductRepository repository;
  List<dynamic>? _cachedProducts;
  
  ProductBloc({required this.repository}) : super(ProductInitial()) {
    on<FetchProducts>(_onFetchProducts);
    on<CreateProduct>(_onCreateProduct);
    on<UpdateProduct>(_onUpdateProduct);
    on<DeleteProduct>(_onDeleteProduct);
  }

  void _logError(String operation, dynamic error, StackTrace? stackTrace) {
    developer.log(
      'ERROR in ProductBloc.',
      name: 'ProductBloc',
      error: error.toString(),
      stackTrace: stackTrace,
    );
  }

  Future<void> _onFetchProducts(FetchProducts event, Emitter<ProductState> emit) async {
    if (_cachedProducts != null && event.searchTerm == null && !event.forceRefresh) {
      emit(ProductLoaded(_cachedProducts!));
      return;
    }
    
    emit(ProductLoading());
    try {
      final products = await repository.getProducts(
        page: event.page, 
        perPage: event.perPage, 
        searchTerm: event.searchTerm
      );
      _cachedProducts = products;
      emit(ProductLoaded(products));
    } catch (e, stackTrace) {
      _logError('_onFetchProducts', e, stackTrace);
      emit(ProductError('Unable to load products. Please check your connection and try again.'));
    }
  }

  Future<void> _onCreateProduct(CreateProduct event, Emitter<ProductState> emit) async {
    emit(ProductLoading());
    
    developer.log('=== CREATE PRODUCT === Images: ${event.images.length}', name: 'ProductBloc');
    
    try {
      // Build product data
      final productData = Map<String, dynamic>.from(event.data);
      
      // Upload images if any and get their URLs
      if (event.images.isNotEmpty) {
        developer.log('Uploading ${event.images.length} images...', name: 'ProductBloc');
        
        final imageUrls = await repository.uploadImages(event.images);
        
        developer.log('Got ${imageUrls.length} image URLs', name: 'ProductBloc');
        
        // Add images to product data using src URLs (RECOMMENDED approach)
        if (imageUrls.isNotEmpty) {
          productData['images'] = imageUrls.map((url) => {'src': url}).toList();
        }
      }
      
      developer.log('Creating product with images: ${productData['images']}', name: 'ProductBloc');
      
      await repository.createProduct(productData);
      emit(ProductOperationSuccess('Product created successfully.'));
      add(const FetchProducts());
    } catch (e, stackTrace) {
      _logError('_onCreateProduct', e, stackTrace);
      
      String userMessage = 'Failed to create product. Please try again.';
      final errorStr = e.toString().toLowerCase();
      
      if (errorStr.contains('socket') || errorStr.contains('connection')) {
        userMessage = 'Cannot connect to server. Please check your internet connection.';
      } else if (errorStr.contains('unauthorized') || errorStr.contains('401')) {
        userMessage = 'Authentication failed. Please check your API credentials.';
      } else if (errorStr.contains('not found') || errorStr.contains('404')) {
        userMessage = 'Server not found. Please verify your WooCommerce URL.';
      } else if (errorStr.contains('timeout')) {
        userMessage = 'Request timed out. Please try again.';
      }
      
      emit(ProductError(userMessage));
    }
  }

  Future<void> _onUpdateProduct(UpdateProduct event, Emitter<ProductState> emit) async {
    emit(ProductLoading());
    try {
      await repository.updateProduct(event.id, event.data);
      emit(ProductOperationSuccess('Product updated successfully.'));
      add(const FetchProducts());
    } catch (e, stackTrace) {
      _logError('_onUpdateProduct', e, stackTrace);
      emit(ProductError('Failed to update product. Please try again.'));
    }
  }

  Future<void> _onDeleteProduct(DeleteProduct event, Emitter<ProductState> emit) async {
    emit(ProductLoading());
    try {
      await repository.deleteProduct(event.id);
      emit(ProductOperationSuccess('Product deleted successfully.'));
      add(const FetchProducts());
    } catch (e, stackTrace) {
      _logError('_onDeleteProduct', e, stackTrace);
      emit(ProductError('Failed to delete product. Please try again.'));
    }
  }
}
