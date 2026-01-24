import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:ims/ui/report/inventry/item_ledger.dart';
import 'package:ims/ui/report/inventry/item_party.dart';
import 'package:ims/utils/button.dart';
import 'package:ims/utils/navigation.dart';
import 'package:intl/intl.dart';
import 'package:ims/ui/inventry/item_model.dart';
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

  String? selectedCategoryFilter;

  /// Filters
  final searchCtrl = TextEditingController();
  final fromDateCtrl = TextEditingController();
  final toDateCtrl = TextEditingController();

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
      "get/inventoryreport?from_date=${_fmt(fromDate)}&to_date=${_fmt(toDate)}",
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

    // 🔍 Search filter
    if (searchCtrl.text.isNotEmpty) {
      final q = searchCtrl.text.toLowerCase();

      temp = temp.where((e) {
        return e.itemName.toLowerCase().contains(q) ||
            e.varientName.toLowerCase().contains(q) ||
            e.itemNo.toLowerCase().contains(q);
      }).toList();
    }

    // 📦 Category filter
    if (selectedCategoryFilter != null && selectedCategoryFilter!.isNotEmpty) {
      temp = temp.where((e) => e.group == selectedCategoryFilter).toList();
    }

    filtered = temp;
    setState(() {});
  }

  // ================= UI =================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xffF8FAFC),
      appBar: AppBar(
        backgroundColor: AppColor.black,
        title: const Text("Inventory Report"),
        actions: [
          Center(
            child: defaultButton(
              text: "Item By Patry",
              height: 40,
              width: 170,
              buttonColor: AppColor.blue,
              onTap: () {
                pushTo(PartyLedgerScreen());
              },
            ),
          ),
          SizedBox(width: 10),
          Center(
            child: defaultButton(
              text: "Item Ledger",
              height: 40,
              width: 170,
              buttonColor: AppColor.blue,
              onTap: () {
                pushTo(ItemLedgerScreen());
              },
            ),
          ),
          SizedBox(width: 10),
        ],
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                _filterBar(),
                Expanded(child: _table()),
              ],
            ),
    );
  }

  // ================= FILTER BAR =================
  Widget _filterBar() {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.all(12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        spacing: 12,
        children: [
          _textField(
            "Search Item",
            searchCtrl,
            onChanged: ((value) {
              applyFilters();
            }),
          ),

          _dateField("From Date", fromDateCtrl, (d) {
            fromDate = d;
          }),

          _dateField("To Date", toDateCtrl, (d) {
            toDate = d;
          }),
          Expanded(
            flex: 3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Group",
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: AppColor.textColor,
                  ),
                ),
                SizedBox(height: 8),
                CommonDropdownField<String>(
                  value: selectedCategoryFilter,
                  items: [
                    DropdownMenuItem(
                      value: null,
                      child: Text("All Categories"),
                    ),
                    ...allItems
                        .map((e) => e.group)
                        .toSet()
                        .map((c) => DropdownMenuItem(value: c, child: Text(c))),
                  ],
                  onChanged: (val) => setState(() {
                    selectedCategoryFilter = val;
                    applyFilters();
                  }),
                  hintText: "Select Group",
                ),
              ],
            ),
          ),

          Spacer(flex: 1),

          defaultButton(
            onTap: () => fetchReport(),
            text: "Apply Filter",
            height: 40,
            width: 180,
            buttonColor: AppColor.blue,
          ),
        ],
      ),
    );
  }

  // ================= TABLE =================
  Widget _table() {
    if (filtered.isEmpty) {
      return const Center(child: Text("No data found"));
    }

    return ListView(
      padding: const EdgeInsets.all(12),
      children: [_header(), ...filtered.map(_row)],
    );
  }

  Widget _header() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColor.black,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(10),
          topRight: Radius.circular(10),
        ),
      ),
      child: Row(
        children: [
          Expanded(flex: 2, child: Text("Item No", style: _th)),
          Expanded(flex: 3, child: Text("Item Name", style: _th)),
          Expanded(flex: 2, child: Text("Variant", style: _th)),
          Expanded(flex: 2, child: Text("Opening", style: _th)),
          Expanded(flex: 2, child: Text("Inward", style: _th)),
          Expanded(flex: 2, child: Text("Outward", style: _th)),
          Expanded(flex: 2, child: Text("Closing", style: _th)),
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
          Expanded(flex: 2, child: Text(i.itemNo, style: _tt)),
          Expanded(flex: 3, child: Text(i.itemName, style: _tt)),
          Expanded(
            flex: 2,
            child: Text(
              i.varientName.isNotEmpty == true ? i.varientName : "-",
              style: _tt,
            ),
          ),
          Expanded(flex: 2, child: Text(i.openingStock, style: _tt)),
          Expanded(flex: 2, child: Text(i.inword, style: _tt)),
          Expanded(flex: 2, child: Text(i.outword, style: _tt)),
          Expanded(flex: 2, child: Text(i.closingStock, style: _tt)),
        ],
      ),
    );
  }

  // ================= HELPERS =================
  Widget _textField(
    String hint,
    TextEditingController c, {
    void Function(String)? onChanged,
  }) {
    return Expanded(
      flex: 3,
      child: TitleTextFeild(
        controller: c,
        hintText: hint,
        titleText: hint,
        onChanged: onChanged,
      ),
    );
  }

  Widget _dateField(
    String label,
    TextEditingController ctrl,
    Function(DateTime) onPick,
  ) {
    return Expanded(
      flex: 2,
      child: TitleTextFeild(
        controller: ctrl,
        readOnly: true,
        titleText: label,
        hintText: "Enter date",
        suffixIcon: const Icon(Icons.calendar_today),
        onTap: () async {
          final d = await showDatePicker(
            context: context,
            firstDate: DateTime(2020),
            lastDate: DateTime.now(),
            initialDate: DateTime.now(),
          );
          if (d != null) {
            ctrl.text = DateFormat("dd-MM-yyyy").format(d);
            onPick(d);
          }
        },
      ),
    );
  }
}

TextStyle _th = GoogleFonts.inter(
  color: Colors.white,
  fontWeight: FontWeight.bold,
);

TextStyle _tt = GoogleFonts.inter(
  color: Colors.black,
  fontWeight: FontWeight.w500,
);
