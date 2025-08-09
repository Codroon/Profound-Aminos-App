import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:icons_plus/icons_plus.dart';
import 'package:woo_management_app/core/theme/app_colors.dart';
import 'package:woo_management_app/widgets/app_reusable_text.dart';

import '../../../../core/routes/routes_name.dart';
import '../../../../widgets/custom_progress_bar.dart'; // Adjust path

class GorgiasCard extends StatelessWidget {
  const GorgiasCard({super.key});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.pushNamed(context, RouteNames.gorgiasDashboard);
      },
      child: Container(
        padding: const EdgeInsets.all(16.0),
        decoration: BoxDecoration(
          color: AppColors.cardDark,
          borderRadius: BorderRadius.circular(16.0),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  Iconsax.element_4_outline,
                  color: Colors.white,
                  size: 24,
                ),
                const SizedBox(width: 8),
                AppReusableText(
                  text: 'Gorgias',
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                ),
              ],
            ),
            const Gap(8),
            // Open Tickets
            const Text(
              'Open',
              style: TextStyle(color: Colors.white70, fontSize: 10),
            ),
            CustomProgressBar(
              progress: 0.45,
              value: '45',
              color: Colors.white,
              backgroundColor: Colors.white.withOpacity(0.3),
            ),
            const Text(
              'Closed',
              style: TextStyle(color: Colors.white70, fontSize: 10),
            ),
            const Gap(2),
            CustomProgressBar(
              progress: 0.70, // Example value for closed
              value: '', // No value shown in the image for closed
              color: const Color(
                0xFF00ADB5,
              ), // Cyan/teal color for closed as seen in image
              backgroundColor: Colors.white.withOpacity(0.3),
            ),
          ],
        ),
      ),
    );
  }
}
