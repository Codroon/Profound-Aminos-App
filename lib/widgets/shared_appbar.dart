import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';
import '../core/theme/app_text_style.dart';

class SharedAppbar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final Function()? onLeading;
  final String? desc;
  final Color backgroundColor;
  final bool? automaticallyImplyLeading;
  final bool? centerTitle;

  final List<Widget>? actions;
  const SharedAppbar({
    super.key,
    required this.title,
    this.onLeading,
    this.desc,
    this.backgroundColor = AppColors.backgroundDark,
    this.automaticallyImplyLeading = true,
    this.actions,
    this.centerTitle = true,
  });

  @override
  Widget build(BuildContext context) {
    return AppBar(
      actions: actions,
      centerTitle: centerTitle,
      backgroundColor: backgroundColor,
      surfaceTintColor: backgroundColor,
      automaticallyImplyLeading: automaticallyImplyLeading ?? true,
      titleSpacing: 0,
      elevation: 0,
      leading:
          (automaticallyImplyLeading ?? true)
              ? IconButton(
                onPressed: onLeading ?? () => Navigator.pop(context),
                icon: const Icon(
                  Icons.arrow_back_ios_new_rounded,
                  weight: 600,
                  size: 20,
                  color: AppColors.surfaceLight,
                ),
              )
              : null,
      title:
          desc == null
              ? Text(title, style: AppTextStyles.appBarTextStyle)
              : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: AppTextStyles.appBarTextStyle),
                  const SizedBox(height: 8),
                  Text(desc ?? ""),
                ],
              ),
    );
  }

  @override
  Size get preferredSize => const Size(double.infinity, 60);
}
