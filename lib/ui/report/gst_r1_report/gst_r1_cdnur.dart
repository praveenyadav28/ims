import 'package:flutter/material.dart';
import 'package:ims/ui/report/gst_r1_report/gstr_1_total.dart';
import 'package:ims/utils/colors.dart';
import 'package:intl/intl.dart';
import 'package:ims/model/cussup_model.dart';
import 'package:ims/ui/sales/models/debitnote_model.dart';
import 'package:ims/ui/sales/models/sale_return_data.dart';

class Gstr1CDNURReportScreen extends StatefulWidget {
  final List<SaleReturnData> saleReturns;
  final List<DebitNoteData> debitNotes;
  final List<Customer> customers;

  const Gstr1CDNURReportScreen({
    super.key,
    required this.saleReturns,
    required this.debitNotes,
    required this.customers,
  });

  @override
  State<Gstr1CDNURReportScreen> createState() => _Gstr1CDNURReportScreenState();
}

class _Gstr1CDNURReportScreenState extends State<Gstr1CDNURReportScreen> {
  List<_CDNRow> rows = [];

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
  void didUpdateWidget(covariant Gstr1CDNURReportScreen oldWidget) {
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

    final recipients = <String>{};

    // -------- Sale Return (Credit Note - Unregistered, >2.5L) --------
    for (final sr in widget.saleReturns) {
      final customer = widget.customers.firstWhere(
        (c) =>
            c.companyName.trim().toLowerCase() ==
            sr.customerName.trim().toLowerCase(),
        orElse: () => TableStyle.emptyCustomer, // 👈 make empty() once
      );

      final bool isUnregistered =
          customer.gstNo.trim().isEmpty ||
          customer.gstType != "Registered Dealer";

      final bool isLargeNote = sr.totalAmount > 250000;

      if (!(isUnregistered && isLargeNote)) continue;

      recipients.add(sr.customerName);

      for (final item in sr.itemDetails) {
        final taxable = _taxableFromGstIncluded(
          qty: item.qty,
          priceWithGst: item.price,
          gst: item.gstRate,
        );

        rows.add(
          _CDNRow(
            gstin: "URP",
            receiver: sr.customerName,
            noteNo: "${sr.prefix}${sr.no}",
            date: DateFormat("dd-MMM-yyyy").format(sr.saleReturnDate),
            noteType: "C",
            pos: sr.placeOfSupply,
            noteValue: sr.totalAmount,
            rate: item.gstRate,
            taxableValue: taxable,
          ),
        );

        totalTaxable += taxable;
      }

      noOfNotes += 1;
      totalNoteValue += sr.totalAmount;
    }

    // -------- Debit Note (Unregistered, >2.5L) --------
    for (final dn in widget.debitNotes) {
      final customer = widget.customers.firstWhere(
        (c) =>
            c.companyName.trim().toLowerCase() ==
            dn.customerName.trim().toLowerCase(),
        orElse: () => TableStyle.emptyCustomer, // 👈 make empty() once
      );

      final bool isUnregistered =
          customer.gstNo.trim().isEmpty ||
          customer.gstType != "Registered Dealer";

      final bool isLargeNote = dn.totalAmount > 250000;

      if (!(isUnregistered && isLargeNote)) continue;

      recipients.add(dn.customerName);

      for (final item in dn.itemDetails) {
        final taxable = _taxableFromGstIncluded(
          qty: item.qty,
          priceWithGst: item.price,
          gst: item.gstRate,
        );

        rows.add(
          _CDNRow(
            gstin: "URP",
            receiver: dn.customerName,
            noteNo: "${dn.prefix}${dn.no}",
            date: DateFormat("dd-MMM-yyyy").format(dn.debitNoteDate),
            noteType: "D",
            pos: dn.placeOfSupply,
            noteValue: dn.totalAmount,
            rate: item.gstRate,
            taxableValue: taxable,
          ),
        );

        totalTaxable += taxable;
      }

      noOfNotes += 1;
      totalNoteValue += dn.totalAmount;
    }

    noOfRecipients = recipients.length;
    totalCess = 0;

    setState(() {});
  }

  double _taxableFromGstIncluded({
    required double qty,
    required double priceWithGst,
    required double gst,
  }) {
    final gross = qty * priceWithGst;
    if (gst == 0) return gross;
    return gross * 100 / (100 + gst);
  }

  // ================= UI =================
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _summary(),
        Expanded(child: _table()),
      ],
    );
  }

  Widget _summary() => Container(
    width: double.infinity,
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
    color: const Color(0xffeef1f7),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        TableStyle.globalSum("Recipients", noOfRecipients.toString()),
        TableStyle.globalSum("Notes", noOfNotes.toString()),
        TableStyle.globalSum(
          "Total Note Value",
          totalNoteValue.toStringAsFixed(2),
        ),
        TableStyle.globalSum("Taxable", totalTaxable.toStringAsFixed(2)),
        TableStyle.globalSum("Cess", totalCess.toStringAsFixed(2)),
      ],
    ),
  );

  Widget _table() => rows.isEmpty
      ? const Center(child: Text("No CDNUR Data"))
      : SizedBox(
          width: double.infinity,
          child: DataTable(
            border: TableBorder.all(color: AppColor.borderColor),
            headingRowColor: WidgetStateProperty.all(Color(0xffeef1f7)),

            columns: [
              TableStyle.label("GSTIN/UIN"),
              TableStyle.label("Receiver"),
              TableStyle.label("Note No"),
              TableStyle.label("Date"),
              TableStyle.label("Type"),
              TableStyle.label("POS"),
              TableStyle.label("Rate"),
              TableStyle.label("Taxable"),
            ],
            rows: rows
                .map(
                  (e) => DataRow(
                    cells: [
                      TableStyle.labelCell(e.gstin),
                      TableStyle.labelCell(e.receiver),
                      TableStyle.labelCell(e.noteNo),
                      TableStyle.labelCell(e.date),
                      TableStyle.labelCell(e.noteType),
                      TableStyle.labelCell(e.pos),
                      TableStyle.labelCell("${e.rate}%"),
                      TableStyle.labelCell(e.taxableValue.toStringAsFixed(2)),
                    ],
                  ),
                )
                .toList(),
          ),
        );
}

class _CDNRow {
  final String gstin;
  final String receiver;
  final String noteNo;
  final String date;
  final String noteType;
  final String pos;
  final double noteValue;
  final double rate;
  final double taxableValue;

  _CDNRow({
    required this.gstin,
    required this.receiver,
    required this.noteNo,
    required this.date,
    required this.noteType,
    required this.pos,
    required this.noteValue,
    required this.rate,
    required this.taxableValue,
  });
}
