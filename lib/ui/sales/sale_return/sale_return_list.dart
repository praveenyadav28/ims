import 'package:flutter/material.dart';
import 'package:ims/ui/master/company/company_api.dart';
import 'package:ims/ui/sales/data/reuse_print.dart';
import 'package:ims/ui/sales/data/transection_list.dart';
import 'package:ims/ui/sales/data/global_repository.dart';
import 'package:ims/ui/sales/models/sale_return_data.dart';
import 'package:ims/ui/sales/sale_return/salereturn_create.dart';
import 'package:ims/utils/navigation.dart';
import 'package:ims/utils/print_mapper.dart';
// import 'package:ims/utils/navigation.dart';

/// EXTENSION TO CONNECT SaleReturn MODEL TO GLOBAL SCREEN
extension SaleReturnMapper on SaleReturnData {
  String get baseId => id;
  DateTime get baseDate => saleReturnDate;
  String get baseNumber => "$prefix-$no";
  String get baseCustomer => customerName;
  double get baseAmount => totalAmount;
}

class SaleReturnInvoiceListScreen extends StatefulWidget {
  SaleReturnInvoiceListScreen({super.key});

  @override
  State<SaleReturnInvoiceListScreen> createState() =>
      _SaleReturnInvoiceListScreenState();
}

class _SaleReturnInvoiceListScreenState
    extends State<SaleReturnInvoiceListScreen> {
  final repo = GLobalRepository();

  /// 🔑 Key to access TransactionListScreen state
  final GlobalKey<TransactionListScreenState<SaleReturnData>> listKey =
      GlobalKey<TransactionListScreenState<SaleReturnData>>();

  @override
  Widget build(BuildContext context) {
    return TransactionListScreen<SaleReturnData>(
      key: listKey,
      title: "Sale Return Invoice",
      fetchData: repo.getSaleReturn,
        onView: (e) async {
        final doc = e.toPrintModel(); // ✅ no dynamic

        final companyApi = await CompanyProfileAPi.getCompanyProfile();
        final company = CompanyPrintProfile.fromApi(companyApi["data"][0]);

        await PdfEngine.printPremiumInvoice(doc: doc, company: company);
      },
      onEdit: (e) async {
        final result = await pushTo(
          CreateSaleReturnFullScreen(saleReturnData: e),
        );

        if (result == true) {
          listKey.currentState?.load();
        }
      },
      onCreate: () async {
        final result = await pushTo(CreateSaleReturnFullScreen());

        if (result == true) {
          listKey.currentState?.load();
        }
      },
      onDelete: repo.deleteSaleReturn,
      idGetter: (e) => e.id,
      dateGetter: (e) => e.saleReturnDate,
      numberGetter: (e) => "${e.prefix} ${e.no}",
      customerGetter: (e) => e.customerName,
      amountGetter: (e) => e.totalAmount,
      mobile: (e) => e.mobile,
      gstGetter: (e) => e.subGst,
      basicGetter: (e) => e.subTotal,
      placeOfSupply: (e) => e.placeOfSupply,
    );
  }
}
