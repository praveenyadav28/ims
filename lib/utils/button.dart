import 'package:flutter/material.dart';
import 'package:ims/utils/colors.dart';
import 'package:google_fonts/google_fonts.dart';

defaultButton({
  Color? buttonColor,
  String? text,
  void Function()? onTap,
  double? width,
  double? height,
}) {
  return InkWell(
    onTap: onTap,
    child: Container(
      height: height,
      width: width,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(6),
        color: buttonColor,
      ),
      child: Text(
        text ?? "",
        style: GoogleFonts.inter(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: AppColor.white,
        ),
      ),
    ),
  );
}

InkWell addDefaultButton(Function()? onTap) {
  return InkWell(
    onTap: onTap,
    child: Container(
      height: 37,
      width: 37,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(5),
        color: AppColor.white,
        border: Border.all(width: 1, color: AppColor.borderColor),
      ),
      child: Icon(Icons.add, color: AppColor.lightblack),
    ),
  );
}
