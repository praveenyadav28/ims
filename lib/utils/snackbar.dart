import 'package:flutter/material.dart';
import 'package:ims/utils/colors.dart';

// ================== BASE SNACKBAR ==================
void _showSnackbar(
  BuildContext context, {
  required String message,
  required Color bgColor,
  required IconData icon,
  Duration duration = const Duration(seconds: 3),
  String? actionLabel,
  VoidCallback? onActionPressed,
}) {
  final snackBar = SnackBar(
    behavior: SnackBarBehavior.floating,
    margin: const EdgeInsets.all(16),
    elevation: 0,
    duration: duration,
    backgroundColor: Colors.transparent,
    content: Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: bgColor.withValues(alpha: .5),
            blurRadius: 10,
            spreadRadius: 5,
          ),
        ],
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.white, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          if (actionLabel != null)
            TextButton(
              onPressed: onActionPressed ?? () {},
              child: Text(
                actionLabel,
                style: const TextStyle(color: Colors.white),
              ),
            ),
        ],
      ),
    ),
  );

  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(snackBar);
}

// ================== ERROR ==================
void showCustomSnackbarError(
  BuildContext context,
  String message, {
  Duration duration = const Duration(seconds: 3),
  String? actionLabel,
  VoidCallback? onActionPressed,
}) {
  _showSnackbar(
    context,
    message: message,
    bgColor: AppColor.red,
    icon: Icons.error_outline,
    duration: duration,
    actionLabel: actionLabel,
    onActionPressed: onActionPressed,
  );
}

// ================== SUCCESS ==================
void showCustomSnackbarSuccess(
  BuildContext context,
  String message, {
  Duration duration = const Duration(seconds: 3),
  String? actionLabel,
  VoidCallback? onActionPressed,
}) {
  _showSnackbar(
    context,
    message: message,
    bgColor: AppColor.primary,
    icon: Icons.check_circle_outline,
    duration: duration,
    actionLabel: actionLabel,
    onActionPressed: onActionPressed,
  );
}
