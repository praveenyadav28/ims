import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:ims/utils/colors.dart';

class GlobalSummaryCard extends StatelessWidget {
  const GlobalSummaryCard({
    super.key,

    /// SUMMARY VALUES
    required this.subtotal,
    required this.totalGst,
    required this.sgst,
    required this.cgst,
    required this.totalAmount,

    /// ROUND OFF
    required this.autoRound,
    required this.onToggleRound,

    /// SECTIONS (INJECTED FROM OUTSIDE)
    required this.additionalChargesSection,
    required this.miscChargesSection,
    required this.discountSection,
  });

  /// ------ NUMERIC VALUES ------
  final double subtotal;
  final double totalGst;
  final double sgst;
  final double cgst;
  final double totalAmount;

  /// ------ ROUND OFF ------
  final bool autoRound;
  final ValueChanged<bool> onToggleRound;

  /// ------ REUSABLE CHILD WIDGETS ------
  final Widget additionalChargesSection;
  final Widget miscChargesSection;
  final Widget discountSection;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
      decoration: BoxDecoration(
        color: AppColor.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColor.borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          _row('Subtotal', subtotal),
          _row('Total GST', totalGst),
          _row('SGST', sgst),
          _row('CGST', cgst),

          /// ---------- Injected Sections ----------
          additionalChargesSection,
          miscChargesSection,
          discountSection,

          Divider(),

          /// -------- ROUND OFF --------
          Row(
            children: [
              Checkbox(
                value: autoRound,
                fillColor: WidgetStatePropertyAll(AppColor.primary),
                shape: ContinuousRectangleBorder(
                  borderRadius: BorderRadiusGeometry.circular(5),
                ),
                onChanged: (v) => onToggleRound(v ?? true),
              ),
              const SizedBox(width: 8),
              Text(
                'Auto Round Off',
                style: GoogleFonts.roboto(
                  fontSize: 14,
                  color: AppColor.textColor,
                ),
              )
            ],
          ),

          const SizedBox(height: 8),

          _row('Total Amount', totalAmount, isBold: true),
        ],
      ),
    );
  }

  Widget _row(String label, double value, {bool isBold = false}) {
    final style = GoogleFonts.roboto(
      fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
      fontSize: 14,
      color: AppColor.textColor,
    );

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: style),
          Text('₹ ${value.toStringAsFixed(2)}', style: style),
        ],
      ),
    );
  }
}
