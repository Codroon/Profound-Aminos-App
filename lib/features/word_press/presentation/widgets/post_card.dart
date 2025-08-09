import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:gap/gap.dart';
import 'package:icons_plus/icons_plus.dart';
import 'package:woo_management_app/core/theme/app_colors.dart';
import 'package:woo_management_app/features/word_press/presentation/pages/word_press_post_edit_page.dart';
import 'package:woo_management_app/widgets/app_reusable_text.dart';

import '../../bloc/wordpress_bloc.dart';
import '../../bloc/wordpress_event.dart';

class PostCard extends StatelessWidget {
  final Map<String, dynamic> post;
  final WordPressBloc bloc;

  const PostCard({super.key, required this.post, required this.bloc});

  String _formatDate(String? dateString) {
    if (dateString == null) return 'Unknown date';

    try {
      final date = DateTime.parse(dateString);
      return '${date.day}/${date.month}/${date.year}';
    } catch (e) {
      return 'Invalid date';
    }
  }

  void _showDeleteConfirmation(BuildContext context, int postId) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            title: const Text('Delete Post'),
            content: const Text(
              'Are you sure you want to delete this post? This action cannot be undone.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text('Cancel', style: TextStyle(color: Colors.white)),
              ),
              TextButton(
                onPressed: () {
                  bloc.add(DeleteWordPressPost(postId: postId));
                  Navigator.pop(context);
                },
                style: TextButton.styleFrom(foregroundColor: Colors.red),
                child: const Text('Delete'),
              ),
            ],
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final title = post['title']?['rendered'] ?? 'Untitled';
    final content = post['content']?['rendered'] ?? '';
    final excerpt = post['excerpt']?['rendered'] ?? '';
    final date = _formatDate(post['date']);
    final status = post['status'] ?? 'unknown';
    final postId = post['id'] as int?;

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: AppReusableText(
                    text: title,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color:
                        status == 'publish'
                            ? AppColors.primary
                            : AppColors.greyB3,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    status,
                    style: const TextStyle(color: Colors.white, fontSize: 12),
                  ),
                ),
              ],
            ),
            const Gap(8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                AppReusableText(
                  text: 'Published on: $date',
                  fontSize: 12,
                  fontWeight: FontWeight.w400,
                  color: AppColors.greyB3,
                ),
                if (postId != null)
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: Icon(Iconsax.edit_outline, size: 18),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder:
                                  (context) => WordPressPostEditPage(
                                    post: post,
                                    bloc: bloc,
                                  ),
                            ),
                          ).then((_) {
                            if (!bloc.isClosed) {
                              bloc.add(const FetchWordPressPosts());
                            }
                          });
                        },
                        tooltip: 'Edit Post',
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        icon: Icon(
                          Iconsax.trash_outline,
                          size: 18,
                          color: Colors.red,
                        ),
                        onPressed: () {
                          _showDeleteConfirmation(context, postId);
                        },
                        tooltip: 'Delete Post',
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    ],
                  ),
              ],
            ),
            const Gap(16),
            SizedBox(
              height: 100,
              child: SingleChildScrollView(
                child: Html(
                  data: excerpt,
                  style: {
                    'body': Style(
                      fontSize: FontSize(14),
                      color: AppColors.greyB3,
                      margin: Margins.zero,
                      padding: HtmlPaddings.zero,
                    ),
                  },
                ),
              ),
            ),
            const Gap(16),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton.icon(
                  onPressed: () {
                    // Show full post content in a dialog
                    showDialog(
                      context: context,
                      builder:
                          (context) => AlertDialog(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            scrollable: true,

                            title: AppReusableText(
                              text: title,
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                            ),
                            content: SingleChildScrollView(
                              child: Html(data: content),
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context),
                                child: const Text(
                                  'Close',
                                  style: TextStyle(color: Colors.white),
                                ),
                              ),
                            ],
                          ),
                    );
                  },
                  icon: const Icon(Icons.article),
                  label: const Text('Read More'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
