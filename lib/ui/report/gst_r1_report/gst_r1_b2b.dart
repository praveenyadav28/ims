import 'package:flutter/material.dart';
import 'package:ims/model/cussup_model.dart';
import 'package:ims/ui/report/gst_r1_report/gstr_1_total.dart';
import 'package:ims/ui/sales/models/globalget_model.dart';
import 'package:ims/utils/colors.dart';
import 'package:intl/intl.dart';
import 'package:ims/ui/sales/models/sale_invoice_data.dart';

// ================= SCREEN =================
class Gstr1B2BReportScreen extends StatefulWidget {
  final List<SaleInvoiceData> invoices;
  final List<Customer> customers;

  const Gstr1B2BReportScreen({
    super.key,
    required this.invoices,
    required this.customers,
  });

  @override
  State<Gstr1B2BReportScreen> createState() => _Gstr1B2BReportScreenState();
}

class _Gstr1B2BReportScreenState extends State<Gstr1B2BReportScreen> {
  List<_B2BRow> rows = [];
  int noOfRecipients = 0;
  int noOfInvoices = 0;
  double totalInvoiceValue = 0;
  double totalTaxableValue = 0;
  double totalCess = 0;
  @override
  void initState() {
    super.initState();
    buildRows();
  }

  @override
  void didUpdateWidget(covariant Gstr1B2BReportScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.invoices != widget.invoices ||
        oldWidget.customers != widget.customers) {
      buildRows();
    }
  }

  // ================= FILTER + MAP (GROUP BY HSN + GST RATE) =================

  void buildRows() {
    rows.clear();

    final recipientSet = <String>{};
    final invoiceSet = <String>{};

    noOfRecipients = 0;
    noOfInvoices = 0;
    totalInvoiceValue = 0;
    totalTaxableValue = 0;
    totalCess = 0;

    for (final inv in widget.invoices) {
      final customer = widget.customers.firstWhere(
        (c) =>
            c.companyName.trim().toLowerCase() ==
            inv.customerName.trim().toLowerCase(),
        orElse: () => TableStyle.emptyCustomer, // 👈 make empty() once
      );

      if (customer.gstType != "Registered Dealer") continue;

      recipientSet.add(customer.gstNo);
      invoiceSet.add("${inv.prefix}${inv.no}");

      final Map<String, _B2BRow> grouped = {};

      for (final item in inv.itemDetails) {
        final hsn = item.hsn;
        final gstRate = (item.gstRate).toDouble();
        final key = "$hsn|$gstRate";

        final taxable = _calculateTaxableValue(item);

        if (grouped.containsKey(key)) {
          final old = grouped[key]!;
          grouped[key] = _B2BRow(
            gstin: old.gstin,
            receiver: old.receiver,
            invoiceNo: old.invoiceNo,
            date: old.date,
            invoiceValue: old.invoiceValue,
            pos: old.pos,
            rate: old.rate,
            taxableValue: old.taxableValue + taxable,
          );
        } else {
          grouped[key] = _B2BRow(
            gstin: customer.gstNo,
            receiver: inv.customerName,
            invoiceNo: "${inv.prefix}${inv.no}",
            date: DateFormat("dd-MMM-yyyy").format(inv.saleInvoiceDate),
            invoiceValue: inv.totalAmount,
            pos: inv.placeOfSupply,
            rate: gstRate,
            taxableValue: taxable,
          );
        }
      }

      rows.addAll(grouped.values);
      totalInvoiceValue += inv.totalAmount;
    }

    noOfRecipients = recipientSet.length;
    noOfInvoices = invoiceSet.length;

    for (final r in rows) {
      totalTaxableValue += r.taxableValue;
    }

    setState(() {});
  }

  double _calculateTaxableValue(ItemDetail item) {
    final gross = item.qty * item.price;
    final gst = item.gstRate.toDouble();
    if (gst == 0) return gross;
    return gross * 100 / (100 + gst);
  }

  // ================= UI =================
  @override
  Widget build(BuildContext context) {
    return rows.isEmpty
        ? const Center(child: Text("No B2B Data"))
        : Column(
            children: [
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
                    TableStyle.globalSum(
                      "No. of Recipients:",
                      noOfRecipients.toString(),
                    ),
                    TableStyle.globalSum(
                      "No. of Invoices:",
                      noOfInvoices.toString(),
                    ),
                    TableStyle.globalSum(
                      "Total Invoice Value:",
                      totalInvoiceValue.toStringAsFixed(2),
                    ),
                    TableStyle.globalSum(
                      "Total Taxable Value:",
                      totalTaxableValue.toStringAsFixed(2),
                    ),
                    TableStyle.globalSum(
                      "Total Cess:",
                      totalCess.toStringAsFixed(2),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: DataTable(
                    border: TableBorder.all(color: AppColor.borderColor),
                    headingRowColor: WidgetStateProperty.all(
                      const Color(0xffeef1f7),
                    ),
                    columns: [
                      TableStyle.label("GSTIN/UIN"),
                      TableStyle.label("Receiver Name"),
                      TableStyle.label("Invoice No"),
                      TableStyle.label("Invoice Date"),
                      TableStyle.label("Invoice Value"),
                      TableStyle.label("Place Of Supply"),
                      TableStyle.label("Reverse Charge"),
                      TableStyle.label("Applicable % of\nTax Rate"),
                      TableStyle.label("Invoice Type"),
                      TableStyle.label("E-Commerce\nGSTIN"),
                      TableStyle.label("Rate"),
                      TableStyle.label("Taxable Value"),
                      TableStyle.label("Cess Amount"),
                    ],
                    rows: rows
                        .map(
                          (e) => DataRow(
                            cells: [
                              TableStyle.labelCell(e.gstin),
                              TableStyle.labelCell(e.receiver),
                              TableStyle.labelCell(e.invoiceNo),
                              TableStyle.labelCell(e.date),
                              TableStyle.labelCell(
                                e.invoiceValue.toStringAsFixed(2),
                              ),
                              TableStyle.labelCell(e.pos),
                              TableStyle.labelCell("N"),
                              TableStyle.labelCell(""),
                              TableStyle.labelCell("Regular B2B"),
                              TableStyle.labelCell(""),
                              TableStyle.labelCell("${e.rate}%"),
                              TableStyle.labelCell(
                                e.taxableValue.toStringAsFixed(2),
                              ),
                              TableStyle.labelCell("0"),
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
}

// ================= UI ROW MODEL =================
class _B2BRow {
  final String gstin;
  final String receiver;
  final String invoiceNo;
  final String date;
  final double invoiceValue;
  final String pos;
  final double rate;
  final double taxableValue;

  _B2BRow({
    required this.gstin,
    required this.receiver,
    required this.invoiceNo,
    required this.date,
    required this.invoiceValue,
    required this.pos,
    required this.rate,
    required this.taxableValue,
  });
}
