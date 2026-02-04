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
import 'package:intl/intl.dart';
import '../../utils/api.dart';
import '../../utils/prefence.dart';

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
