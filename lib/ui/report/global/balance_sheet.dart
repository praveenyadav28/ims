import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:ims/utils/api.dart';
import 'package:ims/utils/prefence.dart';
import 'package:ims/utils/colors.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:pdf/pdf.dart';
import 'package:printing/printing.dart';

class BalanceSheetAllInOneScreen extends StatefulWidget {
  const BalanceSheetAllInOneScreen({super.key});

  @override
  State<BalanceSheetAllInOneScreen> createState() =>
      _BalanceSheetAllInOneScreenState();
}

class _BalanceSheetAllInOneScreenState
    extends State<BalanceSheetAllInOneScreen> {
  DateTime asOn = DateTime.now();
  final asOnCtrl = TextEditingController();

  bool loading = false;

  // ===== P&L + FIFO derived =====
  double openingStock = 0;
  double closingStock = 0;

  double totalSale = 0;
  double totalSaleReturn = 0;
  double totalPurchase = 0;
  double totalPurchaseReturn = 0;

  double totalIncome = 0;
  double totalExpense = 0;

  double netSales = 0;
  double netPurchase = 0;
  double grossProfit = 0;
  double netProfit = 0;

  // ===== Balance Sheet =====
  final Map<String, List<_BSRow>> liabilities = {};
  final Map<String, List<_BSRow>> assets = {};
  final Map<String, double> liabTotals = {};
  final Map<String, double> assetTotals = {};
  double totalLiab = 0;
  double totalAsset = 0;

  @override
  void initState() {
    super.initState();
    asOnCtrl.text = DateFormat("yyyy-MM-dd").format(asOn);
    loadAll();
  }

  String _fmt(DateTime d) => DateFormat("yyyy-MM-dd").format(d);

  // ================= MASTER LOADER =================
  Future<void> loadAll() async {
    setState(() => loading = true);

    await _fetchStock();
    await _fetchTransactions();
    await _fetchExpenses();
    await _fetchIncome();

    _calculatePL();
    await _fetchBalanceSheet();

    setState(() => loading = false);
  }

  // ================= FIFO =================
  Future<void> _fetchStock() async {
    final from = DateTime(asOn.year, 4, 1);
    final res = await ApiService.fetchData(
      "get/fiforeports?from_date=${_fmt(from)}&to_date=${_fmt(asOn)}",
      licenceNo: Preference.getint(PrefKeys.licenseNo),
    );

    openingStock = 0;
    closingStock = 0;

    for (final e in (res['data'] as List)) {
      openingStock += toDouble(e['opening_stock'].toString());
      closingStock += toDouble(e['closing_stock'].toString());
    }
  }

  // ================= TRANSACTIONS =================
  Future<void> _fetchTransactions() async {
    final sales = await ApiService.fetchData(
      "get/invoice",
      licenceNo: Preference.getint(PrefKeys.licenseNo),
    );
    final saleReturns = await ApiService.fetchData(
      "get/returnsale",
      licenceNo: Preference.getint(PrefKeys.licenseNo),
    );
    final purchases = await ApiService.fetchData(
      "get/purchaseinvoice",
      licenceNo: Preference.getint(PrefKeys.licenseNo),
    );
    final purchaseReturns = await ApiService.fetchData(
      "get/purchasereturn",
      licenceNo: Preference.getint(PrefKeys.licenseNo),
    );

    totalSale = (sales['data'] as List)
        .where((e) => !_isAfterAsOn(e['invoice_date']))
        .fold(0.0, (s, e) => s + toDouble(e['sub_total'].toString()));

    totalSaleReturn = (saleReturns['data'] as List)
        .where((e) => !_isAfterAsOn(e['returnsale_date']))
        .fold(0.0, (s, e) => s + toDouble(e['sub_total'].toString()));

    totalPurchase = (purchases['data'] as List)
        .where((e) => !_isAfterAsOn(e['purchaseinvoice_date']))
        .fold(0.0, (s, e) => s + toDouble(e['sub_total'].toString()));

    totalPurchaseReturn = (purchaseReturns['data'] as List)
        .where((e) => !_isAfterAsOn(e['return_date']))
        .fold(0.0, (s, e) => s + toDouble(e['sub_total'].toString()));
  }

  bool _isAfterAsOn(String dateStr) {
    final d = DateTime.parse(dateStr);
    return d.isAfter(asOn);
  }

  // ================= EXPENSE =================
  Future<void> _fetchExpenses() async {
    final res = await ApiService.fetchData(
      "get/expense",
      licenceNo: Preference.getint(PrefKeys.licenseNo),
    );

    totalExpense = (res['data'] as List)
        .where((e) => !DateTime.parse(e['date']).isAfter(asOn))
        .fold(0.0, (s, e) => s + toDouble(e['amount'].toString()));
  }

  // ================= INCOME =================
  Future<void> _fetchIncome() async {
    final res = await ApiService.fetchData(
      "get/reciept",
      licenceNo: Preference.getint(PrefKeys.licenseNo),
    );

    totalIncome = (res['data'] as List)
        .where(
          (e) =>
              e['other1'] == "Income" &&
              !DateTime.parse(e['date']).isAfter(asOn),
        )
        .fold(0.0, (s, e) => s + toDouble(e['amount'].toString()));
  }

  void _calculatePL() {
    netSales = totalSale - totalSaleReturn;
    netPurchase = totalPurchase - totalPurchaseReturn;
    grossProfit = netSales + closingStock - openingStock - netPurchase;
    netProfit = grossProfit + totalIncome - totalExpense;
  }

  // ================= BALANCE SHEET =================
  String _bsHead(String rawGroup) {
    if (rawGroup == 'Capital') return 'Capital Account';
    if (rawGroup == 'Sundry Creditor') return 'Sundry Creditors';
    if (rawGroup == 'Loans (Liability)') return 'Loans (Liability)';
    if (rawGroup == 'Bank Account' ||
        rawGroup == 'Cash In Hand' ||
        rawGroup == 'Sundry Debtor')
      return 'Current Assets';
    if (rawGroup == 'Fixed Asset') return 'Fixed Assets';
    return '';
  }

  Future<void> _fetchBalanceSheet() async {
    final res = await ApiService.fetchData(
      "get/ledgers?from_date=1900-01-01&to_date=${_fmt(asOn)}",
      licenceNo: Preference.getint(PrefKeys.licenseNo),
    );

    liabilities.clear();
    assets.clear();
    liabTotals.clear();
    assetTotals.clear();
    totalLiab = 0;
    totalAsset = 0;

    for (final e in (res['data'] as List)) {
      final name = e['ledger_name'] ?? '';
      final rawGroup = e['ledger_group'] ?? '';
      final bal = toDouble(e['closing_balance'].toString());
      final head = _bsHead(rawGroup);

      if (head.isEmpty) continue;

      if (head == 'Current Assets' || head == 'Fixed Assets') {
        if (bal > 0) _addAsset(head, name, bal);
      } else {
        if (bal < 0) _addLiab(head, name, bal.abs());
      }
    }

    // Closing Stock
    if (closingStock > 0)
      _addAsset('Closing Stock', 'Closing Stock', closingStock);

    // Net Profit / Loss
    if (netProfit >= 0) {
      _addLiab('Capital Account', 'Net Profit', netProfit);
    } else {
      _addAsset('Current Assets', 'Net Loss', netProfit.abs());
    }
  }

  void _addAsset(String head, String name, double amt) {
    assets.putIfAbsent(head, () => []);
    assets[head]!.add(_BSRow(name, amt, isCr: false));
    assetTotals[head] = (assetTotals[head] ?? 0) + amt;
    totalAsset += amt;
  }

  void _addLiab(String head, String name, double amt) {
    liabilities.putIfAbsent(head, () => []);
    liabilities[head]!.add(_BSRow(name, amt, isCr: true));
    liabTotals[head] = (liabTotals[head] ?? 0) + amt;
    totalLiab += amt;
  }

  // ================= UI =================
  @override
  Widget build(BuildContext context) {
    // final balanced = (totalAsset - totalLiab).abs() < 1;

    return Scaffold(
      backgroundColor: AppColor.backgroundColor,
      appBar: AppBar(
        backgroundColor: AppColor.primary,
        title: const Text("Balance Sheet"),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: loadAll),
          IconButton(icon: const Icon(Icons.print), onPressed: _printPdf),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            _filterBar(),
            const SizedBox(height: 8),
            if (loading) const LinearProgressIndicator(),
            const SizedBox(height: 8),
            Expanded(
              child: Row(
                children: [
                  _side("Liabilities", liabilities, liabTotals, totalLiab),
                  const VerticalDivider(width: 1),
                  _side("Assets", assets, assetTotals, totalAsset),
                ],
              ),
            ),
            // _matchBadge(balanced),
          ],
        ),
      ),
    );
  }

  Widget _filterBar() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: _cardDeco(),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: asOnCtrl,
              readOnly: true,
              onTap: () async {
                final d = await showDatePicker(
                  context: context,
                  initialDate: asOn,
                  firstDate: DateTime(2000),
                  lastDate: DateTime(2100),
                );
                if (d != null) {
                  setState(() {
                    asOn = d;
                    asOnCtrl.text = _fmt(d);
                  });
                  loadAll();
                }
              },
              decoration: const InputDecoration(
                labelText: "As On Date",
                suffixIcon: Icon(Icons.calendar_month),
                border: OutlineInputBorder(),
              ),
            ),
          ),
          const SizedBox(width: 12),
          ElevatedButton(
            onPressed: loadAll,
            style: ElevatedButton.styleFrom(backgroundColor: AppColor.primary),
            child: const Text("View"),
          ),
        ],
      ),
    );
  }

  Widget _side(
    String title,
    Map<String, List<_BSRow>> data,
    Map<String, double> totals,
    double grand,
  ) {
    return Expanded(
      child: Container(
        decoration: _cardDeco(),
        child: Column(
          children: [
            _sideHeader(title),
            Expanded(
              child: ListView(
                children: data.entries.map((e) {
                  final head = e.key;
                  final rows = e.value;
                  final sum = totals[head] ?? 0;
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _headRow(head, sum),
                      ...rows.map(_row).toList(),
                      const Divider(height: 1),
                    ],
                  );
                }).toList(),
              ),
            ),
            _totalRow(grand),
          ],
        ),
      ),
    );
  }

  Widget _sideHeader(String t) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(10),
    decoration: BoxDecoration(
      color: AppColor.primary,
      borderRadius: const BorderRadius.vertical(top: Radius.circular(10)),
    ),
    child: Text(
      t,
      textAlign: TextAlign.center,
      style: GoogleFonts.inter(
        color: Colors.white,
        fontWeight: FontWeight.w700,
      ),
    ),
  );

  Widget _headRow(String t, double amt) => Container(
    color: Colors.grey.shade200,
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
    child: Row(
      children: [
        Expanded(
          child: Text(t, style: GoogleFonts.inter(fontWeight: FontWeight.w700)),
        ),
        Text(
          amt.toStringAsFixed(2),
          style: GoogleFonts.inter(fontWeight: FontWeight.w700),
        ),
      ],
    ),
  );

  Widget _row(_BSRow r) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
    child: Row(
      children: [
        Expanded(child: Text(r.name)),
        Text("${r.amount.toStringAsFixed(2)} ${r.isCr ? "Cr" : "Dr"}"),
      ],
    ),
  );

  Widget _totalRow(double total) => Container(
    padding: const EdgeInsets.all(12),
    decoration: const BoxDecoration(border: Border(top: BorderSide(width: 2))),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text("Total", style: GoogleFonts.inter(fontWeight: FontWeight.w700)),
        Text(
          total.toStringAsFixed(2),
          style: GoogleFonts.inter(fontWeight: FontWeight.w700),
        ),
      ],
    ),
  );

  // Widget _matchBadge(bool ok) => Padding(
  //   padding: const EdgeInsets.symmetric(vertical: 6),
  //   child: Row(
  //     mainAxisAlignment: MainAxisAlignment.center,
  //     children: [
  //       Icon(
  //         ok ? Icons.check_circle : Icons.error,
  //         color: ok ? Colors.green : Colors.red,
  //       ),
  //       const SizedBox(width: 6),
  //       Text(
  //         ok ? "Balance Sheet Matched" : "Not Matched",
  //         style: GoogleFonts.inter(fontWeight: FontWeight.w700),
  //       ),
  //     ],
  //   ),
  // );

  BoxDecoration _cardDeco() => BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(10),
    border: Border.all(color: AppColor.borderColor),
    boxShadow: const [BoxShadow(color: Color(0xff171a1f14), blurRadius: 4)],
  );
  Future<void> _printPdf() async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(20),
        build: (_) => [
          pw.Text(
            "Balance Sheet",
            style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold),
          ),
          pw.Text("As on ${DateFormat('dd-MM-yyyy').format(asOn)}"),
          pw.SizedBox(height: 12),

          pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Expanded(
                child: _pdfSide("Liabilities", liabilities, liabTotals),
              ),
              pw.SizedBox(width: 10),
              pw.Expanded(child: _pdfSide("Assets", assets, assetTotals)),
            ],
          ),

          pw.Divider(),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text("Total Liabilities: ${totalLiab.toStringAsFixed(2)}"),
              pw.Text("Total Assets: ${totalAsset.toStringAsFixed(2)}"),
            ],
          ),
        ],
      ),
    );

    await Printing.layoutPdf(onLayout: (_) async => pdf.save());
  }

  pw.Widget _pdfSide(
    String title,
    Map<String, List<_BSRow>> data,
    Map<String, double> totals,
  ) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          title,
          style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 14),
        ),
        pw.SizedBox(height: 6),
        ...data.entries.map((e) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                "${e.key}  ${totals[e.key]!.toStringAsFixed(2)}",
                style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
              ),
              ...e.value.map(
                (r) => pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text(r.name),
                    pw.Text(r.amount.toStringAsFixed(2)),
                  ],
                ),
              ),
              pw.SizedBox(height: 6),
            ],
          );
        }).toList(),
      ],
    );
  }

  double toDouble(dynamic v) {
    if (v == null) return 0.0;
    if (v is num) return v.toDouble();
    final s = v.toString().trim();
    if (s.isEmpty) return 0.0;
    return double.tryParse(s) ?? 0.0;
  }
}

class _BSRow {
  final String name;
  final double amount;
  final bool isCr;
  _BSRow(this.name, this.amount, {this.isCr = false});
}
