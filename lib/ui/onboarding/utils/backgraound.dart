// ignore_for_file: must_be_immutable

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:ims/utils/colors.dart';
import 'package:ims/utils/sizes.dart';

class OnboardingBackground extends StatefulWidget {
  OnboardingBackground({super.key, required this.widget});
  Widget widget;

  @override
  State<OnboardingBackground> createState() => _OnboardingBackgroundState();
}

class _OnboardingBackgroundState extends State<OnboardingBackground> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SizedBox(
      width: Sizes.width,
      height: Sizes.height,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppColor.primary,
              AppColor.primary.withOpacity(.8),
              AppColor.primary.withOpacity(.6),
            ],
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            SizedBox(width: Sizes.width * 0.07),
            Expanded(
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 140,
                          height: 140,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(color: Colors.white24, width: 2),
                          ),
                          alignment: Alignment.center,
                          child: Image.asset(
                            "assets/images/applogo.png",
                            height: 82,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Vyapari Bahi',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 28,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                                letterSpacing: 1.2,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'Inventory made simple',
                              style: theme.textTheme.bodyLarge?.copyWith(
                                fontSize: 20,
                                color: Colors.white70,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            Container(
              width: 450,
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
      ),
    );
  }
}
