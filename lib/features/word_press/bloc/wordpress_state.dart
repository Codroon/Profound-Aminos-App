import 'package:equatable/equatable.dart';

abstract class WordPressState extends Equatable {
  const WordPressState();
  
  @override
  List<Object?> get props => [];
}

class WordPressInitial extends WordPressState {}

class WordPressLoading extends WordPressState {}

class WordPressPostsLoaded extends WordPressState {
  final List<dynamic> posts;
  
  const WordPressPostsLoaded(this.posts);
  
  @override
  List<Object?> get props => [posts];
}

class WordPressPostCreated extends WordPressState {
  final Map<String, dynamic> post;
  
  const WordPressPostCreated(this.post);
  
  @override
  List<Object?> get props => [post];
}

class WordPressPostUpdated extends WordPressState {
  final Map<String, dynamic> post;
  
  const WordPressPostUpdated(this.post);
  
  @override
  List<Object?> get props => [post];
}

class WordPressPostDeleted extends WordPressState {
  final int postId;
  
  const WordPressPostDeleted(this.postId);
  
  @override
  List<Object?> get props => [postId];
}

class WordPressError extends WordPressState {
  final String message;
  
  const WordPressError(this.message);
  
  @override
  List<Object?> get props => [message];
}