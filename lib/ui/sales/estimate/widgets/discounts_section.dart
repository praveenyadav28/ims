import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:ims/ui/sales/estimate/models/estimate_models.dart';
import 'package:ims/ui/sales/estimate/state/estimate_bloc.dart';
import 'package:ims/utils/colors.dart';
import 'package:ims/utils/textfield.dart';

class DiscountsSection extends StatefulWidget {
  const DiscountsSection({super.key, required this.state, required this.bloc});

  final EstState state;
  final EstBloc bloc;

  @override
  State<DiscountsSection> createState() => _DiscountsSectionState();
}

class _DiscountsSectionState extends State<DiscountsSection> {
  final nameCtrl = TextEditingController();
  final valCtrl = TextEditingController();
  bool isPercent = false;
  bool showAddRow = false;

  @override
  Widget build(BuildContext context) {
    final state = widget.state;
    final bloc = widget.bloc;

    return Container(
      padding: EdgeInsets.only(top: 5),
      width: double.infinity,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            onTap: () => setState(() => showAddRow = true),
            child: Text(
              ' + Add Discount',
              style: GoogleFonts.roboto(
                fontSize: 14,
                color: AppColor.primary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),

          // Show existing discounts list
          Column(
            children: state.discounts
                .map(
                  (discount) => ListTile(
                    dense: true,
                    title: Text(discount.name),
                    subtitle: Text(
                      discount.isPercent
                          ? '${discount.amount}% of subtotal'
                          : '₹ ${discount.amount.toStringAsFixed(2)}',
                    ),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: () => bloc.add(EstRemoveDiscount(discount.id)),
                    ),
                  ),
                )
                .toList(),
          ),

          const SizedBox(height: 8),

          // Show add input row only when tapped
          if (showAddRow)
            Row(
              children: [
                Expanded(
                  flex: 4,
                  child: CommonTextField(
                    controller: nameCtrl,

                    hintText: 'Discount Name',
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  flex: 4,
                  child: CommonTextField(
                    controller: valCtrl,
                    hintText: 'Amount',
                  ),
                ),
                // const SizedBox(width: 8),
                // Expanded(
                //   flex: 3,
                //   child: CommonDropdownField<String>(
                //     value: isPercent ? 'Percent' : 'Amount',
                //     items: const [
                //       DropdownMenuItem(
                //         value: 'Percent',
                //         child: Text('Percent'),
                //       ),
                //       DropdownMenuItem(value: 'Amount', child: Text('Amount')),
                //     ],
                //     onChanged: (value) {
                //       setState(() => isPercent = value == 'Percent');
                //     },
                //   ),
                // ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: () {
                    if (valCtrl.text.trim().isEmpty) return;

                    final discount = DiscountLine(
                      id: UniqueKey().toString(),
                      name: nameCtrl.text.trim().isEmpty
                          ? 'Discount'
                          : nameCtrl.text.trim(),
                      amount: double.tryParse(valCtrl.text) ?? 0,
                      isPercent: isPercent,
                    );

                    bloc.add(EstAddDiscount(discount));

                    nameCtrl.clear();
                    valCtrl.clear();

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
