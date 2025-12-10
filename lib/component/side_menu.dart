import 'package:flutter/material.dart';
import 'package:ims/ui/customer_supplier/customer_list.dart';
import 'package:ims/ui/inventry/item/create.dart';
import 'package:ims/ui/inventry/item/old_code.dart';
import 'package:ims/ui/master/company/company_profile.dart';
import 'package:ims/ui/master/ledger/ledger_master.dart';
import 'package:ims/ui/master/misc/misc_charge_list.dart';
import 'package:ims/ui/master/user/user_list.dart';
import 'package:ims/ui/purchase/credit_note/credit_note_list.dart';
import 'package:ims/ui/purchase/purchase_invoice/purchase_invoice_list.dart';
import 'package:ims/ui/purchase/purchase_order/purchase_order_list.dart';
import 'package:ims/ui/purchase/purchase_return/purchase_return_list.dart';
import 'package:ims/ui/sales/debit_note/debit_note_list.dart';
import 'package:ims/ui/sales/dilivery_chalan/challan_list.dart';
import 'package:ims/ui/sales/estimate/estimate_list.dart';
import 'package:ims/ui/sales/performa_invoice/performa_list.dart';
import 'package:ims/ui/sales/sale_invoice/sale_invoice_list.dart';
import 'package:ims/ui/sales/sale_return/sale_return_list.dart';
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

      child: SingleChildScrollView(
        child: Column(
          children: [
            // Master Data Section
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

            // Sales Documents Section
            DrawerListtile(
              onTap: () {
                pushNdRemove(EstimateListScreen());
              },
              title: "Estimate List",
            ),
            DrawerListtile(
              onTap: () {
                pushNdRemove(PerformaInvoiceListScreen());
              },
              title: "Performa Invoice List",
            ),
            DrawerListtile(
              onTap: () {
                pushNdRemove(SaleInvoiceInvoiceListScreen());
              },
              title: "Sale Invoice List",
            ),
            DrawerListtile(
              onTap: () {
                pushNdRemove(DiliveryChallanInvoiceListScreen());
              },
              title: "Delivery Challan List",
            ),

            DrawerListtile(
              onTap: () {
                pushNdRemove(SaleReturnInvoiceListScreen());
              },
              title: "Sales Return List",
            ),
            DrawerListtile(
              onTap: () {
                pushNdRemove(DebitNoteInvoiceListScreen());
              },
              title: "Debit Note List",
            ),
            DrawerListtile(
              onTap: () {
                pushNdRemove(PurchaseOrderListScreen());
              },
              title: "Purchase Order List",
            ),

            // Purchase Documents Section
            DrawerListtile(
              onTap: () {
                pushNdRemove(PurchaseInvoiceListScreen());
              },
              title: "Purchase Invoice List",
            ),

            DrawerListtile(
              onTap: () {
                pushNdRemove(CreditNoteListScreen());
              },
              title: "Credit Note List",
            ),

            DrawerListtile(
              onTap: () {
                pushNdRemove(PurchaseReturnListScreen());
              },
              title: "Purchase Return List",
            ),
          ],
        ),
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
