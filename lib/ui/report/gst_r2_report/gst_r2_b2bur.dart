import 'package:flutter/material.dart';
import 'package:ims/model/cussup_model.dart';
import 'package:ims/ui/report/gst_r1_report/gstr_1_total.dart';
import 'package:ims/ui/sales/models/purcahseinvoice_data.dart';
import 'package:ims/utils/colors.dart';
import 'package:intl/intl.dart';

class Gstr2B2BURReportScreen extends StatefulWidget {
  final List<PurchaseInvoiceData> invoices;
  final List<Customer> suppliers;

  const Gstr2B2BURReportScreen({
    super.key,
    required this.invoices,
    required this.suppliers,
  });

  @override
  State<Gstr2B2BURReportScreen> createState() => _Gstr2B2BURReportScreenState();
}

class _Gstr2B2BURReportScreenState extends State<Gstr2B2BURReportScreen> {
  List<_B2BURRow> rows = [];

  int noOfInvoices = 0;
  double totalInvoiceValue = 0;
  double totalTaxableValue = 0;

  double totalIgst = 0;
  double totalCgst = 0;
  double totalSgst = 0;
  double totalCess = 0;

  double totalItcIgst = 0;
  double totalItcCgst = 0;
  double totalItcSgst = 0;
  double totalItcCess = 0;

  @override
  void initState() {
    super.initState();
    buildRows();
  }

  @override
  void didUpdateWidget(covariant Gstr2B2BURReportScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.invoices != widget.invoices ||
        oldWidget.suppliers != widget.suppliers) {
      buildRows();
    }
  }

  void buildRows() {
    rows.clear();

    noOfInvoices = 0;
    totalInvoiceValue = 0;
    totalTaxableValue = 0;

    totalIgst = 0;
    totalCgst = 0;
    totalSgst = 0;
    totalCess = 0;

    totalItcIgst = 0;
    totalItcCgst = 0;
    totalItcSgst = 0;
    totalItcCess = 0;

    final invoiceSet = <String>{};

    for (final inv in widget.invoices) {
      final supplier = widget.suppliers.firstWhere(
        (c) =>
            c.companyName.trim().toLowerCase() ==
            inv.supplierName.trim().toLowerCase(),
        orElse: () => TableStyle.emptyCustomer,
      );

      // 🔥 B2BUR = Unregistered Supplier
      final bool isUnregistered =
          supplier.gstNo.isEmpty || supplier.gstType != "Registered Dealer";

      if (!isUnregistered) continue;

      invoiceSet.add("${inv.prefix}${inv.no}");

      for (final item in inv.itemDetails) {
        final taxable = _taxable(item.qty, item.price, item.gstRate);
        final gstAmt = taxable * item.gstRate / 100;

        final bool isInter =
            inv.placeOfSupply.toLowerCase() != supplier.state.toLowerCase();

        double igst = 0, cgst = 0, sgst = 0;

        if (isInter) {
          igst = gstAmt;
        } else {
          cgst = gstAmt / 2;
          sgst = gstAmt / 2;
        }

        rows.add(
          _B2BURRow(
            supplierName: inv.supplierName,
            invoiceNo: "${inv.prefix}${inv.no}",
            date: DateFormat("dd-MMM-yyyy").format(inv.purchaseInvoiceDate),
            invoiceValue: inv.totalAmount,
            pos: inv.placeOfSupply,
            supplyType: isInter ? "Inter-State" : "Intra-State",
            rate: item.gstRate,
            taxableValue: taxable,
            igst: igst,
            cgst: cgst,
            sgst: sgst,
          ),
        );

        totalTaxableValue += taxable;
        totalIgst += igst;
        totalCgst += cgst;
        totalSgst += sgst;

        totalItcIgst += igst;
        totalItcCgst += cgst;
        totalItcSgst += sgst;
      }

      totalInvoiceValue += inv.totalAmount;
    }

    noOfInvoices = invoiceSet.length;

    setState(() {});
  }

  double _taxable(double qty, double price, double gst) {
    final gross = qty * price;
    if (gst == 0) return gross;
    return gross * 100 / (100 + gst);
  }

  @override
  Widget build(BuildContext context) {
    return rows.isEmpty
        ? const Center(child: Text("No B2BUR Data"))
        : Column(
            children: [
              Container(
                width: double.infinity,
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                color: const Color(0xffeef1f7),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
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
                        "Total IGST:",
                        totalIgst.toStringAsFixed(2),
                      ),
                      TableStyle.globalSum(
                        "Total CGST:",
                        totalCgst.toStringAsFixed(2),
                      ),
                      TableStyle.globalSum(
                        "Total SGST:",
                        totalSgst.toStringAsFixed(2),
                      ),
                      TableStyle.globalSum(
                        "Total ITC IGST:",
                        totalItcIgst.toStringAsFixed(2),
                      ),
                      TableStyle.globalSum(
                        "Total ITC CGST:",
                        totalItcCgst.toStringAsFixed(2),
                      ),
                      TableStyle.globalSum(
                        "Total ITC SGST:",
                        totalItcSgst.toStringAsFixed(2),
                      ),
                    ],
                  ),
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: DataTable(
                    border: TableBorder.all(color: AppColor.borderColor),
                    headingRowColor:
                        WidgetStateProperty.all(const Color(0xffeef1f7)),
                    columns: [
                      TableStyle.label("Supplier Name"),
                      TableStyle.label("Invoice Number"),
                      TableStyle.label("Invoice Date"),
                      TableStyle.label("Invoice Value"),
                      TableStyle.label("Place Of Supply"),
                      TableStyle.label("Supply Type"),
                      TableStyle.label("Rate"),
                      TableStyle.label("Taxable Value"),
                      TableStyle.label("Integrated Tax Paid"),
                      TableStyle.label("Central Tax Paid"),
                      TableStyle.label("State/UT Tax Paid"),
                      TableStyle.label("Cess Paid"),
                      TableStyle.label("Eligibility For ITC"),
                      TableStyle.label("Availed ITC IGST"),
                      TableStyle.label("Availed ITC CGST"),
                      TableStyle.label("Availed ITC SGST"),
                      TableStyle.label("Availed ITC Cess"),
                    ],
                    rows: rows
                        .map(
                          (e) => DataRow(cells: [
                            TableStyle.labelCell(e.supplierName),
                            TableStyle.labelCell(e.invoiceNo),
                            TableStyle.labelCell(e.date),
                            TableStyle.labelCell(
                                e.invoiceValue.toStringAsFixed(2)),
                            TableStyle.labelCell(e.pos),
                            TableStyle.labelCell(e.supplyType),
                            TableStyle.labelCell("${e.rate}%"),
                            TableStyle.labelCell(
                                e.taxableValue.toStringAsFixed(2)),
                            TableStyle.labelCell(e.igst.toStringAsFixed(2)),
                            TableStyle.labelCell(e.cgst.toStringAsFixed(2)),
                            TableStyle.labelCell(e.sgst.toStringAsFixed(2)),
                            TableStyle.labelCell("0"),
                            TableStyle.labelCell("Eligible"),
                            TableStyle.labelCell(e.igst.toStringAsFixed(2)),
                            TableStyle.labelCell(e.cgst.toStringAsFixed(2)),
                            TableStyle.labelCell(e.sgst.toStringAsFixed(2)),
                            TableStyle.labelCell("0"),
                          ]),
                        )
                        .toList(),
                  ),
                ),
              ),
            ],
          );
  }
}

class _B2BURRow {
  final String supplierName;
  final String invoiceNo;
  final String date;
  final double invoiceValue;
  final String pos;
  final String supplyType;
  final double rate;
  final double taxableValue;
  final double igst;
  final double cgst;
  final double sgst;

  _B2BURRow({
    required this.supplierName,
    required this.invoiceNo,
    required this.date,
    required this.invoiceValue,
    required this.pos,
    required this.supplyType,
    required this.rate,
    required this.taxableValue,
    required this.igst,
    required this.cgst,
    required this.sgst,
  });
}
