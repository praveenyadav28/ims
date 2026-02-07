import 'package:flutter/material.dart';
import 'package:ims/ui/report/gst_r1_report/gstr_1_total.dart';
import 'package:ims/utils/colors.dart';
import 'package:intl/intl.dart';
import 'package:ims/model/cussup_model.dart';
import 'package:ims/ui/sales/models/debitnote_model.dart';
import 'package:ims/ui/sales/models/sale_return_data.dart';

class Gstr1CdnrReportScreen extends StatefulWidget {
  final List<SaleReturnData> saleReturns;
  final List<DebitNoteData> debitNotes;
  final List<Customer> customers;

  const Gstr1CdnrReportScreen({
    super.key,
    required this.saleReturns,
    required this.debitNotes,
    required this.customers,
  });

  @override
  State<Gstr1CdnrReportScreen> createState() => _Gstr1CdnrReportScreenState();
}

class _Gstr1CdnrReportScreenState extends State<Gstr1CdnrReportScreen> {
  List<_CDNRRow> rows = [];

  int noOfRecipients = 0;
  int noOfNotes = 0;
  double totalNoteValue = 0;
  double totalTaxable = 0;
  double totalCess = 0;

  @override
  void initState() {
    super.initState();
    buildRows();
  }

  @override
  void didUpdateWidget(covariant Gstr1CdnrReportScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.saleReturns != widget.saleReturns ||
        oldWidget.debitNotes != widget.debitNotes ||
        oldWidget.customers != widget.customers) {
      buildRows();
    }
  }

  void buildRows() {
    rows.clear();
    noOfRecipients = 0;
    noOfNotes = 0;
    totalNoteValue = 0;
    totalTaxable = 0;
    totalCess = 0;

    final Map<String, bool> uniqueRecipients = {};

    // -------- SALE RETURN = CREDIT NOTE --------
    for (final sr in widget.saleReturns) {
      final customer = widget.customers.firstWhere(
        (c) =>
            c.companyName.trim().toLowerCase() ==
            sr.customerName.trim().toLowerCase(),
        orElse: () => TableStyle.emptyCustomer, // 👈 make empty() once
      );

      if (customer.gstType != "Registered Dealer") continue;

      uniqueRecipients[customer.gstNo] = true;

      for (final item in sr.itemDetails) {
        final taxable = _taxableFromGstIncluded(
          item.price,
          item.qty,
          item.gstRate,
        );

        rows.add(
          _CDNRRow(
            gstin: customer.gstNo,
            receiver: sr.customerName,
            noteNo: "${sr.prefix}${sr.no}",
            noteDate: DateFormat("dd-MMM-yyyy").format(sr.saleReturnDate),
            noteType: "C",
            pos: sr.placeOfSupply,
            reverseCharge: "N",
            noteSupplyType: "Regular",
            noteValue: sr.totalAmount,
            rate: item.gstRate,
            taxableValue: taxable,
          ),
        );

        totalTaxable += taxable;
      }

      totalNoteValue += sr.totalAmount;
      noOfNotes += 1;
    }

    // -------- DEBIT NOTE --------
    for (final dn in widget.debitNotes) {
      final customer = widget.customers.firstWhere(
        (c) =>
            c.companyName.trim().toLowerCase() ==
            dn.customerName.trim().toLowerCase(),
        orElse: () => TableStyle.emptyCustomer, // 👈 make empty() once
      );

      if (customer.gstType != "Registered Dealer") continue;

      uniqueRecipients[customer.gstNo] = true;

      if (dn.itemDetails.isEmpty) {
        rows.add(
          _CDNRRow(
            gstin: customer.gstNo,
            receiver: dn.customerName,
            noteNo: "${dn.prefix}${dn.no}",
            noteDate: DateFormat("dd-MMM-yyyy").format(dn.debitNoteDate),
            noteType: "D",
            pos: dn.placeOfSupply,
            reverseCharge: "N",
            noteSupplyType: "Regular",
            noteValue: dn.totalAmount,
            rate: 0,
            taxableValue: dn.subTotal,
          ),
        );

        totalTaxable += dn.subTotal;
      } else {
        for (final item in dn.itemDetails) {
          final taxable = _taxableFromGstIncluded(
            item.price,
            item.qty,
            item.gstRate,
          );

          rows.add(
            _CDNRRow(
              gstin: customer.gstNo,
              receiver: dn.customerName,
              noteNo: "${dn.prefix}${dn.no}",
              noteDate: DateFormat("dd-MMM-yyyy").format(dn.debitNoteDate),
              noteType: "D",
              pos: dn.placeOfSupply,
              reverseCharge: "N",
              noteSupplyType: "Regular",
              noteValue: dn.totalAmount,
              rate: item.gstRate,
              taxableValue: taxable,
            ),
          );

          totalTaxable += taxable;
        }
      }

      totalNoteValue += dn.totalAmount;
      noOfNotes += 1;
    }

    noOfRecipients = uniqueRecipients.length;
    totalCess = 0;

    setState(() {});
  }

  double _taxableFromGstIncluded(double price, double qty, double gst) {
    final gross = price * qty;
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
          TableStyle.globalSum("No. of Recipients", noOfRecipients.toString()),
          TableStyle.globalSum("No. of Notes", noOfNotes.toString()),
          TableStyle.globalSum(
            "Total Note Value",
            totalNoteValue.toStringAsFixed(2),
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
        ? const Center(child: Text("No CDNR Data"))
        : SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              border: TableBorder.all(color: AppColor.borderColor),
              headingRowColor: WidgetStateProperty.all(Color(0xffeef1f7)),
              columns: [
                TableStyle.label("GSTIN/UIN of Recipient"),
                TableStyle.label("Receiver Name"),
                TableStyle.label("Note Number"),
                TableStyle.label("Note Date"),
                TableStyle.label("Note Type"),
                TableStyle.label("Place Of Supply"),
                TableStyle.label("Reverse Charge"),
                TableStyle.label("Note Supply Type"),
                TableStyle.label("Note Value"),
                TableStyle.label("Applicable % of Tax Rate"),
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
                        TableStyle.labelCell(e.noteNo),
                        TableStyle.labelCell(e.noteDate),
                        TableStyle.labelCell(e.noteType),
                        TableStyle.labelCell(e.pos),
                        TableStyle.labelCell("N"),
                        TableStyle.labelCell("Regular"),
                        TableStyle.labelCell(e.noteValue.toStringAsFixed(2)),
                        TableStyle.labelCell(""),
                        TableStyle.labelCell("${e.rate}%"),
                        TableStyle.labelCell(e.taxableValue.toStringAsFixed(2)),
                        TableStyle.labelCell("0"),
                      ],
                    ),
                  )
                  .toList(),
            ),
          );
  }
}

class _CDNRRow {
  final String gstin;
  final String receiver;
  final String noteNo;
  final String noteDate;
  final String noteType;
  final String pos;
  final String reverseCharge;
  final String noteSupplyType;
  final double noteValue;
  final double rate;
  final double taxableValue;

  _CDNRRow({
    required this.gstin,
    required this.receiver,
    required this.noteNo,
    required this.noteDate,
    required this.noteType,
    required this.pos,
    required this.reverseCharge,
    required this.noteSupplyType,
    required this.noteValue,
    required this.rate,
    required this.taxableValue,
  });
}
