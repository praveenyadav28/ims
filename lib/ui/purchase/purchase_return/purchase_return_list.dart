import 'package:flutter/material.dart';
import 'package:ims/ui/master/company/company_api.dart';
import 'package:ims/ui/purchase/purchase_return/purchase_return_create.dart';
import 'package:ims/ui/sales/data/global_repository.dart';
import 'package:ims/ui/sales/data/reuse_print.dart';
import 'package:ims/ui/sales/data/transection_list.dart';
import 'package:ims/ui/sales/models/purchase_return_data.dart';
import 'package:ims/utils/print_mapper.dart';
import '../../../utils/navigation.dart';

class PurchaseReturnListScreen extends StatefulWidget {
  PurchaseReturnListScreen({super.key});

  @override
  State<PurchaseReturnListScreen> createState() =>
      _PurchaseReturnListScreenState();
}

class _PurchaseReturnListScreenState extends State<PurchaseReturnListScreen> {
  final repo = GLobalRepository();

  /// 🔑 Key to access TransactionListScreen state
  final GlobalKey<TransactionListScreenState<PurchaseReturnData>> listKey =
      GlobalKey<TransactionListScreenState<PurchaseReturnData>>();

  @override
  Widget build(BuildContext context) {
    return TransactionListScreen<PurchaseReturnData>(
      key: listKey,
      title: "Purchase Return",
      fetchData: repo.getPurchaseReturn,
        onView: (e) async {
        final doc = e.toPrintModel(); // ✅ no dynamic

        final companyApi = await CompanyProfileAPi.getCompanyProfile();
        final company = CompanyPrintProfile.fromApi(companyApi["data"][0]);

        await PdfEngine.printPremiumInvoice(doc: doc, company: company);
      },
      onEdit: (e) async {
        final result = await pushTo(
          CreatePurchaseReturnFullScreen(purchaseReturnData: e),
        );
        if (result == true) {
          listKey.currentState?.load(); // ✅ reload list
        }
      },
      onCreate: () async {
        final result = await pushTo(CreatePurchaseReturnFullScreen());

        if (result == true) {
          listKey.currentState?.load(); // ✅ reload list
        }
      },
      onDelete: repo.deletePurchaseReturn,

      /// EXTRACTORS — REQUIRED
      idGetter: (e) => e.id,
      dateGetter: (e) => e.purchaseReturnDate,
      numberGetter: (e) => "${e.prefix} ${e.no}",
      customerGetter: (e) => e.supplierName,
      amountGetter: (e) => e.totalAmount,
      gstGetter: (e) => e.subGst,
      basicGetter: (e) => e.subTotal,
      mobile: (e) => e.mobile,
      placeOfSupply: (e) => e.placeOfSupply,
    );
  }
}
