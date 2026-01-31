import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:ims/ui/inventry/item/create.dart';
import 'package:ims/ui/sales/models/sale_invoice_data.dart';
import 'package:ims/utils/api.dart';
import 'package:ims/utils/button.dart';
import 'package:ims/utils/colors.dart';
import 'package:ims/utils/navigation.dart';
import 'package:ims/utils/prefence.dart';
import 'package:ims/utils/snackbar.dart';
import 'package:ims/utils/textfield.dart';
import 'package:intl/intl.dart';

import 'item_model.dart';

class InventoryScreen extends StatefulWidget {
  const InventoryScreen({super.key});

  @override
  State<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends State<InventoryScreen> {
  bool loading = false;
  List<ItemModel> list = [];

  // ---------------- FILTER STATES ----------------
  String searchText = '';
  String? selectedCategoryFilter;
  bool showLowStockOnly = false;

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    await fetchItems(); // pehle items
    await fetchDeadStockItems(); // phir dead stock
    await fetchStockValueNDP();
  }

  double stockValueNDP = 0;

  Future<void> fetchStockValueNDP() async {
    final res = await ApiService.fetchData(
      "get/fiforeports?from_date=${DateFormat("yyyy-MM-dd").format(DateTime.now())}&to_date=${DateFormat("yyyy-MM-dd").format(DateTime.now())}",
      licenceNo: Preference.getint(PrefKeys.licenseNo),
    );

    double total = 0;

    for (var item in res['data']) {
      final closing = double.tryParse(item['closing_stock'].toString()) ?? 0;

      total += closing;
    }

    setState(() {
      stockValueNDP = total;
    });
  }

  // ---------------- API ----------------
  Future<void> fetchItems() async {
    setState(() => loading = true);

    final res = await ApiService.fetchData(
      'get/item',
      licenceNo: Preference.getint(PrefKeys.licenseNo),
    );
    if (res['status'] == true) {
      list = ((res?['data'] ?? []) as List)
          .map((e) => ItemModel.fromJson(e))
          .toList();
    }

    setState(() => loading = false);
  }

  bool showDeadStock = false;
  String deadStockMonth = "1";
  Set<String> deadStockItemIds = {};
  Future<void> fetchDeadStockItems() async {
    final res = await ApiService.fetchData(
      "get/invoice",
      licenceNo: Preference.getint(PrefKeys.licenseNo),
    );

    final sales = SaleInvoiceListResponse.fromJson(res).data;

    final limitDate = DateTime.now().subtract(
      Duration(days: int.parse(deadStockMonth) * 30),
    );

    final Set<String> soldItemIds = {};

    for (var invoice in sales) {
      if (invoice.saleInvoiceDate.isAfter(limitDate)) {
        for (var item in invoice.itemDetails) {
          soldItemIds.add(item.itemId);
        }
      }
    }

    deadStockItemIds.clear();

    for (var item in list) {
      final stock = double.tryParse(item.stockQty) ?? 0;

      if (stock > 0 && !soldItemIds.contains(item.id)) {
        deadStockItemIds.add(item.id);
      }
    }

    setState(() {});
  }

  int get deadStockCount => deadStockItemIds.length;
  List<ItemModel> get filteredList {
    return list.where((item) {
      final name = item.itemName.toLowerCase();
      final code = item.itemNo.toLowerCase();
      final query = searchText.toLowerCase();

      bool matchesSearch =
          query.isEmpty || name.contains(query) || code.contains(query);

      bool matchesCategory =
          selectedCategoryFilter == null ||
          selectedCategoryFilter == item.group;

      bool matchesLowStock = true;
      if (showLowStockOnly) {
        final qty = double.tryParse(item.stockQty) ?? 0;
        final reorder = double.tryParse(item.reorderLevel) ?? 0;
        matchesLowStock = reorder > 0 && qty <= reorder;
      }

      bool matchesDeadStock = true;
      if (showDeadStock) {
        matchesDeadStock = deadStockItemIds.contains(item.id);
      }

      return matchesSearch &&
          matchesCategory &&
          matchesLowStock &&
          matchesDeadStock;
    }).toList();
  }

  // ---------------- STATS ----------------
  double get stockValueMRP {
    double total = 0;
    for (var i in list) {
      final qty = double.tryParse(i.stockQty) ?? 0;
      final price = double.tryParse(i.salesPrice) ?? 0;
      total += qty * price;
    }
    return total;
  }

  int get lowStockCount {
    return list.where((item) {
      final qty = double.tryParse(item.stockQty) ?? 0;
      final reorder = double.tryParse(item.reorderLevel) ?? 0;

      // ✅ Valid reorder level hona chahiye
      if (reorder <= 0) return false;

      // ✅ Stock hona chahiye
      if (qty <= 0) return false;

      // ✅ Low stock condition
      return qty <= reorder;
    }).length;
  }

  // ---------------- ACTIONS ----------------
  void _editItem(ItemModel item) async {
    final res = await pushTo(CreateNewItemScreen(editItem: item));

    if (res == true) fetchItems();
  }

  void _deleteItemConfirm(ItemModel item) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Delete Item"),
        content: Text("Are you sure you want to delete ${item.itemName}?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _deleteItem(item);
            },
            child: const Text("Delete"),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteItem(ItemModel item) async {
    final res = await ApiService.deleteData(
      'item/${item.id}',
      licenceNo: Preference.getint(PrefKeys.licenseNo),
    );

    if (res?['status'] == true) {
      setState(() => list.removeWhere((e) => e.id == item.id));
      showCustomSnackbarSuccess(context, "Item deleted successfully");
    } else {
      showCustomSnackbarError(context, res?['message'] ?? "Delete failed");
    }
  }

  // ---------------- UI ----------------
  @override
  Widget build(BuildContext context) {
    final data = filteredList;

    return Scaffold(
      backgroundColor: const Color(0xffF8FAFC),
      appBar: AppBar(
        backgroundColor: AppColor.black,
        elevation: 1,
        title: Text(
          "Inventory",
          style: GoogleFonts.inter(
            fontSize: 22,
            fontWeight: FontWeight.w700,
            color: AppColor.white,
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            /// ---------------- STATS ----------------
            Row(
              children: [
                _infoCard(
                  title: "Stock Value (MRP)",
                  value: "₹ ${stockValueMRP.toStringAsFixed(2)}",
                  icon: Icons.trending_up,
                ),
                _infoCard(
                  title: "Low Stock",
                  value: lowStockCount.toString(),
                  bgColor: const Color(0xffFFF7E6),
                  textColor: Colors.orange,
                  icon: Icons.warning,
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                _infoCard(
                  title: "Stock Value (NDP)",
                  value: "₹ ${stockValueNDP.toStringAsFixed(2)}",
                  icon: Icons.trending_up,
                ),
                _infoCard(
                  title: "Dead Stock",
                  value: deadStockCount.toString(),
                  bgColor: const Color(0xffFFE4E6),
                  textColor: Colors.red,
                  icon: Icons.error,
                  onTap: () async {
                    showDeadStock = true;
                    showLowStockOnly = false;

                    await fetchDeadStockItems();
                  },
                ),
              ],
            ),

            const SizedBox(height: 24),

            /// ---------------- FILTER BAR ----------------
            Row(
              children: [
                // SEARCH
                Expanded(
                  child: CommonTextField(
                    perfixIcon: const Icon(Icons.search),
                    hintText: "Search Item",
                    onChanged: (val) => setState(() => searchText = val),
                  ),
                ),
                const SizedBox(width: 12),

                // CATEGORY FILTER
                Expanded(
                  child: CommonDropdownField<String>(
                    value: selectedCategoryFilter,
                    items: [
                      DropdownMenuItem(
                        value: null,
                        child: Text("All Categories"),
                      ),
                      ...list
                          .map((e) => e.group)
                          .toSet()
                          .map(
                            (c) => DropdownMenuItem(value: c, child: Text(c)),
                          ),
                    ],
                    onChanged: (val) =>
                        setState(() => selectedCategoryFilter = val),
                    hintText: "Select Categories",
                  ),
                ),
                const SizedBox(width: 12),

                // LOW STOCK TOGGLE
                Expanded(
                  flex: 3,
                  child: Row(
                    children: [
                      Checkbox(
                        value: showLowStockOnly,
                        onChanged: (v) {
                          setState(() {
                            showLowStockOnly = v ?? false;
                            showDeadStock = false;
                          });
                        },
                      ),
                      const Text("Low Stock"),

                      const SizedBox(width: 16),

                      Checkbox(
                        value: showDeadStock,
                        onChanged: (v) async {
                          showDeadStock = v ?? false;
                          showLowStockOnly = false;

                          if (showDeadStock) {
                            await fetchDeadStockItems();
                          }

                          setState(() {});
                        },
                      ),
                      const Text("Dead Stock"),

                      if (showDeadStock)
                        Padding(
                          padding: const EdgeInsets.only(left: 12),
                          child: SizedBox(
                            width: 200,
                            child: CommonDropdownField<String>(
                              value: deadStockMonth,
                              items: const [
                                DropdownMenuItem(
                                  value: "1",
                                  child: Text("1 Month"),
                                ),
                                DropdownMenuItem(
                                  value: "3",
                                  child: Text("3 Month"),
                                ),
                                DropdownMenuItem(
                                  value: "6",
                                  child: Text("6 Month"),
                                ),
                                DropdownMenuItem(
                                  value: "12",
                                  child: Text("12 Month"),
                                ),
                              ],
                              onChanged: (v) async {
                                deadStockMonth = v!;
                                await fetchDeadStockItems();
                              },
                            ),
                          ),
                        ),
                    ],
                  ),
                ),

                defaultButton(
                  buttonColor: AppColor.blue,
                  height: 35,
                  width: 100,
                  onTap: () async {
                    var data = await pushTo(CreateNewItemScreen());
                    if (data != null) {
                      fetchItems();
                    }
                  },
                  text: "Create Item",
                ),
              ],
            ),

            const SizedBox(height: 16),

            /// ---------------- TABLE ----------------
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: loading
                    ? Center(child: GlowLoader())
                    : Column(
                        children: [
                          _tableHeader(),
                          const Divider(height: 1),
                          Expanded(
                            child: data.isEmpty
                                ? const Center(child: Text("No items found"))
                                : ListView.builder(
                                    itemCount: data.length,
                                    itemBuilder: (context, i) =>
                                        _tableRowModel(data[i]),
                                  ),
                          ),
                        ],
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// ================== WIDGETS ==================
  Widget _infoCard({
    required String title,
    required String value,
    IconData? icon,
    Color bgColor = Colors.white,
    Color textColor = Colors.black,
    VoidCallback? onTap, // 👈 ADD THIS
  }) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          height: 110,
          margin: const EdgeInsets.only(right: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xffE5E7EB)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  if (icon != null) Icon(icon, size: 18, color: textColor),
                  const SizedBox(width: 6),
                  Text(
                    title,
                    style: GoogleFonts.inter(fontSize: 13, color: textColor),
                  ),
                  const Spacer(),
                  const Icon(Icons.open_in_new, size: 16),
                ],
              ),
              const Spacer(),
              Text(
                value,
                style: GoogleFonts.inter(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: textColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _tableHeader() {
    return const Padding(
      padding: EdgeInsets.all(14),
      child: Row(
        children: [
          Expanded(flex: 2, child: Text("Item Name")),
          Expanded(child: Text("Item Code")),
          Expanded(child: Text("Stock QTY")),
          Expanded(child: Text("Selling Price")),
          Expanded(child: Text("Purchase Price")),
          Expanded(child: Text("HSN Code")),
          Expanded(child: Text("Actions")),
        ],
      ),
    );
  }

  Widget _tableRowModel(ItemModel item) {
    return Padding(
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          Expanded(flex: 2, child: Text(item.itemName)),
          Expanded(child: Text(item.itemNo)),
          Expanded(child: Text("${item.stockQty} ${item.baseUnit}")),
          Expanded(child: Text("₹ ${item.salesPrice}")),
          Expanded(child: Text("₹ ${item.purchasePriceSe}")),
          Expanded(child: Text(item.hsnCode)),

          // ACTIONS
          Expanded(
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.edit, color: Colors.blue),
                  onPressed: () => _editItem(item),
                ),
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: () => _deleteItemConfirm(item),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
