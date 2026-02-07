import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:ims/ui/report/gst_r1_report/gstr_1_total.dart';
import 'package:ims/ui/sales/models/purcahseinvoice_data.dart';
import 'package:ims/utils/colors.dart';

class Gstr2HsnSummaryScreen extends StatefulWidget {
  final List<PurchaseInvoiceData> invoices;
  final String sellerState;

  const Gstr2HsnSummaryScreen({
    super.key,
    required this.invoices,
    required this.sellerState,
  });

  @override
  State<Gstr2HsnSummaryScreen> createState() => _Gstr2HsnSummaryScreenState();
}

class _Gstr2HsnSummaryScreenState extends State<Gstr2HsnSummaryScreen> {
  List<_HsnRow> rows = [];

  int noOfHsn = 0;
  double totalValue = 0;
  double totalTaxable = 0;
  double totalIgst = 0;
  double totalCgst = 0;
  double totalSgst = 0;
  double totalCess = 0;

  @override
  void initState() {
    super.initState();
    buildRows();
  }

  @override
  void didUpdateWidget(covariant Gstr2HsnSummaryScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.invoices != widget.invoices) {
      buildRows();
    }
  }

  void buildRows() {
    rows.clear();

    noOfHsn = 0;
    totalValue = 0;
    totalTaxable = 0;
    totalIgst = 0;
    totalCgst = 0;
    totalSgst = 0;
    totalCess = 0;

    final Map<String, _HsnRow> grouped = {};

    for (final inv in widget.invoices) {
      final bool isInterState =
          inv.placeOfSupply.toLowerCase() != widget.sellerState.toLowerCase();

      for (final item in inv.itemDetails) {
        final hsn = item.hsn;
        final desc = item.name;
        final qty = item.qty.toDouble();
        final priceWithGst = item.price.toDouble();
        final gstRate = item.gstRate.toDouble();

        final gross = qty * priceWithGst;
        final taxable = gstRate == 0 ? gross : gross * 100 / (100 + gstRate);
        final gstAmt = taxable * gstRate / 100;

        double igst = 0, cgst = 0, sgst = 0;

        if (isInterState) {
          igst = gstAmt;
        } else {
          cgst = gstAmt / 2;
          sgst = gstAmt / 2;
        }

        if (grouped.containsKey(hsn)) {
          final old = grouped[hsn]!;
          grouped[hsn] = old.copyWith(
            qty: old.qty + qty,
            totalValue: old.totalValue + gross,
            taxable: old.taxable + taxable,
            igst: old.igst + igst,
            cgst: old.cgst + cgst,
            sgst: old.sgst + sgst,
          );
        } else {
          grouped[hsn] = _HsnRow(
            hsn: hsn,
            desc: desc,
            uqc: "",
            qty: qty,
            totalValue: gross,
            taxable: taxable,
            igst: igst,
            cgst: cgst,
            sgst: sgst,
            cess: 0,
          );
        }
      }
    }

    rows = grouped.values.toList();
    noOfHsn = rows.length;

    for (final r in rows) {
      totalValue += r.totalValue;
      totalTaxable += r.taxable;
      totalIgst += r.igst;
      totalCgst += r.cgst;
      totalSgst += r.sgst;
      totalCess += r.cess;
    }

    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return rows.isEmpty
        ? const Center(child: Text("No HSN Data"))
        : Column(
            children: [
              // 🔥 SUMMARY BAR (exact like your design)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                color: const Color(0xffeef1f7),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _sum("No. of HSN", noOfHsn.toString()),
                    _sum("Total Value", totalValue.toStringAsFixed(2)),
                    _sum(
                      "Total Taxable Value",
                      totalTaxable.toStringAsFixed(2),
                    ),
                    _sum("Total Integrated Tax", totalIgst.toStringAsFixed(2)),
                    _sum("Total Central Tax", totalCgst.toStringAsFixed(2)),
                    _sum("Total State/UT Tax", totalSgst.toStringAsFixed(2)),
                    _sum("Total Cess", totalCess.toStringAsFixed(2)),
                  ],
                ),
              ),

              // 🔥 TABLE
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: DataTable(
                    border: TableBorder.all(color: AppColor.borderColor),
                    headingRowColor: WidgetStateProperty.all(
                      const Color(0xffeef1f7),
                    ),
                    columns: [
                      TableStyle.label("HSN"),
                      TableStyle.label("Description"),
                      TableStyle.label("UQC"),
                      TableStyle.label("Total Quantity"),
                      TableStyle.label("Total Value"),
                      TableStyle.label("Taxable Value"),
                      TableStyle.label("Integrated Tax Amount"),
                      TableStyle.label("Central Tax Amount"),
                      TableStyle.label("State/UT Tax Amount"),
                      TableStyle.label("Cess Amount"),
                    ],
                    rows: rows
                        .map(
                          (e) => DataRow(
                            cells: [
                              TableStyle.labelCell(e.hsn),
                              TableStyle.labelCell(e.desc),
                              TableStyle.labelCell(e.uqc),
                              TableStyle.labelCell(e.qty.toStringAsFixed(2)),
                              TableStyle.labelCell(
                                e.totalValue.toStringAsFixed(2),
                              ),
                              TableStyle.labelCell(
                                e.taxable.toStringAsFixed(2),
                              ),
                              TableStyle.labelCell(e.igst.toStringAsFixed(2)),
                              TableStyle.labelCell(e.cgst.toStringAsFixed(2)),
                              TableStyle.labelCell(e.sgst.toStringAsFixed(2)),
                              TableStyle.labelCell(e.cess.toStringAsFixed(2)),
                            ],
                          ),
                        )
                        .toList(),
                  ),
                ),
              ),
            ],
          );
  }

  Widget _sum(String label, String value) {
    return Column(
      children: [
        Text(
          label,
          style: GoogleFonts.inter(fontSize: 12, color: Colors.black87),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w700),
        ),
      ],
    );
  }
}

// ================= UI ROW MODEL =================
class _HsnRow {
  final String hsn;
  final String desc;
  final String uqc;
  final double qty;
  final double totalValue;
  final double taxable;
  final double igst;
  final double cgst;
  final double sgst;
  final double cess;

  _HsnRow({
    required this.hsn,
    required this.desc,
    required this.uqc,
    required this.qty,
    required this.totalValue,
    required this.taxable,
    required this.igst,
    required this.cgst,
    required this.sgst,
    required this.cess,
  });

  _HsnRow copyWith({
    double? qty,
    double? totalValue,
    double? taxable,
    double? igst,
    double? cgst,
    double? sgst,
    double? cess,
  }) {
    return _HsnRow(
      hsn: hsn,
      desc: desc,
      uqc: uqc,
      qty: qty ?? this.qty,
      totalValue: totalValue ?? this.totalValue,
      taxable: taxable ?? this.taxable,
      igst: igst ?? this.igst,
      cgst: cgst ?? this.cgst,
      sgst: sgst ?? this.sgst,
      cess: cess ?? this.cess,
    );
  }
}
