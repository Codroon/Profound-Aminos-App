import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:icons_plus/icons_plus.dart';
import 'package:woo_management_app/features/gorgias/presentation/pages/ticket_chat_screen.dart';
import '../../../../widgets/custom_button.dart';
import '../../../../widgets/custom_text_field.dart';
import '../../../../widgets/app_reusable_text.dart';
import '../../../../widgets/shared_appbar.dart';
import '../widgets/ticket_card_widget.dart';

class TicketDetailScreen extends StatefulWidget {
  final String avatarUrl;
  final String userName;
  final String message;
  final String status;
  final String timeAgo;

  const TicketDetailScreen({
    super.key,
    required this.avatarUrl,
    required this.userName,
    required this.message,
    required this.status,
    required this.timeAgo,
  });

  @override
  State<TicketDetailScreen> createState() => _TicketDetailScreenState();
}

class _TicketDetailScreenState extends State<TicketDetailScreen> {
  String selectedStatus = 'Pending';
  String selectedAssignee = 'Unassigned';
  final TextEditingController noteController = TextEditingController();

  final List<String> statusOptions = ['Pending', 'In Progress', 'Resolved'];
  final List<String> assigneeOptions = ['Unassigned', 'Agent 1', 'Agent 2'];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1e1f28),
      appBar: SharedAppbar(
        title: 'All Tickets',
        actions: [
          IconButton(onPressed: () {}, icon: Icon(Iconsax.add_outline)),
          IconButton(onPressed: () {}, icon: Icon(Icons.more_vert_rounded)),
        ],
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 10),
            child: Container(
              constraints: const BoxConstraints(maxWidth: 400),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF252533),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TicketCardWidget(
                    avatarUrl: widget.avatarUrl,
                    userName: widget.userName,
                    message: widget.message,
                    status: widget.status,
                    timeAgo: widget.timeAgo,
                  ),
                  const Gap(18),
                  DropdownButtonFormField<String>(
                    value: selectedStatus,
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: const Color(0xFF314158),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(28),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                    ),
                    dropdownColor: const Color(0xFF314158),
                    style: const TextStyle(color: Colors.white, fontSize: 15),
                    items:
                        statusOptions
                            .map(
                              (status) => DropdownMenuItem(
                                value: status,
                                child: Text(status),
                              ),
                            )
                            .toList(),
                    onChanged: (value) {
                      if (value != null) setState(() => selectedStatus = value);
                    },
                  ),
                  const Gap(14),
                  DropdownButtonFormField<String>(
                    value: selectedAssignee,
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: const Color(0xFF314158),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(28),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                    ),
                    dropdownColor: const Color(0xFF314158),
                    style: const TextStyle(color: Colors.white, fontSize: 15),
                    items:
                        assigneeOptions
                            .map(
                              (assignee) => DropdownMenuItem(
                                value: assignee,
                                child: Text(assignee),
                              ),
                            )
                            .toList(),
                    onChanged: (value) {
                      if (value != null)
                        setState(() => selectedAssignee = value);
                    },
                  ),
                  const Gap(14),
                  CustomTextField(
                    borderRadius: 12,
                    filledColor: const Color(0xFF314158),
                    controller: noteController,
                    hintText: 'Internal Note',
                    maxLines: 3,
                  ),
                  const Gap(18),
                  Row(
                    spacing: 12,
                    children: [
                      Expanded(
                        child: CustomButton(text: 'Update', onPressed: () {}),
                      ),
                      CircleAvatar(
                        radius: 22,
                        child: IconButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder:
                                    (context) => TicketChatScreen(
                                      avatarUrl: widget.avatarUrl,
                                      userName: widget.userName,
                                      message: widget.message,
                                      status: widget.status,
                                      timeAgo: widget.timeAgo,
                                      assignedTo: selectedAssignee,
                                    ),
                              ),
                            );
                          },
                          icon: Icon(
                            Iconsax.message_bold,
                            color: Colors.white,
                            size: 24,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
