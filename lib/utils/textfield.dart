// ignore_for_file: must_be_immutable

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:ims/utils/colors.dart';
import 'package:searchfield/searchfield.dart';

nameField({required String text, required Widget child, int? flix}) {
  return Row(
    children: [
      Expanded(
        flex: flix ?? 6,
        child: Text(
          text,
          style: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: AppColor.blackText,
          ),
        ),
      ),
      Spacer(flex: 1),
      Expanded(flex: 45, child: child),
    ],
  );
}

class CommonTextField extends StatelessWidget {
  CommonTextField({
    this.hintText,
    this.initialValue,
    this.controller,
    this.onChanged,
    this.onPressIcon,
    this.onTap,
    this.readOnly,
    this.focuesNode,
    this.suffixIcon,
    this.perfixIcon,
    super.key,
  });
  String? hintText;
  String? initialValue;
  TextEditingController? controller;
  bool? readOnly;
  void Function(String)? onChanged;
  void Function()? onPressIcon;
  void Function()? onTap;
  FocusNode? focuesNode;
  Widget? suffixIcon;
  Widget? perfixIcon;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      focusNode: focuesNode,
      controller: controller,
      onChanged: onChanged,
      onTap: onTap,
      initialValue: initialValue,
      readOnly: readOnly ?? false,
      style: TextStyle(color: Color(0xFF565D6D), fontWeight: FontWeight.w500),
      decoration: InputDecoration(
        isDense: true,
        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6),
          borderSide: BorderSide(color: Color(0xFFDEE1E6), width: 1),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6),
          borderSide: BorderSide(color: Color(0xFFDEE1E6), width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6),
          borderSide: BorderSide(color: Color(0xFF565D6D), width: 1),
        ),
        labelText: hintText ?? "",
        suffixIcon: suffixIcon,
        prefixIcon: perfixIcon,

        labelStyle: GoogleFonts.inter(color: Color(0xFF565D6D), fontSize: 14),
      ),
    );
  }
}

class TitleTextFeild extends StatelessWidget {
  TitleTextFeild({
    super.key,
    this.titleText,
    this.hintText,
    this.controller,
    this.onChanged,
    this.validator,
    this.onTap,
    this.readOnly,
    this.focuesNode,
    this.suffixIcon,
    this.prefixIcon,
    this.keyboardType,
    this.maxLength,
  });

  final String? hintText;
  final String? titleText;
  final TextEditingController? controller;
  final bool? readOnly;
  final void Function(String)? onChanged;
  final String? Function(String?)? validator;
  final void Function()? onTap;
  final FocusNode? focuesNode;
  final Widget? suffixIcon;
  final Widget? prefixIcon;
  final TextInputType? keyboardType;
  final int? maxLength;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          titleText ?? "",
          style: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: AppColor.textColor,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          readOnly: readOnly ?? false,
          onChanged: onChanged,
          onTap: onTap,
          style: GoogleFonts.inter(
            color: AppColor.text,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
          validator: validator,
          keyboardType: keyboardType,
          maxLength: maxLength,
          decoration: InputDecoration(
            hintText: hintText ?? "",
            counterText: "",
            prefixIcon: prefixIcon,
            suffixIcon: suffixIcon,
            isDense: true,
            filled: true,
            contentPadding: const EdgeInsets.symmetric(
              vertical: 14,
              horizontal: 10,
            ),
            fillColor: readOnly == true ? AppColor.appbarColor : AppColor.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(6),
              borderSide: BorderSide(color: AppColor.borderColor),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(6),
              borderSide: BorderSide(color: AppColor.borderColor),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(6),
              borderSide: BorderSide(color: AppColor.blue),
            ),
          ),
        ),
      ],
    );
  }
}

class CommonDropdownField<T> extends StatelessWidget {
  final String? hintText;
  final T? value;
  final List<DropdownMenuItem<T>> items;
  final ValueChanged<T?>? onChanged;
  final String? Function(T?)? validator;
  final Widget? prefixIcon;
  final Widget? suffixIcon;
  final bool readOnly;
  final VoidCallback? onTap;

  const CommonDropdownField({
    super.key,
    this.hintText,
    this.value,
    required this.items,
    this.onChanged,
    this.validator,
    this.prefixIcon,
    this.suffixIcon,
    this.readOnly = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      ignoring: readOnly,
      child: DropdownButtonFormField<T>(
        value: value,
        validator: validator,
        items: items,
        onChanged: readOnly ? null : onChanged,
        icon: const Icon(
          Icons.keyboard_arrow_down_rounded,
          color: Color(0xFF565D6D),
        ),
        decoration: InputDecoration(
          labelText: hintText ?? "",
          prefixIcon: prefixIcon,
          suffixIcon: suffixIcon,
          isDense: true,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 12,
          ),
          filled: true,
          fillColor: readOnly == true ? AppColor.appbarColor : Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(6),
            borderSide: const BorderSide(color: Color(0xFFDEE1E6)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(6),
            borderSide: const BorderSide(color: Color(0xFFDEE1E6)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(6),
            borderSide: const BorderSide(color: Color(0xFF565D6D)),
          ),
          labelStyle: GoogleFonts.inter(
            color: const Color(0xFF565D6D),
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        style: GoogleFonts.inter(
          color: const Color(0xFF565D6D),
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}

class CommonSearchableDropdownField<T> extends StatelessWidget {
  final TextEditingController controller;
  final List<SearchFieldListItem<T>> suggestions;
  final String hintText;
  final Function(SearchFieldListItem<T>)? onSuggestionTap;
  final Color? borderColor;
  final Color? boxColor;
  final Widget? prefixIcon;
  final Widget? suffixIcon;
  final bool readOnly;
  final String? Function(String?)? validator;
  final FocusNode? focusNode;
  final EdgeInsetsGeometry? contentPadding;

  const CommonSearchableDropdownField({
    super.key,
    required this.controller,
    required this.suggestions,
    required this.hintText,
    this.onSuggestionTap,
    this.borderColor,
    this.boxColor,
    this.prefixIcon,
    this.suffixIcon,
    this.readOnly = false,
    this.validator,
    this.focusNode,
    this.contentPadding,
  });

  @override
  Widget build(BuildContext context) {
    final borderClr = borderColor ?? const Color(0xFFDEE1E6);
    final bgClr = boxColor ?? Colors.white;

    return SearchField<T>(
      controller: controller,
      focusNode: focusNode,
      suggestions: suggestions,
      readOnly: readOnly,
      validator: validator,
      onSuggestionTap: onSuggestionTap,
      searchInputDecoration: SearchInputDecoration(
        isDense: true,
        filled: true,
        fillColor: bgClr,
        contentPadding:
            contentPadding ??
            const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        labelText: hintText,
        labelStyle: GoogleFonts.inter(
          color: const Color(0xFF565D6D),
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
        prefixIcon: prefixIcon,
        suffixIcon: suffixIcon,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6),
          borderSide: BorderSide(color: borderClr, width: 1),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6),
          borderSide: BorderSide(color: borderClr, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6),
          borderSide: BorderSide(color: const Color(0xFF565D6D), width: 1),
        ),
      ),
      suggestionStyle: GoogleFonts.inter(
        color: const Color(0xFF565D6D),
        fontSize: 14,
        fontWeight: FontWeight.w500,
      ),
      suggestionItemDecoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: borderClr.withOpacity(0.3)),
      ),
    );
  }
}
