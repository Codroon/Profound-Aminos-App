import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:icons_plus/icons_plus.dart';
import '../../../../widgets/app_reusable_text.dart';
import '../../../../widgets/custom_text_field.dart';
import '../../../../widgets/custom_button.dart';
import '../../../../widgets/shared_appbar.dart';
import '../widgets/ticket_card_widget.dart';

class TicketChatScreen extends StatefulWidget {
  final String avatarUrl;
  final String userName;
  final String message;
  final String status;
  final String timeAgo;
  final String assignedTo;

  const TicketChatScreen({
    super.key,
    required this.avatarUrl,
    required this.userName,
    required this.message,
    required this.status,
    required this.timeAgo,
    this.assignedTo = 'Unassigned',
  });

  @override
  State<TicketChatScreen> createState() => _TicketChatScreenState();
}

class _TicketChatScreenState extends State<TicketChatScreen> {
  final TextEditingController messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<Map<String, dynamic>> messages = [
    {
      'text':
          'Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do.',
      'isMe': false,
      'time': '1 FEB 12:00',
    },
    {
      'text': 'Ut enim ad minima veniam, quis nostrud',
      'isMe': true,
      'time': '',
    },
    {'text': 'Next month?', 'isMe': false, 'time': '00:12'},
    {
      'text':
          'I am almost finish. Please give me your email, I will ZIP them and send you as soon as Im finish.',
      'isMe': true,
      'time': '',
    },
    {'text': '?', 'isMe': false, 'time': '04:43'},
    {'text': 'myoki.kawasaki@email.com', 'isMe': true, 'time': ''},
    {'text': '👍', 'isMe': false, 'time': ''},
  ];

  final String internalNote = 'Check with logistics team before replying.';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: SharedAppbar(
        title: 'Chat',
        actions: [
          IconButton(onPressed: () {}, icon: Icon(Iconsax.add_outline)),
          IconButton(onPressed: () {}, icon: Icon(Icons.more_vert_rounded)),
        ],
      ),
      body: SafeArea(
        child: Center(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 400),
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 10),
            child: Column(
              children: [
                Expanded(
                  child: ListView(
                    controller: _scrollController,
                    padding: EdgeInsets.zero,
                    children: [
                      TicketCardWidget(
                        avatarUrl: widget.avatarUrl,
                        userName: widget.userName,
                        message: widget.message,
                        status: widget.status,
                        timeAgo: widget.timeAgo,
                      ),
                      const Gap(8),
                      Row(
                        children: [
                          AppReusableText(
                            text: 'Assigned to: ',
                            fontWeight: FontWeight.w400,
                            fontSize: 13,
                            color: Colors.white70,
                          ),
                          AppReusableText(
                            text: widget.assignedTo,
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                            color: Colors.white,
                          ),
                        ],
                      ),
                      const Gap(16),
                      ..._buildChatBubbles(),
                      const Gap(18),
                      Container(
                        decoration: BoxDecoration(
                          color: const Color(0xFF314158),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.all(12),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(
                              Icons.info_outline,
                              color: Colors.white,
                              size: 20,
                            ),
                            const Gap(8),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  AppReusableText(
                                    text: 'Internal Note',
                                    fontWeight: FontWeight.w600,
                                    fontSize: 13,
                                    color: Colors.white,
                                  ),
                                  const Gap(4),
                                  AppReusableText(
                                    text: internalNote,
                                    fontWeight: FontWeight.w400,
                                    fontSize: 13,
                                    color: Colors.white70,
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
                Row(
                  children: [
                    Expanded(
                      child: CustomTextField(
                        controller: messageController,
                        hintText: 'Write a message',
                        borderRadius: 28,
                        filledColor: const Color(0xFF252533),
                        suffixIcon: Container(
                          margin: const EdgeInsets.symmetric(
                            vertical: 2,
                            horizontal: 4,
                          ),
                          width: 32,
                          height: 32,
                          decoration: const BoxDecoration(
                            color: Color(0xFF5D2DE6),
                            shape: BoxShape.circle,
                          ),
                          child: IconButton(
                            icon: const Icon(Icons.send, color: Colors.white),
                            onPressed: () {},
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
        ),
      ),
    );
  }

  List<Widget> _buildChatBubbles() {
    List<Widget> bubbles = [];
    for (var msg in messages) {
      bubbles.add(
        Align(
          alignment: msg['isMe'] ? Alignment.centerRight : Alignment.centerLeft,
          child: Container(
            margin: const EdgeInsets.symmetric(vertical: 4),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
            decoration: BoxDecoration(
              color:
                  msg['isMe']
                      ? const Color(0xFF1D293D)
                      : const Color(0xFF314158),
              borderRadius: BorderRadius.only(
                topLeft: const Radius.circular(16),
                topRight: const Radius.circular(16),
                bottomLeft: Radius.circular(msg['isMe'] ? 16 : 4),
                bottomRight: Radius.circular(msg['isMe'] ? 4 : 16),
              ),
            ),
            child: AppReusableText(
              text: msg['text'],
              fontWeight: FontWeight.w400,
              fontSize: 14,
              color: Colors.white,
            ),
          ),
        ),
      );
      if (msg['time'] != null && msg['time'] != '') {
        bubbles.add(
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 2),
            child: Center(
              child: AppReusableText(
                text: msg['time'],
                fontWeight: FontWeight.w400,
                fontSize: 11,
                color: Colors.white38,
              ),
            ),
          ),
        );
      }
    }
    return bubbles;
  }
}
