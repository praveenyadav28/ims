import 'package:flutter/material.dart';
import 'package:ims/ui/customer_supplier/customer_list.dart';
import 'package:ims/ui/inventry/item/create.dart';
import 'package:ims/ui/inventry/item/old_code.dart';
import 'package:ims/ui/master/company/company_profile.dart';
import 'package:ims/ui/master/ledger/ledger_master.dart';
import 'package:ims/ui/master/misc/misc_charge_list.dart';
import 'package:ims/ui/master/user/user_list.dart';
import 'package:ims/ui/sales/estimate/estimate_screen.dart';
import 'package:ims/ui/voucher/payment/create.dart';
import 'package:ims/utils/colors.dart';
import 'package:ims/utils/navigation.dart';

class SideMenu extends StatefulWidget {
  const SideMenu({super.key});

  @override
  State<SideMenu> createState() => _SideMenuState();
}

class _SideMenuState extends State<SideMenu> {
  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: AppColor.white,

      child: Column(
        children: [
          DrawerListtile(
            onTap: () {
              pushNdRemove(const CustomerTableScreen());
            },
            title: "Customer Supplier",
          ),
          DrawerListtile(
            onTap: () {
              pushNdRemove(const CreateNewItemScreen());
            },
            title: "Create Item",
          ),
          DrawerListtile(
            onTap: () {
              pushNdRemove(const CreateNewItemScreenOld());
            },
            title: "Create Item Old",
          ),
          DrawerListtile(
            onTap: () {
              pushNdRemove(const PaymentEntry());
            },
            title: "Payment Entry",
          ),
          DrawerListtile(
            onTap: () {
              pushNdRemove(const CreateLedger());
            },
            title: "Ledger Master",
          ),
          DrawerListtile(
            onTap: () {
              pushNdRemove(const CompanyProfileScreen());
            },
            title: "Company Profile",
          ),
          DrawerListtile(
            onTap: () {
              pushNdRemove(const UserEmpTableScreen());
            },
            title: "User Master",
          ),
          DrawerListtile(
            onTap: () {
              pushNdRemove(const MiscChargeScreen());
            },
            title: "Misc Charge",
          ),
          DrawerListtile(
            onTap: () {
              pushNdRemove(CreateEstimateFullScreen());
            },
            title: "Estimate",
          ),
        ],
      ),
    );
  }
}

class DrawerListtile extends StatelessWidget {
  DrawerListtile({
    required this.title,
    required this.onTap,
    this.style,
    super.key,
  });
  final String title;
  final TextStyle? style;
  final void Function()? onTap;
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          flex: 9,
          child: InkWell(
            onTap: onTap,

            child: Container(
              decoration: BoxDecoration(
                boxShadow: [
                  BoxShadow(
                    color: AppColor.grey,
                    blurRadius: 2,
                    spreadRadius: 0,
                    offset: Offset(0, 1),
                  ),
                ],
                color: style != null
                    ? Color.fromARGB(255, 250, 208, 208)
                    : AppColor.white,
                border: Border.all(color: AppColor.grey),
                borderRadius: BorderRadius.only(
                  topRight: Radius.circular(30),
                  bottomRight: Radius.circular(30),
                ),
              ),
              alignment: Alignment.centerLeft,
              margin: EdgeInsets.symmetric(vertical: 8),
              padding: EdgeInsets.symmetric(vertical: 10, horizontal: 15),
              child: Text(
                title,
                style:
                    style ??
                    TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
              ),
            ),
          ),
        ),
        Expanded(flex: 2, child: Container()),
      ],
    );
  }
}
