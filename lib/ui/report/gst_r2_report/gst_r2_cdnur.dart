import 'package:flutter/material.dart';
import 'package:ims/model/cussup_model.dart';
import 'package:ims/ui/report/gst_r1_report/gstr_1_total.dart';
import 'package:ims/utils/colors.dart';
import 'package:intl/intl.dart';
import 'package:ims/ui/sales/models/purchase_return_data.dart';
import 'package:ims/ui/sales/models/credit_note_data.dart';

// ================= SCREEN =================
class Gstr2CdnurReportScreen extends StatefulWidget {
  final List<PurchaseReturnData> purchaseReturns; // credit note (item return)
  final List<CreditNoteData> creditNotes; // debit note
  final List<Customer> suppliers;

  const Gstr2CdnurReportScreen({
    super.key,
    required this.purchaseReturns,
    required this.creditNotes,
    required this.suppliers,
  });

  @override
  State<Gstr2CdnurReportScreen> createState() => _Gstr2CdnurReportScreenState();
}

class _Gstr2CdnurReportScreenState extends State<Gstr2CdnurReportScreen> {
  List<_CDNURRow> rows = [];

  int noOfSuppliers = 0;
  int noOfNotes = 0;
  double totalNoteValue = 0;
  double totalTaxableValue = 0;
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
  void didUpdateWidget(covariant Gstr2CdnurReportScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.purchaseReturns != widget.purchaseReturns ||
        oldWidget.creditNotes != widget.creditNotes ||
        oldWidget.suppliers != widget.suppliers) {
      buildRows();
    }
  }

  // ================= BUILD =================
  void buildRows() {
    rows.clear();

    final supplierSet = <String>{};
    final noteSet = <String>{};

    noOfSuppliers = 0;
    noOfNotes = 0;
    totalNoteValue = 0;
    totalTaxableValue = 0;
    totalIgst = 0;
    totalCgst = 0;
    totalSgst = 0;
    totalCess = 0;

    // -------- Purchase Return (Credit Note) --------
    for (final pr in widget.purchaseReturns) {
      final supplier = widget.suppliers.firstWhere(
        (s) =>
            s.companyName.trim().toLowerCase() ==
            pr.supplierName.trim().toLowerCase(),
        orElse: () => TableStyle.emptyCustomer,
      );

      // 🔥 ONLY UNREGISTERED
      if (supplier.gstType == "Registered Dealer") continue;

      supplierSet.add(pr.supplierName);
      noteSet.add("${pr.prefix}${pr.no}");

      for (final item in pr.itemDetails) {
        final taxable = _taxable(item.qty, item.price, item.gstRate);
        final gstAmt = taxable * item.gstRate / 100;

        rows.add(
          _CDNURRow(
            supplier: pr.supplierName,
            noteNo: "${pr.prefix}${pr.no}",
            date: DateFormat("dd-MMM-yyyy").format(pr.purchaseReturnDate),
            noteType: "C",
            pos: pr.placeOfSupply,
            rate: item.gstRate,
            taxable: taxable,
            igst: gstAmt, // CDNUR mostly IGST
            cgst: 0,
            sgst: 0,
          ),
        );

        totalTaxableValue += taxable;
        totalIgst += gstAmt;
      }

      totalNoteValue += pr.totalAmount;
    }

    // -------- Purchase Credit Note (Debit Note) --------
    for (final cn in widget.creditNotes) {
      final supplier = widget.suppliers.firstWhere(
        (s) =>
            s.companyName.trim().toLowerCase() ==
            cn.ledgerName.trim().toLowerCase(),
        orElse: () => TableStyle.emptyCustomer,
      );

      // 🔥 ONLY UNREGISTERED
      if (supplier.gstType == "Registered Dealer") continue;

      supplierSet.add(cn.ledgerName);
      noteSet.add("${cn.prefix}${cn.no}");

      for (final item in cn.itemDetails) {
        final taxable = _taxable(item.qty, item.price, item.gstRate);
        final gstAmt = taxable * item.gstRate / 100;

        rows.add(
          _CDNURRow(
            supplier: cn.ledgerName,
            noteNo: "${cn.prefix}${cn.no}",
            date: DateFormat("dd-MMM-yyyy").format(cn.creditNoteDate),
            noteType: "D",
            pos: cn.placeOfSupply,
            rate: item.gstRate,
            taxable: taxable,
            igst: gstAmt,
            cgst: 0,
            sgst: 0,
          ),
        );

        totalTaxableValue += taxable;
        totalIgst += gstAmt;
      }

      totalNoteValue += cn.totalAmount;
    }

    noOfSuppliers = supplierSet.length;
    noOfNotes = noteSet.length;

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
    return rows.isEmpty
        ? const Center(child: Text("No CDNUR Data"))
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
                      TableStyle.globalSum("No. of Suppliers:", "$noOfSuppliers"),
                      TableStyle.globalSum("No. of Notes:", "$noOfNotes"),
                      TableStyle.globalSum("Total Note Value:",
                          totalNoteValue.toStringAsFixed(2)),
                      TableStyle.globalSum("Total Taxable Value:",
                          totalTaxableValue.toStringAsFixed(2)),
                      TableStyle.globalSum("Total IGST:",
                          totalIgst.toStringAsFixed(2)),
                      TableStyle.globalSum("Total Cess:",
                          totalCess.toStringAsFixed(2)),
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
                      TableStyle.label("Note Number"),
                      TableStyle.label("Note Date"),
                      TableStyle.label("Note Type"),
                      TableStyle.label("Place Of Supply"),
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
                            TableStyle.labelCell(e.supplier),
                            TableStyle.labelCell(e.noteNo),
                            TableStyle.labelCell(e.date),
                            TableStyle.labelCell(e.noteType),
                            TableStyle.labelCell(e.pos),
                            TableStyle.labelCell("${e.rate}%"),
                            TableStyle.labelCell(
                                e.taxable.toStringAsFixed(2)),
                            TableStyle.labelCell(e.igst.toStringAsFixed(2)),
                            TableStyle.labelCell("0"),
                            TableStyle.labelCell("0"),
                            TableStyle.labelCell("0"),
                            TableStyle.labelCell("Ineligible"),
                            TableStyle.labelCell("0"),
                            TableStyle.labelCell("0"),
                            TableStyle.labelCell("0"),
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

// ================= ROW MODEL =================
class _CDNURRow {
  final String supplier;
  final String noteNo;
  final String date;
  final String noteType; // C / D
  final String pos;
  final double rate;
  final double taxable;
  final double igst;
  final double cgst;
  final double sgst;

  _CDNURRow({
    required this.supplier,
    required this.noteNo,
    required this.date,
    required this.noteType,
    required this.pos,
    required this.rate,
    required this.taxable,
    required this.igst,
    required this.cgst,
    required this.sgst,
  });
}
