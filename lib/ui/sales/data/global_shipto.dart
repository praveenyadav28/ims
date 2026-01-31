import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:ims/utils/colors.dart';
import 'package:ims/utils/sizes.dart';
import 'package:ims/utils/textfield.dart';
import 'package:searchfield/searchfield.dart';

class GlobalShipToCard extends StatelessWidget {
  const GlobalShipToCard({
    super.key,
    required this.billingController,
    required this.shippingController,
    this.stateController,
    required this.onEditAddresses,
    this.onStateSelected,
    this.statesSuggestions,
  });

  final TextEditingController billingController;
  final TextEditingController shippingController;
  final TextEditingController? stateController;
  final List<String>? statesSuggestions;
  final Function(String)? onStateSelected;
  final VoidCallback onEditAddresses;

  @override
  Widget build(BuildContext context) {
    final billingAddress = billingController.text;
    final shippingAddress = shippingController.text;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        /// ------------ HEADER ------------
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Ship To',
              style: GoogleFonts.roboto(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColor.textColor,
              ),
            ),
            OutlinedButton(
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColor.primary,
                side: BorderSide(color: AppColor.primary, width: 1),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
              onPressed: onEditAddresses,
              child: Text(
                'Change Shipping Address',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),

        SizedBox(height: Sizes.height * .02),

        /// ------------ BILLING ADDRESS ------------
        Text(
          'Billing Address',
          style: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: AppColor.textColor,
          ),
        ),
        const SizedBox(height: 5),
        Text(
          billingAddress,
          style: GoogleFonts.roboto(
            fontSize: 14,
            color: const Color(0xff565D6D),
          ),
        ),

        SizedBox(height: Sizes.height * .02),

        /// ------------ SHIPPING ADDRESS ------------
        Text(
          'Shipping Address',
          style: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: AppColor.textColor,
          ),
        ),
        const SizedBox(height: 5),
        Text(
          shippingAddress,
          style: GoogleFonts.roboto(
            fontSize: 14,
            color: const Color(0xff565D6D),
          ),
        ),
        SizedBox(height: Sizes.height * .02),
        Text(
          "Place Of Supply",
          style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 6),

        CommonSearchableDropdownField<String>(
          controller: stateController!,
          hintText: "Select State",
          suggestions: statesSuggestions!
              .map((e) => SearchFieldListItem(e, item: e))
              .toList(),
          onSuggestionTap: (item) {
            stateController!.text = item.searchKey;
            onStateSelected!(item.searchKey);
          },
        ),
      ],
    );
  }
}
