import 'package:ims/ui/report/global/day_book.dart';
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
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:ims/utils/navigation.dart';

class ReportsDashboardScreen extends StatelessWidget {
  const ReportsDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: [
        _ProReportCard(
          title: "Inventory Reports",
          icon: Icons.inventory_2_outlined,
          items: const [
            "Item Report By Party",
            "Item Sales and Purchase Summary",
            "Item Profit/Loss Report",
            "Stock Details Report",
          ],
          onItemTap: (name) => _navigate(context, name),
        ),
        _ProReportCard(
          title: "Transaction Reports",
          icon: Icons.swap_horiz_rounded,
          items: const [
            "Purchase Invoice Report",
            "Sale Invoice Report",
            "GST Purchase Report",
            "GST Sale Report",
          ],
          onItemTap: (name) => _navigate(context, name),
        ),
        _ProReportCard(
          title: "GST Reports",
          icon: Icons.receipt_long_outlined,
          items: const ["GSTR-1", "GSTR-2"],
          onItemTap: (name) => _navigate(context, name),
        ),
        _ProReportCard(
          title: "Accounts Reports",
          icon: Icons.account_balance_outlined,
          items: const [
            "Profit and Loss Report",
            "Ledger Report",
            "OutStanding Report",
            "Bank Book",
            "Cash Book",
            "Day Book",
          ],
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
    } else if (name == "Bank Book") {
      pushTo(BankBookReportScreen());
    } else if (name == "Cash Book") {
      pushTo(CashBookReportScreen());
    } else if (name == "Day Book") {
      pushTo(DayBookReportScreen());
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("$name screen not linked yet")));
    }
  }
}

// ---------------- Modern Card ----------------
class _ProReportCard extends StatefulWidget {
  final String title;
  final List<String> items;
  final Function(String) onItemTap;
  final IconData icon;

  const _ProReportCard({
    required this.title,
    required this.items,
    required this.onItemTap,
    required this.icon,
  });

  @override
  State<_ProReportCard> createState() => _ProReportCardState();
}

class _ProReportCardState extends State<_ProReportCard> {
  bool isExpanded = false;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, 8),
          ),
        ],
        border: Border.all(color: const Color(0xFF8947E5).withOpacity(0.15)),
      ),
      child: Column(
        children: [
          /// HEADER (always visible)
          InkWell(
            onTap: () {
              setState(() => isExpanded = !isExpanded);
            },
            borderRadius: BorderRadius.circular(18),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: const Color(0xFF8947E5).withOpacity(0.12),
                    ),
                    child: Icon(widget.icon, color: const Color(0xFF8947E5)),
                  ),
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
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF8947E5).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      "${widget.items.length}",
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: const Color(0xFF8947E5),
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  AnimatedRotation(
                    turns: isExpanded ? 0.5 : 0,
                    duration: const Duration(milliseconds: 200),
                    child: const Icon(Icons.keyboard_arrow_down_rounded),
                  ),
                ],
              ),
            ),
          ),

          /// BODY (expandable)
          AnimatedCrossFade(
            duration: const Duration(milliseconds: 200),
            crossFadeState: isExpanded
                ? CrossFadeState.showFirst
                : CrossFadeState.showSecond,
            firstChild: Column(
              children: widget.items
                  .map(
                    (e) => InkWell(
                      onTap: () {
                        widget.onItemTap(e); // 🚀 navigate only
                      },
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          vertical: 10,
                          horizontal: 18,
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.arrow_right_rounded,
                              size: 18,
                              color: Colors.black54,
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                e,
                                style: GoogleFonts.inter(fontSize: 13),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  )
                  .toList(),
            ),
            secondChild: const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }
}
