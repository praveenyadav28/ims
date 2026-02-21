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
              _totalsClassic(doc, company),
              pw.SizedBox(height: 6),
              _gstSummary(doc, company),
              pw.SizedBox(height: 6),
              _termsAndSign(company, sign, doc),
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
          width: 100,
          height: 100,
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
                "City: ${c.city} | District: ${c.district}",
                style: pw.TextStyle(fontSize: 9),
              ),
              pw.Text(
                "State: ${c.state} | Pin Code: ${c.pincode}",
                style: pw.TextStyle(fontSize: 9),
              ),
              pw.Text("GSTIN: ${c.gst}", style: pw.TextStyle(fontSize: 9)),
              pw.Text(
                "Phone: ${c.phone} | Email: ${c.email}",
                style: pw.TextStyle(fontSize: 9),
              ),
            ],
          ),
        ),
        pw.Container(
          width: 100,
          height: 100,
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
            _cell(d.address0),
            _cell("Date"),
            _cell(DateFormat("dd-MM-yyyy").format(d.date)),
          ],
        ),
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
              _td(it.amount.toStringAsFixed(2)),
              _td(it.discount.toStringAsFixed(2)),
              _td("${it.gstRate}%"),
              _td(
                (it.amount - ((it.amount * it.gstRate) / (100 + it.gstRate)))
                    .toStringAsFixed(2),
              ),
            ],
          );
        }),
      ],
    );
  }

  // ================= TOTALS =================
  static pw.Widget _totalsClassic(PrintDocModel d, CompanyPrintProfile p) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Text(
          "Amount in Words: ${amountToWordsIndian(d.grandTotal.round())} Only",
          style: pw.TextStyle(fontSize: 9),
        ),
        pw.Container(
          width: 200,
          child: pw.Table(
            border: pw.TableBorder.all(),
            children: [
              _row2("Taxable Amount", d.subTotal),
              _row2("IGST", d.placeOfSupply == p.state ? d.gstTotal : 0),
              _row2("CGST", d.placeOfSupply != p.state ? d.gstTotal / 2 : 0),
              _row2("SGST", d.placeOfSupply != p.state ? d.gstTotal / 2 : 0),
              _row2("Grand Total", d.grandTotal),
            ],
          ),
        ),
      ],
    );
  }

  // ================= GST SUMMARY =================
  static pw.Widget _gstSummary(PrintDocModel d, CompanyPrintProfile p) {
    final rows = _buildGstSummaryRows(d, p);

    return pw.Table(
      border: pw.TableBorder.all(),
      columnWidths: const {
        0: pw.FlexColumnWidth(1.2), // GST Rate
        1: pw.FlexColumnWidth(2), // Taxable
        2: pw.FlexColumnWidth(1.5), // IGST
        3: pw.FlexColumnWidth(1.5), // CGST
        4: pw.FlexColumnWidth(1.5), // SGST
      },
      children: [
        pw.TableRow(
          decoration: const pw.BoxDecoration(color: PdfColors.grey300),
          children: [
            _th("GST Rate"),
            _th("Taxable Amount"),
            _th("IGST"),
            _th("CGST"),
            _th("SGST"),
          ],
        ),
        ...rows,
      ],
    );
  }

  static List<pw.TableRow> _buildGstSummaryRows(
    PrintDocModel d,
    CompanyPrintProfile p,
  ) {
    final Map<double, double> rateWiseTaxable = {};

    // 1️⃣ Group taxable amount by GST Rate
    for (final item in d.items) {
      final rate = item.gstRate.toDouble();
      final taxable =
          item.amount - ((item.amount * item.gstRate) / (100 + item.gstRate));

      rateWiseTaxable[rate] = (rateWiseTaxable[rate] ?? 0) + taxable;
    }

    // 2️⃣ Convert into table rows
    return rateWiseTaxable.entries.map((e) {
      final rate = e.key;
      final taxable = e.value;

      final totalGst = taxable * rate / 100;

      final igst = d.placeOfSupply == p.state ? totalGst : 0;
      final cgst = d.placeOfSupply != p.state ? totalGst / 2 : 0;
      final sgst = d.placeOfSupply != p.state ? totalGst / 2 : 0;

      return pw.TableRow(
        children: [
          _td("${rate.toStringAsFixed(0)}%"),
          _td(taxable.toStringAsFixed(2)),
          _td(igst.toStringAsFixed(2)),
          _td(cgst.toStringAsFixed(2)),
          _td(sgst.toStringAsFixed(2)),
        ],
      );
    }).toList();
  }

  // ================= TERMS + SIGN =================
  static pw.Widget _termsAndSign(
    CompanyPrintProfile c,
    pw.ImageProvider? sign,
    PrintDocModel p,
  ) {
    return pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Expanded(
          flex: 2,
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
                pw.Column(
                  children: List.generate(p.terms.length, (i) {
                    return pw.Text(
                      "${i + 1}. ${p.terms[i]}",
                      style: pw.TextStyle(fontSize: 9),
                    );
                  }),
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
  final String city;
  final String district;
  final String state;
  final String pincode;
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
    required this.city,
    required this.district,
    required this.state,
    required this.pincode,
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
      address: company["address"] ?? "",
      city: company["city"] ?? "",
      state: company["state"] ?? "",
      district: company["district"] ?? "",
      pincode: company["pincode"].toString(),
      gst: company["gst_no"] ?? "",
      pan: company["pan_number"] ?? "",
      logoUrl: company["company_logo"] ?? "",
      otherlogoUrl: company["other_logo"] ?? "",
      signatureUrl: company["signature"] ?? "",
    );
  }
}

String amountToWordsIndian(int number) {
  const units = [
    '',
    'One',
    'Two',
    'Three',
    'Four',
    'Five',
    'Six',
    'Seven',
    'Eight',
    'Nine',
    'Ten',
    'Eleven',
    'Twelve',
    'Thirteen',
    'Fourteen',
    'Fifteen',
    'Sixteen',
    'Seventeen',
    'Eighteen',
    'Nineteen',
  ];
  const tens = [
    '',
    '',
    'Twenty',
    'Thirty',
    'Forty',
    'Fifty',
    'Sixty',
    'Seventy',
    'Eighty',
    'Ninety',
  ];

  String twoDigits(int n) {
    if (n < 20) return units[n];
    return tens[n ~/ 10] + (n % 10 != 0 ? " ${units[n % 10]}" : "");
  }

  String words(int n) {
    if (n < 100) return twoDigits(n);
    if (n < 1000) return "${units[n ~/ 100]} Hundred ${words(n % 100)}";
    if (n < 100000) return "${words(n ~/ 1000)} Thousand ${words(n % 1000)}";
    if (n < 10000000) return "${words(n ~/ 100000)} Lakh ${words(n % 100000)}";
    return "${words(n ~/ 10000000)} Crore ${words(n % 10000000)}";
  }

  return words(number).replaceAll(RegExp(r'\s+'), ' ').trim();
}
