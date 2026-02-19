import 'package:flutter/material.dart';
import 'package:ims/ui/master/company/company_api.dart';
import 'package:ims/ui/sales/data/reuse_print.dart';
import 'package:ims/ui/sales/data/transection_list.dart';
import 'package:ims/ui/sales/data/global_repository.dart';
import 'package:ims/ui/sales/models/sale_invoice_data.dart';
import 'package:ims/ui/sales/sale_invoice/saleinvoice_create.dart';
import 'package:ims/utils/navigation.dart';
import 'package:ims/utils/print_mapper.dart';
// import 'package:ims/utils/navigation.dart';

/// EXTENSION TO CONNECT SaleInvoice MODEL TO GLOBAL SCREEN
extension SaleInvoiceMapper on SaleInvoiceData {
  String get baseId => id;
  DateTime get baseDate => saleInvoiceDate;
  String get baseNumber => "$prefix-$no";
  String get baseCustomer => customerName;
  double get baseAmount => totalAmount;
}

class SaleInvoiceInvoiceListScreen extends StatefulWidget {
  SaleInvoiceInvoiceListScreen({super.key});

  @override
  State<SaleInvoiceInvoiceListScreen> createState() =>
      _SaleInvoiceInvoiceListScreenState();
}

class _SaleInvoiceInvoiceListScreenState
    extends State<SaleInvoiceInvoiceListScreen> {
  final repo = GLobalRepository();

  /// 🔑 Key to access TransactionListScreen state
  final GlobalKey<TransactionListScreenState<SaleInvoiceData>> listKey =
      GlobalKey<TransactionListScreenState<SaleInvoiceData>>();

  @override
  Widget build(BuildContext context) {
    return TransactionListScreen<SaleInvoiceData>(
      key: listKey,
      title: "Sale Invoice",
      fetchData: repo.getSaleInvoice,
      onView: (e) async {
        final doc = e.toPrintModel(); // ✅ no dynamic

        final companyApi = await CompanyProfileAPi.getCompanyProfile();
        final company = CompanyPrintProfile.fromApi(companyApi["data"][0]);

        await PdfEngine.printPremiumInvoice(doc: doc, company: company);
      },
      onEdit: (e) async {
        final result = await pushTo(
          CreateSaleInvoiceFullScreen(saleInvoiceData: e),
        );
        if (result == true) {
          listKey.currentState?.load(); // ✅ reload list
        }
      },
      onCreate: () async {
        final result = await pushTo(CreateSaleInvoiceFullScreen());

        if (result == true) {
          listKey.currentState?.load(); // ✅ reload list
        }
      },
      onDelete: repo.deleteSaleInvoice,
      idGetter: (e) => e.id,
      dateGetter: (e) => e.saleInvoiceDate,
      numberGetter: (e) => "${e.prefix} ${e.no}",
      customerGetter: (e) => e.customerName,
      gstGetter: (e) => e.subGst,
      basicGetter: (e) => e.subTotal,
      amountGetter: (e) => e.totalAmount,
      mobile: (e) => e.mobile,
      placeOfSupply: (e) => e.placeOfSupply,
    );
  }
}
