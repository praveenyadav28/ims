//Snackbar Error
import 'package:flutter/material.dart';
import 'package:ims/utils/colors.dart';

void showCustomSnackbarError(
  BuildContext context,
  String message, {
  Duration duration = const Duration(seconds: 2),
  String? actionLabel,
  VoidCallback? onActionPressed,
}) {
  final snackBar = SnackBar(
    content: Text(message),
    duration: duration,
    backgroundColor: AppColor.red,
    action: actionLabel != null
        ? SnackBarAction(
            label: actionLabel,
            onPressed: onActionPressed ?? () {},
          )
        : null,
  );

  ScaffoldMessenger.of(context).showSnackBar(snackBar);
}

//Snackbar Success
void showCustomSnackbarSuccess(
  BuildContext context,
  String message, {
  Duration duration = const Duration(seconds: 2),
  String? actionLabel,
  VoidCallback? onActionPressed,
}) {
  final snackBar = SnackBar(
    content: Text(message),
    duration: duration,
    backgroundColor: AppColor.primary,
    action: actionLabel != null
        ? SnackBarAction(
            label: actionLabel,
            onPressed: onActionPressed ?? () {},
          )
        : null,
  );

  ScaffoldMessenger.of(context).showSnackBar(snackBar);
}
