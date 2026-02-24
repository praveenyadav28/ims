import 'package:pdf/widgets.dart' as pw;
import 'package:pdf/pdf.dart';
import 'package:printing/printing.dart';
import 'package:intl/intl.dart';
import 'package:ims/ui/sales/data/reuse_print.dart'; // CompanyPrintProfile + amountToWordsIndian
import 'package:flutter/material.dart';
import 'package:ims/model/expanse_model.dart';
import 'package:ims/model/payment_model.dart';
import 'package:ims/ui/inventry/item_model.dart';
import 'package:ims/ui/sales/models/purcahseinvoice_data.dart';
import 'package:ims/ui/sales/models/purchase_return_data.dart';
import 'package:ims/ui/sales/models/sale_invoice_data.dart';
import 'package:ims/ui/sales/models/sale_return_data.dart';
import 'package:ims/utils/button.dart';
import 'package:ims/utils/colors.dart';
import 'package:ims/utils/textfield.dart';
import '../../../utils/api.dart';
import '../../../utils/prefence.dart';

class ProfitLossScreen extends StatefulWidget {
  const ProfitLossScreen({super.key});

  @override
  State<ProfitLossScreen> createState() => _ProfitLossScreenState();
}

class _ProfitLossScreenState extends State<ProfitLossScreen> {
  DateTime? fromDate;
  DateTime? toDate;

  final fromDateCtrl = TextEditingController();
  final toDateCtrl = TextEditingController();

  bool loading = false;

  double openingStock = 0;
  double closingStock = 0;
  List<ExpanseModel> expenseList = [];
  List<PaymentModel> incomeList = [];
  double totalIncome = 0;
  double totalExpense = 0;
  double netProfit = 0;

  double totalSale = 0;
  double totalSaleReturn = 0;
  double totalPurchase = 0;
  double totalPurchaseReturn = 0;

  double netSales = 0;
  double netPurchase = 0;
  double grossProfit = 0;

  @override
  void initState() {
    super.initState();
    setFinancialYear();
    fetchProfitLoss();
  }

  // ================= FINANCIAL YEAR =================
  void setFinancialYear() {
    final now = DateTime.now();

    if (now.month >= 4) {
      fromDate = DateTime(now.year, 4, 1);
      toDate = DateTime(now.year + 1, 3, 31);
    } else {
      fromDate = DateTime(now.year - 1, 4, 1);
      toDate = DateTime(now.year, 3, 31);
    }

    fromDateCtrl.text = DateFormat("dd/MM/yyyy").format(fromDate!);
    toDateCtrl.text = DateFormat("dd/MM/yyyy").format(toDate!);
  }

  Future<void> fetchIncome() async {
    final res = await ApiService.fetchData(
      "get/reciept",
      licenceNo: Preference.getint(PrefKeys.licenseNo),
    );

    final all = (res['data'] as List)
        .map((e) => PaymentModel.fromJson(e))
        .toList();

    incomeList = all.where((e) {
      return e.other1 == "Income" &&
          !e.date.isBefore(fromDate!) &&
          !e.date.isAfter(toDate!.add(const Duration(days: 1)));
    }).toList();

    totalIncome = 0;
    for (final i in incomeList) {
      totalIncome += i.amount;
    }
  }

  Future<void> fetchProfitLoss() async {
    setState(() => loading = true);

    await fetchStock();
    await fetchTransactions();
    await fetchExpenses();
    await fetchIncome(); // ✅ ADD THIS

    calculateProfitLoss();

    setState(() => loading = false);
  }

  // ================= FIFO STOCK =================
  Future<void> fetchStock() async {
    final res = await ApiService.fetchData(
      "get/fiforeports?from_date=${_fmt(fromDate)}&to_date=${_fmt(toDate)}",
      licenceNo: Preference.getint(PrefKeys.licenseNo),
    );

    final list = (res['data'] as List)
        .map((e) => FifoReportModel.fromJson(e))
        .toList();

    openingStock = 0;
    closingStock = 0;

    for (var e in list) {
      openingStock += double.parse(e.openingStock);
      closingStock += double.parse(e.closingStock);
    }
  }

  Future<void> fetchExpenses() async {
    final res = await ApiService.fetchData(
      "get/expense",
      licenceNo: Preference.getint(PrefKeys.licenseNo),
    );

    final all = (res['data'] as List)
        .map((e) => ExpanseModel.fromJson(e))
        .toList();

    // ✅ filter by date range
    expenseList = all.where((e) {
      return !e.date.isBefore(fromDate!) &&
          !e.date.isAfter(toDate!.add(const Duration(days: 1)));
    }).toList();

    totalExpense = 0;
    for (var e in expenseList) {
      totalExpense += e.amount;
    }
  }

  // ================= TRANSACTIONS =================
  Future<void> fetchTransactions() async {
    final sales = await getSaleInvoice();
    final saleReturns = await getSaleReturn();
    final purchases = await getPurchaseInvoice();
    final purchaseReturns = await getPurchaseReturn();

    totalSale = 0;
    totalSaleReturn = 0;
    totalPurchase = 0;
    totalPurchaseReturn = 0;

    for (var s in sales) {
      totalSale += s.subTotal;
    }

    for (var sr in saleReturns) {
      totalSaleReturn += sr.subTotal;
    }

    for (var p in purchases) {
      totalPurchase += p.subTotal;
    }

    for (var pr in purchaseReturns) {
      totalPurchaseReturn += pr.subTotal;
    }
  }

  void calculateProfitLoss() {
    netSales = totalSale - totalSaleReturn;
    netPurchase = totalPurchase - totalPurchaseReturn;

    grossProfit = netSales + closingStock - openingStock - netPurchase;
    netProfit = grossProfit + totalIncome - totalExpense;
  }

  // ================= API METHODS =================
  Future<List<SaleInvoiceData>> getSaleInvoice() async {
    final res = await ApiService.fetchData(
      "get/invoice",
      licenceNo: Preference.getint(PrefKeys.licenseNo),
    );
    return SaleInvoiceListResponse.fromJson(res).data;
  }

  Future<List<SaleReturnData>> getSaleReturn() async {
    final res = await ApiService.fetchData(
      "get/returnsale",
      licenceNo: Preference.getint(PrefKeys.licenseNo),
    );
    return SaleReturnListResponse.fromJson(res).data;
  }

  Future<List<PurchaseInvoiceData>> getPurchaseInvoice() async {
    final res = await ApiService.fetchData(
      "get/purchaseinvoice",
      licenceNo: Preference.getint(PrefKeys.licenseNo),
    );
    return PurchaseInvoiceListResponse.fromJson(res).data;
  }

  Future<List<PurchaseReturnData>> getPurchaseReturn() async {
    final res = await ApiService.fetchData(
      "get/purchasereturn",
      licenceNo: Preference.getint(PrefKeys.licenseNo),
    );
    return PurchaseReturnListResponse.fromJson(res).data;
  }

  String _fmt(DateTime? d) =>
      d == null ? "" : DateFormat("yyyy-MM-dd").format(d);

  // ================= UI =================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Profit & Loss"),
        backgroundColor: AppColor.primary,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            _dateFilter(),
            loading ? const Center(child: GlowLoader()) : _profitView(),
          ],
        ),
      ),
    );
  }

  Widget _dateFilter() {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          _dateBox("From", fromDateCtrl),
          const SizedBox(width: 10),
          _dateBox("To", toDateCtrl),
          const SizedBox(width: 10),
          defaultButton(
            onTap: fetchProfitLoss,
            text: "Search",
            height: 40,
            width: 150,
            buttonColor: AppColor.blue,
          ),
          const SizedBox(width: 10),
          IconButton(
            icon: Icon(Icons.print, color: AppColor.primary),
            onPressed: () async {
              final companyRes = await ApiService.fetchData(
                "get/company",
                licenceNo: Preference.getint(PrefKeys.licenseNo),
              );

              final data = companyRes['data'];

              final company = CompanyPrintProfile.fromApi(
                data is List ? data.first : data,
              );

              await ProfitLossPdfEngine.printPL(
                company: company,
                from: fromDate!,
                to: toDate!,
                openingStock: openingStock,
                closingStock: closingStock,
                netSales: netSales,
                netPurchase: netPurchase,
                grossProfit: grossProfit,
                totalIncome: totalIncome,
                totalExpense: totalExpense,
                netProfit: netProfit,
                groupedExpenses: _groupExpensesBySupplier(),
                groupedIncome: _groupIncomeBySupplier(),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _dateBox(String label, TextEditingController ctrl) {
    return Expanded(
      child: CommonTextField(controller: ctrl, readOnly: true, hintText: label),
    );
  }

  Widget _profitView() {
    final totalLeft =
        openingStock +
        netPurchase +
        totalExpense +
        (netProfit > 0 ? netProfit : 0);

    final totalRight =
        netSales + closingStock + (netProfit < 0 ? netProfit.abs() : 0);
    final groupedIncome = _groupIncomeBySupplier();
    final groupedExpenses = _groupExpensesBySupplier();
    final expenseEntries = groupedExpenses.entries.toList();
    final incomeEntries = groupedIncome.entries.toList();

    final maxLen = expenseEntries.length > incomeEntries.length
        ? expenseEntries.length
        : incomeEntries.length;

    return Container(
      margin: const EdgeInsets.all(12),
      decoration: BoxDecoration(border: Border.all(color: Colors.black54)),
      child: Column(
        children: [
          // HEADER
          Container(
            color: const Color(0xFF6C757D),
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: Row(
              children: const [
                Expanded(
                  child: Padding(
                    padding: EdgeInsets.only(left: 20),
                    child: Text(
                      "Particulars",
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: Text(
                    "Amount    ",
                    textAlign: TextAlign.right,
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                SizedBox(width: 20),
                VerticalDivider(color: Colors.white, thickness: 1),
                Expanded(
                  child: Padding(
                    padding: EdgeInsets.only(left: 20),
                    child: Text(
                      "Particulars",
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: Text(
                    "Amount",
                    textAlign: TextAlign.right,
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                SizedBox(width: 20),
              ],
            ),
          ),

          _plRow(
            left: "Opening Stock",
            leftAmt: openingStock,
            right: "Sales Accounts",
            rightAmt: netSales,
          ),
          _plRow(
            left: "Purchase Accounts",
            leftAmt: netPurchase,
            right: "Closing Stock",
            rightAmt: closingStock,
          ),
          _plRow(
            left: "Gross Profit C/F",
            leftAmt: grossProfit,
            right: "",
            rightAmt: 0,
            boldLeft: true,
          ),

          const Divider(thickness: 1, height: 0),

          _plRow(
            left: "Total",
            leftAmt: totalLeft,
            right: "Total",
            rightAmt: totalRight,
            boldLeft: true,
            boldRight: true,
          ),

          const Divider(thickness: 1, height: 0),

          _plRow(
            left: "",
            leftAmt: 0,
            right: "Gross Profit B/D",
            rightAmt: grossProfit,
            boldRight: true,
          ),
          const Divider(thickness: 1, height: 0),
          for (int i = 0; i < maxLen; i++)
            _plRow(
              left: i < expenseEntries.length ? expenseEntries[i].key : "",
              leftAmt: i < expenseEntries.length ? expenseEntries[i].value : 0,
              right: i < incomeEntries.length ? incomeEntries[i].key : "",
              rightAmt: i < incomeEntries.length ? incomeEntries[i].value : 0,
            ),
          _plRow(
            left: "Total Expenses",
            leftAmt: totalExpense,
            right: "Total Income",
            rightAmt: totalIncome,
            boldLeft: true,
            boldRight: true,
          ),
          const Divider(thickness: 1, height: 0),

          if (netProfit > 0)
            _plRow(
              left: "Net Profit",
              leftAmt: netProfit,
              right: "",
              rightAmt: 0,
              boldLeft: true,
            )
          else
            _plRow(
              left: "",
              leftAmt: 0,
              right: "Net Loss",
              rightAmt: netProfit.abs(),
              boldRight: true,
            ),
        ],
      ),
    );
  }

  Widget _plRow({
    required String left,
    required double leftAmt,
    required String right,
    required double rightAmt,
    bool boldLeft = false,
    bool boldRight = false,
  }) {
    return Row(
      children: [
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(left: 20),
            child: Text(
              left,
              style: TextStyle(
                fontWeight: boldLeft ? FontWeight.bold : FontWeight.w500,
              ),
            ),
          ),
        ),
        Expanded(
          child: Text(
            leftAmt == 0 ? "" : leftAmt.toStringAsFixed(2),
            textAlign: TextAlign.right,
            style: TextStyle(
              fontWeight: boldLeft ? FontWeight.bold : FontWeight.w500,
            ),
          ),
        ),
        SizedBox(width: 20),
        Container(width: 1, height: 55, color: Colors.black26),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(left: 20),
            child: Text(
              right,
              style: TextStyle(
                fontWeight: boldRight ? FontWeight.bold : FontWeight.w500,
              ),
            ),
          ),
        ),
        Expanded(
          child: Text(
            rightAmt == 0 ? "" : rightAmt.toStringAsFixed(2),
            textAlign: TextAlign.right,
            style: TextStyle(
              fontWeight: boldRight ? FontWeight.bold : FontWeight.w500,
            ),
          ),
        ),
        SizedBox(width: 20),
      ],
    );
  }

  Map<String, double> _groupExpensesBySupplier() {
    final Map<String, double> map = {};

    for (final e in expenseList) {
      final key = e.supplierName.trim();
      map[key] = (map[key] ?? 0) + e.amount;
    }

    return map;
  }

  Map<String, double> _groupIncomeBySupplier() {
    final Map<String, double> map = {};

    for (final e in incomeList) {
      final key = e.supplierName.trim();
      map[key] = (map[key] ?? 0) + e.amount;
    }

    return map;
  }
}

class ProfitLossPdfEngine {
  static Future<void> printPL({
    required CompanyPrintProfile company,
    required DateTime from,
    required DateTime to,
    required double openingStock,
    required double closingStock,
    required double netSales,
    required double netPurchase,
    required double grossProfit,
    required double totalIncome,
    required double totalExpense,
    required double netProfit,
    required Map<String, double> groupedExpenses,
    required Map<String, double> groupedIncome,
  }) async {
    final pdf = pw.Document();

    final logo = await _loadNetImage(company.logoUrl);
    final otherLogo = await _loadNetImage(company.otherlogoUrl);

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(20),
        build: (_) => pw.Container(
          decoration: pw.BoxDecoration(border: pw.Border.all()),
          padding: const pw.EdgeInsets.all(8),
          child: pw.Column(
            children: [
              _header(company, logo, otherLogo),
              pw.SizedBox(height: 8),
              pw.Text(
                "PROFIT & LOSS STATEMENT",
                style: pw.TextStyle(
                  fontWeight: pw.FontWeight.bold,
                  fontSize: 12,
                ),
              ),
              pw.Text(
                "From ${DateFormat('dd-MM-yyyy').format(from)} To ${DateFormat('dd-MM-yyyy').format(to)}",
                style: pw.TextStyle(fontSize: 9),
              ),
              pw.SizedBox(height: 8),
              _plTable(
                openingStock: openingStock,
                closingStock: closingStock,
                netSales: netSales,
                netPurchase: netPurchase,
                grossProfit: grossProfit,
                totalIncome: totalIncome,
                totalExpense: totalExpense,
                netProfit: netProfit,
                groupedExpenses: groupedExpenses,
                groupedIncome: groupedIncome,
              ),
              pw.SizedBox(height: 10),
              _footer(company.name),
            ],
          ),
        ),
      ),
    );

    final bytes = await pdf.save();
    await Printing.layoutPdf(onLayout: (_) async => bytes);
  }

  // ================= HEADER =================
  static pw.Widget _header(
    CompanyPrintProfile c,
    pw.ImageProvider? logo,
    pw.ImageProvider? otherLogo,
  ) {
    return pw.Row(
      children: [
        pw.SizedBox(
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
              pw.Text("GSTIN: ${c.gst}", style: pw.TextStyle(fontSize: 9)),
              pw.Text(
                "Phone: ${c.phone} | Email: ${c.email}",
                style: pw.TextStyle(fontSize: 9),
              ),
            ],
          ),
        ),
        pw.SizedBox(
          width: 60,
          height: 60,
          child: otherLogo != null ? pw.Image(otherLogo) : pw.Container(),
        ),
      ],
    );
  }

  // ================= MAIN TABLE =================
  static pw.Widget _plTable({
    required double openingStock,
    required double closingStock,
    required double netSales,
    required double netPurchase,
    required double grossProfit,
    required double totalIncome,
    required double totalExpense,
    required double netProfit,
    required Map<String, double> groupedExpenses,
    required Map<String, double> groupedIncome,
  }) {
    final expenseEntries = groupedExpenses.entries.toList();
    final incomeEntries = groupedIncome.entries.toList();
    final maxLen = expenseEntries.length > incomeEntries.length
        ? expenseEntries.length
        : incomeEntries.length;

    return pw.Table(
      border: pw.TableBorder.all(),
      columnWidths: const {
        0: pw.FlexColumnWidth(2.5),
        1: pw.FlexColumnWidth(1.2),
        2: pw.FlexColumnWidth(.2),
        3: pw.FlexColumnWidth(2.5),
        4: pw.FlexColumnWidth(1.2),
      },
      children: [
        _rowH("Particulars", "Amount", "Particulars", "Amount"),

        _row("Opening Stock", openingStock, "Sales Accounts", netSales),
        _row("Purchase Accounts", netPurchase, "Closing Stock", closingStock),
        _row("Gross Profit C/F", grossProfit, "", 0, boldLeft: true),

        _row(
          "TOTAL",
          openingStock +
              netPurchase +
              totalExpense +
              (netProfit > 0 ? netProfit : 0),
          "TOTAL",
          netSales + closingStock + (netProfit < 0 ? netProfit.abs() : 0),
          boldLeft: true,
          boldRight: true,
        ),

        _row("", 0, "Gross Profit B/D", grossProfit, boldRight: true),

        for (int i = 0; i < maxLen; i++)
          _row(
            i < expenseEntries.length ? expenseEntries[i].key : "",
            i < expenseEntries.length ? expenseEntries[i].value : 0,
            i < incomeEntries.length ? incomeEntries[i].key : "",
            i < incomeEntries.length ? incomeEntries[i].value : 0,
          ),

        _row(
          "Total Expenses",
          totalExpense,
          "Total Income",
          totalIncome,
          boldLeft: true,
          boldRight: true,
        ),

        netProfit >= 0
            ? _row("Net Profit", netProfit, "", 0, boldLeft: true)
            : _row("", 0, "Net Loss", netProfit.abs(), boldRight: true),
      ],
    );
  }

  static pw.TableRow _rowH(String l1, String l2, String r1, String r2) {
    return pw.TableRow(
      decoration: const pw.BoxDecoration(color: PdfColors.grey300),
      children: [_th(l1), _th(l2), pw.Container(), _th(r1), _th(r2)],
    );
  }

  static pw.TableRow _row(
    String l1,
    double l2,
    String r1,
    double r2, {
    bool boldLeft = false,
    bool boldRight = false,
  }) {
    return pw.TableRow(
      children: [
        _td(l1, bold: boldLeft),
        _td(
          l2 == 0 ? "" : l2.toStringAsFixed(2),
          bold: boldLeft,
          alignRight: true,
        ),
        pw.Container(),
        _td(r1, bold: boldRight),
        _td(
          r2 == 0 ? "" : r2.toStringAsFixed(2),
          bold: boldRight,
          alignRight: true,
        ),
      ],
    );
  }

  static pw.Widget _th(String t) => pw.Padding(
    padding: const pw.EdgeInsets.all(6),
    child: pw.Text(
      t,
      style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9),
    ),
  );

  static pw.Widget _td(
    String t, {
    bool bold = false,
    bool alignRight = false,
  }) => pw.Padding(
    padding: const pw.EdgeInsets.all(6),
    child: pw.Text(
      t,
      textAlign: alignRight ? pw.TextAlign.right : pw.TextAlign.left,
      style: pw.TextStyle(
        fontSize: 9,
        fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal,
      ),
    ),
  );

  static pw.Widget _footer(String companyName) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Text(
          "This is a computer generated statement",
          style: pw.TextStyle(fontSize: 8),
        ),
        pw.Text(
          "For $companyName\nAuthorised Signatory",
          style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold),
        ),
      ],
    );
  }

  static Future<pw.ImageProvider?> _loadNetImage(String url) async {
    if (url.isEmpty) return null;
    try {
      return await networkImage(url);
    } catch (_) {
      return null;
    }
  }
}
