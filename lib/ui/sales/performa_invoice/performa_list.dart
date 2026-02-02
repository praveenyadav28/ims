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

class PerformaInvoiceListScreen extends StatefulWidget {
  const PerformaInvoiceListScreen({super.key});

  @override
  State<PerformaInvoiceListScreen> createState() =>
      _PerformaInvoiceListScreenState();
}

class _PerformaInvoiceListScreenState extends State<PerformaInvoiceListScreen> {
  final repo = GLobalRepository();

  /// 🔑 Key to access TransactionListScreen state
  final GlobalKey<TransactionListScreenState<PerformaData>> listKey =
      GlobalKey<TransactionListScreenState<PerformaData>>();

  @override
  Widget build(BuildContext context) {
    return TransactionListScreen<PerformaData>(
      key: listKey, // 👈 IMPORTANT
      title: "Performa Invoice",

      /// API Call
      fetchData: repo.getPerforma,

      /// ACTIONS
      onView: (e) {
        print("VIEW PERFORMA PDF: ${e.baseNumber}");
      },

      onEdit: (e) async {
        final result = await pushTo(CreatePerformaFullScreen(performaData: e));

        if (result == true) {
          listKey.currentState?.load(); // ✅ reload list
        }
      },

      onDelete: repo.deletePerforma,

      onCreate: () async {
        final result = await pushTo(CreatePerformaFullScreen());

        if (result == true) {
          listKey.currentState?.load(); // ✅ reload list
        }
      },

      /// EXTRACTORS
      idGetter: (e) => e.id,
      dateGetter: (e) => e.performaDate,
      numberGetter: (e) => "${e.prefix} ${e.no}",
      customerGetter: (e) => e.customerName,
      amountGetter: (e) => e.totalAmount,
      mobile: (e) => e.mobile,
      gstGetter: (e) => e.subGst,
      basicGetter: (e) => e.subTotal,
      placeOfSupply: (e) => e.placeOfSupply,
    );
  }
}
