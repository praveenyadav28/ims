import 'package:flutter/material.dart';
import 'package:ims/ui/sales/data/transection_list.dart';
import 'package:ims/ui/sales/data/global_repository.dart';
import 'package:ims/ui/sales/models/sale_invoice_data.dart';
import 'package:ims/ui/sales/sale_invoice/saleinvoice_create.dart';
import 'package:ims/utils/navigation.dart';
// import 'package:ims/utils/navigation.dart';

/// EXTENSION TO CONNECT SaleInvoice MODEL TO GLOBAL SCREEN
extension SaleInvoiceMapper on SaleInvoiceData {
  String get baseId => id;
  DateTime get baseDate => saleInvoiceDate;
  String get baseNumber => "$prefix-$no";
  String get baseCustomer => customerName;
  double get baseAmount => totalAmount;
}

class SaleInvoiceInvoiceListScreen extends StatelessWidget {
  final repo = GLobalRepository();

  SaleInvoiceInvoiceListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return TransactionListScreen<SaleInvoiceData>(
      title: "SaleInvoice Invoice",
      fetchData: repo.getSaleInvoice,
      onView: (e) {
        print("VIEW SaleInvoice PDF: ${e.id}");
      },
      onEdit: (e) => pushTo(CreateSaleInvoiceFullScreen(saleInvoiceData: e)),
      onDelete: repo.deleteSaleInvoice,
      onCreate: () => pushTo(CreateSaleInvoiceFullScreen()),
      idGetter: (e) => e.id,
      dateGetter: (e) => e.saleInvoiceDate,
      numberGetter: (e) => "${e.prefix}-${e.no}",
      customerGetter: (e) => e.customerName,
      amountGetter: (e) => e.totalAmount,
    );
  }
}
