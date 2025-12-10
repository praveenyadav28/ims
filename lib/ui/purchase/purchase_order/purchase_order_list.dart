import 'package:flutter/material.dart';
import 'package:ims/ui/purchase/purchase_order/purchase_order_create.dart';
import 'package:ims/ui/sales/data/global_repository.dart';
import 'package:ims/ui/sales/data/transection_list.dart';
import 'package:ims/ui/sales/models/purchaseorder_model.dart';
import '../../../utils/navigation.dart';

class PurchaseOrderListScreen extends StatelessWidget {
  final repo = GLobalRepository();

  PurchaseOrderListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return TransactionListScreen<PurchaseOrderData>(
      title: "Purchase Order",
      fetchData: repo.getPurchaseOrder,
      onView: (e) {
        print("VIEW Purchase Order PDF: ${e.no}");
      },
      onEdit: (e) => pushTo(CreatePurchaseOrderFullScreen(purchaseOrderData: e)),
      onDelete: repo.deletePurchaseOrder,
      onCreate: () => pushTo(CreatePurchaseOrderFullScreen()),

      /// EXTRACTORS — REQUIRED
      idGetter: (e) => e.id,
      dateGetter: (e) => e.purchaseOrderDate,
      numberGetter: (e) => "${e.prefix} ${e.no}",
      customerGetter: (e) => e.supplierName,
      amountGetter: (e) => e.totalAmount,
    );
  }
}
