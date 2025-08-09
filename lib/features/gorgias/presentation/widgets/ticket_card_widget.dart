import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../widgets/app_reusable_text.dart';

class TicketCardWidget extends StatelessWidget {
  final String avatarUrl;
  final String userName;
  final String message;
  final String status;
  final String timeAgo;
  final Color statusColor;
  final Color statusTextColor;
  final VoidCallback? onTap;

  const TicketCardWidget({
    super.key,
    required this.avatarUrl,
    required this.userName,
    required this.message,
    required this.status,
    required this.timeAgo,
    this.statusColor = AppColors.amber300,
    this.statusTextColor = Colors.black, this.onTap, // Default black text
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 10),
        decoration: BoxDecoration(
          color: AppColors.cardDark,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(radius: 28, backgroundImage: NetworkImage(avatarUrl)),
            const Gap(16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: AppReusableText(
                          text: userName,
                          fontWeight: FontWeight.w700,
                          fontSize: 18,
                          color: AppColors.textPrimary,
                          maxLines: 1,
                        ),
                      ),
                      AppReusableText(
                        text: timeAgo,
                        fontWeight: FontWeight.w400,
                        fontSize: 14,
                        color: AppColors.greyA9,
                      ),
                    ],
                  ),
                  const Gap(4),
                  AppReusableText(
                    text: message,
                    fontWeight: FontWeight.w400,
                    fontSize: 14,
                    color: AppColors.greyA9,
                    maxLines: 2,
                  ),
                  const Gap(12),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: statusColor,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: AppReusableText(
                      text: status,
                      fontWeight: FontWeight.w500,
                      fontSize: 12,
                      color: statusTextColor,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
