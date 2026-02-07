import 'package:flutter/material.dart';
import 'package:ims/ui/report/gst_r1_report/gstr_1_total.dart';
import 'package:ims/ui/sales/models/credit_note_data.dart';
import 'package:ims/ui/sales/models/purcahseinvoice_data.dart';
import 'package:ims/ui/sales/models/purchase_return_data.dart';
import 'package:ims/utils/colors.dart';

class Gstr2DocsReportScreen extends StatefulWidget {
  final List<PurchaseInvoiceData> invoices;
  final List<PurchaseReturnData> purchaseReturns;
  final List<CreditNoteData> creditNotes;

  const Gstr2DocsReportScreen({
    super.key,
    required this.invoices,
    required this.purchaseReturns,
    required this.creditNotes,
  });

  @override
  State<Gstr2DocsReportScreen> createState() => _Gstr2DocsReportScreenState();
}

class _Gstr2DocsReportScreenState extends State<Gstr2DocsReportScreen> {
  List<_DocsRow> rows = [];

  int totalNumber = 0;
  int totalCancelled = 0;

  @override
  void initState() {
    super.initState();
    buildRows();
  }

  @override
  void didUpdateWidget(covariant Gstr2DocsReportScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.invoices != widget.invoices ||
        oldWidget.purchaseReturns != widget.purchaseReturns ||
        oldWidget.creditNotes != widget.creditNotes) {
      buildRows();
    }
  }

  void buildRows() {
    rows.clear();
    totalNumber = 0;
    totalCancelled = 0;

    // ---------------- Purchase Invoices ----------------
    final invs = widget.invoices;
    if (invs.isNotEmpty) {
      final nums = invs.map((e) => e.no).toList()..sort();
      rows.add(
        _DocsRow(
          nature: "Invoices for inward supply",
          from: nums.first,
          to: nums.last,
          total: nums.length,
          cancelled: 0, // cancel flag ho to count yaha add kar sakte ho
        ),
      );
      totalNumber += nums.length;
    } else {
      rows.add(
        _DocsRow(
          nature: "Invoices for inward supply",
          from: 0,
          to: 0,
          total: 0,
          cancelled: 0,
        ),
      );
    }

    // ---------------- Purchase Return ----------------
    final prs = widget.purchaseReturns;
    if (prs.isNotEmpty) {
      final nums = prs.map((e) => e.no).toList()..sort();
      rows.add(
        _DocsRow(
          nature: "Debit Note (Purchase Return)",
          from: nums.first,
          to: nums.last,
          total: nums.length,
          cancelled: 0,
        ),
      );
      totalNumber += nums.length;
    } else {
      rows.add(
        _DocsRow(
          nature: "Debit Note (Purchase Return)",
          from: 0,
          to: 0,
          total: 0,
          cancelled: 0,
        ),
      );
    }

    // ---------------- Credit Notes ----------------
    final cns = widget.creditNotes;
    if (cns.isNotEmpty) {
      final nums = cns.map((e) => e.no).toList()..sort();
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

    setState(() {});
  }

  // ================= UI =================
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // 🔥 SUMMARY BAR
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          color: const Color(0xffeef1f7),
          child: Row(
            children: [
              TableStyle.globalSum("Total Number:", totalNumber.toString()),
              const SizedBox(width: 24),
              TableStyle.globalSum(
                "Total Cancelled:",
                totalCancelled.toString(),
              ),
            ],
          ),
        ),

        // 🔥 TABLE
        Expanded(
          child: SizedBox(
            width: double.infinity,
            child: DataTable(
              border: TableBorder.all(color: AppColor.borderColor),
              headingRowColor: WidgetStateProperty.all(const Color(0xffeef1f7)),
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
          ),
        ),
      ],
    );
  }
}

// ================= ROW MODEL =================
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
