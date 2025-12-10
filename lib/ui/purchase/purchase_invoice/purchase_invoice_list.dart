import 'package:flutter/material.dart';
import 'package:ims/ui/purchase/purchase_Invoice/purchase_Invoice_create.dart';
import 'package:ims/ui/sales/data/global_repository.dart';
import 'package:ims/ui/sales/data/transection_list.dart';
import 'package:ims/ui/sales/models/purcahseinvoice_data.dart';
import '../../../utils/navigation.dart';

class PurchaseInvoiceListScreen extends StatelessWidget {
  final repo = GLobalRepository();

  PurchaseInvoiceListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return TransactionListScreen<PurchaseInvoiceData>(
      title: "Purchase Invoice",
      fetchData: repo.getPurchaseInvoice,
      onView: (e) {
        print("VIEW Purchase Invoice PDF: ${e.no}");
      },
      onEdit: (e) => pushTo(CreatePurchaseInvoiceFullScreen(purchaseInvoiceData: e)),
      onDelete: repo.deletePurchaseInvoice,
      onCreate: () => pushTo(CreatePurchaseInvoiceFullScreen()),

      /// EXTRACTORS — REQUIRED
      idGetter: (e) => e.id,
      dateGetter: (e) => e.purchaseInvoiceDate,
      numberGetter: (e) => "${e.prefix} ${e.no}",
      customerGetter: (e) => e.supplierName,
      amountGetter: (e) => e.totalAmount,
    );
  }
}
