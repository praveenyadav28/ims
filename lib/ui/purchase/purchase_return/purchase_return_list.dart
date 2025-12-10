import 'package:flutter/material.dart';
import 'package:ims/ui/purchase/purchase_return/purchase_return_create.dart';
import 'package:ims/ui/sales/data/global_repository.dart';
import 'package:ims/ui/sales/data/transection_list.dart';
import 'package:ims/ui/sales/models/purchase_return_data.dart';
import '../../../utils/navigation.dart';

class PurchaseReturnListScreen extends StatelessWidget {
  final repo = GLobalRepository();

  PurchaseReturnListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return TransactionListScreen<PurchaseReturnData>(
      title: "Purchase Return",
      fetchData: repo.getPurchaseReturn,
      onView: (e) {
        print("VIEW Purchase Return PDF: ${e.no}");
      },
      onEdit: (e) =>
          pushTo(CreatePurchaseReturnFullScreen(purchaseReturnData: e)),
      onDelete: repo.deletePurchaseReturn,
      onCreate: () => pushTo(CreatePurchaseReturnFullScreen()),

      /// EXTRACTORS — REQUIRED
      idGetter: (e) => e.id,
      dateGetter: (e) => e.purchaseReturnDate,
      numberGetter: (e) => "${e.prefix} ${e.no}",
      customerGetter: (e) => e.supplierName,
      amountGetter: (e) => e.totalAmount,
    );
  }
}
