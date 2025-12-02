// ignore_for_file: must_be_immutable

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:ims/utils/colors.dart';

class AppbarClass extends StatelessWidget {
  AppbarClass({this.title, super.key});
  String? title;
  @override
  Widget build(BuildContext context) {
    return AppBar(
      elevation: 0,
      leading: IconButton(
        onPressed: () {
          Navigator.pop(context);
        },
        icon: Icon(Icons.arrow_back_ios_new, size: 20, color: AppColor.black),
      ),
      backgroundColor: AppColor.transparent,
      // centerTitle: true,
      title: Text(
        title!,
        style: GoogleFonts.inter(
          fontSize: 18,
          fontWeight: FontWeight.w500,
          color: AppColor.black,
        ),
      ),
    );
  }
}
