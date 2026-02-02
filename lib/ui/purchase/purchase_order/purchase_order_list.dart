import 'package:flutter/material.dart';
import 'package:ims/ui/purchase/purchase_order/purchase_order_create.dart';
import 'package:ims/ui/sales/data/global_repository.dart';
import 'package:ims/ui/sales/data/transection_list.dart';
import 'package:ims/ui/sales/models/purchaseorder_model.dart';
import '../../../utils/navigation.dart';

class PurchaseOrderListScreen extends StatefulWidget {
  PurchaseOrderListScreen({super.key});

  @override
  State<PurchaseOrderListScreen> createState() =>
      _PurchaseOrderListScreenState();
}

class _PurchaseOrderListScreenState extends State<PurchaseOrderListScreen> {
  final repo = GLobalRepository();

  /// 🔑 Key to access TransactionListScreen state
  final GlobalKey<TransactionListScreenState<PurchaseOrderData>> listKey =
      GlobalKey<TransactionListScreenState<PurchaseOrderData>>();

  @override
  Widget build(BuildContext context) {
    return TransactionListScreen<PurchaseOrderData>(
      key: listKey,
      title: "Purchase Order",
      fetchData: repo.getPurchaseOrder,
      onView: (e) {
        print("VIEW Purchase Order PDF: ${e.no}");
      },
      onEdit: (e) async {
        final result = await pushTo(
          CreatePurchaseOrderFullScreen(purchaseOrderData: e),
        );

        if (result == true) {
          listKey.currentState?.load();
        }
      },
      onCreate: () async {
        final result = await pushTo(CreatePurchaseOrderFullScreen());

        if (result == true) {
          listKey.currentState?.load();
        }
      },
      onDelete: repo.deletePurchaseOrder,

      /// EXTRACTORS — REQUIRED
      idGetter: (e) => e.id,
      dateGetter: (e) => e.purchaseOrderDate,
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
