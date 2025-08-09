import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:woo_management_app/features/word_press/repository/word_press_repo.dart';
import 'wordpress_event.dart';
import 'wordpress_state.dart';

class WordPressBloc extends Bloc<WordPressEvent, WordPressState> {
  final WordPressRepository repository;

  WordPressBloc({required this.repository}) : super(WordPressInitial()) {
    on<FetchWordPressPosts>(_onFetchPosts);
    on<CreateWordPressPost>(_onCreatePost);
    on<UpdateWordPressPost>(_onUpdatePost);
    on<DeleteWordPressPost>(_onDeletePost);
  }

  Future<void> _onFetchPosts(
    FetchWordPressPosts event,
    Emitter<WordPressState> emit,
  ) async {
    emit(WordPressLoading());
    try {
      final posts = await repository.getPosts(
        page: event.page,
        perPage: event.perPage,
      );
      emit(WordPressPostsLoaded(posts));
    } catch (e) {
      emit(WordPressError('Failed to fetch posts: ${e.toString()}'));
    }
  }

  Future<void> _onCreatePost(
    CreateWordPressPost event,
    Emitter<WordPressState> emit,
  ) async {
    emit(WordPressLoading());
    try {
      final post = await repository.createPost(
        title: event.title,
        content: event.content,
        published: event.published,
        excerpt: event.excerpt,
        tags: event.tags,
        categories: event.categories,
      );
      emit(WordPressPostCreated(post));
      // Remove automatic refresh - let the parent page handle it
    } catch (e) {
      emit(WordPressError('Failed to create post: ${e.toString()}'));
    }
  }
  
  Future<void> _onUpdatePost(
    UpdateWordPressPost event,
    Emitter<WordPressState> emit,
  ) async {
    emit(WordPressLoading());
    try {
      final post = await repository.updatePost(
        postId: event.postId,
        title: event.title,
        content: event.content,
        excerpt: event.excerpt,
        published: event.published,
        tags: event.tags,
        categories: event.categories,
      );
      emit(WordPressPostUpdated(post));
      // Remove automatic refresh - let the parent page handle it
    } catch (e) {
      emit(WordPressError('Failed to update post: ${e.toString()}'));
    }
  }
  
  Future<void> _onDeletePost(
    DeleteWordPressPost event,
    Emitter<WordPressState> emit,
  ) async {
    emit(WordPressLoading());
    try {
      await repository.deletePost(event.postId);
      emit(WordPressPostDeleted(event.postId));
      // Remove automatic refresh - let the parent page handle it
    } catch (e) {
      emit(WordPressError('Failed to delete post: ${e.toString()}'));
    }
  }
}
