import 'package:flutter/material.dart';
import 'package:ims/model/cussup_model.dart';
import 'package:ims/ui/report/gst_r1_report/gstr_1_total.dart';
import 'package:ims/ui/sales/models/globalget_model.dart';
import 'package:ims/ui/sales/models/sale_invoice_data.dart';
import 'package:ims/utils/colors.dart';
import 'package:ims/utils/prefence.dart';

class Gstr1B2CSReportScreen extends StatefulWidget {
  final List<SaleInvoiceData> invoices;
  final List<Customer> customers;

  const Gstr1B2CSReportScreen({
    super.key,
    required this.invoices,
    required this.customers,
  });

  @override
  State<Gstr1B2CSReportScreen> createState() => _Gstr1B2CSReportScreenState();
}

class _Gstr1B2CSReportScreenState extends State<Gstr1B2CSReportScreen> {
  List<_B2CSRow> rows = [];

  double totalTaxable = 0;
  double totalCess = 0;

  final String sellerState = Preference.getString(PrefKeys.state);

  @override
  void initState() {
    super.initState();
    buildRows();
  }

  @override
  void didUpdateWidget(covariant Gstr1B2CSReportScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.invoices != widget.invoices ||
        oldWidget.customers != widget.customers) {
      buildRows();
    }
  }

  // ================= FILTER + MAP (B2CS RULES) =================
  void buildRows() {
    rows.clear();
    totalTaxable = 0;
    totalCess = 0;

    final Map<String, _B2CSRow> grouped = {};

    for (final inv in widget.invoices) {
      final customer = widget.customers.firstWhere(
        (c) =>
            c.companyName.trim().toLowerCase() ==
            inv.customerName.trim().toLowerCase(),
        orElse: () => TableStyle.emptyCustomer,
      );

      // -------- B2CS CONDITIONS --------
      final bool isUnregistered =
          customer.gstNo.trim().isEmpty ||
          customer.gstType != "Registered Dealer";

      final bool isSmallInvoice = inv.totalAmount <= 250000;

      if (!(isUnregistered && isSmallInvoice)) continue;

      for (final item in inv.itemDetails) {
        final String pos = inv.placeOfSupply;
        final double gstRate = (item.gstRate).toDouble();

        final String key = "$pos|$gstRate";

        final taxable = _taxableFromGstIncluded(item);

        if (grouped.containsKey(key)) {
          final old = grouped[key]!;
          grouped[key] = old.copyWith(taxableValue: old.taxableValue + taxable);
        } else {
          grouped[key] = _B2CSRow(
            type: "", // no e-commerce
            pos: pos,
            rate: gstRate,
            taxableValue: taxable,
          );
        }
      }
    }

    rows = grouped.values.toList();

    for (final r in rows) {
      totalTaxable += r.taxableValue;
    }

    totalCess = 0;
    setState(() {});
  }

  double _taxableFromGstIncluded(ItemDetail item) {
    final qty = (item.qty).toDouble();
    final priceWithGst = (item.price).toDouble();
    final gst = (item.gstRate).toDouble();

    final gross = qty * priceWithGst;
    if (gst == 0) return gross;
    return gross * 100 / (100 + gst);
  }

  // ================= UI =================
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _summaryBar(),
        SizedBox(child: Expanded(child: _table())),
      ],
    );
  }

  Widget _summaryBar() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      color: const Color(0xffeef1f7),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          TableStyle.globalSum(
            "Total Taxable Value",
            totalTaxable.toStringAsFixed(2),
          ),
          TableStyle.globalSum("Total Cess", totalCess.toStringAsFixed(2)),
        ],
      ),
    );
  }

  Widget _table() {
    return rows.isEmpty
        ? const Center(child: Text("No B2CS Data"))
        : SingleChildScrollView(
            child: SizedBox(
              width: double.infinity,
              child: DataTable(
                border: TableBorder.all(color: AppColor.borderColor),
                headingRowColor: WidgetStateProperty.all(
                  const Color(0xffeef1f7),
                ),
                columns: [
                  TableStyle.label("Type"),
                  TableStyle.label("Place Of Supply"),
                  TableStyle.label("Applicable % of Tax Rate"),
                  TableStyle.label("Rate"),
                  TableStyle.label("Taxable Value"),
                  TableStyle.label("Cess Amount"),
                  TableStyle.label("E-Commerce GSTIN"),
                ],
                rows: rows
                    .map(
                      (e) => DataRow(
                        cells: [
                          TableStyle.labelCell(e.type),
                          TableStyle.labelCell(e.pos),
                          TableStyle.labelCell(""),
                          TableStyle.labelCell("${e.rate}%"),
                          TableStyle.labelCell(
                            e.taxableValue.toStringAsFixed(2),
                          ),
                          TableStyle.labelCell("0"),
                          TableStyle.labelCell(""),
                        ],
                      ),
                    )
                    .toList(),
              ),
            ),
          );
  }
}

// ================= UI ROW MODEL =================
class _B2CSRow {
  final String type;
  final String pos;
  final double rate;
  final double taxableValue;

  _B2CSRow({
    required this.type,
    required this.pos,
    required this.rate,
    required this.taxableValue,
  });

  _B2CSRow copyWith({
    String? type,
    String? pos,
    double? rate,
    double? taxableValue,
  }) {
    return _B2CSRow(
      type: type ?? this.type,
      pos: pos ?? this.pos,
      rate: rate ?? this.rate,
      taxableValue: taxableValue ?? this.taxableValue,
    );
  }
}
