import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:ims/utils/api.dart';
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
  final String Function(T) mobile;
  final String Function(T) placeOfSupply;

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
    required this.mobile,
    required this.placeOfSupply,
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
  T? expandedRow;

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

  final TextEditingController fromDateCtrl = TextEditingController();
  final TextEditingController toDateCtrl = TextEditingController();
  void _applyFilters() {
    DateTime? from;
    DateTime? to;

    if (fromDateCtrl.text.isNotEmpty) {
      from = DateFormat('dd-MM-yyyy').parse(fromDateCtrl.text);
    }

    if (toDateCtrl.text.isNotEmpty) {
      to = DateFormat('dd-MM-yyyy').parse(toDateCtrl.text);
    }

    filtered = items.where((item) {
      final dt = widget.dateGetter(item);

      bool dateOk = true;

      if (from != null && dt.isBefore(from)) {
        dateOk = false;
      }

      if (to != null && dt.isAfter(to)) {
        dateOk = false;
      }

      final q = searchCtrl.text.toLowerCase();

      bool searchOk =
          widget.customerGetter(item).toLowerCase().contains(q) ||
          widget.numberGetter(item).toLowerCase().contains(q) ||
          widget.mobile(item).toLowerCase().contains(q);

      return dateOk && searchOk;
    }).toList();

    setState(() {});
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
      body: loading ? Center(child: GlowLoader()) : _layout(),
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
        Expanded(
          flex: 2,
          child: Row(
            children: [
              _dateField(
                label: "From Date",
                controller: fromDateCtrl,
                onPick: (d) {
                  setState(() {
                    fromDateCtrl.text = DateFormat('dd-MM-yyyy').format(d);
                  });
                  _applyFilters();
                },
              ),
              const SizedBox(width: 10),
              _dateField(
                label: "To Date",
                controller: toDateCtrl,
                onPick: (d) {
                  setState(() {
                    toDateCtrl.text = DateFormat('dd-MM-yyyy').format(d);
                  });
                  _applyFilters();
                },
              ),
            ],
          ),
        ),

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

  /// TABLE HEADER
  Widget _header() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: AppColor.primary,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(7),
          topRight: Radius.circular(7),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(
              "Date",
              style: headerStyle,
              textAlign: TextAlign.center,
            ),
          ),
          Container(height: 40, width: 2, color: AppColor.borderColor),
          Expanded(
            flex: 2,
            child: Text(
              "Number",
              style: headerStyle,
              textAlign: TextAlign.center,
            ),
          ),
          Container(height: 40, width: 2, color: AppColor.borderColor),
          Expanded(
            flex: 2,
            child: Text(
              "Party",
              style: headerStyle,
              textAlign: TextAlign.center,
            ),
          ),
          Container(height: 40, width: 2, color: AppColor.borderColor),
          Expanded(
            flex: 2,
            child: Text(
              "Mobile",
              style: headerStyle,
              textAlign: TextAlign.center,
            ),
          ),
          Container(height: 40, width: 2, color: AppColor.borderColor),
          Expanded(
            flex: 2,
            child: Text(
              "State",
              style: headerStyle,
              textAlign: TextAlign.center,
            ),
          ),
          Container(height: 40, width: 2, color: AppColor.borderColor),
          Expanded(
            flex: 2,
            child: Text(
              "Basic Value",
              style: headerStyle,
              textAlign: TextAlign.center,
            ),
          ),
          Container(height: 40, width: 2, color: AppColor.borderColor),
          Expanded(
            flex: 2,
            child: Text(
              "GST Value",
              style: headerStyle,
              textAlign: TextAlign.center,
            ),
          ),
          Container(height: 40, width: 2, color: AppColor.borderColor),
          Expanded(
            flex: 2,
            child: Text(
              "Final Value",
              style: headerStyle,
              textAlign: TextAlign.center,
            ),
          ),
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
    final String mobile = widget.mobile(item);
    final String placeOfSupply = widget.placeOfSupply(item);
    final String baseId = widget.idGetter(item);

    bool selected = activeRow == item;
    bool selectedForItem = expandedRow == item;

    return InkWell(
      onDoubleTap: () {
        setState(() => activeRow = selected ? null : item);
      },
      onTap: () {
        setState(() {
          expandedRow = expandedRow == item ? null : item;
        });
      },
      child: Column(
        children: [
          Container(
            height: 55,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            decoration: BoxDecoration(
              color: selectedForItem
                  ? AppColor.green.withValues(alpha: .1)
                  : AppColor.white,
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
                Container(height: 54, width: 2, color: AppColor.borderColor),
                Expanded(
                  flex: 2,
                  child: Text(
                    baseNumber,
                    style: rowStyle,
                    textAlign: TextAlign.center,
                  ),
                ),
                Container(height: 54, width: 2, color: AppColor.borderColor),
                Expanded(
                  flex: 2,
                  child: Text(
                    baseCustomer,
                    style: rowStyle,
                    textAlign: TextAlign.center,
                  ),
                ),
                Container(height: 54, width: 2, color: AppColor.borderColor),
                Expanded(
                  flex: 2,
                  child: Text(
                    mobile,
                    style: rowStyle,
                    textAlign: TextAlign.center,
                  ),
                ),
                Container(height: 54, width: 2, color: AppColor.borderColor),
                Expanded(
                  flex: 2,
                  child: Text(
                    placeOfSupply,
                    style: rowStyle,
                    textAlign: TextAlign.center,
                  ),
                ),
                Container(height: 54, width: 2, color: AppColor.borderColor),
                Expanded(
                  flex: 2,
                  child: Text(
                    "₹${basicAmount.toStringAsFixed(2)}",
                    style: GoogleFonts.inter(fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                ),
                Container(height: 54, width: 2, color: AppColor.borderColor),
                Expanded(
                  flex: 2,
                  child: Text(
                    "₹${gstAmount.toStringAsFixed(2)}",
                    style: GoogleFonts.inter(fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                ),
                Container(height: 54, width: 2, color: AppColor.borderColor),
                Expanded(
                  flex: 2,
                  child: Text(
                    "₹${finalAmount.toStringAsFixed(2)}",
                    style: GoogleFonts.inter(fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                ),
                if (selected) ...[
                  const SizedBox(width: 10),
                  _action(
                    Icons.picture_as_pdf,
                    AppColor.primary,
                    () => widget.onView(item),
                  ),
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

          if (expandedRow == item)
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(12),
              color: AppColor.green.withValues(alpha: .1),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColor.green.withValues(alpha: .1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Row(
                      children: [
                        Expanded(child: Text("  Item", style: _th)),
                        Expanded(child: Text("Item No", style: _th)),
                        Expanded(child: Text("Qty", style: _th)),
                        Expanded(child: Text("Price", style: _th)),
                        Expanded(child: Text("GST Rate", style: _th)),
                        Expanded(child: Text("Discount", style: _th)),
                        Expanded(child: Text("Amount", style: _th)),
                      ],
                    ),
                  ),

                  const SizedBox(height: 6),

                  /// 🔹 TABLE ROWS
                  ...(item as dynamic).itemDetails.map<Widget>((e) {
                    return Container(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      child: Row(
                        children: [
                          // ignore: prefer_interpolation_to_compose_strings
                          Expanded(child: Text("  " + e.name)),
                          Expanded(child: Text(e.itemNo)),
                          Expanded(child: Text(e.qty.toString())),
                          Expanded(child: Text("₹${e.price}")),
                          Expanded(
                            child: Text(
                              "${e.gstRate}% ${e.inclusive ? "In" : "Ex"}",
                            ),
                          ),
                          Expanded(child: Text("${e.discount}%")),
                          Expanded(child: Text("₹${e.amount}")),
                        ],
                      ),
                    );
                  }).toList(),
                ],
              ),
            ),
        ],
      ),
    );
  }

  TextStyle _th = TextStyle(fontWeight: FontWeight.bold, fontSize: 13);

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

  Widget _dateField({
    required String label,
    required TextEditingController controller,
    required Function(DateTime) onPick,
  }) {
    return Expanded(
      child: CommonTextField(
        controller: controller,
        readOnly: true,
        hintText: label,
        suffixIcon: const Icon(Icons.calendar_today, size: 18),
        onTap: () async {
          final picked = await showDatePicker(
            context: context,
            firstDate: DateTime(1990),
            lastDate: DateTime(2100),
            initialDate: DateTime.now(),
          );
          if (picked != null) {
            onPick(picked);
          }
        },
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
