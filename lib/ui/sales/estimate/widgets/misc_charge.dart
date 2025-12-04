import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:ims/ui/master/misc/misc_charge_model.dart';
import 'package:ims/ui/sales/estimate/state/estimate_bloc.dart';
import 'package:ims/utils/colors.dart';
import 'package:ims/utils/textfield.dart';

class MiscChargesSection extends StatefulWidget {
  final EstState state;
  final EstBloc bloc;
  final List<MiscChargeModelList> miscList; // From API

  const MiscChargesSection({
    super.key,
    required this.state,
    required this.bloc,
    required this.miscList,
  });

  @override
  State<MiscChargesSection> createState() => _MiscChargesSectionState();
}

class _MiscChargesSectionState extends State<MiscChargesSection> {
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
    final state = widget.state;
    final bloc = widget.bloc;

    return SizedBox(
      width: double.infinity,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(height: 10),

          /// ---------------- ADD MISC BUTTON ----------------
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

          /// ---------------- EXISTING MISC LIST ----------------
          Column(
            children: state.miscCharges.map((m) {
              return ListTile(
                dense: true,
                title: Text(m.name),
                subtitle: Text(
                  '₹ ${m.amount.toStringAsFixed(2)} • GST ${m.gst.toStringAsFixed(2)}% • ${m.taxIncluded ? "Inclusive" : "Exclusive"}',
                ),
                trailing: IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: () => bloc.add(EstRemoveMiscCharge(m.id)),
                ),
              );
            }).toList(),
          ),

          const SizedBox(height: 6),

          /// ---------------- ADD FORM ----------------
          if (showAdd)
            Row(
              children: [
                /// SELECT MISC TYPE
                Expanded(
                  flex: 4,
                  child: CommonDropdownField<MiscChargeModelList>(
                    value: selected,
                    hintText: "Select Charge",

                    items: widget.miscList.map((mc) {
                      return DropdownMenuItem<MiscChargeModelList>(
                        value: mc,
                        child: Text(mc.name),
                      );
                    }).toList(),
                    onChanged: (v) => setState(() => selected = v),
                  ),
                ),

                const SizedBox(width: 8),

                /// AMOUNT
                Expanded(
                  flex: 3,
                  child: CommonTextField(
                    controller: amtCtrl,
                    hintText: 'Amount',
                  ),
                ),

                const SizedBox(width: 8),

                /// INCLUSIVE GST
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

                    final entry = MiscChargeEntry(
                      id: UniqueKey().toString(),
                      miscId: selected!.id,
                      ledgerId: selected!.ledgerId,
                      name: selected!.name,
                      hsn: selected!.hsn,
                      gst: selected!.gst ?? 0,
                      amount: double.tryParse(amtCtrl.text.trim()) ?? 0,
                      taxIncluded: incl,
                    );

                    bloc.add(EstAddMiscCharge(entry));

                    /// reset
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
