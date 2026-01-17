import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:ims/ui/sales/data/global_repository.dart';
import 'package:ims/ui/sales/models/purcahseinvoice_data.dart';
import 'package:ims/utils/colors.dart';
import 'package:ims/utils/textfield.dart';
import 'package:intl/intl.dart';

class PurchaseInvoiceAdvancedReportScreen extends StatefulWidget {
  const PurchaseInvoiceAdvancedReportScreen({super.key});

  @override
  State<PurchaseInvoiceAdvancedReportScreen> createState() =>
      _PurchaseInvoiceAdvancedReportScreenState();
}

class _PurchaseInvoiceAdvancedReportScreenState
    extends State<PurchaseInvoiceAdvancedReportScreen> {
  final repo = GLobalRepository();

  // ---------------- DATA ----------------
  List<PurchaseInvoiceData> allItems = [];
  List<PurchaseInvoiceData> filtered = [];

  bool loading = true;

  // ---------------- FILTER STATE ----------------
  String supplierFilter = "All";
  String itemFilter = "All";
  String paymentFilter = "All"; // All / Cash / Credit
  bool gstOnly = false;
  bool discountOnly = false;

  double? minAmount;
  double? maxAmount;

  DateTime? fromDate;
  DateTime? toDate;

  final searchCtrl = TextEditingController();

  // ---------------- INIT ----------------
  @override
  void initState() {
    super.initState();
    loadData();
  }

  // ---------------- LOAD ----------------
  Future<void> loadData() async {
    setState(() => loading = true);

    allItems = await repo.getPurchaseInvoice();
    applyFilters();

    setState(() => loading = false);
  }

  // =========================================================
  // ===================== FILTER LOGIC ======================
  // =========================================================

  void applyFilters() {
    List<PurchaseInvoiceData> temp = List.from(allItems);

    // SEARCH (supplier + invoice no)
    final q = searchCtrl.text.toLowerCase();
    if (q.isNotEmpty) {
      temp = temp.where((e) {
        return e.supplierName.toLowerCase().contains(q) ||
            "${e.prefix} ${e.no}".toLowerCase().contains(q);
      }).toList();
    }

    // SUPPLIER
    if (supplierFilter != "All") {
      temp = temp.where((e) => e.supplierName == supplierFilter).toList();
    }

    // ITEM
    if (itemFilter != "All") {
      temp = temp
          .where((e) => e.itemDetails.any((i) => i.name == itemFilter))
          .toList();
    }

    // PAYMENT
    if (paymentFilter == "Cash") {
      temp = temp.where((e) => e.caseSale == true).toList();
    } else if (paymentFilter == "Credit") {
      temp = temp.where((e) => e.caseSale == false).toList();
    }

    // GST ONLY
    if (gstOnly) {
      temp = temp.where((e) => e.subGst > 0).toList();
    }

    // DISCOUNT ONLY
    if (discountOnly) {
      temp = temp.where((e) => e.discountLines.isNotEmpty).toList();
    }

    // AMOUNT RANGE
    if (minAmount != null) {
      temp = temp.where((e) => e.totalAmount >= minAmount!).toList();
    }
    if (maxAmount != null) {
      temp = temp.where((e) => e.totalAmount <= maxAmount!).toList();
    }

    // DATE RANGE
    if (fromDate != null) {
      temp = temp
          .where(
            (e) =>
                e.purchaseInvoiceDate.isAfter(fromDate!) ||
                e.purchaseInvoiceDate.isAtSameMomentAs(fromDate!),
          )
          .toList();
    }
    if (toDate != null) {
      temp = temp
          .where(
            (e) =>
                e.purchaseInvoiceDate.isBefore(toDate!) ||
                e.purchaseInvoiceDate.isAtSameMomentAs(toDate!),
          )
          .toList();
    }

    filtered = temp;
    setState(() {});
  }

  void clearFilters() {
    supplierFilter = "All";
    itemFilter = "All";
    paymentFilter = "All";
    gstOnly = false;
    discountOnly = false;
    minAmount = null;
    maxAmount = null;
    fromDate = null;
    toDate = null;
    searchCtrl.clear();
    applyFilters();
  }

  // =========================================================
  // =========================== UI ==========================
  // =========================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Purchase Invoice Report",
          style: GoogleFonts.inter(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: AppColor.white,
          ),
        ),
        backgroundColor: AppColor.black,
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

  // =========================================================
  // ======================== FILTER BAR =====================
  // =========================================================

  Widget _filterBar() {
    return Container(
      padding: const EdgeInsets.all(12),
      margin: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xffF9FAFB),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Wrap(
        spacing: 12,
        runSpacing: 12,
        children: [
          _textField("Search...", "Search supplier / invoice", searchCtrl, () {
            applyFilters();
          }),

          _dropdown("Supplier", supplierFilter, _suppliers(), (v) {
            supplierFilter = v!;
            applyFilters();
          }),

          _dropdown("Item", itemFilter, _items(), (v) {
            itemFilter = v!;
            applyFilters();
          }),

          _dropdown("Payment", paymentFilter, const ["All", "Cash", "Credit"], (
            v,
          ) {
            paymentFilter = v!;
            applyFilters();
          }),

          _amountField("0", "Min ₹", (v) {
            minAmount = double.tryParse(v);
            applyFilters();
          }),
          _amountField("0", "Max ₹", (v) {
            maxAmount = double.tryParse(v);
            applyFilters();
          }),

          _dateBtn("From", fromDate, (d) {
            fromDate = d;
            applyFilters();
          }),
          _dateBtn("To", toDate, (d) {
            toDate = d;
            applyFilters();
          }),

          _check("GST Only", gstOnly, (v) {
            gstOnly = v;
            applyFilters();
          }),
          _check("With Discount", discountOnly, (v) {
            discountOnly = v;
            applyFilters();
          }),

          TextButton(onPressed: clearFilters, child: const Text("Clear")),
        ],
      ),
    );
  }

  // =========================================================
  // ======================== SUMMARY ========================
  // =========================================================

  Widget _summaryBar() {
    final totalInvoices = filtered.length;
    final totalAmount = filtered.fold<double>(0, (p, e) => p + e.totalAmount);
    final cashCount = filtered.where((e) => e.caseSale == true).length;
    final creditCount = filtered.where((e) => e.caseSale == false).length;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        children: [
          _summaryCard("Invoices", totalInvoices.toString()),
          _summaryCard("Total Amount", "₹ ${totalAmount.toStringAsFixed(2)}"),
          _summaryCard("Cash", cashCount.toString()),
          _summaryCard("Credit", creditCount.toString()),
        ],
      ),
    );
  }

  Widget _summaryCard(String title, String value) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.only(right: 10, bottom: 8),
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

  // =========================================================
  // ========================== TABLE ========================
  // =========================================================

  Widget _table() {
    if (filtered.isEmpty) {
      return const Center(child: Text("No data found"));
    }

    return ListView(
      padding: const EdgeInsets.all(12),
      children: [_tableHeader(), ...filtered.map(_row).toList()],
    );
  }

  Widget _tableHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
      decoration: const BoxDecoration(
        color: Color(0xff111827),
        borderRadius: BorderRadius.vertical(top: Radius.circular(8)),
      ),
      child: Row(
        children: [
          _h("Date", 2),
          _h("Number", 2),
          _h("Supplier", 3),
          _h("Amount", 2),
          _h("Payment", 2),
          _h("Items", 3),
        ],
      ),
    );
  }

  Widget _h(String t, int f) {
    return Expanded(
      flex: f,
      child: Text(
        t,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w600,
          fontSize: 13,
        ),
      ),
    );
  }

  Widget _row(PurchaseInvoiceData e) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: Colors.grey.shade300)),
      ),
      child: Row(
        children: [
          _c(DateFormat("dd MMM yyyy").format(e.purchaseInvoiceDate), 2),
          _c("${e.prefix} ${e.no}", 2),
          _c(e.supplierName, 3),
          _c("₹${e.totalAmount.toStringAsFixed(2)}", 2, bold: true),
          _c(e.caseSale ? "Cash" : "Credit", 2),
          _c(e.itemDetails.map((i) => i.name).join(", "), 3),
        ],
      ),
    );
  }

  Widget _c(String t, int f, {bool bold = false}) {
    return Expanded(
      flex: f,
      child: Text(
        t,
        style: GoogleFonts.inter(
          fontSize: 13,
          fontWeight: bold ? FontWeight.w600 : FontWeight.w500,
        ),
        overflow: TextOverflow.ellipsis,
      ),
    );
  }

  // =========================================================
  // ======================== HELPERS ========================
  // =========================================================

  List<String> _suppliers() => [
    "All",
    ...{for (var e in allItems) e.supplierName},
  ];

  List<String> _items() => [
    "All",
    ...{
      for (var e in allItems)
        for (var i in e.itemDetails) i.name,
    },
  ];

  // =========================================================
  // ===================== SMALL WIDGETS =====================
  // =========================================================

  Widget _dropdown(
    String label,
    String value,
    List<String> items,
    Function(String?) onChanged,
  ) {
    return SizedBox(
      width: 200,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: AppColor.textColor,
            ),
          ),
          const SizedBox(height: 8),
          CommonDropdownField<String>(
            value: value,
            items: items
                .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                .toList(),
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }

  Widget _amountField(String hint, String title, Function(String) onChange) {
    return SizedBox(
      width: 120,
      child: TitleTextFeild(
        keyboardType: TextInputType.number,
        hintText: hint,
        titleText: title,

        onChanged: onChange,
      ),
    );
  }

  Widget _textField(
    String hint,
    String title,
    TextEditingController ctrl,
    VoidCallback onChange,
  ) {
    return SizedBox(
      width: 260,
      child: TitleTextFeild(
        controller: ctrl,
        hintText: hint,
        titleText: title,
        onChanged: (_) => onChange(),
      ),
    );
  }

  Widget _check(String label, bool value, Function(bool) onChanged) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Checkbox(value: value, onChanged: (v) => onChanged(v ?? false)),
        Text(label),
      ],
    );
  }

  Widget _dateBtn(String label, DateTime? date, Function(DateTime) onPick) {
    return OutlinedButton(
      onPressed: () async {
        final picked = await showDatePicker(
          context: context,
          firstDate: DateTime(2020),
          lastDate: DateTime.now(),
          initialDate: date ?? DateTime.now(),
        );
        if (picked != null) onPick(picked);
      },
      child: Text(
        date == null ? label : DateFormat("dd MMM yyyy").format(date),
      ),
    );
  }
}
