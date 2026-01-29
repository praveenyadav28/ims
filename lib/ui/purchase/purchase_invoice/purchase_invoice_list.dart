import 'package:flutter/material.dart';
import 'package:ims/ui/purchase/purchase_Invoice/purchase_Invoice_create.dart';
import 'package:ims/ui/sales/data/global_repository.dart';
import 'package:ims/ui/sales/data/transection_list.dart';
import 'package:ims/ui/sales/models/purcahseinvoice_data.dart';
import '../../../utils/navigation.dart';

class PurchaseInvoiceListScreen extends StatefulWidget {
  PurchaseInvoiceListScreen({super.key});

  @override
  State<PurchaseInvoiceListScreen> createState() =>
      _PurchaseInvoiceListScreenState();
}

class _PurchaseInvoiceListScreenState extends State<PurchaseInvoiceListScreen> {
  final repo = GLobalRepository();

  /// 🔑 Key to access TransactionListScreen state
  final GlobalKey<TransactionListScreenState<PurchaseInvoiceData>> listKey =
      GlobalKey<TransactionListScreenState<PurchaseInvoiceData>>();

  @override
  Widget build(BuildContext context) {
    return TransactionListScreen<PurchaseInvoiceData>(
      key: listKey,
      title: "Purchase Invoice",
      fetchData: repo.getPurchaseInvoice,
      onView: (e) {
        print("VIEW Purchase Invoice PDF: ${e.no}");
      },
      onEdit: (e) async {
        final result = await pushTo(
          CreatePurchaseInvoiceFullScreen(purchaseInvoiceData: e),
        );

        if (result == true) {
          listKey.currentState?.load();
        }
      },
      onCreate: () async {
        final result = await pushTo(CreatePurchaseInvoiceFullScreen());

        if (result == true) {
          listKey.currentState?.load();
        }
      },
      onDelete: repo.deletePurchaseInvoice,

      /// EXTRACTORS — REQUIRED
      idGetter: (e) => e.id,
      dateGetter: (e) => e.purchaseInvoiceDate,
      numberGetter: (e) => "${e.prefix} ${e.no}",
      customerGetter: (e) => e.supplierName,
      amountGetter: (e) => e.totalAmount,
      gstGetter: (e) => e.subGst,
      basicGetter: (e) => e.subTotal,
      mobile: (e) => e.mobile,
    );
  }
}
