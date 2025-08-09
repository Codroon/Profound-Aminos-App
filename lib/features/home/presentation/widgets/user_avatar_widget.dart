import 'package:flutter/material.dart';
import 'package:gap/gap.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../widgets/app_reusable_text.dart';

class UserAvatarWidget extends StatelessWidget {
  const UserAvatarWidget({
    super.key,
    required this.text,
    required this.userImage,
  });

  final String text;
  final String userImage;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 220,
      child: Row(
        children: [
          CircleAvatar(radius: 24, backgroundImage: AssetImage(userImage)),
          const Gap(12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AppReusableText(
                text: 'Welcome Back to!',
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
              AppReusableText(
                text: text,
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: AppColors.info,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
