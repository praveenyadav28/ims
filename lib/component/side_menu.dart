import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:ims/ui/onboarding/splash_screen.dart';
import 'package:ims/utils/access.dart';
import 'package:ims/utils/colors.dart';
import 'package:ims/utils/navigation.dart';
import 'package:ims/utils/prefence.dart';
import 'package:ims/utils/snackbar.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'menu_screen.dart';

class SideMenu extends StatefulWidget {
  final MenuScreen selected;
  final Function(MenuScreen) onSelect;

  const SideMenu({super.key, required this.selected, required this.onSelect});

  @override
  State<SideMenu> createState() => _SideMenuState();
}

class _SideMenuState extends State<SideMenu> {
  String? expandedKey;

  Color get activeColor => const Color(0xff22CCB2);
  Color get bgColor => AppColor.black;
  Color get tileColor => const Color(0xff20293C);

  // ================= ACCESS CHECK =================
  bool canAccessMenu({String? menuRight, String? module}) {
    if (isAdmin()) return true;

    if (menuRight != null && hasMenuAccess(menuRight)) return true;

    if (module != null && hasModuleAccess(module, "view")) return true;

    return false;
  }

  // ================= MENU ITEM =================
  Widget menuItem(
    String icon,
    String title,
    MenuScreen screen, {
    String? module,
    String? right,
  }) {
    final bool active = widget.selected == screen;

    return InkWell(
      onTap: () {
        if (canAccessMenu(menuRight: right, module: module)) {
          widget.onSelect(screen);
        } else {
          showCustomSnackbarError(context, "Access Denied");
        }
      },
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
  Widget childItem({
    required String title,
    required MenuScreen screen,
    String? module,
    String? right,
  }) {
    final bool active = widget.selected == screen;

    return InkWell(
      onTap: () {
        if (canAccessMenu(menuRight: right, module: module)) {
          widget.onSelect(screen);
        } else {
          showCustomSnackbarError(context, "Access Denied");
        }
      },
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

  // ================= EXPANDABLE =================
  Widget expandableMenu({
    required String menuKey,
    required String icon,
    required String title,
    required List<Map<String, dynamic>> children,
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
                    children: children.map((e) {
                      return childItem(
                        title: e["title"],
                        screen: e["screen"],
                        module: e["module"],
                        right: e["right"],
                      );
                    }).toList(),
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
    return Container(
      color: bgColor,
      child: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 16),
            InkWell(
              onTap: () => widget.onSelect(MenuScreen.dashboardScreen),
              child: Image.asset("assets/images/applogo.png", height: 24),
            ),
            const SizedBox(height: 10),

            /// Dashboard
            menuItem(
              "assets/icons/home.svg",
              "Home",
              MenuScreen.dashboardScreen,
              right: "Dashboard",
            ),

            /// Trader
            expandableMenu(
              menuKey: "trader",
              icon: "assets/icons/user.svg",
              title: "Trader",
              children: [
                {
                  "title": "Customer",
                  "screen": MenuScreen.customerList,
                  "module": "Ledger",
                },
                {
                  "title": "Supplier",
                  "screen": MenuScreen.supplierList,
                  "module": "Ledger",
                },
              ],
            ),

            /// Inventory

            /// Sales
            expandableMenu(
              menuKey: "sales",
              icon: "assets/icons/sales.svg",
              title: "Sales",
              children: [
                {
                  "title": "Estimate",
                  "screen": MenuScreen.estimateList,
                  "module": "Estimate",
                },
                {
                  "title": "Performa Invoice",
                  "screen": MenuScreen.performaInvoice,
                  "module": "Performa Invoice",
                },
                {
                  "title": "Delivery",
                  "screen": MenuScreen.deliveryChallan,
                  "module": "Delivery Challan",
                },
                {
                  "title": "Sale Invoice",
                  "screen": MenuScreen.saleInvoice,
                  "module": "Sale Invoice",
                },
                {
                  "title": "Sales Return",
                  "screen": MenuScreen.saleReturn,
                  "module": "Sale Return",
                },
                {
                  "title": "Credit Note",
                  "screen": MenuScreen.debitNote,
                  "module": "Credit Note",
                },
              ],
            ),

            /// Purchase
            expandableMenu(
              menuKey: "purchase",
              icon: "assets/icons/purchase.svg",
              title: "Purchase",
              children: [
                {
                  "title": "Purchase Order",
                  "screen": MenuScreen.purchaseOrder,
                  "module": "Purchase Order",
                },
                {
                  "title": "Purchase Invoice",
                  "screen": MenuScreen.purchaseInvoice,
                  "module": "Purchase Invoice",
                },
                {
                  "title": "Purchase Return",
                  "screen": MenuScreen.purchaseReturn,
                  "module": "Purchase Return",
                },
                {
                  "title": "Debit Note",
                  "screen": MenuScreen.creditNote,
                  "module": "Debit Note",
                },
              ],
            ),

            /// Vouchers
            expandableMenu(
              menuKey: "voucher",
              icon: "assets/icons/vouchers.svg",
              title: "Vouchers",
              children: [
                {
                  "title": "Reciept",
                  "screen": MenuScreen.reciept,
                  "module": "Receipt Voucher",
                },
                {
                  "title": "Expense",
                  "screen": MenuScreen.expanse,
                  "module": "Expense Voucher",
                },
                {
                  "title": "Payment",
                  "screen": MenuScreen.payment,
                  "module": "Payment Voucher",
                },
                {
                  "title": "Contra",
                  "screen": MenuScreen.contra,
                  "module": "Contra Voucher",
                },
                {
                  "title": "Journal",
                  "screen": MenuScreen.journal,
                  "module": "Journal Voucher",
                },
              ],
            ),
            menuItem(
              "assets/icons/inventry.svg",
              "Inventory",
              MenuScreen.inventoryScreen,
              module: "Item",
            ),

            /// Employee/User
            expandableMenu(
              menuKey: "employee",
              icon: "assets/icons/employee.png",
              title: "Employees/Users",
              isPng: true,
              children: [
                {
                  "title": "User",
                  "screen": MenuScreen.userMaster,
                  "module": "User",
                },
                {
                  "title": "Employee",
                  "screen": MenuScreen.employeeMaster,
                  "module": "Employee",
                },
              ],
            ),

            /// Utilities
            expandableMenu(
              menuKey: "utils",
              icon: "assets/icons/utils.svg",
              title: "Utilities",
              children: [
                {
                  "title": "Company Profile",
                  "screen": MenuScreen.companyProfile,
                  "right": "Company Profile",
                },
                {
                  "title": "Ledger",
                  "screen": MenuScreen.ledgerMaster,
                  "module": "Ledger",
                },
                {
                  "title": "Misc Charge",
                  "screen": MenuScreen.miscCharge,
                  "module": "Misc Charge",
                },
              ],
            ),

            /// Logout
            IconButton(
              icon: const Icon(Icons.logout, color: Colors.white),
              onPressed: () async {
                final prefs = await SharedPreferences.getInstance();
                await prefs.clear();
                pushNdRemove(SplashScreen());
              },
            ),
          ],
        ),
      ),
    );
  }
}
