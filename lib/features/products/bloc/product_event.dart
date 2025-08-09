import 'package:equatable/equatable.dart';

abstract class ProductEvent extends Equatable {
  const ProductEvent();
  @override
  List<Object?> get props => [];
}

class FetchProducts extends ProductEvent {
  final int page;
  final int perPage;
  final String? searchTerm;
  const FetchProducts({this.page = 1, this.perPage = 20, this.searchTerm});
  @override
  List<Object?> get props => [page, perPage, searchTerm];
}

class CreateProduct extends ProductEvent {
  final Map<String, dynamic> data;
  const CreateProduct(this.data);
  @override
  List<Object?> get props => [data];
}

class UpdateProduct extends ProductEvent {
  final int id;
  final Map<String, dynamic> data;
  const UpdateProduct(this.id, this.data);
  @override
  List<Object?> get props => [id, data];
}

class DeleteProduct extends ProductEvent {
  final int id;
  const DeleteProduct(this.id);
  @override
  List<Object?> get props => [id];
}