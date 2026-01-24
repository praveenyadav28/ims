import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:ims/utils/button.dart';
import 'package:ims/utils/colors.dart';
import 'package:ims/utils/textfield.dart';
import 'package:intl/intl.dart';

class TransactionListScreen<T> extends StatefulWidget {
  final String title;

  /// API call function
  final Future<List<T>> Function() fetchData;

  /// Actions
  final void Function(T) onView;
  final void Function(T) onEdit;
  final Future<bool> Function(String id) onDelete;
  final Future<void> Function()? onCreate;

  /// Extractors — YOU must provide these
  final String Function(T) idGetter;
  final DateTime Function(T) dateGetter;
  final String Function(T) numberGetter;
  final String Function(T) customerGetter;
  final double Function(T) basicGetter;
  final double Function(T) gstGetter;
  final double Function(T) amountGetter;
  final String Function(T) addressGetter;

  const TransactionListScreen({
    super.key,
    required this.title,
    required this.fetchData,
    required this.onView,
    required this.onEdit,
    required this.onDelete,
    required this.idGetter,
    required this.dateGetter,
    required this.numberGetter,
    required this.customerGetter,
    required this.basicGetter,
    required this.gstGetter,
    required this.amountGetter,
    required this.addressGetter,
    this.onCreate,
  });

  @override
  State<TransactionListScreen<T>> createState() =>
      TransactionListScreenState<T>(); // 👈 PUBLIC STATE
}

/// 🔓 PUBLIC STATE CLASS (no underscore)
class TransactionListScreenState<T> extends State<TransactionListScreen<T>> {
  List<T> items = [];
  List<T> filtered = [];

  bool loading = true;
  T? activeRow;

  final searchCtrl = TextEditingController();

  /// DATE FILTER OPTIONS
  String dateRange = "Last 365 Days";
  final Map<String, int> dayFilters = {
    "Last 1 Day": 1,
    "Last 7 Days": 7,
    "Last 30 Days": 30,
    "Last 180 Days": 180,
    "Last 365 Days": 365,
  };

  @override
  void initState() {
    super.initState();
    load();
  }

  /// LOAD DATA
  Future<void> load() async {
    loading = true;
    setState(() {});

    items = await widget.fetchData();
    _applyFilters();

    loading = false;
    setState(() {});
  }

  /// FILTERS: DATE + SEARCH
  void _applyFilters() {
    int days = dayFilters[dateRange] ?? 365;
    DateTime now = DateTime.now();
    DateTime minDate = now.subtract(Duration(days: days));

    String q = searchCtrl.text.toLowerCase().trim();

    filtered = items.where((item) {
      DateTime dt = widget.dateGetter(item);
      String customer = widget.customerGetter(item).toLowerCase();
      String number = widget.numberGetter(item).toLowerCase();

      bool dateOk = dt.isAfter(minDate) || dt.isAtSameMomentAs(minDate);
      bool searchOk = q.isEmpty || customer.contains(q) || number.contains(q);

      return dateOk && searchOk;
    }).toList();
  }

  void search(String _) {
    _applyFilters();
    setState(() {});
  }

  /// ------------------------------------------------------
  /// UI
  /// ------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColor.white,
      appBar: AppBar(
        elevation: 0.4,
        iconTheme: IconThemeData(color: AppColor.black),
        backgroundColor: AppColor.black,
        title: Text(
          widget.title,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: AppColor.white,
          ),
        ),
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : _layout(),
    );
  }

  Widget _layout() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          _filters(),
          const SizedBox(height: 20),
          _header(),
          Expanded(child: _list()),
        ],
      ),
    );
  }

  /// TOP FILTER ROW
  Widget _filters() {
    return Row(
      children: [
        Expanded(
          flex: 2,
          child: CommonTextField(
            controller: searchCtrl,
            onChanged: search,
            hintText: "Search...",
          ),
        ),
        const SizedBox(width: 12),
        _dateDropdown(),
        const Spacer(flex: 3),
        if (widget.onCreate != null)
          defaultButton(
            height: 40,
            width: 160,
            buttonColor: AppColor.blue,
            onTap: widget.onCreate!,
            text: "Create",
          ),
      ],
    );
  }

  /// DATE FILTER DROPDOWN
  Widget _dateDropdown() {
    return Expanded(
      flex: 1,
      child: PopupMenuButton<String>(
        onSelected: (value) {
          dateRange = value;
          _applyFilters();
          setState(() {});
        },
        itemBuilder: (context) => dayFilters.keys
            .map(
              (e) => PopupMenuItem(
                value: e,
                child: Text(
                  e,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            )
            .toList(),
        child: Container(
          height: 40,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: Colors.black12),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                dateRange,
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const Icon(Icons.arrow_drop_down),
            ],
          ),
        ),
      ),
    );
  }

  /// TABLE HEADER
  Widget _header() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
      decoration: BoxDecoration(
        color: AppColor.primary,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(7),
          topRight: Radius.circular(7),
        ),
      ),
      child: Row(
        children: [
          Expanded(flex: 2, child: Text("DATE", style: headerStyle)),
          Expanded(flex: 2, child: Text("NUMBER", style: headerStyle)),
          Expanded(flex: 2, child: Text("PARTY", style: headerStyle)),
          Expanded(flex: 2, child: Text("Basic Value", style: headerStyle)),
          Expanded(flex: 2, child: Text("GST Value", style: headerStyle)),
          Expanded(flex: 2, child: Text("Final Value", style: headerStyle)),
          Expanded(flex: 3, child: Text("ADDRESS", style: headerStyle)),
        ],
      ),
    );
  }

  /// LIST VIEW
  Widget _list() {
    if (filtered.isEmpty) {
      return const Center(child: Text("No data found"));
    }

    return ListView.builder(
      itemCount: filtered.length,
      itemBuilder: (_, i) => _row(filtered[i]),
    );
  }

  /// EACH ROW
  Widget _row(T item) {
    final DateTime baseDate = widget.dateGetter(item);
    final String baseNumber = widget.numberGetter(item);
    final String baseCustomer = widget.customerGetter(item);
    final double gstAmount = widget.gstGetter(item);
    final double basicAmount = widget.basicGetter(item);
    final double finalAmount = widget.amountGetter(item);
    final String address = widget.addressGetter(item);
    final String baseId = widget.idGetter(item);

    bool selected = activeRow == item;

    return InkWell(
      onDoubleTap: () {
        setState(() => activeRow = selected ? null : item);
      },
      child: Container(
        height: 55,
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 20),
        decoration: BoxDecoration(
          color: AppColor.white,
          border: Border.all(
            color: selected ? AppColor.primary : Colors.grey.shade300,
            width: selected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Expanded(
              flex: 2,
              child: Text(
                DateFormat("dd MMM yyyy").format(baseDate),
                style: rowStyle,
              ),
            ),
            Expanded(flex: 2, child: Text(baseNumber, style: rowStyle)),
            Expanded(flex: 2, child: Text(baseCustomer, style: rowStyle)),
            Expanded(
              flex: 2,
              child: Text(
                "₹${basicAmount.toStringAsFixed(2)}",
                style: GoogleFonts.inter(fontWeight: FontWeight.bold),
              ),
            ),
            Expanded(
              flex: 2,
              child: Text(
                "₹${gstAmount.toStringAsFixed(2)}",
                style: GoogleFonts.inter(fontWeight: FontWeight.bold),
              ),
            ),
            Expanded(
              flex: 2,
              child: Text(
                "₹${finalAmount.toStringAsFixed(2)}",
                style: GoogleFonts.inter(fontWeight: FontWeight.bold),
              ),
            ),
            Expanded(flex: 3, child: Text(address, style: rowStyle)),
            if (selected) ...[
              const SizedBox(width: 10),
              _action(Icons.visibility, Colors.blue, () => widget.onView(item)),
              _action(Icons.edit, Colors.orange, () => widget.onEdit(item)),
              _action(Icons.delete, Colors.red, () async {
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (context) {
                    return AlertDialog(
                      title: const Text("Delete Confirmation"),
                      content: Text(
                        "Are you sure you want to delete this record?",
                        style: GoogleFonts.inter(),
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context, false),
                          child: const Text("Cancel"),
                        ),
                        TextButton(
                          onPressed: () => Navigator.pop(context, true),
                          child: const Text(
                            "Delete",
                            style: TextStyle(color: Colors.red),
                          ),
                        ),
                      ],
                    );
                  },
                );

                if (confirm == true) {
                  bool ok = await widget.onDelete(baseId);
                  if (ok) load();
                }
              }),
            ],
          ],
        ),
      ),
    );
  }

  Widget _action(IconData icon, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(left: 8),
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: color.withOpacity(.1),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Icon(icon, size: 18, color: color),
      ),
    );
  }
}

/// HEADER STYLE
TextStyle headerStyle = GoogleFonts.inter(
  color: AppColor.white,
  fontWeight: FontWeight.w600,
  fontSize: 13,
);

TextStyle rowStyle = GoogleFonts.inter(
  color: AppColor.black,
  fontWeight: FontWeight.w500,
  fontSize: 13,
);
