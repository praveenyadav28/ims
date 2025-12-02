import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:ims/ui/sales/estimate/models/estimate_models.dart';
import 'package:ims/ui/sales/estimate/state/estimate_bloc.dart';
import 'package:ims/utils/colors.dart';
import 'package:ims/utils/textfield.dart';

class AdditionalChargesSection extends StatefulWidget {
  const AdditionalChargesSection({
    super.key,
    required this.state,
    required this.bloc,
  });

  final EstState state;
  final EstBloc bloc;

  @override
  State<AdditionalChargesSection> createState() =>
      _AdditionalChargesSectionState();
}

class _AdditionalChargesSectionState extends State<AdditionalChargesSection> {
  final nameCtrl = TextEditingController();
  final amtCtrl = TextEditingController();
  bool incl = false;
  bool showAddRow = false;

  @override
  Widget build(BuildContext context) {
    final state = widget.state;
    final bloc = widget.bloc;

    return SizedBox(
      width: double.infinity,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,

        children: [
          InkWell(
            onTap: () => setState(() => showAddRow = true),
            child: Text(
              ' + Additional Charges',
              style: GoogleFonts.roboto(
                fontSize: 14,
                color: AppColor.primary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),

          // show added charges
          Column(
            children: state.charges
                .map(
                  (charge) => ListTile(
                    dense: true,
                    title: Text(charge.name),
                    subtitle: Text('₹ ${charge.amount.toStringAsFixed(2)}'),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: () => bloc.add(EstRemoveCharge(charge.id)),
                    ),
                  ),
                )
                .toList(),
          ),

          const SizedBox(height: 2),

          // show form only when tapped
          if (showAddRow)
            Row(
              children: [
                Expanded(
                  child: CommonTextField(
                    controller: nameCtrl,
                    hintText: 'Charge Name',
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: CommonTextField(
                    controller: amtCtrl,
                    hintText: 'Amount',
                  ),
                ),
                const SizedBox(width: 8),

                ElevatedButton(
                  onPressed: () {
                    if (amtCtrl.text.trim().isEmpty) return;

                    final charge = AdditionalCharge(
                      id: UniqueKey().toString(),
                      name: nameCtrl.text.trim().isEmpty
                          ? 'Charge'
                          : nameCtrl.text.trim(),
                      amount: double.tryParse(amtCtrl.text) ?? 0,
                      taxPercent: 0,
                      taxIncluded: incl,
                    );

                    bloc.add(EstAddCharge(charge));

                    nameCtrl.clear();
                    amtCtrl.clear();
                    incl = false;
                    setState(() {});
                  },
                  child: const Text('Add'),
                ),
              ],
            ),
        ],
      ),
    );
  }
}
