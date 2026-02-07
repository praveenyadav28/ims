import 'package:flutter/material.dart';
import 'package:ims/ui/report/gst_r1_report/gstr_1_total.dart';
import 'package:ims/ui/sales/models/credit_note_data.dart';
import 'package:ims/ui/sales/models/purcahseinvoice_data.dart';
import 'package:ims/ui/sales/models/purchase_return_data.dart';
import 'package:ims/utils/colors.dart';

class Gstr2ItcSummaryScreen extends StatefulWidget {
  final List<PurchaseInvoiceData> invoices;
  final List<PurchaseReturnData> purchaseReturns;
  final List<CreditNoteData> creditNotes;
  final String sellerState;

  const Gstr2ItcSummaryScreen({
    super.key,
    required this.invoices,
    required this.purchaseReturns,
    required this.creditNotes,
    required this.sellerState,
  });

  @override
  State<Gstr2ItcSummaryScreen> createState() => _Gstr2ItcSummaryScreenState();
}

class _Gstr2ItcSummaryScreenState extends State<Gstr2ItcSummaryScreen> {
  List<_ItcRow> rows = [];

  double totalIgst = 0;
  double totalCgst = 0;
  double totalSgst = 0;
  double totalCess = 0;

  double totalEligibleIgst = 0;
  double totalEligibleCgst = 0;
  double totalEligibleSgst = 0;
  double totalEligibleCess = 0;

  @override
  void initState() {
    super.initState();
    buildRows();
  }

  @override
  void didUpdateWidget(covariant Gstr2ItcSummaryScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.invoices != widget.invoices ||
        oldWidget.purchaseReturns != widget.purchaseReturns ||
        oldWidget.creditNotes != widget.creditNotes) {
      buildRows();
    }
  }

  void buildRows() {
    rows.clear();

    totalIgst = 0;
    totalCgst = 0;
    totalSgst = 0;
    totalCess = 0;

    totalEligibleIgst = 0;
    totalEligibleCgst = 0;
    totalEligibleSgst = 0;
    totalEligibleCess = 0;

    void addTax({
      required bool isInterState,
      required double taxable,
      required double gstRate,
      required bool eligible,
    }) {
      final gstAmt = taxable * gstRate / 100;

      if (isInterState) {
        totalIgst += gstAmt;
        if (eligible) totalEligibleIgst += gstAmt;
      } else {
        totalCgst += gstAmt / 2;
        totalSgst += gstAmt / 2;
        if (eligible) {
          totalEligibleCgst += gstAmt / 2;
          totalEligibleSgst += gstAmt / 2;
        }
      }
    }

    // ---------------- PURCHASE INVOICE (ADD ITC) ----------------
    for (final inv in widget.invoices) {
      final bool isInterState =
          inv.placeOfSupply.toLowerCase() != widget.sellerState.toLowerCase();

      for (final item in inv.itemDetails) {
        final taxable = _taxable(item.qty, item.price, item.gstRate);
        addTax(
          isInterState: isInterState,
          taxable: taxable,
          gstRate: item.gstRate.toDouble(),
          eligible: true, // 🔥 maan rahe eligible ITC hai
        );
      }
    }

    // ---------------- PURCHASE RETURN (REVERSE ITC) ----------------
    for (final pr in widget.purchaseReturns) {
      final bool isInterState =
          pr.placeOfSupply.toLowerCase() != widget.sellerState.toLowerCase();

      for (final item in pr.itemDetails) {
        final taxable = _taxable(item.qty, item.price, item.gstRate);
        addTax(
          isInterState: isInterState,
          taxable: -taxable,
          gstRate: item.gstRate.toDouble(),
          eligible: true,
        );
      }
    }

    // ---------------- CREDIT NOTE (REVERSE ITC) ----------------
    for (final cn in widget.creditNotes) {
      final bool isInterState =
          cn.placeOfSupply.toLowerCase() != widget.sellerState.toLowerCase();

      for (final item in cn.itemDetails) {
        final taxable = _taxable(item.qty, item.price, item.gstRate);
        addTax(
          isInterState: isInterState,
          taxable: -taxable,
          gstRate: item.gstRate.toDouble(),
          eligible: true,
        );
      }
    }

    rows.addAll([
      _ItcRow("Integrated Tax (IGST)", totalIgst, totalEligibleIgst),
      _ItcRow("Central Tax (CGST)", totalCgst, totalEligibleCgst),
      _ItcRow("State/UT Tax (SGST)", totalSgst, totalEligibleSgst),
      _ItcRow("Cess", totalCess, totalEligibleCess),
    ]);

    setState(() {});
  }

  double _taxable(double qty, double price, double gst) {
    final gross = qty * price;
    if (gst == 0) return gross;
    return gross * 100 / (100 + gst);
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
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              TableStyle.globalSum("Total IGST:", totalIgst.toStringAsFixed(2)),
              TableStyle.globalSum("Total CGST:", totalCgst.toStringAsFixed(2)),
              TableStyle.globalSum("Total SGST:", totalSgst.toStringAsFixed(2)),
              TableStyle.globalSum("Total Cess:", totalCess.toStringAsFixed(2)),
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
                TableStyle.label("Type of ITC"),
                TableStyle.label("ITC Available"),
                TableStyle.label("ITC Availed"),
              ],
              rows: rows
                  .map(
                    (e) => DataRow(
                      cells: [
                        TableStyle.labelCell(e.type),
                        TableStyle.labelCell(e.available.toStringAsFixed(2)),
                        TableStyle.labelCell(e.availed.toStringAsFixed(2)),
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
class _ItcRow {
  final String type;
  final double available;
  final double availed;

  _ItcRow(this.type, this.available, this.availed);
}
