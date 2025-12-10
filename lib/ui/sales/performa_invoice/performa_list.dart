import 'package:flutter/material.dart';
import 'package:ims/ui/sales/data/transection_list.dart';
import 'package:ims/ui/sales/models/performa_data.dart';
import 'package:ims/ui/sales/performa_invoice/performa_screen.dart';
import 'package:ims/ui/sales/data/global_repository.dart';
import 'package:ims/utils/navigation.dart';

/// EXTENSION TO CONNECT PERFORMA MODEL TO GLOBAL SCREEN
extension PerformaMapper on PerformaData {
  String get baseId => id;
  DateTime get baseDate => performaDate;
  String get baseNumber => "$prefix-$no";
  String get baseCustomer => customerName;
  double get baseAmount => totalAmount;
}

class PerformaInvoiceListScreen extends StatelessWidget {
  final repo = GLobalRepository();

  PerformaInvoiceListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return TransactionListScreen<PerformaData>(
      title: "Performa Invoice",
      fetchData: repo.getPerforma,
      onView: (e) {
        print("VIEW PERFORMA PDF: ${e.baseNumber}");
      },
      onEdit: (e) => pushTo(CreatePerformaFullScreen(performaData: e)),
      onDelete: repo.deletePerforma,
      onCreate: () => pushTo(CreatePerformaFullScreen()),
      idGetter: (e) => e.id,
      dateGetter: (e) => e.performaDate,
      numberGetter: (e) => "${e.prefix}-${e.no}",
      customerGetter: (e) => e.customerName,
      amountGetter: (e) => e.totalAmount,
    );
  }
}
