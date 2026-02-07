import 'package:flutter/material.dart';
import 'package:ims/ui/report/gst_r1_report/gstr_1_total.dart';
import 'package:ims/utils/colors.dart';
import 'package:intl/intl.dart';
import 'package:ims/model/cussup_model.dart';
import 'package:ims/ui/sales/models/globalget_model.dart';
import 'package:ims/ui/sales/models/sale_invoice_data.dart';

class Gstr1B2CLReportScreen extends StatefulWidget {
  final List<SaleInvoiceData> invoices;
  final List<Customer> customers;

  const Gstr1B2CLReportScreen({
    super.key,
    required this.invoices,
    required this.customers,
  });

  @override
  State<Gstr1B2CLReportScreen> createState() => _Gstr1B2CLReportScreenState();
}

class _Gstr1B2CLReportScreenState extends State<Gstr1B2CLReportScreen> {
  List<_B2CLRow> rows = [];

  int noOfInvoices = 0;
  double totalInvValue = 0;
  double totalTaxable = 0;
  double totalCess = 0;

  // 🔥 Seller State (dashboard ya pref se bhi le sakta hai)
  final String sellerState = "Rajasthan";

  @override
  void initState() {
    super.initState();
    buildRows();
  }

  @override
  void didUpdateWidget(covariant Gstr1B2CLReportScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.invoices != widget.invoices ||
        oldWidget.customers != widget.customers) {
      buildRows();
    }
  }

  // ================= FILTER + MAP (B2CL RULES) =================
  void buildRows() {
    rows.clear();
    noOfInvoices = 0;
    totalInvValue = 0;
    totalTaxable = 0;
    totalCess = 0;

    for (final inv in widget.invoices) {
      final customer = widget.customers.firstWhere(
        (c) =>
            c.companyName.trim().toLowerCase() ==
            inv.customerName.trim().toLowerCase(),
        orElse: () => TableStyle.emptyCustomer, // 👈 make empty() once
      );

      // ---- B2CL CONDITIONS ----
      final bool isUnregistered =
          customer.gstNo.trim().isEmpty ||
          customer.gstType.trim() != "Registered Dealer";

      final bool isInterState =
          inv.placeOfSupply.trim().toLowerCase() != sellerState.toLowerCase();

      final bool isLargeInvoice = inv.totalAmount > 250000;

      if (!(isUnregistered && isInterState && isLargeInvoice)) continue;

      // ---- Group by HSN + GST rate ----
      final Map<String, _B2CLRow> grouped = {};

      for (final item in inv.itemDetails) {
        final hsn = item.hsn;
        final gstRate = (item.gstRate).toDouble();
        final key = "$hsn|$gstRate";

        final taxable = _taxableFromGstIncluded(item);

        if (grouped.containsKey(key)) {
          final old = grouped[key]!;
          grouped[key] = old.copyWith(taxableValue: old.taxableValue + taxable);
        } else {
          grouped[key] = _B2CLRow(
            invoiceNo: "${inv.prefix}${inv.no}",
            date: DateFormat("dd-MMM-yyyy").format(inv.saleInvoiceDate),
            invoiceValue: inv.totalAmount,
            pos: inv.placeOfSupply,
            rate: gstRate,
            taxableValue: taxable,
          );
        }
      }

      final invoiceRows = grouped.values.toList();
      if (invoiceRows.isNotEmpty) {
        noOfInvoices += 1;
        totalInvValue += inv.totalAmount;

        for (final r in invoiceRows) {
          totalTaxable += r.taxableValue;
        }

        rows.addAll(invoiceRows);
      }
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
        Expanded(child: _table()),
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
          TableStyle.globalSum("No. of Invoices", noOfInvoices.toString()),
          TableStyle.globalSum(
            "Total Inv Value",
            totalInvValue.toStringAsFixed(2),
          ),
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
        ? const Center(child: Text("No B2CL Data"))
        : SizedBox(
            width: double.infinity,
            child: DataTable(
              border: TableBorder.all(color: AppColor.borderColor),
              headingRowColor: WidgetStateProperty.all(const Color(0xffeef1f7)),
              columns: [
                TableStyle.label("Invoice Number"),
                TableStyle.label("Invoice date"),
                TableStyle.label("Invoice Value"),
                TableStyle.label("Place Of Supply"),
                TableStyle.label("Applicable %\nof Tax Rate"),
                TableStyle.label("Rate"),
                TableStyle.label("Taxable Value"),
                TableStyle.label("Cess Amount"),
                TableStyle.label("E-Commerce\nGSTIN"),
              ],
              rows: rows
                  .map(
                    (e) => DataRow(
                      cells: [
                        TableStyle.labelCell(e.invoiceNo),
                        TableStyle.labelCell(e.date),
                        TableStyle.labelCell(e.invoiceValue.toStringAsFixed(2)),
                        TableStyle.labelCell(e.pos),
                        TableStyle.labelCell(""),
                        TableStyle.labelCell("${e.rate}%"),
                        TableStyle.labelCell(e.taxableValue.toStringAsFixed(2)),
                        TableStyle.labelCell("0"),
                        TableStyle.labelCell(""),
                      ],
                    ),
                  )
                  .toList(),
            ),
          );
  }
}

class _B2CLRow {
  final String invoiceNo;
  final String date;
  final double invoiceValue;
  final String pos;
  final double rate;
  final double taxableValue;

  _B2CLRow({
    required this.invoiceNo,
    required this.date,
    required this.invoiceValue,
    required this.pos,
    required this.rate,
    required this.taxableValue,
  });

  _B2CLRow copyWith({
    String? invoiceNo,
    String? date,
    double? invoiceValue,
    String? pos,
    double? rate,
    double? taxableValue,
  }) {
    return _B2CLRow(
      invoiceNo: invoiceNo ?? this.invoiceNo,
      date: date ?? this.date,
      invoiceValue: invoiceValue ?? this.invoiceValue,
      pos: pos ?? this.pos,
      rate: rate ?? this.rate,
      taxableValue: taxableValue ?? this.taxableValue,
    );
  }
}
