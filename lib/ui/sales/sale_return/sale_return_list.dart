import 'package:flutter/material.dart';
import 'package:ims/ui/sales/data/transection_list.dart';
import 'package:ims/ui/sales/data/global_repository.dart';
import 'package:ims/ui/sales/models/sale_return_data.dart';
import 'package:ims/ui/sales/sale_return/salereturn_create.dart';
import 'package:ims/utils/navigation.dart';
// import 'package:ims/utils/navigation.dart';

/// EXTENSION TO CONNECT SaleReturn MODEL TO GLOBAL SCREEN
extension SaleReturnMapper on SaleReturnData {
  String get baseId => id;
  DateTime get baseDate => saleReturnDate;
  String get baseNumber => "$prefix-$no";
  String get baseCustomer => customerName;
  double get baseAmount => totalAmount;
}

class SaleReturnInvoiceListScreen extends StatelessWidget {
  final repo = GLobalRepository();

  SaleReturnInvoiceListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return TransactionListScreen<SaleReturnData>(
      title: "Sale Return Invoice",
      fetchData: repo.getSaleReturn,
      onView: (e) {
        print("VIEW SaleReturn PDF: ${e.baseNumber}");
      },
      onEdit: (e) => pushTo(CreateSaleReturnFullScreen(saleReturnData: e)),
      onDelete: repo.deleteSaleReturn,
      onCreate: () => pushTo(CreateSaleReturnFullScreen()),
      idGetter: (e) => e.id,
      dateGetter: (e) => e.saleReturnDate,
      numberGetter: (e) => "${e.prefix} ${e.no}",
      customerGetter: (e) => e.customerName,
      amountGetter: (e) => e.totalAmount,
    );
  }
}
