import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:icons_plus/icons_plus.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../widgets/app_reusable_text.dart';
import '../../models/gorgias_models.dart';

class TicketCardWidget extends StatelessWidget {
  final Ticket ticket;
  final VoidCallback? onTap;

  const TicketCardWidget({super.key, required this.ticket, this.onTap});

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'open':
        return Colors.green.withOpacity(0.15);
      case 'pending':
        return AppColors.amber300.withOpacity(0.15);
      case 'closed':
        return Colors.grey.withOpacity(0.15);
      case 'spam':
        return Colors.red.withOpacity(0.15);
      default:
        return AppColors.amber300.withOpacity(0.15);
    }
  }

  Color _getStatusTextColor(String status) {
    switch (status.toLowerCase()) {
      case 'open':
        return Colors.green.shade600;
      case 'pending':
        return Colors.orange.shade600;
      case 'closed':
        return Colors.grey.shade600;
      case 'spam':
        return Colors.red.shade600;
      default:
        return Colors.orange.shade600;
    }
  }

  @override
  Widget build(BuildContext context) {
    final statusColor = _getStatusColor(ticket.status);
    final statusTextColor = _getStatusTextColor(ticket.status);
    final customerName = ticket.customer.name;
    final avatarUrl = ticket.customer.avatar;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.cardDark,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: AppColors.border.withOpacity(0.3),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(isDark ? 0.1 : 0.03),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              radius: 26,
              backgroundColor:
                  isDark ? const Color(0xFF2C2F48) : const Color(0xFFE2E8F0),
              backgroundImage:
                  avatarUrl != null && avatarUrl.isNotEmpty
                      ? NetworkImage(avatarUrl)
                      : null,
              child:
                  avatarUrl == null || avatarUrl.isEmpty
                      ? Text(
                        customerName.isNotEmpty
                            ? customerName[0].toUpperCase()
                            : '?',
                        style: TextStyle(
                          color:
                              isDark
                                  ? AppColors.textPrimary
                                  : AppColors.primary,
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      )
                      : null,
            ),
            Gap(16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Row(
                          children: [
                            Flexible(
                              child: AppReusableText(
                                text: customerName,
                                fontWeight: FontWeight.w700,
                                fontSize: 16,
                                color: AppColors.textPrimary,
                                maxLines: 1,
                              ),
                            ),
                            if (ticket.isUnread) ...[
                              Gap(8),
                              Container(
                                width: 8,
                                height: 8,
                                decoration: BoxDecoration(
                                  color: AppColors.primary,
                                  shape: BoxShape.circle,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      AppReusableText(
                        text:
                            ticket.lastMessagePreview != null &&
                                    ticket.lastMessagePreview!.length > 10
                                ? '${ticket.lastMessagePreview!.substring(0, 10)}...'
                                : ticket.lastMessagePreview ?? '',
                        fontWeight: FontWeight.w400,
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ],
                  ),
                  AppReusableText(
                    text: ticket.lastMessagePreview ?? '',
                    fontWeight: FontWeight.w400,
                    fontSize: 13,
                    color: AppColors.textSecondary,
                    maxLines: 2,
                  ),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: statusColor,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: AppReusableText(
                          text: ticket.status.toUpperCase(),
                          fontWeight: FontWeight.w700,
                          fontSize: 10,
                          color: statusTextColor,
                        ),
                      ),
                      if (ticket.priority != 'normal') ...[
                        Gap(8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color:
                                ticket.priority == 'high'
                                    ? Colors.red.withOpacity(0.15)
                                    : Colors.orange.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: AppReusableText(
                            text: ticket.priority.toUpperCase(),
                            fontWeight: FontWeight.w700,
                            fontSize: 10,
                            color:
                                ticket.priority == 'high'
                                    ? Colors.red.shade600
                                    : Colors.orange.shade600,
                          ),
                        ),
                      ],
                      if (ticket.channel.isNotEmpty) ...[
                        const Spacer(),
                        Icon(
                          Iconsax.message_outline,
                          size: 16,
                          color: AppColors.textSecondary,
                        ),
                      ],
                    ],
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
