import 'package:flutter_bloc/flutter_bloc.dart';
import 'product_event.dart';
import 'product_state.dart';
import '../repository/product_repository.dart';

class ProductBloc extends Bloc<ProductEvent, ProductState> {
  final ProductRepository repository;
  ProductBloc({required this.repository}) : super(ProductInitial()) {
    on<FetchProducts>(_onFetchProducts);
    on<CreateProduct>(_onCreateProduct);
    on<UpdateProduct>(_onUpdateProduct);
    on<DeleteProduct>(_onDeleteProduct);
  }

  Future<void> _onFetchProducts(FetchProducts event, Emitter<ProductState> emit) async {
    emit(ProductLoading());
    try {
      final products = await repository.getProducts(
        page: event.page, 
        perPage: event.perPage, 
        searchTerm: event.searchTerm
      );
      emit(ProductLoaded(products));
    } catch (e) {
      emit(ProductError('Failed to fetch products.'));
    }
  }

  Future<void> _onCreateProduct(CreateProduct event, Emitter<ProductState> emit) async {
    emit(ProductLoading());
    try {
      await repository.createProduct(event.data);
      emit(ProductOperationSuccess('Product created successfully.'));
      add(const FetchProducts());
    } catch (e) {
      emit(ProductError('Failed to create product.'));
    }
  }

  Future<void> _onUpdateProduct(UpdateProduct event, Emitter<ProductState> emit) async {
    emit(ProductLoading());
    try {
      await repository.updateProduct(event.id, event.data);
      emit(ProductOperationSuccess('Product updated successfully.'));
      add(const FetchProducts());
    } catch (e) {
      emit(ProductError('Failed to update product.'));
    }
  }

  Future<void> _onDeleteProduct(DeleteProduct event, Emitter<ProductState> emit) async {
    emit(ProductLoading());
    try {
      await repository.deleteProduct(event.id);
      emit(ProductOperationSuccess('Product deleted successfully.'));
      add(const FetchProducts());
    } catch (e) {
      emit(ProductError('Failed to delete product.'));
    }
  }
}