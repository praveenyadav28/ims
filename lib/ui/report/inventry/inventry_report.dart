import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:ims/ui/inventry/item_model.dart';
import 'package:intl/intl.dart';
import 'package:ims/utils/api.dart';
import 'package:ims/utils/colors.dart';
import 'package:ims/utils/prefence.dart';
import 'package:ims/utils/textfield.dart';

class InventoryAdvancedReportScreen extends StatefulWidget {
  const InventoryAdvancedReportScreen({super.key});

  @override
  State<InventoryAdvancedReportScreen> createState() =>
      _InventoryAdvancedReportScreenState();
}

class _InventoryAdvancedReportScreenState
    extends State<InventoryAdvancedReportScreen> {
  bool loading = true;

  List<ItemModel> allItems = [];
  List<ItemModel> filtered = [];

  // Filters
  String searchText = "";
  String? selectedCategory;
  bool showLowStock = false;

  DateTime? fromDate;
  DateTime? toDate;

  @override
  void initState() {
    super.initState();
    fetchReport();
  }

  // ================= API =================
  Future<void> fetchReport() async {
    setState(() => loading = true);

    final res = await ApiService.fetchData(
      "get/inventoryreport"
      "?from_date=${_fmt(fromDate)}"
      "&to_date=${_fmt(toDate)}",
      licenceNo: Preference.getint(PrefKeys.licenseNo),
    );

    allItems = (res['data'] as List).map((e) => ItemModel.fromJson(e)).toList();

    applyFilters();
    setState(() => loading = false);
  }

  String _fmt(DateTime? d) =>
      d == null ? "" : DateFormat("yyyy-MM-dd").format(d);

  // ================= FILTER =================
  void applyFilters() {
    List<ItemModel> temp = List.from(allItems);

    if (searchText.isNotEmpty) {
      temp = temp.where((e) {
        return e.itemName.toLowerCase().contains(searchText.toLowerCase()) ||
            e.itemNo.toLowerCase().contains(searchText.toLowerCase());
      }).toList();
    }

    if (selectedCategory != null) {
      temp = temp.where((e) => e.group == selectedCategory).toList();
    }

    if (showLowStock) {
      temp = temp.where((e) {
        final qty = double.tryParse(e.openingStock) ?? 0;
        final min = double.tryParse(e.minStockQty) ?? 0;
        return qty <= min && min > 0;
      }).toList();
    }

    filtered = temp;
    setState(() {});
  }

  // ================= STATS =================
  double get openingTotal => filtered.fold(0, (p, e) => p + _d(e.openingStock));

  double get closingTotal => filtered.fold(0, (p, e) => p + _d(e.openingStock));

  double get stockValue =>
      filtered.fold(0, (p, e) => p + (_d(e.openingStock) * _d(e.salesPrice)));

  double _d(String? v) => double.tryParse(v ?? "0") ?? 0;

  // ================= UI =================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xffF8FAFC),
      appBar: AppBar(
        backgroundColor: AppColor.black,
        title: const Text("Inventory Report"),
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                _filterBar(),
                _summaryBar(),
                Expanded(child: _table()),
              ],
            ),
    );
  }

  // ================= FILTER BAR =================
  Widget _filterBar() {
    return Container(
      padding: const EdgeInsets.all(12),
      margin: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Wrap(
        spacing: 12,
        runSpacing: 12,
        children: [
          _textField("Search Item", (v) {
            searchText = v;
            applyFilters();
          }),

          _dropdown(
            "Category",
            selectedCategory,
            [
              null,
              ...{for (var i in allItems) i.group},
            ],
            (v) {
              selectedCategory = v;
              applyFilters();
            },
          ),

          _dateBtn("From", fromDate, (d) {
            fromDate = d;
            fetchReport();
          }),
          _dateBtn("To", toDate, (d) {
            toDate = d;
            fetchReport();
          }),

          Row(
            children: [
              Checkbox(
                value: showLowStock,
                onChanged: (v) {
                  showLowStock = v!;
                  applyFilters();
                },
              ),
              const Text("Low Stock"),
            ],
          ),

          TextButton(
            onPressed: () {
              searchText = "";
              selectedCategory = null;
              showLowStock = false;
              fromDate = null;
              toDate = null;
              fetchReport();
            },
            child: const Text("Clear"),
          ),
        ],
      ),
    );
  }

  // ================= SUMMARY =================
  Widget _summaryBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        children: [
          _summary("Opening Stock", openingTotal.toStringAsFixed(2)),
          _summary("Closing Stock", closingTotal.toStringAsFixed(2)),
          _summary("Stock Value", "₹ ${stockValue.toStringAsFixed(2)}"),
        ],
      ),
    );
  }

  Widget _summary(String title, String value) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.all(6),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xffEEF2FF),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ================= TABLE =================
  Widget _table() {
    return ListView(
      padding: const EdgeInsets.all(12),
      children: [_header(), ...filtered.map(_row).toList()],
    );
  }

  Widget _header() {
    return Container(
      padding: const EdgeInsets.all(12),
      color: AppColor.black,
      child: const Row(
        children: [
          Expanded(flex: 2, child: Text("Item", style: _th)),
          Expanded(child: Text("Opening", style: _th)),
          Expanded(child: Text("In", style: _th)),
          Expanded(child: Text("Out", style: _th)),
          Expanded(child: Text("Closing", style: _th)),
          Expanded(child: Text("Value", style: _th)),
        ],
      ),
    );
  }

  Widget _row(ItemModel i) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: Colors.grey.shade300)),
      ),
      child: Row(
        children: [
          Expanded(flex: 2, child: Text(i.itemName)),
          Expanded(child: Text(i.openingStock)),
          Expanded(child: Text(i.stockQty)),
          Expanded(child: Text(i.stockQty)),
          Expanded(child: Text(i.openingStock)),
          Expanded(
            child: Text(
              "₹ ${(double.tryParse(i.openingStock)! * double.tryParse(i.salesPrice)!).toStringAsFixed(2)}",
            ),
          ),
        ],
      ),
    );
  }

  // ================= SMALL WIDGETS =================
  Widget _textField(String hint, Function(String) onChange) {
    return SizedBox(
      width: 220,
      child: TitleTextFeild(
        hintText: hint,
        titleText: hint,
        onChanged: onChange,
      ),
    );
  }

  Widget _dropdown(
    String title,
    String? value,
    List<String?> items,
    Function(String?) onChanged,
  ) {
    return SizedBox(
      width: 200,
      child: CommonDropdownField<String>(
        hintText: title,
        value: value,
        items: items
            .map((e) => DropdownMenuItem(value: e, child: Text(e ?? "All")))
            .toList(),
        onChanged: onChanged,
      ),
    );
  }

  Widget _dateBtn(String title, DateTime? date, Function(DateTime) onPick) {
    return OutlinedButton(
      onPressed: () async {
        final d = await showDatePicker(
          context: context,
          firstDate: DateTime(2020),
          lastDate: DateTime.now(),
          initialDate: date ?? DateTime.now(),
        );
        if (d != null) onPick(d);
      },
      child: Text(
        date == null ? title : DateFormat("dd MMM yyyy").format(date),
      ),
    );
  }
}

const TextStyle _th = TextStyle(
  color: Colors.white,
  fontWeight: FontWeight.bold,
);
