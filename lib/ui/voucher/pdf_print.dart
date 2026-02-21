import 'package:ims/ui/sales/data/reuse_print.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:pdf/pdf.dart';
import 'package:printing/printing.dart';
import 'package:intl/intl.dart';
import 'package:ims/model/contra_model.dart';
import 'package:ims/model/payment_model.dart';
import 'package:ims/model/expanse_model.dart';

class VoucherPdfEngine {
  // ================= PUBLIC APIS =================

  static Future<void> printContra({
    required ContraModel data,
    required CompanyPrintProfile company,
  }) async {
    return _printVoucher(
      title: "CONTRA VOUCHER",
      refNo: "${data.prefix} ${data.voucherNo}",
      date: data.date,
      receivedFrom: data.fromAccount,
      amount: data.amount,
      description: "Transfer to ${data.toAccount}",
      company: company,
    );
  }

  static Future<void> printExpense({
    required ExpanseModel data,
    required CompanyPrintProfile company,
  }) async {
    return _printVoucher(
      title: "EXPENSE VOUCHER",
      refNo: "${data.prefix} ${data.voucherNo}",
      date: data.date,
      receivedFrom: data.supplierName,
      amount: data.amount,
      description: "Expense for ${data.ledgerName}\n${data.note}",
      company: company,
    );
  }

  static Future<void> printPayment({
    required PaymentModel data,
    required CompanyPrintProfile company,
  }) async {
    return _printVoucher(
      title: "PAYMENT VOUCHER",
      refNo: "${data.prefix} ${data.voucherNo}",
      date: data.date,
      receivedFrom: data.supplierName,
      amount: data.amount,
      description: data.note,
      company: company,
    );
  }

  static Future<void> printReceipt({
    required PaymentModel data,
    required CompanyPrintProfile company,
  }) async {
    return _printVoucher(
      title: "RECEIPT",
      refNo: "${data.prefix} ${data.voucherNo}",
      date: data.date,
      receivedFrom: data.supplierName,
      amount: data.amount,
      description: data.note,
      company: company,
    );
  }

  static Future<void> printJournal({
    required ContraModel data,
    required CompanyPrintProfile company,
  }) async {
    return _printVoucher(
      title: "JOURNAL VOUCHER",
      refNo: "${data.prefix} ${data.voucherNo}",
      date: data.date,
      receivedFrom: data.toAccount,
      amount: data.amount,
      description: data.note,
      company: company,
    );
  }

  // ================= CORE ENGINE =================

  static Future<void> _printVoucher({
    required String title,
    required String refNo,
    required DateTime date,
    required String receivedFrom,
    required double amount,
    required String description,
    required CompanyPrintProfile company,
  }) async {
    final pdf = pw.Document();

    final logo = await _loadNetImage(company.logoUrl);
    final otherLogo = await _loadNetImage(company.otherlogoUrl);

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(20),
        build: (_) => pw.Container(
          alignment: pw.Alignment.center,
          decoration: pw.BoxDecoration(border: pw.Border.all()),
          padding: const pw.EdgeInsets.all(8),
          child: pw.Column(
            children: [
              _header(company, logo, otherLogo),
              pw.SizedBox(height: 6),
              pw.Text(
                title,
                style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
              ),
              pw.SizedBox(height: 6),
              _voucherTable(refNo, date, receivedFrom),
              pw.SizedBox(height: 6),
              _amountBlock(amount),
              pw.SizedBox(height: 6),
              _descriptionBlock(description),
              pw.SizedBox(height: 6),
              _footer(company.name),
            ],
          ),
        ),
      ),
    );

    final bytes = await pdf.save();
    await Printing.layoutPdf(onLayout: (_) async => bytes);
  }

  // ================= UI BLOCKS =================

  static pw.Widget _header(
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

  static pw.Widget _voucherTable(
    String refNo,
    DateTime date,
    String receivedFrom,
  ) {
    return pw.Table(
      border: pw.TableBorder.all(),
      children: [
        _row("Received With Thanks From", receivedFrom, "REF NO", refNo),
        _row(
          "Cheque Receipt is Subject to Realisation",
          "",
          "DATE",
          DateFormat("dd-MM-yyyy").format(date),
        ),
      ],
    );
  }

  static pw.Widget _amountBlock(double amount) {
    return pw.Table(
      border: pw.TableBorder.all(),
      children: [
        pw.TableRow(
          children: [
            _cell("Amount in Words"),
            _cell(
              "Rs. ${amountToWordsIndian(amount.round()).toUpperCase()} ONLY",
            ),
            _cell("Rs."),
            _cell(amount.toStringAsFixed(2)),
          ],
        ),
      ],
    );
  }

  static pw.Widget _descriptionBlock(String desc) {
    return pw.Table(
      border: pw.TableBorder.all(),
      children: [
        pw.TableRow(children: [_cell("Description"), _cell(desc)]),
      ],
    );
  }

  static pw.Widget _footer(String companyName) {
    return pw.Table(
      border: pw.TableBorder.all(),
      children: [
        pw.TableRow(
          children: [
            _cell("Deposited in: CASH"),
            _cell("For $companyName\n\nAuthorised Signatory"),
          ],
        ),
      ],
    );
  }

  // ================= HELPERS =================

  static pw.TableRow _row(String l1, String v1, String l2, String v2) {
    return pw.TableRow(children: [_cell(l1), _cell(v1), _cell(l2), _cell(v2)]);
  }

  static pw.Widget _cell(String t) => pw.Padding(
    padding: const pw.EdgeInsets.all(6),
    child: pw.Text(t, style: pw.TextStyle(fontSize: 9)),
  );

  static Future<pw.ImageProvider?> _loadNetImage(String url) async {
    if (url.isEmpty) return null;
    try {
      return await networkImage(url);
    } catch (_) {
      return null;
    }
  }
}
