import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppLogoWidget extends StatelessWidget {
  const AppLogoWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      mainAxisSize: MainAxisSize.min,
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
          child: Image.asset("assets/images/applogo.png", height: 82),
        ),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
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
    );
  }
}
