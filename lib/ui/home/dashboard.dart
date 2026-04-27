import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:ims/model/expanse_model.dart';
import 'package:ims/model/ledger_model.dart';
import 'package:ims/ui/purchase/purchase_invoice/purchase_invoice_list.dart';
import 'package:ims/ui/report/report_screen.dart';
import 'package:ims/ui/sales/models/sale_invoice_data.dart';
import 'package:ims/ui/sales/models/purcahseinvoice_data.dart';
import 'package:ims/ui/sales/sale_invoice/sale_invoice_list.dart';
import 'package:ims/ui/sales/sale_invoice/saleinvoice_create.dart';
import 'package:ims/ui/voucher/expanse/expanse_list.dart';
import 'package:ims/utils/access.dart';
import 'package:ims/utils/api.dart';
import 'package:ims/utils/colors.dart';
import 'package:ims/utils/navigation.dart';
import 'package:ims/utils/prefence.dart';
import 'package:ims/utils/sizes.dart';
import 'package:ims/utils/snackbar.dart';

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

  List<SaleInvoiceData> saleInvoices = [];
  List<PurchaseInvoiceData> purchaseInvoices = [];
  List<ExpanseModel> expenses = [];

  Map<int, double> saleMonthly = {};
  Map<int, double> purchaseMonthly = {};

  List<LedgerListModel> ledgerList = [];

  @override
  void initState() {
    super.initState();
    if (hasMenuAccess("Dashboard")) {
      initDashboard();
    } else {
      loading = false;
    }
  }

  Future<void> initDashboard() async {
    await loadTotalAmount();

    await loadSalePurchaseGraph(); // 🔥 wait karo

    setState(() => loading = false);

    // background me baaki
    Future.microtask(() async {
      await Future.wait([fetchExpenses(), loadOutStandingData()]);
      setState(() {});
    });
  }

  // ================= NEW TOTAL API =================
  Future<void> loadTotalAmount() async {
    final res = await ApiService.fetchData(
      "get/getTotalAmount",
      licenceNo: Preference.getint(PrefKeys.licenseNo),
    );

    if (res == null) return;

    final data = res['data'];

    saleTotal = double.tryParse(data['saleTotal'].toString()) ?? 0;
    purchaseTotal = double.tryParse(data['purchaseTotal'].toString()) ?? 0;
    totalExpanse = double.tryParse(data['expanseTotal'].toString()) ?? 0;
  }
  // ================= OLD METHODS (UNCHANGED) =================

  Future<void> loadOutStandingData() async {
    final ledRes = await ApiService.fetchData(
      "get/ledger",
      licenceNo: Preference.getint(PrefKeys.licenseNo),
    );
    if (ledRes == null) return;
    ledgerList = (ledRes['data'] as List)
        .map((e) => LedgerListModel.fromJson(e))
        .where((l) {
          return ((l.closingBalance ?? 0) > 0) &&
              l.ledgerGroup == "Sundry Debtor";
        })
        .toList();
  }

  Future<void> loadSalePurchaseGraph() async {
    final res = await ApiService.fetchData(
      "get/salepurchase",
      licenceNo: Preference.getint(PrefKeys.licenseNo),
    );

    if (res == null) return;
    final List data = res['data'];

    saleMonthly.clear();
    purchaseMonthly.clear();

    for (var e in data) {
      final month = (e['month'] as num).toInt();

      saleMonthly[month] = (e['sale'] as num).toDouble();
      purchaseMonthly[month] = (e['purchase'] as num).toDouble();
    }
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

    // 🔥 only latest 5 (UI same)
    if (expenses.length > 5) {
      expenses = expenses.reversed.take(5).toList();
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
          ? Center(child: GlowLoader())
          : Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        // LEFT
                        Expanded(
                          flex: 5,
                          child: Column(
                            children: [
                              Row(
                                children: [
                                  _statCard(
                                    title: "Total Sale",
                                    amount: "₹ ${saleTotal.toStringAsFixed(2)}",
                                    subtitle: "",
                                    color: const Color(0xffD1FAE5),
                                    onTap: () async {
                                      if (hasModuleAccess(
                                        "Sale Invoice",
                                        "view",
                                      )) {
                                        var data = await pushTo(
                                          SaleInvoiceInvoiceListScreen(
                                            canBack: true,
                                          ),
                                        );
                                        if (data != null) {
                                          await initDashboard();
                                          setState(() {});
                                        }
                                      } else {
                                        showCustomSnackbarError(
                                          context,
                                          "Access Denied",
                                        );
                                      }
                                    },
                                  ),
                                  _statCard(
                                    title: "Total Purchase",
                                    amount:
                                        "₹ ${purchaseTotal.toStringAsFixed(2)}",
                                    subtitle: "",
                                    color: const Color(0xffFEE2E2),
                                    onTap: () async {
                                      if (hasModuleAccess(
                                        "Purchase Invoice",
                                        "view",
                                      )) {
                                        var data = await pushTo(
                                          PurchaseInvoiceListScreen(
                                            canBack: true,
                                          ),
                                        );
                                        if (data != null) {
                                          await initDashboard();
                                          setState(() {});
                                        }
                                      } else {
                                        showCustomSnackbarError(
                                          context,
                                          "Access Denied",
                                        );
                                      }
                                    },
                                  ),
                                  _statCard(
                                    title: "Total Expanse",
                                    amount: "₹ $totalExpanse",
                                    subtitle: "",
                                    color: const Color(0xffFECACA),
                                    onTap: () async {
                                      if (hasModuleAccess(
                                        "Expense Voucher",
                                        "View",
                                      )) {
                                        var data = await pushTo(
                                          ExpanseListTableScreen(
                                            canBack: true,
                                          ),
                                        );
                                        if (data != null) {
                                          await initDashboard();
                                          setState(() {});
                                        }
                                      } else {
                                        showCustomSnackbarError(
                                          context,
                                          "Access Denied",
                                        );
                                      }
                                    },
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
                              SizedBox(height: 15),
                              InkWell(
                                borderRadius: BorderRadius.circular(12),
                                onTap: () async {
                                  if (hasModuleAccess(
                                    "Sale Invoice",
                                    "create",
                                  )) {
                                    var data = await pushTo(
                                      CreateSaleInvoiceFullScreen(),
                                    );
                                    if (data != null) {
                                      await initDashboard();
                                      setState(() {});
                                    }
                                  } else {
                                    showCustomSnackbarError(
                                      context,
                                      "Access Denied",
                                    );
                                  }
                                },
                                child: Container(
                                  height: 45,
                                  width: 210,
                                  alignment: Alignment.center,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(12),
                                    gradient: const LinearGradient(
                                      colors: [
                                        Color(0xff1AB39B),
                                        Color(0xff22CCB2),
                                        Color(0xff5FE0CD),
                                      ],
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.purple.withOpacity(0.5),
                                        blurRadius: 12,
                                        spreadRadius: 1,
                                        offset: const Offset(0, 6),
                                      ),
                                    ],
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      const Icon(
                                        Icons.receipt_long,
                                        color: Colors.white,
                                        size: 20,
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        "Sale Invoice",
                                        style: GoogleFonts.inter(
                                          fontSize: 15,
                                          fontWeight: FontWeight.w600,
                                          color: AppColor.white,
                                          letterSpacing: 0.5,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 16),
                        // RIGHT
                        Expanded(flex: 2, child: ReportsDashboardScreen()),
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  // // ===================== WIDGETS =====================

  // Widget _topButton(String title, {Color? color}) {
  //   return Padding(
  //     padding: const EdgeInsets.only(right: 8),
  //     child: ElevatedButton(
  //       style: ElevatedButton.styleFrom(
  //         backgroundColor: color ?? const Color(0xff1E293B),
  //         shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
  //       ),
  //       onPressed: () {},
  //       child: Text(title),
  //     ),
  //   );
  // }

  Widget _statCard({
    required String title,
    required String amount,
    required String subtitle,
    required Color color,
    required Function()? onTap,
  }) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
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
      ),
    );
  }

  // ================= CASH FLOW =================

  Widget _graphCard() {
    return Container(
      height: 180,
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
          const SizedBox(height: 10),
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

    return saleMonthly.isEmpty &&
            purchaseMonthly.isEmpty &&
            hasMenuAccess("Dashboard")
        ? Center(child: CircularProgressIndicator())
        : Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: months.map((m) {
              final sale = saleMonthly[m] ?? 0;
              final purchase = purchaseMonthly[m] ?? 0;

              final saleH = (sale / maxVal) * 100;
              final purH = (purchase / maxVal) * 100;

              return Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Container(
                          width: 8,
                          height: saleH,
                          color: Colors.greenAccent,
                        ),
                        const SizedBox(width: 4),
                        Container(
                          width: 8,
                          height: purH,
                          color: Colors.redAccent,
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      _monthName(m),
                      style: const TextStyle(
                        color: Colors.white54,
                        fontSize: 10,
                      ),
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

  // ================= EXPENSE LIST =================

  Widget _expenseList() {
    return Expanded(
      child: Container(
        height: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xff111827),
          borderRadius: BorderRadius.circular(12),
        ),
        child: SingleChildScrollView(
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
          _row("Company Name", Preference.getString(PrefKeys.branchName)),
          _row("Address", Preference.getString(PrefKeys.branchAddress)),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xffF2F3F7),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
              child: Text(
                "Validity  -  ${Preference.getString(PrefKeys.amcDueDate)}",
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

  Widget _reminderList() {
    ScrollController _scrollController = ScrollController();
    return Expanded(
      child: Container(
        height: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
        decoration: BoxDecoration(
          color: const Color(0xff111827),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Scrollbar(
          controller: _scrollController,
          trackVisibility: true,
          thumbVisibility: true,
          child: SingleChildScrollView(
            controller: _scrollController,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Outstanding",
                  style: GoogleFonts.inter(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 12),

                if (ledgerList.isEmpty)
                  const Text(
                    "No Pending Reminders",
                    style: TextStyle(color: Colors.white54),
                  ),
                ...ledgerList
                    .take(5)
                    .map(
                      (r) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              r.ledgerName ?? "",
                              style: GoogleFonts.inter(
                                color: Colors.red,
                                fontWeight: FontWeight.w600,
                              ),
                            ),

                            Text(
                              "₹ ${r.closingBalance!.abs()}",
                              style: GoogleFonts.inter(
                                color: Colors.red,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
