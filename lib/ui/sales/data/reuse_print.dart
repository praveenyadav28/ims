// import 'package:ims/ui/sales/models/print_model.dart';
// import 'package:pdf/widgets.dart' as pw;
// import 'package:pdf/pdf.dart';
// import 'package:printing/printing.dart';
// import 'package:intl/intl.dart';

// class PdfEngine {
//   static Future<void> printPremiumInvoice({
//     required PrintDocModel doc,
//     required CompanyPrintProfile company,
//   }) async {
//     final pdf = pw.Document();

//     pdf.addPage(
//       pw.MultiPage(
//         pageFormat: PdfPageFormat.a4,
//         margin: const pw.EdgeInsets.all(24),
//         build: (_) => [
//           _premiumHeader(company, doc),
//           pw.SizedBox(height: 16),
//           _buyerCard(doc),
//           pw.SizedBox(height: 16),
//           _premiumItemsTable(doc),
//           pw.SizedBox(height: 16),
//           _summaryCard(doc),
//           pw.SizedBox(height: 16),
//           _notesAndTerms(doc),
//           pw.SizedBox(height: 24),
//           _premiumFooter(company),
//         ],
//       ),
//     );

//     final bytes = await pdf.save();

//     try {
//       await Printing.layoutPdf(onLayout: (_) async => bytes);
//     } catch (_) {
//       // Desktop / Web fallback
//     }
//   }

//   // ================= HEADER =================
//   static pw.Widget _premiumHeader(CompanyPrintProfile c, PrintDocModel d) {
//     return pw.Container(
//       padding: const pw.EdgeInsets.all(16),
//       decoration: pw.BoxDecoration(
//         borderRadius: pw.BorderRadius.circular(10),
//         color: PdfColors.grey100,
//       ),
//       child: pw.Row(
//         mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
//         children: [
//           pw.Column(
//             crossAxisAlignment: pw.CrossAxisAlignment.start,
//             children: [
//               pw.Text(
//                 c.name,
//                 style: pw.TextStyle(
//                   fontSize: 18,
//                   fontWeight: pw.FontWeight.bold,
//                 ),
//               ),
//               pw.Text(c.address),
//               pw.Text("GST: ${c.gst}"),
//               pw.Text("Phone: ${c.phone}"),
//             ],
//           ),
//           pw.Container(
//             padding: const pw.EdgeInsets.all(12),
//             decoration: pw.BoxDecoration(
//               borderRadius: pw.BorderRadius.circular(8),
//               color: PdfColors.white,
//               border: pw.Border.all(color: PdfColors.grey400),
//             ),
//             child: pw.Column(
//               crossAxisAlignment: pw.CrossAxisAlignment.end,
//               children: [
//                 pw.Text(
//                   d.title.toUpperCase(),
//                   style: pw.TextStyle(
//                     fontSize: 14,
//                     fontWeight: pw.FontWeight.bold,
//                   ),
//                 ),
//                 pw.Text("No: ${d.number}"),
//                 pw.Text("Date: ${DateFormat("dd MMM yyyy").format(d.date)}"),
//               ],
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   // ================= BUYER =================
//   static pw.Widget _buyerCard(PrintDocModel d) {
//     return pw.Container(
//       padding: const pw.EdgeInsets.all(14),
//       decoration: pw.BoxDecoration(
//         borderRadius: pw.BorderRadius.circular(10),
//         border: pw.Border.all(color: PdfColors.grey400),
//       ),
//       child: pw.Row(
//         children: [
//           pw.Expanded(
//             child: pw.Column(
//               crossAxisAlignment: pw.CrossAxisAlignment.start,
//               children: [
//                 pw.Text(
//                   "Bill To",
//                   style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
//                 ),
//                 pw.SizedBox(height: 4),
//                 pw.Text(d.partyName),
//                 pw.Text("${d.address0} ${d.address1}"),
//                 pw.Text("Mobile: ${d.mobile}"),
//                 pw.Text("State: ${d.placeOfSupply}"),
//               ],
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   // ================= ITEMS =================
//   static pw.Widget _premiumItemsTable(PrintDocModel d) {
//     return pw.Table(
//       border: pw.TableBorder.all(color: PdfColors.grey400),
//       columnWidths: const {
//         0: pw.FlexColumnWidth(1),
//         1: pw.FlexColumnWidth(4),
//         2: pw.FlexColumnWidth(1.5),
//         3: pw.FlexColumnWidth(2),
//         4: pw.FlexColumnWidth(2),
//       },
//       children: [
//         pw.TableRow(
//           decoration: pw.BoxDecoration(color: PdfColors.grey300),
//           children: [
//             _th("No"),
//             _th("Item"),
//             _th("Qty"),
//             _th("Rate"),
//             _th("Amount"),
//           ],
//         ),
//         ...d.items.asMap().entries.map(
//           (e) => pw.TableRow(
//             decoration: pw.BoxDecoration(
//               color: e.key.isEven ? PdfColors.white : PdfColors.grey100,
//             ),
//             children: [
//               _td("${e.key + 1}"),
//               _td(e.value.name),
//               _td("${e.value.qty}"),
//               _td(e.value.price.toStringAsFixed(2)),
//               _td(e.value.amount.toStringAsFixed(2)),
//             ],
//           ),
//         ),
//       ],
//     );
//   }

//   // ================= SUMMARY =================
//   static pw.Widget _summaryCard(PrintDocModel d) {
//     return pw.Align(
//       alignment: pw.Alignment.centerRight,
//       child: pw.Container(
//         width: 220,
//         padding: const pw.EdgeInsets.all(12),
//         decoration: pw.BoxDecoration(
//           borderRadius: pw.BorderRadius.circular(10),
//           color: PdfColors.grey100,
//         ),
//         child: pw.Column(
//           crossAxisAlignment: pw.CrossAxisAlignment.end,
//           children: [
//             _sumRow("Sub Total", d.subTotal),
//             _sumRow("GST", d.gstTotal),
//             pw.Divider(),
//             pw.Text(
//               "Total: Rs. ${d.grandTotal.toStringAsFixed(2)}",
//               style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 13),
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   static pw.Widget _sumRow(String k, double v) {
//     return pw.Row(
//       mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
//       children: [pw.Text(k), pw.Text("Rs. ${v.toStringAsFixed(2)}")],
//     );
//   }

//   // ================= NOTES =================
//   static pw.Widget _notesAndTerms(PrintDocModel d) {
//     return pw.Row(
//       crossAxisAlignment: pw.CrossAxisAlignment.start,
//       children: [
//         pw.Expanded(
//           child: pw.Container(
//             padding: const pw.EdgeInsets.all(12),
//             decoration: pw.BoxDecoration(
//               borderRadius: pw.BorderRadius.circular(10),
//               border: pw.Border.all(color: PdfColors.grey400),
//             ),
//             child: pw.Column(
//               crossAxisAlignment: pw.CrossAxisAlignment.start,
//               children: [
//                 pw.Text(
//                   "Notes",
//                   style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
//                 ),
//                 ...d.notes.map((e) => pw.Text("• $e")),
//               ],
//             ),
//           ),
//         ),
//         pw.SizedBox(width: 12),
//         pw.Expanded(
//           child: pw.Container(
//             padding: const pw.EdgeInsets.all(12),
//             decoration: pw.BoxDecoration(
//               borderRadius: pw.BorderRadius.circular(10),
//               border: pw.Border.all(color: PdfColors.grey400),
//             ),
//             child: pw.Column(
//               crossAxisAlignment: pw.CrossAxisAlignment.start,
//               children: [
//                 pw.Text(
//                   "Terms",
//                   style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
//                 ),
//                 ...d.terms.map((e) => pw.Text("• $e")),
//               ],
//             ),
//           ),
//         ),
//       ],
//     );
//   }

//   // ================= FOOTER =================
//   static pw.Widget _premiumFooter(CompanyPrintProfile c) {
//     return pw.Row(
//       mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
//       children: [
//         pw.Text("This is a computer generated invoice"),
//         pw.Column(
//           crossAxisAlignment: pw.CrossAxisAlignment.end,
//           children: [
//             pw.Text(
//               "For ${c.name}",
//               style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
//             ),
//             pw.SizedBox(height: 30),
//             pw.Text("Authorised Signatory"),
//           ],
//         ),
//       ],
//     );
//   }

//   static pw.Widget _th(String t) => pw.Padding(
//     padding: const pw.EdgeInsets.all(8),
//     child: pw.Text(t, style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
//   );

//   static pw.Widget _td(String t) =>
//       pw.Padding(padding: const pw.EdgeInsets.all(8), child: pw.Text(t));
// }

// ignore_for_file: prefer_interpolation_to_compose_strings

import 'package:ims/ui/sales/models/print_model.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:pdf/pdf.dart';
import 'package:printing/printing.dart';
import 'package:intl/intl.dart';

class PdfEngine {
  static Future<void> printPremiumInvoice({
    required PrintDocModel doc,
    required CompanyPrintProfile company,
  }) async {
    final pdf = pw.Document();

    final logo = await _loadNetImage(company.logoUrl);
    final otherLogo = await _loadNetImage(company.otherlogoUrl);
    final sign = await _loadNetImage(company.signatureUrl);

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(20),
        build: (_) => pw.Container(
          decoration: pw.BoxDecoration(
            border: pw.Border.all(color: PdfColors.black),
          ),
          padding: const pw.EdgeInsets.all(8),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              _headerClassic(company, logo, otherLogo),
              pw.SizedBox(height: 8),
              pw.Center(
                child: pw.Text(
                  doc.title,
                  style: pw.TextStyle(
                    fontWeight: pw.FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
              pw.SizedBox(height: 6),
              _partyAndInvoice(doc),
              pw.SizedBox(height: 6),
              _itemTableClassic(doc),
              pw.SizedBox(height: 6),
              _totalsClassic(doc),
              pw.SizedBox(height: 6),
              _gstSummary(doc),
              pw.SizedBox(height: 6),
              _termsAndSign(company, sign),
              pw.SizedBox(height: 6),
              pw.Center(
                child: pw.Text("Page 1 of 1", style: pw.TextStyle(fontSize: 9)),
              ),
            ],
          ),
        ),
      ),
    );

    final bytes = await pdf.save();
    await Printing.layoutPdf(onLayout: (_) async => bytes);
  }

  // ================= HEADER =================
  static pw.Widget _headerClassic(
    CompanyPrintProfile c,
    pw.ImageProvider? logo,
    pw.ImageProvider? otherLogo,
  ) {
    return pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Container(
          width: 60,
          height: 60,
          child: logo != null ? pw.Image(logo) : pw.Container(),
        ),
        pw.Expanded(
          child: pw.Column(
            children: [
              pw.Text(
                c.name,
                style: pw.TextStyle(
                  fontWeight: pw.FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              pw.Text(
                c.address,
                textAlign: pw.TextAlign.center,
                style: pw.TextStyle(fontSize: 9),
              ),
              pw.Text(
                "GSTIN: ${c.gst}  |  PAN: ${c.pan}",
                style: pw.TextStyle(fontSize: 9),
              ),
              pw.Text(
                "Phone: ${c.phone} | Email: ${c.email}",
                style: pw.TextStyle(fontSize: 9),
              ),
            ],
          ),
        ),
        pw.Container(
          width: 60,
          height: 60,
          child: otherLogo != null ? pw.Image(otherLogo) : pw.Container(),
        ),
      ],
    );
  }

  // ================= PARTY + INVOICE =================
  static pw.Widget _partyAndInvoice(PrintDocModel d) {
    return pw.Table(
      border: pw.TableBorder.all(),
      columnWidths: const {
        0: pw.FlexColumnWidth(1),
        1: pw.FlexColumnWidth(2),
        2: pw.FlexColumnWidth(1),
        3: pw.FlexColumnWidth(2),
      },
      children: [
        pw.TableRow(
          children: [
            _cell("Party Name"),
            _cell(d.partyName),
            _cell("Invoice No"),
            _cell(d.number),
          ],
        ),
        pw.TableRow(
          children: [
            _cell("Address"),
            _cell("${d.address0} ${d.address1}"),
            _cell("Date"),
            _cell(DateFormat("dd-MM-yyyy").format(d.date)),
          ],
        ),
        pw.TableRow(children: [_cell("GSTIN"), _cell(d.gstTotal.toString())]),
        pw.TableRow(children: [_cell("State"), _cell(d.placeOfSupply)]),
      ],
    );
  }

  // ================= ITEMS TABLE =================
  static pw.Widget _itemTableClassic(PrintDocModel d) {
    return pw.Table(
      border: pw.TableBorder.all(),
      columnWidths: const {
        0: pw.FlexColumnWidth(1),
        1: pw.FlexColumnWidth(3),
        2: pw.FlexColumnWidth(1.5),
        3: pw.FlexColumnWidth(1),
        4: pw.FlexColumnWidth(1),
        5: pw.FlexColumnWidth(1),
        6: pw.FlexColumnWidth(1),
        7: pw.FlexColumnWidth(1.2),
      },
      children: [
        pw.TableRow(
          decoration: const pw.BoxDecoration(color: PdfColors.grey300),
          children: [
            _th("S.N"),
            _th("Item Description"),
            _th("HSN"),
            _th("Qty"),
            _th("Rate"),
            _th("Disc"),
            _th("GST %"),
            _th("Taxable"),
          ],
        ),
        ...d.items.asMap().entries.map((e) {
          final i = e.key + 1;
          final it = e.value;
          return pw.TableRow(
            children: [
              _td("$i"),
              _td(it.name),
              _td(it.hsn),
              _td("${it.qty}"),
              _td(it.price.toStringAsFixed(2)),
              _td(it.discount.toStringAsFixed(2)),
              _td("${it.gstRate}%"),
              _td(it.amount.toStringAsFixed(2)),
            ],
          );
        }),
      ],
    );
  }

  // ================= TOTALS =================
  static pw.Widget _totalsClassic(PrintDocModel d) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Text(
          "Amount in Words: ${d.grandTotal}",
          style: pw.TextStyle(fontSize: 9),
        ),
        pw.Container(
          width: 200,
          child: pw.Table(
            border: pw.TableBorder.all(),
            children: [
              _row2("Taxable Amount", d.subTotal),
              _row2("CGST", d.gstTotal),
              _row2("SGST", d.gstTotal),
              _row2("IGST", d.gstTotal),
              _row2("Grand Total", d.grandTotal),
            ],
          ),
        ),
      ],
    );
  }

  // ================= GST SUMMARY =================
  static pw.Widget _gstSummary(PrintDocModel d) {
    return pw.Table(
      border: pw.TableBorder.all(),
      children: [
        pw.TableRow(
          decoration: const pw.BoxDecoration(color: PdfColors.grey300),
          children: [
            _th("GST Summary"),
            _th("Taxable"),
            _th("CGST"),
            _th("SGST"),
            _th("IGST"),
          ],
        ),
        pw.TableRow(
          children: [
            _td("Total"),
            _td(d.subTotal.toStringAsFixed(2)),
            _td(d.gstTotal.toStringAsFixed(2)),
            _td(d.gstTotal.toStringAsFixed(2)),
            _td(d.gstTotal.toStringAsFixed(2)),
          ],
        ),
      ],
    );
  }

  // ================= TERMS + SIGN =================
  static pw.Widget _termsAndSign(
    CompanyPrintProfile c,
    pw.ImageProvider? sign,
  ) {
    return pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Expanded(
          child: pw.Container(
            padding: const pw.EdgeInsets.all(6),
            decoration: pw.BoxDecoration(border: pw.Border.all()),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  "Terms & Conditions",
                  style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                ),
                pw.Text(
                  "1. Goods once sold will not be taken back.",
                  style: pw.TextStyle(fontSize: 9),
                ),
                pw.Text(
                  "2. Interest @18% will be charged if payment delayed.",
                  style: pw.TextStyle(fontSize: 9),
                ),
              ],
            ),
          ),
        ),
        pw.SizedBox(width: 6),
        pw.Expanded(
          child: pw.Container(
            padding: const pw.EdgeInsets.all(6),
            decoration: pw.BoxDecoration(border: pw.Border.all()),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.end,
              children: [
                pw.Text(
                  "For ${c.name}",
                  style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                ),
                pw.SizedBox(height: 30),
                if (sign != null) pw.Image(sign, height: 40),
                pw.Text(
                  "Authorised Signatory",
                  style: pw.TextStyle(fontSize: 9),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ================= HELPERS =================
  static pw.Widget _cell(String t) => pw.Padding(
    padding: const pw.EdgeInsets.all(4),
    child: pw.Text(t, style: pw.TextStyle(fontSize: 9)),
  );

  static pw.Widget _th(String t) => pw.Padding(
    padding: const pw.EdgeInsets.all(4),
    child: pw.Text(
      t,
      style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9),
    ),
  );

  static pw.Widget _td(String t) => pw.Padding(
    padding: const pw.EdgeInsets.all(4),
    child: pw.Text(t, style: pw.TextStyle(fontSize: 9)),
  );

  static pw.TableRow _row2(String k, double v) =>
      pw.TableRow(children: [_td(k), _td(v.toStringAsFixed(2))]);

  static Future<pw.ImageProvider?> _loadNetImage(String url) async {
    if (url.isEmpty) return null;
    try {
      return await networkImage(url); // ✅ already ImageProvider
    } catch (e) {
      return null;
    }
  }
}

class CompanyPrintProfile {
  final String name;
  final String phone;
  final String email;
  final String address;
  final String gst;
  final String pan;
  final String logoUrl;
  final String otherlogoUrl;
  final String signatureUrl;

  CompanyPrintProfile({
    required this.name,
    required this.phone,
    required this.email,
    required this.address,
    required this.gst,
    required this.pan,
    required this.logoUrl,
    required this.otherlogoUrl,
    required this.signatureUrl,
  });

  factory CompanyPrintProfile.fromApi(Map<String, dynamic> company) {
    return CompanyPrintProfile(
      name: company["business_name"] ?? "",
      phone: company["phone_no"]?.toString() ?? "",
      email: company["email"] ?? "",
      address:
          "${company["address"] ?? ""}, ${company["city"] ?? ""}, ${company["state"] ?? ""}-${company["pincode"] ?? ""}",
      gst: company["gst_no"] ?? "",
      pan: company["pan_number"] ?? "",
      logoUrl: company["company_logo"] ?? "",
      otherlogoUrl: company["other_logo"] ?? "",
      signatureUrl: company["signature"] ?? "",
    );
  }
}
