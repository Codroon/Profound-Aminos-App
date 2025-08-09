import 'package:flutter/cupertino.dart';
import 'package:gap/gap.dart';

import '../../../../core/theme/app_text_style.dart';

class ProductPerformanceValue extends StatelessWidget {
  const ProductPerformanceValue({
    super.key,
    required this.title,
    required this.value,
  });
  final String title;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(title, style: AppTextStyles.bodyLarge),
        Gap(2),
        SizedBox(
          height: 40,
          width: 88,
          child: Text(
            value,
            textAlign: TextAlign.center,
            style: AppTextStyles.secondaryTextStyle,
            maxLines: 2,
          ),
        ),
      ],
    );
  }
}
