import 'package:equatable/equatable.dart';

abstract class WordPressEvent extends Equatable {
  const WordPressEvent();
  
  @override
  List<Object?> get props => [];
}

class FetchWordPressPosts extends WordPressEvent {
  final int page;
  final int perPage;
  
  const FetchWordPressPosts({this.page = 1, this.perPage = 10});
  
  @override
  List<Object?> get props => [page, perPage];
}

class CreateWordPressPost extends WordPressEvent {
  final String title;
  final String content;
  final bool published;
  final String? excerpt;
  final List<String>? tags;
  final List<String>? categories;
  
  const CreateWordPressPost({
    required this.title,
    required this.content,
    this.published = true,
    this.excerpt,
    this.tags,
    this.categories,
  });
  
  @override
  List<Object?> get props => [title, content, published, excerpt, tags, categories];
}

class UpdateWordPressPost extends WordPressEvent {
  final int postId;
  final String? title;
  final String? content;
  final String? excerpt;
  final bool? published;
  final List<String>? tags;
  final List<String>? categories;
  
  const UpdateWordPressPost({
    required this.postId,
    this.title,
    this.content,
    this.excerpt,
    this.published,
    this.tags,
    this.categories,
  });
  
  @override
  List<Object?> get props => [postId, title, content, excerpt, published, tags, categories];
}

class DeleteWordPressPost extends WordPressEvent {
  final int postId;
  
  const DeleteWordPressPost({required this.postId});
  
  @override
  List<Object?> get props => [postId];
}