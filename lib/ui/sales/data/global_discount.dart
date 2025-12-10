import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:ims/ui/sales/models/global_models.dart';
import 'package:ims/utils/colors.dart';
import 'package:ims/utils/textfield.dart';

class GlobalDiscountsSection extends StatefulWidget {
  const GlobalDiscountsSection({
    super.key,
    required this.discounts,
    required this.onAddDiscount,
    required this.onRemoveDiscount,
  });

  /// List of discounts from BLoC or any state manager
  final List<DiscountLine> discounts;

  /// Callback when user adds a discount
  final Function(DiscountLine discount) onAddDiscount;

  /// Callback when user deletes a discount
  final Function(String id) onRemoveDiscount;

  @override
  State<GlobalDiscountsSection> createState() => _GlobalDiscountsSectionState();
}

class _GlobalDiscountsSectionState extends State<GlobalDiscountsSection> {
  final nameCtrl = TextEditingController();
  final valCtrl = TextEditingController();
  bool isPercent = false;
  bool showAddRow = false;

  @override
  void dispose() {
    nameCtrl.dispose();
    valCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.only(top: 5),
      width: double.infinity,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          /// ADD BUTTON
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

          /// EXISTING DISCOUNTS LIST
          Column(
            children: widget.discounts.map((discount) {
              return ListTile(
                dense: true,
                title: Text(discount.name),
                subtitle: Text(
                  discount.isPercent
                      ? '${discount.amount}% of subtotal'
                      : '₹ ${discount.amount.toStringAsFixed(2)}',
                ),
                trailing: IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: () => widget.onRemoveDiscount(discount.id),
                ),
              );
            }).toList(),
          ),

          const SizedBox(height: 8),

          /// ADD DISCOUNT FORM
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

                const SizedBox(width: 8),

                ElevatedButton(
                  onPressed: () {
                    if (valCtrl.text.trim().isEmpty) return;

                    final discount = DiscountLine(
                      id: UniqueKey().toString(),
                      name: nameCtrl.text.trim().isEmpty
                          ? 'Discount'
                          : nameCtrl.text.trim(),
                      amount: double.tryParse(valCtrl.text.trim()) ?? 0,
                      isPercent: isPercent,
                    );

                    widget.onAddDiscount(discount);

                    nameCtrl.clear();
                    valCtrl.clear();

                    setState(() {
                      showAddRow = false;
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
