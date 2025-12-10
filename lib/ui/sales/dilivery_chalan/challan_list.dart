import 'package:flutter/material.dart';
import 'package:ims/ui/sales/data/transection_list.dart';
import 'package:ims/ui/sales/data/global_repository.dart';
import 'package:ims/ui/sales/dilivery_chalan/dilivery_create.dart';
import 'package:ims/ui/sales/models/dilivery_data.dart';
import 'package:ims/utils/navigation.dart';
// import 'package:ims/utils/navigation.dart';
extension DiliveryChallanMapper on DiliveryChallanData {
  String get baseId => id;
  DateTime get baseDate => diliveryChallanDate;
  String get baseNumber => "$prefix-$no";
  String get baseCustomer => customerName;
  double get baseAmount => totalAmount;
}

class  DiliveryChallanInvoiceListScreen extends StatelessWidget {
  final repo = GLobalRepository();

   DiliveryChallanInvoiceListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return TransactionListScreen<DiliveryChallanData>(
      title: "Dilivery Challan",
      fetchData: repo.getDiliveryChallan,
      onView: (e) {
        print("VIEW Challan PDF: ${e.baseNumber}");
      },
      onEdit: (e) => pushTo(CreateDiliveryChallanFullScreen(diliveryChallanData: e)),
      onDelete: repo.deleteDiliveryChallan,
      onCreate: () => pushTo(CreateDiliveryChallanFullScreen()),
      idGetter: (e) => e.id,
      dateGetter: (e) => e.diliveryChallanDate,
      numberGetter: (e) => "${e.prefix} ${e.no}",
      customerGetter: (e) => e.customerName,
      amountGetter: (e) => e.totalAmount,
    );
  }
}
