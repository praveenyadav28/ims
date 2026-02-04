import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:ims/utils/colors.dart';
import 'menu_screen.dart';

class SideMenu extends StatefulWidget {
  final MenuScreen selected;
  final Function(MenuScreen) onSelect;

  const SideMenu({super.key, required this.selected, required this.onSelect});

  @override
  State<SideMenu> createState() => _SideMenuState();
}

class _SideMenuState extends State<SideMenu> with TickerProviderStateMixin {
  String? expandedKey;

  Color get activeColor => const Color(0xff22CCB2);
  Color get bgColor => AppColor.black;
  Color get tileColor => const Color(0xff20293C);

  // ================= SINGLE MENU =================
  Widget menuItem(String icon, String title, MenuScreen screen) {
    final bool active = widget.selected == screen;

    return InkWell(
      onTap: () => widget.onSelect(screen),
      child: Container(
        height: 77,
        width: double.infinity,
        margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
        decoration: BoxDecoration(
          color: active ? activeColor : tileColor,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SvgPicture.asset(icon, height: 24, color: AppColor.white),
            const SizedBox(height: 6),
            Text(
              title,
              style: GoogleFonts.inter(fontSize: 14, color: AppColor.white),
            ),
          ],
        ),
      ),
    );
  }

  // ================= CHILD ITEM =================
  Widget childItem(String title, MenuScreen screen) {
    final bool active = widget.selected == screen;

    return InkWell(
      onTap: () => widget.onSelect(screen),
      child: Container(
        width: double.infinity,
        margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
        padding: const EdgeInsets.only(top: 8, bottom: 8, left: 4),
        alignment: Alignment.centerLeft,
        decoration: BoxDecoration(
          color: active ? activeColor : tileColor,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(
          title,
          textAlign: TextAlign.center,
          style: GoogleFonts.inter(fontSize: 12, color: AppColor.white),
        ),
      ),
    );
  }

  // ================= EXPANDABLE MENU =================
  Widget expandableMenu({
    required String menuKey,
    required String icon,
    required String title,
    required List<Map<String, MenuScreen>> children,

    bool isPng = false,
  }) {
    final bool isOpen = expandedKey == menuKey;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
      decoration: BoxDecoration(
        color: tileColor,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Column(
        children: [
          InkWell(
            onTap: () {
              setState(() {
                expandedKey = isOpen ? null : menuKey;
              });
            },
            child: Stack(
              alignment: Alignment.centerRight,
              children: [
                Container(
                  height: 77,
                  alignment: Alignment.center,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      isPng
                          ? Image.asset(icon, height: 24, color: AppColor.white)
                          : SvgPicture.asset(
                              icon,
                              height: 24,
                              color: AppColor.white,
                            ),
                      const SizedBox(height: 6),
                      Text(
                        title,
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          color: AppColor.white,
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Icon(
                    isOpen
                        ? Icons.keyboard_arrow_up
                        : Icons.keyboard_arrow_down,
                    size: 20,
                    color: AppColor.white,
                  ),
                ),
              ],
            ),
          ),

          AnimatedSize(
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeInOut,
            child: isOpen
                ? Column(
                    children: children
                        .map((e) => childItem(e.keys.first, e.values.first))
                        .toList(),
                  )
                : const SizedBox(),
          ),
        ],
      ),
    );
  }

  // ================= BUILD =================
  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Container(
        color: bgColor,
        child: Column(
          children: [
            const SizedBox(height: 16),
            const Icon(Icons.blur_on, color: Colors.white),
            const SizedBox(height: 20),

            menuItem(
              "assets/icons/home.svg",
              "Home",
              MenuScreen.dashboardScreen,
            ),

            expandableMenu(
              menuKey: "customers",
              icon: "assets/icons/user.svg",
              title: "Trader",
              children: [
                {"Customer": MenuScreen.customerList},
                {"Supplier": MenuScreen.supplierList},
              ],
            ),

            menuItem(
              "assets/icons/inventry.svg",
              "Inventory",
              MenuScreen.inventoryScreen,
            ),

            expandableMenu(
              menuKey: "sales",
              icon: "assets/icons/sales.svg",
              title: "Sales",
              children: [
                {"Estimate": MenuScreen.estimateList},
                {"Performa Invoice": MenuScreen.performaInvoice},
                {"Delivery": MenuScreen.deliveryChallan},
                {"Sale Invoice": MenuScreen.saleInvoice},
                {"Sales Return": MenuScreen.saleReturn},
                {"Credit Note": MenuScreen.debitNote},
              ],
            ),

            expandableMenu(
              menuKey: "purchase",
              icon: "assets/icons/purchase.svg",
              title: "Purchase",
              children: [
                {"Purchase Order": MenuScreen.purchaseOrder},
                {"Purchase Invoice": MenuScreen.purchaseInvoice},
                {"Purchase Return": MenuScreen.purchaseReturn},
                {"Debit Note": MenuScreen.creditNote},
              ],
            ),

            expandableMenu(
              menuKey: "reports",
              icon: "assets/icons/reports.svg",
              title: "Reports",
              children: [
                {"Ledger Report": MenuScreen.ledgerReport},
                {"Profit/Loss": MenuScreen.profitLoss},
                // {"Supplier Report": MenuScreen.supplierReport},
                {"P Invoice Report": MenuScreen.purchaseInvReport},
                {"S Invoice Report": MenuScreen.saleInvReport},
                {"Inventory Report": MenuScreen.inventoryReport},
              ],
            ),

            expandableMenu(
              menuKey: "vouchers",
              icon: "assets/icons/vouchers.svg",
              title: "Vouchers",
              children: [
                {"Payment": MenuScreen.payment},
                {"Reciept": MenuScreen.reciept},
                {"Expense": MenuScreen.expanse},
                {"Contra": MenuScreen.contra},
                {"Journal": MenuScreen.journal},
              ],
            ),
            expandableMenu(
              menuKey: "employee",
              icon: "assets/icons/employee.png",
              title: "Employees/Users",
              children: [
                {"User": MenuScreen.userMaster},
                {"Employee": MenuScreen.employeeMaster},
              ],
              isPng: true,
            ),

            expandableMenu(
              menuKey: "utils",
              icon: "assets/icons/utils.svg",
              title: "Utilities",
              children: [
                {"Misc Charge": MenuScreen.miscCharge},
                {"Company Profile": MenuScreen.companyProfile},
                {"Ledger": MenuScreen.ledgerMaster},
              ],
            ),

            const SizedBox(height: 20),
            IconButton(
              icon: const Icon(Icons.logout, color: Colors.white),
              onPressed: () {},
            ),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }
}
