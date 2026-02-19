import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:ims/ui/inventry/item_model.dart';
import 'package:ims/utils/api.dart';
import 'package:ims/utils/colors.dart';
import 'package:ims/utils/prefence.dart';
import 'package:ims/utils/sizes.dart';
import 'package:ims/utils/snackbar.dart';
import 'package:ims/utils/textfield.dart';

class ConsumptionItem {
  ItemModel? item;
  TextEditingController qtyController = TextEditingController();
}

class ConsumptionCreateScreen extends StatefulWidget {
  const ConsumptionCreateScreen({super.key});

  @override
  State<ConsumptionCreateScreen> createState() =>
      _ConsumptionCreateScreenState();
}

class _ConsumptionCreateScreenState extends State<ConsumptionCreateScreen> {
  bool loading = false;
  List<ItemModel> list = [];
  List<ConsumptionItem> rows = [ConsumptionItem()];

  TextEditingController finishedItemName = TextEditingController();
  TextEditingController finishedItemNo = TextEditingController();
  TextEditingController finishedQty = TextEditingController();

  @override
  void initState() {
    super.initState();
    fetchItems();
  }

  Future<void> fetchItems() async {
    setState(() => loading = true);
    final res = await ApiService.fetchData(
      'get/item',
      licenceNo: Preference.getint(PrefKeys.licenseNo),
    );
    if (res['status'] == true) {
      list = ((res['data'] ?? []) as List)
          .map((e) => ItemModel.fromJson(e))
          .toList();
    }
    setState(() => loading = false);
  }

  double _stockOf(ItemModel item) {
    return double.tryParse(item.closingStock) ?? 0;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xffF9FAFC),
      appBar: AppBar(
        backgroundColor: AppColor.white,
        elevation: .4,
        title: Text(
          "Create Consumption",
          style: GoogleFonts.plusJakartaSans(
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: EdgeInsets.symmetric(
                horizontal: Sizes.width * .04,
                vertical: Sizes.height * .03,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _sectionCard(
                    title: "Finished Item",
                    child: Column(
                      children: [
                        CommonTextField(
                          hintText: "Finished Item Name",
                          controller: finishedItemName,
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Expanded(
                              child: CommonTextField(
                                hintText: "Item No",
                                controller: finishedItemNo,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: CommonTextField(
                                hintText: "Qty Produced",
                                controller: finishedQty,
                                // keyboardType: TextInputType.number,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  _sectionCard(
                    title: "Consume Raw Items",
                    trailing: IconButton(
                      icon: const Icon(
                        Icons.add_circle,
                        color: Color(0xff8947E5),
                      ),
                      onPressed: () =>
                          setState(() => rows.add(ConsumptionItem())),
                    ),
                    child: Column(
                      children: rows.asMap().entries.map((entry) {
                        final i = entry.key;
                        final row = entry.value;
                        return _consumeRow(i, row);
                      }).toList(),
                    ),
                  ),

                  const SizedBox(height: 24),

                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xff8947E5),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: _submit,
                      child: const Text("Create Consumption"),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _sectionCard({
    required String title,
    required Widget child,
    Widget? trailing,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              if (trailing != null) trailing,
            ],
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }

  Widget _consumeRow(int index, ConsumptionItem row) {
    final stock = row.item == null ? 0 : _stockOf(row.item!);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xffF8F9FC),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        children: [
          DropdownButtonFormField<ItemModel>(
            decoration: const InputDecoration(
              hintText: "Select Item",
              border: OutlineInputBorder(),
            ),
            value: row.item,
            items: list
                .map(
                  (e) => DropdownMenuItem(
                    value: e,
                    child: Text("${e.itemName} (${e.closingStock})"),
                  ),
                )
                .toList(),
            onChanged: (val) => setState(() => row.item = val),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: CommonTextField(
                  hintText: "Qty to consume",
                  controller: row.qtyController,
                  // keyboardType: TextInputType.number,
                ),
              ),
              const SizedBox(width: 12),
              Chip(
                backgroundColor: stock > 0
                    ? const Color(0xffEDE5FF)
                    : Colors.red.shade100,
                label: Text("Stock: $stock"),
              ),
              IconButton(
                icon: const Icon(Icons.delete, color: Colors.red),
                onPressed: rows.length == 1
                    ? null
                    : () => setState(() => rows.removeAt(index)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _submit() async {
    if (finishedItemName.text.isEmpty || finishedQty.text.isEmpty) {
      showCustomSnackbarError(context, "Enter finished item details");
      return;
    }

    for (final r in rows) {
      if (r.item == null || r.qtyController.text.isEmpty) {
        showCustomSnackbarError(context, "Select item & qty");
        return;
      }

      final consume = double.tryParse(r.qtyController.text) ?? 0;
      final stock = _stockOf(r.item!);
      if (consume > stock) {
        showCustomSnackbarError(context, "Consume qty greater than stock");
        return;
      }
    }

    final payload = {
      "finished_item": finishedItemName.text.trim(),
      "finished_item_no": finishedItemNo.text.trim(),
      "finished_qty": finishedQty.text.trim(),
      "consume": rows
          .map((e) => {"item_id": e.item!.id, "qty": e.qtyController.text})
          .toList(),
    };

    debugPrint(payload.toString());

    // 🔗 Call your API here
    showCustomSnackbarSuccess(context, "Consumption created (demo)");
  }
}
