import 'package:flutter/material.dart';
import 'package:ims/utils/textfield.dart';

class DateTextField extends StatefulWidget {
  final String title;
  final TextEditingController controller;
  final VoidCallback onTap;

  const DateTextField({
    super.key,
    required this.title,
    required this.controller,
    required this.onTap,
  });

  @override
  State<DateTextField> createState() => _DateTextFieldState();
}

class _DateTextFieldState extends State<DateTextField> {
  bool isDeleting = false;

  @override
  Widget build(BuildContext context) {
    return TitleTextFeild(
      titleText: widget.title,
      hintText: "yyyy-MM-dd",
      controller: widget.controller,
      readOnly: false,
      suffixIcon: IconButton(
        icon: const Icon(Icons.calendar_month),
        onPressed: widget.onTap,
      ),
      onChanged: (value) {
        // Check if user is deleting
        isDeleting = value.length < widget.controller.text.length;

        if (isDeleting) {
          // Don't format during delete
          return;
        }

        // Only digits for formatting
        String digits = value.replaceAll(RegExp(r'[^0-9]'), '');

        String y = '';
        String m = '';
        String d = '';

        if (digits.length >= 1)
          y = digits.substring(0, digits.length.clamp(0, 4));
        if (digits.length >= 5)
          m = digits.substring(4, digits.length.clamp(4, 6));
        if (digits.length >= 7)
          d = digits.substring(6, digits.length.clamp(6, 8));

        String formatted = y;
        if (m.isNotEmpty) formatted += "-$m";
        if (d.isNotEmpty) formatted += "-$d";

        if (formatted != value) {
          widget.controller.value = TextEditingValue(
            text: formatted,
            selection: TextSelection.collapsed(offset: formatted.length),
          );
        }
      },
    );
  }
}
