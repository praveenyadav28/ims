import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:ims/ui/sales/estimate/state/estimate_bloc.dart';
import 'package:ims/utils/colors.dart';
import 'package:ims/utils/sizes.dart';

class ShipToCard extends StatelessWidget {
  const ShipToCard({
    super.key,
    required this.state,
    required this.cashBillingController,
    required this.cashShippingController,
    required this.onEditAddresses,
  });

  final EstState state;
  final TextEditingController cashBillingController;
  final TextEditingController cashShippingController;
  final VoidCallback onEditAddresses;

  @override
  Widget build(BuildContext context) {
    final isCashSale = state.cashSaleDefault;

    /// ---------- BILLING ADDRESS ----------
    final billingAddress = isCashSale
        ? cashBillingController.text
        : (state.selectedCustomer?.billingAddress ?? '');

    final shippingAddress = isCashSale
        ? cashShippingController.text
        : (state.selectedCustomer?.shippingAddress ?? '');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Top header
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

        SizedBox(height: Sizes.height * .05),

        /// ---------- BILLING ----------
        Text(
          'Billing Address',
          style: GoogleFonts.inter(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AppColor.textColor,
          ),
        ),
        SizedBox(height: 5),
        Text(
          billingAddress,
          style: GoogleFonts.roboto(
            fontSize: 14,
            color: const Color(0xff565D6D),
          ),
        ),

        SizedBox(height: Sizes.height * .03),

        /// ---------- SHIPPING ----------
        Text(
          'Shipping Address',
          style: GoogleFonts.inter(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AppColor.textColor,
          ),
        ),
        SizedBox(height: 5),
        Text(
          shippingAddress,
          style: GoogleFonts.roboto(
            fontSize: 14,
            color: const Color(0xff565D6D),
          ),
        ),
      ],
    );
  }
}
