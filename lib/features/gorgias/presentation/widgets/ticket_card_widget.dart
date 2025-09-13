import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
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
        return Colors.green.shade400;
      case 'pending':
        return AppColors.amber300;
      case 'closed':
        return Colors.grey.shade400;
      case 'spam':
        return Colors.red.shade400;
      default:
        return AppColors.amber300;
    }
  }

  Color _getStatusTextColor(String status) {
    switch (status.toLowerCase()) {
      case 'open':
        return Colors.white;
      case 'pending':
        return Colors.black;
      case 'closed':
        return Colors.white;
      case 'spam':
        return Colors.white;
      default:
        return Colors.black;
    }
  }

  @override
  Widget build(BuildContext context) {
    final statusColor = _getStatusColor(ticket.status);
    final statusTextColor = _getStatusTextColor(ticket.status);
    final customerName = ticket.customer?.name ?? 'Unknown Customer';
    final avatarUrl = ticket.customer?.avatar;

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
            CircleAvatar(
              radius: 28,
              backgroundColor: Colors.grey.shade600,
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
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 20,
                        ),
                      )
                      : null,
            ),
            const Gap(16),
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
                                fontSize: 18,
                                color: AppColors.textPrimary,
                                maxLines: 1,
                              ),
                            ),
                            if (ticket.isUnread) ...[
                              const Gap(8),
                              Container(
                                width: 8,
                                height: 8,
                                decoration: BoxDecoration(
                                  color: Colors.blue.shade400,
                                  shape: BoxShape.circle,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      AppReusableText(
                        text:
                            ticket.lastMessagePreview != null
                                ? ticket.lastMessagePreview!.substring(0, 10)
                                : '',
                        fontWeight: FontWeight.w400,
                        fontSize: 14,
                        color: AppColors.greyA9,
                      ),
                    ],
                  ),
                  const Gap(4),
                  AppReusableText(
                    text: ticket.lastMessagePreview ?? '',
                    fontWeight: FontWeight.w400,
                    fontSize: 14,
                    color: AppColors.greyA9,
                    maxLines: 2,
                  ),
                  const Gap(8),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: statusColor,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: AppReusableText(
                          text: ticket.status.toUpperCase(),
                          fontWeight: FontWeight.w600,
                          fontSize: 11,
                          color: statusTextColor,
                        ),
                      ),
                      if (ticket.priority != 'normal') ...[
                        const Gap(8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color:
                                ticket.priority == 'high'
                                    ? Colors.red.shade100
                                    : Colors.orange.shade100,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: AppReusableText(
                            text: ticket.priority.toUpperCase(),
                            fontWeight: FontWeight.w500,
                            fontSize: 10,
                            color:
                                ticket.priority == 'high'
                                    ? Colors.red.shade800
                                    : Colors.orange.shade800,
                          ),
                        ),
                      ],
                      if (ticket.channel.isNotEmpty) ...[
                        const Gap(8),
                        Icon(
                          // ticket.channelIcon,
                          Icons.message,
                          size: 16,
                          color: AppColors.greyA9,
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
