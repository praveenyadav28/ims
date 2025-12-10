import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:ims/ui/master/misc/misc_charge_model.dart';
import 'package:ims/ui/sales/models/global_models.dart';
import 'package:ims/utils/colors.dart';
import 'package:ims/utils/textfield.dart';

// ignore: must_be_immutable
class GlobalMiscChargesSection extends StatefulWidget {
  GlobalMiscChargesSection({
    super.key,
    required this.miscCharges,
    required this.miscList,
    required this.onAddMisc,
    required this.onRemoveMisc,
  });
  List<GlobalMiscChargeEntry> miscCharges;

  final List<MiscChargeModelList> miscList;

  final Function(GlobalMiscChargeEntry entry) onAddMisc;

  final Function(String id) onRemoveMisc;

  @override
  State<GlobalMiscChargesSection> createState() =>
      _GlobalMiscChargesSectionState();
}

class _GlobalMiscChargesSectionState extends State<GlobalMiscChargesSection> {
  MiscChargeModelList? selected;
  final amtCtrl = TextEditingController();
  bool incl = false;
  bool showAdd = false;

  @override
  void dispose() {
    amtCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 10),

          /// ADD BUTTON
          InkWell(
            onTap: () => setState(() => showAdd = true),
            child: Text(
              ' + Misc Charges',
              style: GoogleFonts.roboto(
                fontSize: 14,
                color: AppColor.primary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),

          const SizedBox(height: 4),

          /// EXISTING LIST
          Column(
            children: widget.miscCharges.map((m) {
              return ListTile(
                dense: true,
                title: Text(m.name),
                subtitle: Text(
                  '₹ ${m.amount.toStringAsFixed(2)} • GST ${m.gst.toStringAsFixed(2)}% • ${m.taxIncluded ? "Inclusive" : "Exclusive"}',
                ),
                trailing: IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: () => widget.onRemoveMisc(m.id),
                ),
              );
            }).toList(),
          ),

          const SizedBox(height: 6),

          /// ADD FORM
          if (showAdd)
            Row(
              children: [
                /// SELECT MISC TYPE
                Expanded(
                  flex: 4,
                  child: CommonDropdownField<MiscChargeModelList>(
                    value: selected,
                    hintText: "Select Charge",
                    items: widget.miscList.map((m) {
                      return DropdownMenuItem(value: m, child: Text(m.name));
                    }).toList(),
                    onChanged: (v) => setState(() => selected = v),
                  ),
                ),

                const SizedBox(width: 8),

                /// AMOUNT FIELD
                Expanded(
                  flex: 3,
                  child: CommonTextField(
                    controller: amtCtrl,
                    hintText: 'Amount',
                  ),
                ),

                const SizedBox(width: 8),

                /// INCLUSIVE CHECKBOX
                Column(
                  children: [
                    Row(
                      children: [
                        Checkbox(
                          value: incl,
                          onChanged: (val) =>
                              setState(() => incl = val ?? false),
                        ),
                        const SizedBox(width: 4),
                        const Text('Inclusive'),
                      ],
                    ),
                  ],
                ),

                const SizedBox(width: 8),

                /// ADD BUTTON
                ElevatedButton(
                  onPressed: () {
                    if (selected == null) return;
                    if (amtCtrl.text.trim().isEmpty) return;

                    final entry = GlobalMiscChargeEntry(
                      id: UniqueKey().toString(),
                      miscId: selected!.id,
                      ledgerId: selected!.ledgerId,
                      name: selected!.name,
                      hsn: selected!.hsn,
                      gst: selected!.gst ?? 0,
                      amount: double.tryParse(amtCtrl.text.trim()) ?? 0,
                      taxIncluded: incl,
                    );

                    widget.onAddMisc(entry);

                    /// Reset
                    setState(() {
                      selected = null;
                      amtCtrl.clear();
                      incl = false;
                      showAdd = false;
                    });
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
