import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:ims/model/cussup_model.dart';
import 'package:ims/model/expanse_model.dart';

import 'package:ims/ui/sales/models/sale_invoice_data.dart';
import 'package:ims/ui/sales/models/purcahseinvoice_data.dart';
import 'package:ims/utils/api.dart';
import 'package:ims/utils/colors.dart';
import 'package:ims/utils/prefence.dart';
import 'package:ims/utils/sizes.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  double saleTotal = 0;
  double purchaseTotal = 0;
  double totalExpanse = 0;
  bool loading = true;

  int invoices = 0;
  int purchases = 0;

  // DATA
  List<SaleInvoiceData> saleInvoices = [];
  List<PurchaseInvoiceData> purchaseInvoices = [];
  List<Customer> customers = [];
  List<ExpanseModel> expenses = [];

  // OUTSTANDING
  List<Customer> outstandingList = [];

  // CASHFLOW
  Map<int, double> saleMonthly = {};
  Map<int, double> purchaseMonthly = {};

  @override
  void initState() {
    super.initState();
    loadDashboard();
  }

  Future<void> loadDashboard() async {
    await Future.wait([
      loadSaleTotal(),
      loadPurchaseTotal(),
      loadCustomers(),
      fetchExpenses(),
    ]);

    buildOutstanding();
    buildCashFlow();

    setState(() => loading = false);
  }

  // ================= API CALLS =================

  Future<void> loadSaleTotal() async {
    final res = await ApiService.fetchData(
      "get/invoice",
      licenceNo: Preference.getint(PrefKeys.licenseNo),
    );

    if (res == null) return;

    final parsed = SaleInvoiceListResponse.fromJson(res);
    saleInvoices = parsed.data;

    invoices = saleInvoices.length;
    saleTotal = saleInvoices.fold(0, (p, e) => p + e.totalAmount);
  }

  Future<void> loadPurchaseTotal() async {
    final res = await ApiService.fetchData(
      "get/purchaseinvoice",
      licenceNo: Preference.getint(PrefKeys.licenseNo),
    );

    if (res == null) return;

    final parsed = PurchaseInvoiceListResponse.fromJson(res);
    purchaseInvoices = parsed.data;

    purchases = purchaseInvoices.length;
    purchaseTotal = purchaseInvoices.fold(0, (p, e) => p + e.totalAmount);
  }

  Future<void> loadCustomers() async {
    final res = await ApiService.fetchData(
      "get/customer",
      licenceNo: Preference.getint(PrefKeys.licenseNo),
    );

    if (res == null) return;

    final List list = res['data'] ?? [];
    customers = list.map((e) => Customer.fromJson(e)).toList();
  }

  Future<void> fetchExpenses() async {
    final res = await ApiService.fetchData(
      'get/expense',
      licenceNo: Preference.getint(PrefKeys.licenseNo),
    );

    if (res == null) return;

    expenses = (res['data'] as List)
        .map((e) => ExpanseModel.fromJson(e))
        .toList();
    totalExpanse = expenses.fold(0, (p, e) => p + e.amount);
  }

  // ================= LOGIC =================

  void buildOutstanding() {
    outstandingList = customers.where((c) => c.closingBalance < 0).toList();

    outstandingList.sort(
      (a, b) => b.closingBalance.abs().compareTo(a.closingBalance.abs()),
    );
  }

  void buildCashFlow() {
    saleMonthly.clear();
    purchaseMonthly.clear();

    for (var e in saleInvoices) {
      final m = e.saleInvoiceDate.month;
      saleMonthly[m] = (saleMonthly[m] ?? 0) + e.totalAmount;
    }

    for (var e in purchaseInvoices) {
      final m = e.purchaseInvoiceDate.month;
      purchaseMonthly[m] = (purchaseMonthly[m] ?? 0) + e.totalAmount;
    }
  }

  // ======================================================
  // ========================== UI ========================
  // ======================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColor.white,
      appBar: AppBar(
        backgroundColor: AppColor.black,
        title: Text(
          "Dashboard",
          style: GoogleFonts.inter(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: AppColor.white,
          ),
        ),
        centerTitle: true,
        actions: [
          Row(
            children: [
              // _topButton("+ Quick Create", color: AppColor.blue),
              // _topButton("Date Range"),
              // _topButton("This Month"),
              const SizedBox(width: 10),
              InkWell(
                onTap: () => showProfilePopup(context),
                child: SvgPicture.asset(
                  "assets/icons/accountCircle.svg",
                  height: 34,
                  width: 34,
                ),
              ),
              const SizedBox(width: 15),
            ],
          ),
        ],
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        // LEFT
                        Expanded(
                          flex: 3,
                          child: Column(
                            children: [
                              Row(
                                children: [
                                  _statCard(
                                    title: "Total Sale",
                                    amount: "₹ ${saleTotal.toStringAsFixed(2)}",
                                    subtitle: "$invoices Invoices",
                                    color: const Color(0xffD1FAE5),
                                  ),
                                  _statCard(
                                    title: "Total Purchase",
                                    amount:
                                        "₹ ${purchaseTotal.toStringAsFixed(2)}",
                                    subtitle: "$purchases Invoices",
                                    color: const Color(0xffFEE2E2),
                                  ),
                                  _statCard(
                                    title: "Total Expanse",
                                    amount: "₹ $totalExpanse",
                                    subtitle: "",
                                    color: const Color(0xffFECACA),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              _graphCard(),
                              const SizedBox(height: 16),
                              Expanded(
                                child: Row(
                                  children: [
                                    _reminderList(),
                                    const SizedBox(width: 16),
                                    _expenseList(),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 16),
                        // RIGHT
                        Expanded(
                          flex: 1,
                          child: Container(
                            decoration: BoxDecoration(
                              color: const Color.fromARGB(255, 206, 202, 202),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Center(
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xff7C3AED),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(30),
                                  ),
                                ),
                                onPressed: () {},
                                child: const Text(
                                  "Add Screen of your choice +",
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  // ===================== WIDGETS =====================

  Widget _topButton(String title, {Color? color}) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: color ?? const Color(0xff1E293B),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
        ),
        onPressed: () {},
        child: Text(title),
      ),
    );
  }

  Widget _statCard({
    required String title,
    required String amount,
    required String subtitle,
    required Color color,
  }) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.only(right: 16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              amount,
              style: GoogleFonts.inter(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 6),
            Text(subtitle, style: GoogleFonts.inter(fontSize: 12)),
          ],
        ),
      ),
    );
  }

  // ================= CASH FLOW =================

  Widget _graphCard() {
    return Container(
      height: 280,
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xff111827),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Cash Flow Graph",
            style: GoogleFonts.inter(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 20),
          Expanded(child: _cashFlowBars()),
        ],
      ),
    );
  }

  Widget _cashFlowBars() {
    final months = List.generate(12, (i) => i + 1);

    double maxVal = 0;
    for (var m in months) {
      maxVal = max(maxVal, max(saleMonthly[m] ?? 0, purchaseMonthly[m] ?? 0));
    }
    if (maxVal == 0) maxVal = 1;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: months.map((m) {
        final sale = saleMonthly[m] ?? 0;
        final purchase = purchaseMonthly[m] ?? 0;

        final saleH = (sale / maxVal) * 160;
        final purH = (purchase / maxVal) * 160;

        return Expanded(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Container(width: 8, height: saleH, color: Colors.greenAccent),
                  const SizedBox(width: 4),
                  Container(width: 8, height: purH, color: Colors.redAccent),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                _monthName(m),
                style: const TextStyle(color: Colors.white54, fontSize: 10),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  String _monthName(int m) {
    const list = [
      "Jan",
      "Feb",
      "Mar",
      "Apr",
      "May",
      "Jun",
      "Jul",
      "Aug",
      "Sep",
      "Oct",
      "Nov",
      "Dec",
    ];
    return list[m - 1];
  }

  // ================= OUTSTANDING =================

  Widget _reminderList() {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xff111827),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Outstanding Reminders",
              style: GoogleFonts.inter(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),

            if (outstandingList.isEmpty)
              const Text(
                "No Outstanding",
                style: TextStyle(color: Colors.white54),
              ),

            ...outstandingList
                .take(5)
                .map(
                  (c) => _reminder(
                    c.companyName.isNotEmpty ? c.companyName : c.firstName,
                    "₹ ${c.closingBalance.abs()}",
                    true,
                  ),
                ),
          ],
        ),
      ),
    );
  }

  Widget _reminder(String name, String amount, bool danger) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            name,
            style: GoogleFonts.inter(color: danger ? Colors.red : Colors.white),
          ),
          Text(
            amount,
            style: GoogleFonts.inter(color: danger ? Colors.red : Colors.white),
          ),
        ],
      ),
    );
  }

  // ================= EXPENSE LIST =================

  Widget _expenseList() {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xff111827),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Big Expenses List",
                  style: GoogleFonts.inter(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                // Chip(
                //   backgroundColor: const Color(0xff7C3AED),
                //   label: Text(
                //     "Weekly",
                //     style: GoogleFonts.inter(color: Colors.white),
                //   ),
                // ),
              ],
            ),
            const SizedBox(height: 12),
            if (expenses.isEmpty)
              const Text(
                "No Expenses",
                style: TextStyle(color: Colors.white54),
              ),

            ...expenses
                .take(5)
                .map(
                  (e) => _expense(
                    e.supplierName,
                    "₹ ${e.amount.toStringAsFixed(0)}",
                  ),
                ),
          ],
        ),
      ),
    );
  }

  Widget _expense(String title, String amount) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: GoogleFonts.inter(color: Colors.white)),
          Text(amount, style: GoogleFonts.inter(color: Colors.red)),
        ],
      ),
    );
  }

  // ================= PROFILE POPUP =================

  void showProfilePopup(BuildContext context) {
    showMenu(
      context: context,
      position: RelativeRect.fromLTRB(Sizes.width, kToolbarHeight, 10, 0),
      items: [PopupMenuItem(enabled: false, child: _profileCard())],
      elevation: 0,
      color: Colors.transparent,
    );
  }

  Widget _profileCard() {
    return Container(
      width: 295,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.image, size: 40),
          const SizedBox(height: 6),
          const Text("#User ID", style: TextStyle(fontWeight: FontWeight.w600)),
          const Divider(thickness: 1),
          _row(
            "License Number",
            Preference.getint(PrefKeys.licenseNo).toString(),
          ),
          _row("Company Name", "Modern Software"),
          _row("Owner Name", "Kapil"),
          _row("Address", Preference.getString(PrefKeys.branchAddress)),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xffF2F3F7),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Center(
              child: Text(
                "Validity   2023-01-15  -  2024-01-14",
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _row(String title, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 4,
            child: Text(
              title,
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ),
          Expanded(
            flex: 6,
            child: Text(
              value,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}
