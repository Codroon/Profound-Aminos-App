import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gap/gap.dart';
import 'package:woo_management_app/features/gorgias/bloc/gorgias_bloc.dart';
import 'package:woo_management_app/features/gorgias/bloc/gorgias_event.dart';
import 'package:woo_management_app/features/gorgias/bloc/gorgias_state.dart';
import 'package:woo_management_app/features/gorgias/models/gorgias_models.dart';
import '../../../../widgets/app_reusable_text.dart';
import '../../../../widgets/custom_text_field.dart';
import '../../../../widgets/shared_appbar.dart';
import '../widgets/ticket_card_widget.dart';
import '../../../../core/theme/app_colors.dart';

class TicketChatScreen extends StatefulWidget {
  final String ticketId;

  const TicketChatScreen({super.key, required this.ticketId});

  @override
  State<TicketChatScreen> createState() => _TicketChatScreenState();
}

class _TicketChatScreenState extends State<TicketChatScreen> {
  final TextEditingController messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  Ticket? currentTicket;
  List<Message> messages = [];
  late GorgiasBloc _gorgiasBloc;

  @override
  void initState() {
    super.initState();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    // Get bloc reference safely
    _gorgiasBloc = context.read<GorgiasBloc>();

    // Start real-time updates for this ticket
    _gorgiasBloc.add(const StartRealtimeUpdates());

    // Fetch ticket details and messages when screen loads
    _gorgiasBloc.add(FetchTicketDetails(widget.ticketId));
    _gorgiasBloc.add(FetchTicketMessages(widget.ticketId));
  }

  @override
  void dispose() {
    // Stop real-time updates
    _gorgiasBloc.add(const StopRealtimeUpdates());
    messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _sendMessage() {
    final messageText = messageController.text.trim();
    if (messageText.isEmpty) return;

    _gorgiasBloc.add(
      SendMessage(
        ticketId: widget.ticketId,
        message: messageText,
        isInternal: false,
      ),
    );

    messageController.clear();

    // Scroll to bottom after sending message
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: SharedAppbar(
        title: 'Chat',
        actions: [
          IconButton(
            onPressed: () {
              // Refresh messages
              _gorgiasBloc.add(FetchTicketMessages(widget.ticketId));
            },
            icon: Icon(Icons.refresh_rounded),
          ),
         
        ],
      ),
      body: SafeArea(
        child: BlocConsumer<GorgiasBloc, GorgiasState>(
          listener: (context, state) {
            if (state is MessageSent) {
              // Refresh messages after sending
              context.read<GorgiasBloc>().add(
                FetchTicketMessages(widget.ticketId),
              );
            }

            if (state is MessageSendError) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Failed to send message: ${state.message}'),
                  backgroundColor: Colors.red,
                  action: SnackBarAction(
                    label: 'Retry',
                    onPressed: () {
                      // TODO: Implement retry logic
                    },
                  ),
                ),
              );
            }

            if (state is MessageSendError) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(state.message),
                  backgroundColor: Colors.red,
                ),
              );
            }
          },
          builder: (context, state) {
            // Update local state based on BLoC state
            if (state is TicketDetailsLoaded) {
              currentTicket = state.ticket;
            }
            if (state is TicketDetailsLoaded) {
              messages = state.messages;
            }

            return Center(
              child: Container(
                constraints: const BoxConstraints(maxWidth: 400),
                padding: const EdgeInsets.symmetric(
                  vertical: 16,
                  horizontal: 10,
                ),
                child: Column(
                  children: [
                    Expanded(
                      child: ListView(
                        controller: _scrollController,
                        padding: EdgeInsets.zero,
                        children: [
                          // Ticket Card
                          if (currentTicket != null)
                            TicketCardWidget(
                              ticket: currentTicket!,
                              onTap: null,
                            )
                          else if (state is TicketDetailsLoading)
                            Container(
                              height: 100,
                              decoration: BoxDecoration(
                                color: AppColors.cardDark,
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: const Center(
                                child: CircularProgressIndicator(),
                              ),
                            )
                          else
                            Container(
                              height: 100,
                              decoration: BoxDecoration(
                                color: AppColors.cardDark,
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Center(
                                child: Text(
                                  'Loading ticket details...',
                                    style: TextStyle(color: AppColors.textSecondary),
                                ),
                              ),
                            ),

                          const Gap(8),

                          // Assignment Info
                          if (currentTicket != null)
                            Row(
                              children: [
                                AppReusableText(
                                  text: 'Assigned to: ',
                                  fontWeight: FontWeight.w400,
                                  fontSize: 13,
                                  color: AppColors.textSecondary,
                                ),
                                AppReusableText(
                                  text:
                                      currentTicket!.assignedUser?.name ??
                                      'Unassigned',
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13,
                                  color: AppColors.textPrimary,
                                ),
                              ],
                            ),

                          const Gap(16),

                          // Messages
                          if (state is MessagesLoading)
                            const Center(
                              child: Padding(
                                padding: EdgeInsets.all(20),
                                child: CircularProgressIndicator(),
                              ),
                            )
                          else if (messages.isEmpty)
                            Center(
                              child: Padding(
                                padding: const EdgeInsets.all(20),
                                child: Text(
                                  'No messages yet',
                                  style: TextStyle(
                                    color: AppColors.textSecondary,
                                    fontSize: 16,
                                  ),
                                ),
                              ),
                            )
                          else
                            ..._buildChatBubbles(),

                          const Gap(18),

                          // Internal Note (if exists)
                          if (currentTicket?.tags.isNotEmpty == true)
                            Container(
                              decoration: BoxDecoration(
                                color: AppColors.cardDark,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              padding: const EdgeInsets.all(12),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Icon(
                                    Icons.info_outline,
                                    color: AppColors.textPrimary,
                                    size: 20,
                                  ),
                                  const Gap(8),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        AppReusableText(
                                          text: 'Tags',
                                          fontWeight: FontWeight.w600,
                                          fontSize: 13,
                                          color: AppColors.textPrimary,
                                        ),
                                        const Gap(4),
                                        AppReusableText(
                                          text: currentTicket!.tags.join(', '),
                                          fontWeight: FontWeight.w400,
                                          fontSize: 13,
                                          color: AppColors.textSecondary,
                                          maxLines: 2,
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),

                          const Gap(8),
                        ],
                      ),
                    ),

                    // Message Input
                    Row(
                      children: [
                        Expanded(
                          child: CustomTextField(
                            controller: messageController,
                            hintText: 'Write a message',
                            borderRadius: 28,
                            filledColor: AppColors.cardDark,
                            onSubmitted: (_) => _sendMessage(),
                            suffixIcon: Container(
                              margin: const EdgeInsets.symmetric(
                                vertical: 2,
                                horizontal: 4,
                              ),
                              width: 32,
                              height: 32,
                              decoration: BoxDecoration(
                                color: AppColors.primary,
                                shape: BoxShape.circle,
                              ),
                              child: IconButton(
                                icon:
                                    state is SendingMessage
                                        ? const SizedBox(
                                          width: 16,
                                          height: 16,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            valueColor:
                                                AlwaysStoppedAnimation<Color>(
                                                  Colors.white,
                                                ),
                                          ),
                                        )
                                        : const Icon(
                                          Icons.send,
                                          color: Colors.white,
                                        ),
                                onPressed:
                                    state is SendingMessage
                                        ? null
                                        : _sendMessage,
                              ),
                            ),
                            prefixIcon: Icons.attach_file_outlined,
                          ),
                        ),
                        const Gap(8),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  List<Widget> _buildChatBubbles() {
    List<Widget> bubbles = [];

    for (int i = 0; i < messages.length; i++) {
      final message = messages[i];
      final isFromCustomer = message.sender.type == 'customer';
      final isInternal = message.isInternal;

      // Skip internal messages in chat view (they're for agents only)
      if (isInternal) continue;

      bubbles.add(
        Align(
          alignment:
              isFromCustomer ? Alignment.centerLeft : Alignment.centerRight,
          child: Container(
            margin: const EdgeInsets.symmetric(vertical: 4),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.75,
            ),
            decoration: BoxDecoration(
              color: isFromCustomer
                  ? (Theme.of(context).brightness == Brightness.dark
                      ? const Color(0xFF1E2138)
                      : const Color(0xFFF1F5F9))
                  : AppColors.primary,
              borderRadius: BorderRadius.only(
                topLeft: const Radius.circular(16),
                topRight: const Radius.circular(16),
                bottomLeft: Radius.circular(isFromCustomer ? 4 : 16),
                bottomRight: Radius.circular(isFromCustomer ? 16 : 4),
              ),
              border: isFromCustomer
                  ? Border.all(
                      color: Theme.of(context).brightness == Brightness.dark
                          ? const Color(0xFF2D3154)
                          : const Color(0xFFE2E8F0),
                      width: 1,
                    )
                  : null,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (message.sender.name.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: AppReusableText(
                      text: message.sender.name,
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                      color: isFromCustomer ? AppColors.textSecondary : Colors.white70,
                    ),
                  ),
                AppReusableText(
                  text: message.bodyText,
                  fontWeight: FontWeight.w400,
                  fontSize: 14,
                  color: isFromCustomer ? AppColors.textPrimary : Colors.white,
                  maxLines: 50,
                ),
                if (message.attachments.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Wrap(
                      spacing: 4,
                      children:
                          message.attachments.map((attachment) {
                            return Chip(
                              label: Text(
                                attachment.name,
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Colors.white,
                                ),
                              ),
                              backgroundColor: Colors.blue.shade700,
                              materialTapTargetSize:
                                  MaterialTapTargetSize.shrinkWrap,
                            );
                          }).toList(),
                    ),
                  ),
              ],
            ),
          ),
        ),
      );

      // Show timestamp for every few messages or if significant time gap
      final showTime =
          i == 0 ||
          i == messages.length - 1 ||
          (i > 0 &&
              message.createdAt.difference(messages[i - 1].createdAt).inHours >
                  1);

      if (showTime) {
        bubbles.add(
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Center(
              child: AppReusableText(
                text: message.formattedTime,
                fontWeight: FontWeight.w400,
                fontSize: 11,
                color: AppColors.textSecondary.withValues(alpha: 0.5),
              ),
            ),
          ),
        );
      }
    }

    return bubbles;
  }
}
