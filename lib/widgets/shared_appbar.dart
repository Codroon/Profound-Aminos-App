import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';
import '../core/theme/app_text_style.dart';

class SharedAppbar extends StatefulWidget implements PreferredSizeWidget {
  final String title;
  final Function()? onLeading;
  final String? desc;
  final Color? backgroundColor;
  final bool? automaticallyImplyLeading;
  final bool? centerTitle;
  final List<Widget>? actions;

  const SharedAppbar({
    super.key,
    required this.title,
    this.onLeading,
    this.desc,
    this.backgroundColor,
    this.automaticallyImplyLeading = true,
    this.actions,
    this.centerTitle = true,
  });

  @override
  Size get preferredSize => const Size(double.infinity, 60);

  @override
  State<SharedAppbar> createState() => _SharedAppbarState();
}

class _SharedAppbarState extends State<SharedAppbar> {
  @override
  void initState() {
    super.initState();
    ThemeManager.themeModeNotifier.addListener(_onThemeChanged);
  }

  @override
  void dispose() {
    ThemeManager.themeModeNotifier.removeListener(_onThemeChanged);
    super.dispose();
  }

  void _onThemeChanged() => setState(() {});

  @override
  Widget build(BuildContext context) {
    return AppBar(
      actions: widget.actions,
      centerTitle: widget.centerTitle,
      backgroundColor: widget.backgroundColor ?? AppColors.backgroundDark,
      surfaceTintColor: widget.backgroundColor ?? AppColors.backgroundDark,
      automaticallyImplyLeading: widget.automaticallyImplyLeading ?? true,
      titleSpacing: 0,
      elevation: 0,
      leading:
          (widget.automaticallyImplyLeading ?? true)
              ? IconButton(
                onPressed: widget.onLeading ?? () => Navigator.pop(context),
                icon: Icon(
                  Icons.arrow_back_ios_new_rounded,
                  weight: 600,
                  size: 20,
                  color: AppColors.textPrimary,
                ),
              )
              : null,
      title:
          widget.desc == null
              ? Text(widget.title, style: AppTextStyles.appBarTextStyle)
              : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(widget.title, style: AppTextStyles.appBarTextStyle),
                  const SizedBox(height: 8),
                  Text(widget.desc ?? ''),
                ],
              ),
    );
  }
}
