import 'package:flutter/material.dart';
import 'package:icons_plus/icons_plus.dart';
import 'package:woo_management_app/core/theme/app_colors.dart';
import 'package:woo_management_app/features/gorgias/presentation/pages/ticket_detail_screen.dart';
import 'package:woo_management_app/widgets/custom_text_field.dart';
import 'package:woo_management_app/widgets/shared_appbar.dart';

import '../widgets/ticket_card_widget.dart';

class GorgiasDashboard extends StatelessWidget {
  const GorgiasDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: SharedAppbar(
        title: 'All Tickets',
        actions: [
          IconButton(onPressed: () {}, icon: Icon(Iconsax.add_outline)),
          IconButton(onPressed: () {}, icon: Icon(Icons.more_vert_rounded)),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(12.0),
          physics: const BouncingScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CustomTextField(
                controller: TextEditingController(),
                prefixIcon: Iconsax.search_normal_outline,
                hintText: 'Search tickets...',
              ),
              const SizedBox(height: 16),
              _TicketFilterBar(),
              const SizedBox(height: 20),
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: 3,
                itemBuilder: (context, index) {
                  final tickets = [
                    {
                      'avatarUrl':
                          'https://randomuser.me/api/portraits/women/1.jpg',
                      'userName': 'Emma Garcia',
                      'message': 'Order delayed? Please help!',
                      'status': 'Pending',
                      'timeAgo': '2h',
                    },
                    {
                      'avatarUrl':
                          'https://randomuser.me/api/portraits/men/7.jpg',
                      'userName': 'Liam Smith',
                      'message': 'Received wrong item.',
                      'status': 'Pending',
                      'timeAgo': '1h',
                    },
                    {
                      'avatarUrl':
                          'https://randomuser.me/api/portraits/women/3.jpg',
                      'userName': 'Sophia Lee',
                      'message': 'How to return a product?',
                      'status': 'Pending',
                      'timeAgo': '30m',
                    },
                  ];
                  final ticket = tickets[index];
                  return TicketCardWidget(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder:
                              (_) => TicketDetailScreen(
                                avatarUrl: ticket['avatarUrl']!,
                                userName: ticket['userName']!,
                                message: ticket['message']!,
                                status: ticket['status']!,
                                timeAgo: ticket['timeAgo']!,
                              ),
                        ),
                      );
                    },
                    avatarUrl: ticket['avatarUrl']!,

                    userName: ticket['userName']!,
                    message: ticket['message']!,
                    status: ticket['status']!,
                    timeAgo: ticket['timeAgo']!,
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TicketFilterBar extends StatefulWidget {
  @override
  State<_TicketFilterBar> createState() => _TicketFilterBarState();
}

class _TicketFilterBarState extends State<_TicketFilterBar> {
  final List<String> filters = [
    'All',
    'Open',
    'Pending',
    'Closed',
    'Email',
    'Chat',
    'Instagram',
  ];
  int selected = 0;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 40,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: filters.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final isSelected = selected == index;
          return GestureDetector(
            onTap: () => setState(() => selected = index),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
              decoration: BoxDecoration(
                color:
                    isSelected ? const Color(0xFF314158) : AppColors.cardDark,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                filters[index],
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w400,
                  fontSize: 14,
                  letterSpacing: 0.2,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
