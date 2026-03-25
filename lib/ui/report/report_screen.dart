import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:ims/utils/navigation.dart';

import 'package:ims/ui/home/reminder_screen.dart';
import 'package:ims/ui/report/global/balance_sheet.dart';
import 'package:ims/ui/report/global/day_book.dart';
import 'package:ims/ui/report/global/ledger_balance.dart';
import 'package:ims/ui/report/global/trial_balance.dart';
import 'package:ims/ui/report/inventry/item_party.dart';
import 'package:ims/ui/report/inventry/item_ledger.dart';
import 'package:ims/ui/report/inventry/itemwise_profit.dart';
import 'package:ims/ui/report/inventry/inventry_report.dart';
import 'package:ims/ui/report/purchase/purchase_inv_report.dart';
import 'package:ims/ui/report/purchase/gst_purchase_report.dart';
import 'package:ims/ui/report/sale/sale_inv_report.dart';
import 'package:ims/ui/report/sale/gst_sale_report.dart';
import 'package:ims/ui/report/gst_r1_report/gstr_1_total.dart';
import 'package:ims/ui/report/gst_r2_report/total_gst_r2.dart';
import 'package:ims/ui/report/global/profit_loss.dart';
import 'package:ims/ui/report/global/particular_ledger.dart';
import 'package:ims/ui/report/global/outstanding_report.dart';
import 'package:ims/ui/report/global/bank_book.dart';
import 'package:ims/ui/report/global/cash_book.dart';

class ReportsDashboardScreen extends StatefulWidget {
  const ReportsDashboardScreen({super.key});

  @override
  State<ReportsDashboardScreen> createState() => _ReportsDashboardScreenState();
}

class _ReportsDashboardScreenState extends State<ReportsDashboardScreen> {
  Map<String, List<String>> reports = {
    "Inventory Reports": [
      "Item Report By Party",
      "Item Sales and Purchase Summary",
      "Item Profit/Loss Report",
      "Stock Details Report",
    ],
    "Transaction Reports": [
      "Purchase Invoice Report",
      "Sale Invoice Report",
      "GST Purchase Report",
      "GST Sale Report",
    ],
    "GST Reports": ["GSTR-1", "GSTR-2"],
    "Accounts Reports": [
      "Profit and Loss Report",
      "Ledger Report",
      "OutStanding Report",
      "Ledger Balance Report",
      "Bank Book",
      "Cash Book",
      "Day Book",
      "OutStanding Reminder",
      "Trial Balance",
      "Balance Sheet",
    ],
  };

  List<String> favouriteReports = [];
  void toggleFavourite(String name) async {
    final prefs = await SharedPreferences.getInstance();

    setState(() {
      if (favouriteReports.contains(name)) {
        favouriteReports.remove(name);
      } else {
        favouriteReports.add(name);
      }
    });

    await prefs.setStringList('fav_reports', favouriteReports);
  }

  List<String> getCategoryItems(String category) {
    return reports[category]!
        .where((e) => !favouriteReports.contains(e))
        .toList();
  }

  @override
  void initState() {
    super.initState();
    _loadFavourites();
  }

  Future<void> _loadFavourites() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      favouriteReports = prefs.getStringList('fav_reports') ?? [];
    });
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: [
        /// ⭐ Favourite Reports
        if (favouriteReports.isNotEmpty)
          _ProReportCard(
            title: "Favourite Reports",
            icon: Icons.star,
            items: favouriteReports,
            defaultExpanded: true,
            favouriteReports: favouriteReports,
            onFavouriteTap: toggleFavourite,
            onItemTap: (name) => _navigate(context, name),
          ),

        /// Inventory
        _ProReportCard(
          title: "Inventory Reports",
          icon: Icons.inventory_2_outlined,
          items: getCategoryItems("Inventory Reports"),
          favouriteReports: favouriteReports,
          onFavouriteTap: toggleFavourite,
          onItemTap: (name) => _navigate(context, name),
        ),

        /// Transaction
        _ProReportCard(
          title: "Transaction Reports",
          icon: Icons.swap_horiz_rounded,
          items: getCategoryItems("Transaction Reports"),
          favouriteReports: favouriteReports,
          onFavouriteTap: toggleFavourite,
          onItemTap: (name) => _navigate(context, name),
        ),

        /// GST
        _ProReportCard(
          title: "GST Reports",
          icon: Icons.receipt_long_outlined,
          items: getCategoryItems("GST Reports"),
          favouriteReports: favouriteReports,
          onFavouriteTap: toggleFavourite,
          onItemTap: (name) => _navigate(context, name),
        ),

        /// Accounts
        _ProReportCard(
          title: "Accounts Reports",
          icon: Icons.account_balance_outlined,
          items: getCategoryItems("Accounts Reports"),
          favouriteReports: favouriteReports,
          onFavouriteTap: toggleFavourite,
          onItemTap: (name) => _navigate(context, name),
        ),
      ],
    );
  }

  void _navigate(BuildContext context, String name) {
    if (name == "Item Report By Party") {
      pushTo(PartyLedgerScreen());
    } else if (name == "Item Sales and Purchase Summary") {
      pushTo(ItemLedgerScreen());
    } else if (name == "Item Profit/Loss Report") {
      pushTo(FifoReportScreen());
    } else if (name == "Stock Details Report") {
      pushTo(InventoryAdvancedReportScreen());
    } else if (name == "Purchase Invoice Report") {
      pushTo(PurchaseInvoiceAdvancedReportScreen());
    } else if (name == "GST Purchase Report") {
      pushTo(GstPurchaseReportScreen());
    } else if (name == "Sale Invoice Report") {
      pushTo(SaleInvoiceAdvancedReportScreen());
    } else if (name == "GST Sale Report") {
      pushTo(GstSaleReportScreen());
    } else if (name == "GSTR-1") {
      pushTo(Gstr1DashboardScreen());
    } else if (name == "GSTR-2") {
      pushTo(Gstr2DashboardScreen());
    } else if (name == "Profit and Loss Report") {
      pushTo(ProfitLossScreen());
    } else if (name == "Ledger Report") {
      pushTo(LedgerReportScreen());
    } else if (name == "OutStanding Report") {
      pushTo(OutstandingReportScreen());
    } else if (name == "Ledger Balance Report") {
      pushTo(BalanceReportScreen());
    } else if (name == "Bank Book") {
      pushTo(BankBookReportScreen());
    } else if (name == "Cash Book") {
      pushTo(CashBookReportScreen());
    } else if (name == "Day Book") {
      pushTo(DayBookReportScreen());
    } else if (name == "OutStanding Reminder") {
      pushTo(OutStandingReminder());
    } else if (name == "Trial Balance") {
      pushTo(TrialBalanceScreen());
    } else if (name == "Balance Sheet") {
      pushTo(BalanceSheetAllInOneScreen());
    }
  }
}

class _ProReportCard extends StatefulWidget {
  final String title;
  final List<String> items;
  final Function(String) onItemTap;
  final Function(String) onFavouriteTap;
  final List<String> favouriteReports;
  final IconData icon;
  final bool defaultExpanded;

  const _ProReportCard({
    required this.title,
    required this.items,
    required this.onItemTap,
    required this.onFavouriteTap,
    required this.favouriteReports,
    required this.icon,
    this.defaultExpanded = false,
  });

  @override
  State<_ProReportCard> createState() => _ProReportCardState();
}

class _ProReportCardState extends State<_ProReportCard> {
  late bool isExpanded;

  @override
  void initState() {
    super.initState();
    isExpanded = widget.defaultExpanded;
  }

  @override
  Widget build(BuildContext context) {
    if (widget.items.isEmpty) return const SizedBox();

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(.08),
            blurRadius: 12,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          InkWell(
            onTap: () {
              setState(() => isExpanded = !isExpanded);
            },
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Icon(widget.icon, color: const Color(0xFF8947E5)),

                  const SizedBox(width: 10),

                  Expanded(
                    child: Text(
                      widget.title,
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),

                  AnimatedRotation(
                    turns: isExpanded ? .5 : 0,
                    duration: const Duration(milliseconds: 200),
                    child: const Icon(Icons.keyboard_arrow_down),
                  ),
                ],
              ),
            ),
          ),

          if (isExpanded)
            Column(
              children: widget.items.map((e) {
                bool fav = widget.favouriteReports.contains(e);

                return InkWell(
                  onTap: () => widget.onItemTap(e),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 18,
                      vertical: 10,
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.arrow_right_rounded, size: 18),

                        const SizedBox(width: 6),

                        Expanded(
                          child: Text(
                            e,
                            style: GoogleFonts.inter(fontSize: 13),
                          ),
                        ),

                        IconButton(
                          icon: Icon(
                            fav ? Icons.star : Icons.star_border,
                            color: Colors.amber,
                          ),
                          onPressed: () {
                            widget.onFavouriteTap(e);
                          },
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
        ],
      ),
    );
  }
}
