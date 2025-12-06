// estimate_pdf_generator.dart
import 'dart:typed_data';
import 'package:flutter/services.dart' show rootBundle;
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import 'package:ims/ui/sales/estimate/models/estimateget_model.dart';

enum PdfLayoutMode { exact, professional, hybrid }

Future<Uint8List> generateEstimatePdf(
  EstimateData data, {
  PdfLayoutMode mode = PdfLayoutMode.professional,
}) async {
  // ---------------- FONTS (Unicode support) ----------------
  final fontRegular = pw.Font.ttf(
    await rootBundle.load("assets/fonts/Roboto-Regular.ttf"),
  );
  final fontBold = pw.Font.ttf(
    await rootBundle.load("assets/fonts/Roboto-Bold.ttf"),
  );

  final theme = pw.ThemeData.withFont(base: fontRegular, bold: fontBold);

  final pdf = pw.Document(theme: theme);
  final dateFormatter = DateFormat("dd MMM yyyy");

  // ---------------- TEXT STYLES ----------------
  final normal = pw.TextStyle(fontSize: 10);
  final bold = pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold);
  final smallGrey = pw.TextStyle(fontSize: 8, color: PdfColors.grey600);

  // ================================================================
  //                        ITEM TABLE BUILDER
  // ================================================================

  pw.Widget _summaryRow(String title, double value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 2),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(title, style: smallGrey),
          pw.Text("₹${value.toStringAsFixed(2)}", style: smallGrey),
        ],
      ),
    );
  }

  List<List<String>> buildItemTable() {
    List<List<String>> rows = [];

    rows.add([
      "Item / Service",
      "HSN/SAC",
      "QTY",
      "UNIT",
      "PRICE",
      "TAX %",
      "AMOUNT",
    ]);

    for (var i in data.itemDetails) {
      rows.add([
        i.name,
        i.hsn,
        i.qty.toString(),
        i.unit,
        i.price.toStringAsFixed(2),
        i.gstRate.toStringAsFixed(2),
        i.amount.toStringAsFixed(2),
      ]);
    }

    for (var s in data.serviceDetails) {
      rows.add([
        s.name,
        s.hsn,
        s.qty.toString(),
        s.unit,
        s.price.toStringAsFixed(2),
        s.gstRate.toStringAsFixed(2),
        s.amount.toStringAsFixed(2),
      ]);
    }

    return rows;
  }

  // ================================================================
  //                      SUMMARY PANEL
  // ================================================================
  pw.Widget buildSummaryPanel() {
    final totalGST = data.subGst;
    final subtotal = data.subTotal;
    final sgst = totalGST / 2;
    final cgst = totalGST / 2;

    return pw.Container(
      width: 220,
      padding: const pw.EdgeInsets.all(8),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey400),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          _summaryRow("Subtotal", subtotal),
          _summaryRow("Total GST", totalGST),
          _summaryRow("SGST", sgst),
          _summaryRow("CGST", cgst),

          if (data.additionalCharges.isNotEmpty) pw.Divider(),

          ...data.additionalCharges.map((c) => _summaryRow(c.name, c.amount)),

          pw.Divider(),

          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text("Total Amount", style: bold),
              pw.Text(
                "₹${data.totalAmount.toStringAsFixed(2)}",
                style: pw.TextStyle(
                  fontSize: 12,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.green900,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ================================================================
  //                TOP HEADER (Company + Estimate Info)
  // ================================================================
  pw.Widget buildTopHeader() {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Container(
              width: 120,
              height: 48,
              color: PdfColors.grey300,
              child: pw.Center(child: pw.Text("LOGO")),
            ),
            pw.SizedBox(height: 6),
            pw.Text("Business Name", style: bold),
            pw.Text("Address Line 1", style: smallGrey),
            pw.Text("City, State", style: smallGrey),
          ],
        ),

        // Estimate Details
        pw.Container(
          padding: const pw.EdgeInsets.all(8),
          decoration: pw.BoxDecoration(
            border: pw.Border.all(color: PdfColors.grey300),
          ),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                "ESTIMATE",
                style: pw.TextStyle(
                  fontSize: 14,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 6),
              pw.Text("No: ${data.prefix}-${data.no}", style: bold),
              pw.Text(
                "Date: ${dateFormatter.format(data.estimateDate)}",
                style: normal,
              ),
              pw.Text(
                "Valid Till: ${dateFormatter.format(data.estimateDate.add(Duration(days: data.paymentTerms)))}",
                style: normal,
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ================================================================
  //                BILL TO / SHIP TO
  // ================================================================
  pw.Widget buildBillShip() {
    return pw.Row(
      children: [
        pw.Expanded(
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text("Bill To", style: bold),
              pw.SizedBox(height: 4),
              pw.Text(data.customerName, style: normal),
              pw.Text(data.address0, style: smallGrey),
              pw.Text("Mobile: ${data.mobile}", style: smallGrey),
            ],
          ),
        ),
        pw.SizedBox(width: 20),
        pw.Expanded(
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text("Ship To", style: bold),
              pw.SizedBox(height: 4),
              pw.Text(data.customerName, style: normal),
              pw.Text(data.address1, style: smallGrey),
            ],
          ),
        ),
      ],
    );
  }

  // ================================================================
  //             NOTES + TERMS + SIGNATURE SECTION
  // ================================================================
  pw.Widget buildNotesTermsSignature() {
    return pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        // NOTES + TERMS
        pw.Expanded(
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text("Notes", style: bold),
              pw.Text(
                data.notes.isNotEmpty ? data.notes.join("\n") : "-",
                style: smallGrey,
              ),
              pw.SizedBox(height: 10),
              pw.Text("Terms & Conditions", style: bold),
              pw.Text(
                data.terms.isNotEmpty ? data.terms.join("\n") : "-",
                style: smallGrey,
              ),
            ],
          ),
        ),

        pw.SizedBox(width: 12),

        // SIGNATURE
        pw.Column(
          children: [
            pw.Text("Authorized Signatory", style: smallGrey),
            pw.SizedBox(height: 8),
            pw.Container(
              width: 140,
              height: 60,
              decoration: pw.BoxDecoration(
                border: pw.Border.all(color: PdfColors.grey400),
              ),
              child: data.signature.isNotEmpty
                  ? pw.Center(child: pw.Text("Signature Attached"))
                  : null,
            ),
          ],
        ),
      ],
    );
  }

  // ================================================================
  //                   MAIN PAGE CONTENT BUILDER
  // ================================================================
  pw.Widget buildPage() {
    final rows = buildItemTable();

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        buildTopHeader(),
        pw.SizedBox(height: 15),
        buildBillShip(),
        pw.SizedBox(height: 15),

        // Table
        pw.Table.fromTextArray(
          headers: rows.first,
          data: rows.sublist(1),
          cellStyle: normal,
          headerStyle: bold,
          headerDecoration: pw.BoxDecoration(color: PdfColors.grey200),
          border: pw.TableBorder.all(color: PdfColors.grey400),
          cellAlignment: pw.Alignment.centerLeft,
          columnWidths: {
            0: const pw.FlexColumnWidth(3),
            1: const pw.FlexColumnWidth(1.4),
            2: const pw.FlexColumnWidth(1),
            3: const pw.FlexColumnWidth(1.2),
            4: const pw.FlexColumnWidth(1.4),
            5: const pw.FlexColumnWidth(1.2),
            6: const pw.FlexColumnWidth(1.6),
          },
        ),

        pw.SizedBox(height: 15),

        pw.Row(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Expanded(child: buildNotesTermsSignature()),
            pw.SizedBox(width: 20),
            buildSummaryPanel(),
          ],
        ),
      ],
    );
  }

  // ================================================================
  //                  PAGE MODE HANDLER
  // ================================================================
  if (mode == PdfLayoutMode.exact) {
    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4.landscape,
        margin: const pw.EdgeInsets.all(20),
        build: (_) => [buildPage()],
      ),
    );
  } else if (mode == PdfLayoutMode.hybrid) {
    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(14),
        theme: pw.ThemeData(defaultTextStyle: pw.TextStyle(fontSize: 9)),
        build: (_) => [buildPage()],
      ),
    );
  } else {
    // Professional
    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(20),
        build: (_) => [buildPage()],
      ),
    );
  }

  return pdf.save();
}
