import 'package:flutter/material.dart';
import 'package:ims/ui/home/dashboard.dart';
import 'package:ims/ui/inventry/list.dart';
import 'package:ims/ui/master/customer_supplier/supplier_list.dart';
import 'package:ims/ui/master/ledger/ledger_list.dart';
import 'package:ims/ui/master/user/employee_list.dart';
import 'package:ims/ui/report/customer/customer_report.dart';
import 'package:ims/ui/report/inventry/inventry_report.dart';
import 'package:ims/ui/report/purchase/purchase_inv_report.dart';
import 'package:ims/ui/report/sale/sale_inv_report.dart';
import 'package:ims/ui/report/supplier/supplier_repost.dart';
import 'package:ims/ui/voucher/contra/contra_list.dart';
import 'package:ims/ui/voucher/expanse/expanse_list.dart';
import 'package:ims/ui/voucher/payment/payment_list.dart';
import 'package:ims/ui/voucher/recipt/reciept_list.dart';
import 'menu_screen.dart';
import 'side_menu.dart';

// IMPORT ALL SCREENS
import 'package:ims/ui/master/customer_supplier/customer_list.dart';
import 'package:ims/ui/inventry/item/create.dart';
import 'package:ims/ui/master/company/company_profile.dart';
import 'package:ims/ui/master/misc/misc_charge_list.dart';
import 'package:ims/ui/master/user/user_list.dart';
import 'package:ims/ui/sales/estimate/estimate_list.dart';
import 'package:ims/ui/sales/performa_invoice/performa_list.dart';
import 'package:ims/ui/sales/sale_invoice/sale_invoice_list.dart';
import 'package:ims/ui/sales/dilivery_chalan/challan_list.dart';
import 'package:ims/ui/sales/sale_return/sale_return_list.dart';
import 'package:ims/ui/sales/debit_note/debit_note_list.dart';
import 'package:ims/ui/purchase/purchase_order/purchase_order_list.dart';
import 'package:ims/ui/purchase/purchase_invoice/purchase_invoice_list.dart';
import 'package:ims/ui/purchase/credit_note/credit_note_list.dart';
import 'package:ims/ui/purchase/purchase_return/purchase_return_list.dart';

class FullScreen extends StatefulWidget {
  const FullScreen({super.key});

  @override
  State<FullScreen> createState() => _FullScreenState();
}

class _FullScreenState extends State<FullScreen> {
  MenuScreen selected = MenuScreen.dashboardScreen;

  Widget getScreen() {
    switch (selected) {
      case MenuScreen.dashboardScreen:
        return const DashboardScreen();
      case MenuScreen.customerList:
        return const CustomerTableScreen();
      case MenuScreen.customerReport:
        return const CustomerReportScreen();
      case MenuScreen.supplierReport:
        return const SupplierReportScreen();
      case MenuScreen.purchaseInvReport:
        return const PurchaseInvoiceAdvancedReportScreen();
      case MenuScreen.saleInvReport:
        return const SaleInvoiceAdvancedReportScreen();
      case MenuScreen.inventoryReport:
        return const InventoryAdvancedReportScreen();
      case MenuScreen.supplierList:
        return const SupplierTableScreen();
      case MenuScreen.inventoryScreen:
        return const InventoryScreen();
      case MenuScreen.createItem:
        return CreateNewItemScreen();
      case MenuScreen.ledgerMaster:
        return const LedgerListScreen();
      case MenuScreen.payment:
        return const PaymentListTableScreen();
      case MenuScreen.reciept:
        return const RecieptListTableScreen();
      case MenuScreen.contra:
        return const ContraListTableScreen();
      case MenuScreen.expanse:
        return const ExpanseListTableScreen();
      case MenuScreen.companyProfile:
        return const CompanyProfileScreen();
      case MenuScreen.userMaster:
        return const UserEmpTableScreen();
      case MenuScreen.employeeMaster:
        return const EmployeeTableScreen();
      case MenuScreen.miscCharge:
        return const MiscChargeScreen();
      case MenuScreen.estimateList:
        return EstimateListScreen();
      case MenuScreen.performaInvoice:
        return PerformaInvoiceListScreen();
      case MenuScreen.saleInvoice:
        return SaleInvoiceInvoiceListScreen();
      case MenuScreen.deliveryChallan:
        return DiliveryChallanInvoiceListScreen();
      case MenuScreen.saleReturn:
        return SaleReturnInvoiceListScreen();
      case MenuScreen.debitNote:
        return DebitNoteInvoiceListScreen();
      case MenuScreen.purchaseOrder:
        return PurchaseOrderListScreen();
      case MenuScreen.purchaseInvoice:
        return PurchaseInvoiceListScreen();
      case MenuScreen.creditNote:
        return CreditNoteListScreen();
      case MenuScreen.purchaseReturn:
        return PurchaseReturnListScreen();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          SizedBox(
            width: 145,
            child: SideMenu(
              selected: selected,
              onSelect: (screen) {
                setState(() => selected = screen);
              },
            ),
          ),
          Expanded(child: getScreen()),
        ],
      ),
    );
  }
}
