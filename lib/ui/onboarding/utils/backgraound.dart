// ignore_for_file: must_be_immutable

import 'package:flutter/material.dart';
import 'package:ims/utils/colors.dart';
import 'package:ims/utils/sizes.dart';

class OnboardingBackground extends StatefulWidget {
   OnboardingBackground({super.key,required this.widget});
  Widget widget;

  @override
  State<OnboardingBackground> createState() => _OnboardingBackgroundState();
}

class _OnboardingBackgroundState extends State<OnboardingBackground> {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: BoxDecoration(
        image: DecorationImage(
          image: AssetImage("assets/images/login_background.jpg"),
          fit: BoxFit.cover,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          SizedBox(width: Sizes.width * 0.07),
          Container(
            width: Sizes.width > 600 ? 450 : Sizes.width - Sizes.width * 0.14,
            padding: const EdgeInsets.symmetric(horizontal: 50),
            height: Sizes.height * 0.8,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(5),
              color: AppColor.white.withOpacity(0.8),
            ),
            child: Center(child: widget.widget),
          ),
          SizedBox(width: Sizes.width * 0.07),
        ],
      ),
    );
  }
}
