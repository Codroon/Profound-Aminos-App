import 'package:flutter/material.dart';
import '../core/theme/app_colors.dart';

class CustomTextField extends StatelessWidget {
  final TextEditingController controller;
  final String hintText;
  final String? initialValue;
  final IconData? prefixIcon;
  final Widget? suffixIcon;
  final Widget? prefixWidget;
  final bool obscureText;
  final TextInputType? keyboardType;
  final String? Function(String?)? validator;
  final void Function(String)? onChanged;
  final int? maxLines;
  final Color? filledColor;
  final double? borderRadius;
  final void Function(String)? onSubmitted;
  final String? suffixText;
  final String? prefixText;
  final FocusNode? focusNode;


  const CustomTextField({
    super.key,
    required this.controller,
    required this.hintText,
    this.prefixIcon,
    this.suffixIcon,
    this.obscureText = false,
    this.keyboardType,
    this.validator,
    this.onChanged,
    this.maxLines = 1,
    this.prefixWidget,
    this.initialValue,
    this.filledColor,
    this.borderRadius,
    this.onSubmitted,
    this.suffixText,
    this.prefixText,
    this.focusNode,

  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      initialValue: initialValue,
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      validator: validator,
      onChanged: onChanged,
      maxLines: maxLines,
      focusNode: focusNode,
      textCapitalization: TextCapitalization.sentences,
      onTapOutside: (_) {
        FocusScope.of(context).unfocus();
      },
      onFieldSubmitted: onSubmitted,
      style: const TextStyle(color: AppColors.textPrimary, fontSize: 16),
      cursorColor: AppColors.primary,
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: const TextStyle(
          color: AppColors.textSecondary,
          fontSize: 11,
          fontWeight: FontWeight.w400,
        ),
        suffixText: suffixText,
        prefixIcon:
            prefixIcon != null
                ? Icon(prefixIcon, color: AppColors.surfaceLight, size: 20)
                : null,
        suffixIcon: suffixIcon,
        prefix: prefixWidget,
        prefixText: prefixText,
        suffixIconColor: AppColors.surfaceLight,
        filled: true,
        fillColor: filledColor ?? AppColors.cardDark,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 12,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(borderRadius ?? 22),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(borderRadius ?? 22),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(borderRadius ?? 22),
          borderSide: const BorderSide(color: AppColors.primary, width: 1),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(borderRadius ?? 22),
          borderSide: const BorderSide(color: AppColors.error),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(borderRadius ?? 22),
          borderSide: const BorderSide(color: AppColors.error, width: 1),
        ),
        errorStyle: const TextStyle(color: AppColors.error, fontSize: 12),
      ),
    );
  }
}
