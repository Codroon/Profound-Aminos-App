import 'dart:io';

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
  final bool forceRefresh;

  const FetchProducts({this.page = 1, this.perPage = 20, this.searchTerm, this.forceRefresh = false});

  @override
  List<Object?> get props => [page, perPage, searchTerm, forceRefresh];
}

class CreateProduct extends ProductEvent {
  final Map<String, dynamic> data;
  final List<File> images;
  
  const CreateProduct(this.data, {required this.images});
  
  @override
  List<Object?> get props => [data, images];
}

class UpdateProduct extends ProductEvent {
  final int id;
  final Map<String, dynamic> data;
  final List<File> newImages; // New images to upload
  final List<String> existingImageUrls; // Existing image URLs to keep
  
  const UpdateProduct(
    this.id,
    this.data, {
    this.newImages = const [],
    this.existingImageUrls = const [],
  });
  
  @override
  List<Object?> get props => [id, data, newImages, existingImageUrls];
}

class DeleteProduct extends ProductEvent {
  final int id;
  const DeleteProduct(this.id);
  @override
  List<Object?> get props => [id];
}
