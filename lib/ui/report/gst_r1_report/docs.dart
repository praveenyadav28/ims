import 'package:flutter/material.dart';
import 'package:ims/ui/report/gst_r1_report/gstr_1_total.dart';
import 'package:ims/ui/sales/models/debitnote_model.dart';
import 'package:ims/ui/sales/models/sale_invoice_data.dart';
import 'package:ims/ui/sales/models/sale_return_data.dart';
import 'package:ims/utils/colors.dart';

class Gstr1DocsReportScreen extends StatefulWidget {
  final List<SaleInvoiceData> invoices;
  final List<SaleReturnData> saleReturns;
  final List<DebitNoteData> debitNotes;

  const Gstr1DocsReportScreen({
    super.key,
    required this.invoices,
    required this.saleReturns,
    required this.debitNotes,
  });

  @override
  State<Gstr1DocsReportScreen> createState() => _Gstr1DocsReportScreenState();
}

class _Gstr1DocsReportScreenState extends State<Gstr1DocsReportScreen> {
  List<_DocsRow> rows = [];

  int totalNumber = 0;
  int totalCancelled = 0;

  @override
  void initState() {
    super.initState();
    buildRows();
  }

  @override
  void didUpdateWidget(covariant Gstr1DocsReportScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.invoices != widget.invoices ||
        oldWidget.saleReturns != widget.saleReturns ||
        oldWidget.debitNotes != widget.debitNotes) {
      buildRows();
    }
  }

  void buildRows() {
    rows.clear();
    totalNumber = 0;
    totalCancelled = 0;

    // ---- Invoices for outward supply ----
    final invs = widget.invoices;
    if (invs.isNotEmpty) {
      final nums = invs.map((e) => e.no).toList()..sort();
      rows.add(
        _DocsRow(
          nature: "Invoices for outward supply",
          from: nums.first,
          to: nums.last,
          total: nums.length,
          cancelled: 0, // agar cancel flag ho to yahan count
        ),
      );
      totalNumber += nums.length;
    } else {
      rows.add(
        _DocsRow(
          nature: "Invoices for outward supply",
          from: 0,
          to: 0,
          total: 0,
          cancelled: 0,
        ),
      );
    }

    // ---- Credit Notes (Sale Return) ----
    final crs = widget.saleReturns;
    if (crs.isNotEmpty) {
      final nums = crs.map((e) => e.no).toList()..sort();
      rows.add(
        _DocsRow(
          nature: "Credit Note",
          from: nums.first,
          to: nums.last,
          total: nums.length,
          cancelled: 0,
        ),
      );
      totalNumber += nums.length;
    } else {
      rows.add(
        _DocsRow(nature: "Credit Note", from: 0, to: 0, total: 0, cancelled: 0),
      );
    }

    // ---- Debit Notes ----
    final dns = widget.debitNotes;
    if (dns.isNotEmpty) {
      final nums = dns.map((e) => e.no).toList()..sort();
      rows.add(
        _DocsRow(
          nature: "Debit Note",
          from: nums.first,
          to: nums.last,
          total: nums.length,
          cancelled: 0,
        ),
      );
      totalNumber += nums.length;
    } else {
      rows.add(
        _DocsRow(nature: "Debit Note", from: 0, to: 0, total: 0, cancelled: 0),
      );
    }

    setState(() {});
  }

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
        TableStyle.globalSum("Total Number:", "$totalNumber"),
        TableStyle.globalSum("Total Cancelled:", "$totalCancelled"),
      ],
    ),
  );

  Widget _table() => SizedBox(
    width: double.infinity,
    child: DataTable(
      border: TableBorder.all(color: AppColor.borderColor),
      headingRowColor: WidgetStateProperty.all(Color(0xffeef1f7)),
      columns: [
        TableStyle.label("Nature of Document"),
        TableStyle.label("Sr. No. From"),
        TableStyle.label("Sr. No. To"),
        TableStyle.label("Total Number"),
        TableStyle.label("Cancelled"),
      ],
      rows: rows
          .map(
            (e) => DataRow(
              cells: [
                TableStyle.labelCell(e.nature),
                TableStyle.labelCell(e.from.toString()),
                TableStyle.labelCell(e.to.toString()),
                TableStyle.labelCell(e.total.toString()),
                TableStyle.labelCell(e.cancelled.toString()),
              ],
            ),
          )
          .toList(),
    ),
  );
}

// ================= UI ROW MODEL =================
class _DocsRow {
  final String nature;
  final int from;
  final int to;
  final int total;
  final int cancelled;

  _DocsRow({
    required this.nature,
    required this.from,
    required this.to,
    required this.total,
    required this.cancelled,
  });
}
