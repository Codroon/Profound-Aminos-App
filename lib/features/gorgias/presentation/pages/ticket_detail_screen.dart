import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gap/gap.dart';
import 'package:icons_plus/icons_plus.dart';
import 'package:woo_management_app/features/gorgias/bloc/gorgias_bloc.dart';
import 'package:woo_management_app/features/gorgias/bloc/gorgias_event.dart';
import 'package:woo_management_app/features/gorgias/bloc/gorgias_state.dart';
import 'package:woo_management_app/features/gorgias/models/gorgias_models.dart';
import 'package:woo_management_app/core/theme/app_colors.dart';
import 'package:woo_management_app/features/gorgias/presentation/pages/ticket_chat_screen.dart';
import 'package:woo_management_app/widgets/custom_loading_widget.dart';
import '../../../../widgets/custom_button.dart';
import '../../../../widgets/custom_text_field.dart';
import '../../../../widgets/app_reusable_text.dart';
import '../../../../widgets/shared_appbar.dart';
import '../widgets/ticket_card_widget.dart';

class TicketDetailScreen extends StatefulWidget {
  final String ticketId;

  const TicketDetailScreen({super.key, required this.ticketId});

  @override
  State<TicketDetailScreen> createState() => _TicketDetailScreenState();
}

class _TicketDetailScreenState extends State<TicketDetailScreen> {
  String? selectedStatus;
  String? selectedAssignee;
  final TextEditingController noteController = TextEditingController();
  Ticket? currentTicket; // ✅ cache
  late GorgiasBloc _gorgiasBloc;
  bool _hasInitialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _gorgiasBloc = context.read<GorgiasBloc>();

    if (!_hasInitialized) {
      _gorgiasBloc.add(FetchTicketDetails(widget.ticketId));
      _hasInitialized = true;
    }
  }

  @override
  void dispose() {
    noteController.dispose();
    super.dispose();
  }

  void _updateTicket() {
    if (currentTicket == null) return;

    final updates = <String, dynamic>{};

    if (selectedStatus != null && selectedStatus != currentTicket!.status) {
      updates['status'] = selectedStatus;
    }

    if (selectedAssignee != null &&
        selectedAssignee != currentTicket!.assignee?.name) {
      if (selectedAssignee == 'Unassigned') {
        updates['assignee_user_id'] = null;
      } else {
        if (currentTicket!.assignee?.name == selectedAssignee) {
          final assigneeId = int.tryParse(currentTicket!.assignee!.id);
          updates['assignee_user_id'] = assigneeId;
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Cannot assign to hardcoded users. Please select Unassigned or current assignee.',
              ),
              backgroundColor: Colors.orange,
            ),
          );
          return;
        }
      }
    }

    if (noteController.text.isNotEmpty) {
      updates['internal_note'] = noteController.text;
    }

    if (updates.isNotEmpty) {
      _gorgiasBloc.add(
        UpdateTicketStatus(ticketId: widget.ticketId, updates: updates),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      appBar: SharedAppbar(
        title: 'Ticket Details',
        actions: [
          IconButton(
            onPressed: () {
              _gorgiasBloc.add(FetchTicketDetails(widget.ticketId));
            },
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: SafeArea(
        child: BlocConsumer<GorgiasBloc, GorgiasState>(
          listener: (context, state) {
            if (state is TicketUpdated) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Ticket updated successfully'),
                  backgroundColor: Colors.green,
                ),
              );
              _gorgiasBloc.add(FetchTicketDetails(widget.ticketId));
            }

            if (state is TicketDetailsError) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(state.message),
                  backgroundColor: Colors.red,
                ),
              );
            }
          },
          builder: (context, state) {
            // ✅ Always prefer showing cached ticket if available
            if (state is TicketDetailsLoaded) {
              currentTicket = state.ticket;
            }

            if (currentTicket == null) {
              // Pehli dafa data aane tak spinner
              return Center(
                child: CustomLoadingWidget(
                  text: 'Getting your ticket details...',
                ),
              );
            }

            // Yahan ham cached/currentTicket ko show karte rahenge
            final ticket = currentTicket!;

            // Initialize dropdown values if not set
            selectedStatus ??= ticket.status;
            final assigneeName = ticket.assignee?.name;
            final availableAssignees = [
              'Unassigned',
              'Agent 1',
              'Agent 2',
              'Agent 3',
            ];
            selectedAssignee ??=
                (assigneeName != null &&
                        availableAssignees.contains(assigneeName))
                    ? assigneeName
                    : 'Unassigned';

            return Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  vertical: 16,
                  horizontal: 10,
                ),
                child: Container(
                  constraints: const BoxConstraints(maxWidth: 400),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.cardDark,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      TicketCardWidget(ticket: ticket, onTap: null),
                      const Gap(18),

                      // Status Dropdown
                      AppReusableText(
                        text: 'Status',
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                      const Gap(8),
                      DropdownButtonFormField<String>(
                        initialValue: selectedStatus,
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
                        dropdownColor: AppColors.cardDark,
                        style: TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 15,
                        ),
                        items:
                            GorgiasConstants.ticketStatuses
                                .map(
                                  (status) => DropdownMenuItem(
                                    value: status,
                                    child: Text(status.toUpperCase()),
                                  ),
                                )
                                .toList(),
                        onChanged: (value) {
                          if (value != null) {
                            setState(() => selectedStatus = value);
                          }
                        },
                      ),
                      const Gap(14),

                      // Assignee Dropdown
                      AppReusableText(
                        text: 'Assigned To',
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                      const Gap(8),
                      DropdownButtonFormField<String>(
                        initialValue: selectedAssignee,
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
                        dropdownColor: AppColors.cardDark,
                        style: TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 15,
                        ),
                        items: [
                          const DropdownMenuItem(
                            value: 'Unassigned',
                            child: Text('Unassigned'),
                          ),
                          ...['Agent 1', 'Agent 2', 'Agent 3']
                              .map(
                                (assignee) => DropdownMenuItem(
                                  value: assignee,
                                  child: Text(assignee),
                                ),
                              )
                              ,
                        ],
                        onChanged: (value) {
                          if (value != null) {
                            setState(() => selectedAssignee = value);
                          }
                        },
                      ),
                      const Gap(14),

                      // Internal Note
                      AppReusableText(
                        text: 'Internal Note',
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                      const Gap(8),
                      CustomTextField(
                        borderRadius: 12,
                        filledColor: const Color(0xFF314158),
                        controller: noteController,
                        hintText: 'Add internal note...',
                        maxLines: 3,
                      ),
                      const Gap(18),

                      // Action Buttons
                      Row(
                        spacing: 12,
                        children: [
                          Expanded(
                            child: CustomButton(
                              text:
                                  state is UpdatingTicket
                                      ? 'Updating...'
                                      : 'Update',
                              onPressed:
                                  state is UpdatingTicket
                                      ? null
                                      : _updateTicket,
                            ),
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
                                          ticketId: widget.ticketId,
                                        ),
                                  ),
                                );
                              },
                              icon: const Icon(
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
            );
          },
        ),
      ),
    );
  }
}
