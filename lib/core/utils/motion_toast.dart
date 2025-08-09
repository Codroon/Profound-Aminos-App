import 'package:flutter/material.dart';
import 'package:motion_toast/motion_toast.dart';
import 'package:woo_management_app/core/theme/app_colors.dart';

class ToastUtils {
  static void showSuccessToast(
    BuildContext context, {
    required String title,
    required String description,
    Alignment position = Alignment.topCenter,
  }) {
    MotionToast(
      icon: Icons.check_circle,
      secondaryColor: Colors.white,
      primaryColor: AppColors.primary,
      title: Text(
        title,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
        ),
      ),
      description: Text(
        description,
        style: const TextStyle(color: Colors.white),
      ),
      toastAlignment: position,
      animationType:
          position == MotionToastPosition.top
              ? AnimationType.slideInFromTop
              : AnimationType.slideInFromBottom,
      height: 80,
      width: 300,
      constraints: const BoxConstraints(maxWidth: 400),
    ).show(context);
  }

  static void showErrorToast(
    BuildContext context, {
    required String title,
    required String description,
    Alignment position = Alignment.topCenter,
  }) {
    MotionToast(
      icon: Icons.error_outline,
      primaryColor: Colors.red,
      barrierColor: Colors.black,
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
      description: Text(description),
      toastAlignment: position,
      animationType:
          position == MotionToastPosition.top
              ? AnimationType.slideInFromTop
              : AnimationType.slideInFromBottom,
      height: 80,
      width: 300,
      constraints: const BoxConstraints(maxWidth: 300),
    ).show(context);
  }

  static void showWarningToast(
    BuildContext context, {
    required String title,
    required String description,
    Alignment position = Alignment.topCenter,
  }) {
    MotionToast(
      icon: Icons.warning_amber,
      primaryColor: Colors.orange,
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
      description: Text(description),
      toastAlignment: position,
      animationType:
          position == MotionToastPosition.top
              ? AnimationType.slideInFromTop
              : AnimationType.slideInFromBottom,
      height: 80,
      width: 300,
      constraints: const BoxConstraints(maxWidth: 300),
    ).show(context);
  }

  static void showInfoToast(
    BuildContext context, {
    required String title,
    required String description,
    double? animationDuration,
    Alignment position = Alignment.topCenter,
  }) {
    MotionToast(
      toastDuration: Duration(seconds: animationDuration!.toInt()),
      icon: Icons.info_outline,
      primaryColor: Colors.blue,
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
      description: Text(description),
      toastAlignment: position,
      animationType:
          position == MotionToastPosition.top
              ? AnimationType.slideInFromTop
              : AnimationType.slideInFromBottom,
      height: 80,
      width: 300,
      constraints: const BoxConstraints(maxWidth: 300),
    ).show(context);
  }

  static void showDeleteToast(
    BuildContext context, {
    required String title,
    required String description,
    Alignment position = Alignment.topCenter,
  }) {
    MotionToast(
      icon: Icons.delete_outline,
      primaryColor: Colors.red,
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
      description: Text(description),
      toastAlignment: position,
      animationType:
          position == MotionToastPosition.top
              ? AnimationType.slideInFromTop
              : AnimationType.slideInFromBottom,
      height: 80,
      width: 300,
      constraints: const BoxConstraints(maxWidth: 300),
    ).show(context);
  }

  // Custom toast with more options
  static void showCustomToast(
    BuildContext context, {
    required String title,
    required String description,
    required IconData icon,
    required Color primaryColor,
    Alignment position = Alignment.topCenter,
    AnimationType animationType = AnimationType.slideInFromTop,
    Duration? duration,
  }) {
    MotionToast(
      icon: icon,
      primaryColor: primaryColor,
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
      description: Text(description),
      toastAlignment: position,
      animationType: animationType,
      height: 80,
      width: 300,
      constraints: const BoxConstraints(maxWidth: 300),
      animationDuration: duration ?? const Duration(seconds: 3),
    ).show(context);
  }
}
