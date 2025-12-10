import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:ims/ui/sales/models/global_models.dart';
import 'package:ims/utils/colors.dart';
import 'package:ims/utils/textfield.dart';

class GlobalAdditionalChargesSection extends StatefulWidget {
  const GlobalAdditionalChargesSection({
    super.key,
    required this.charges,
    required this.onAddCharge,
    required this.onRemoveCharge,
  });

  /// Reusable data coming from any bloc/state
  final List<AdditionalCharge> charges;

  /// When user adds a new charge
  final Function(AdditionalCharge) onAddCharge;

  /// When user removes a charge
  final Function(String id) onRemoveCharge;

  @override
  State<GlobalAdditionalChargesSection> createState() =>
      _GlobalAdditionalChargesSectionState();
}

class _GlobalAdditionalChargesSectionState
    extends State<GlobalAdditionalChargesSection> {
  final nameCtrl = TextEditingController();
  final amtCtrl = TextEditingController();
  bool incl = false;
  bool showAddRow = false;

  @override
  void dispose() {
    nameCtrl.dispose();
    amtCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final charges = widget.charges;

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

          /// Existing charges list
          Column(
            children: charges.map((charge) {
              return ListTile(
                dense: true,
                title: Text(charge.name),
                subtitle:
                    Text('₹ ${charge.amount.toStringAsFixed(2)}'),
                trailing: IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: () => widget.onRemoveCharge(charge.id),
                ),
              );
            }).toList(),
          ),

          const SizedBox(height: 4),

          /// Add-form
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
                      amount: double.tryParse(amtCtrl.text.trim()) ?? 0,
                      taxPercent: 0,
                      taxIncluded: incl,
                    );

                    widget.onAddCharge(charge);

                    nameCtrl.clear();
                    amtCtrl.clear();
                    incl = false;
                    setState(() => showAddRow = false);
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
