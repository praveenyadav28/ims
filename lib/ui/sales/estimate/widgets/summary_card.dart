import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:ims/ui/sales/estimate/state/estimate_bloc.dart';
import 'package:ims/ui/sales/estimate/widgets/additional_charges_section.dart';
import 'package:ims/ui/sales/estimate/widgets/discounts_section.dart';
import 'package:ims/utils/colors.dart';

class SummaryCard extends StatelessWidget {
  const SummaryCard({super.key, required this.state, required this.bloc});

  final EstState state;
  final EstBloc bloc;

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
          _row('Subtotal', state.subtotal),
          _row('Total GST', state.totalGst),
          _row('SGST', state.sgst),
          _row('CGST', state.cgst),
          AdditionalChargesSection(state: state, bloc: bloc),
          DiscountsSection(state: state, bloc: bloc),
          Divider(),
          Row(
            children: [
              Checkbox(
                fillColor: WidgetStatePropertyAll(AppColor.primary),
                shape: ContinuousRectangleBorder(
                  borderRadius: BorderRadiusGeometry.circular(5),
                ),
                value: state.autoRound,
                onChanged: (value) =>
                    bloc.add(EstToggleRoundOff(value ?? true)),
              ),
              const SizedBox(width: 8),
              Text(
                'Auto Round Off',
                style: GoogleFonts.roboto(
                  fontSize: 14,
                  color: AppColor.textColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          _row('Total Amount', state.totalAmount, isBold: true),
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
