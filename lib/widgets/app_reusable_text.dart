import 'package:flutter/material.dart';

import '../core/theme/app_text_style.dart';

class AppReusableText extends StatelessWidget {
  const AppReusableText({
    super.key,
    required this.text,
    this.fontWeight,
    this.fontSize,
    this.color,
    this.textAlignment = TextAlign.start,
    this.maxLines = 1,
    this.fontStyle,
  });

  final String text;
  final FontWeight? fontWeight;
  final double? fontSize;
  final Color? color;
  final TextAlign textAlignment;
  final int? maxLines;
  final FontStyle? fontStyle;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      overflow: TextOverflow.ellipsis,
      textAlign: textAlignment,
      maxLines: maxLines,

      style: AppTextStyles.h2.copyWith(
        fontStyle: fontStyle ?? FontStyle.normal,
        fontWeight: fontWeight,
        fontSize: fontSize,
        color: color,
      ),
    );
  }
}
