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

class DiliveryChallanInvoiceListScreen extends StatefulWidget {
  DiliveryChallanInvoiceListScreen({super.key});

  @override
  State<DiliveryChallanInvoiceListScreen> createState() =>
      _DiliveryChallanInvoiceListScreenState();
}

class _DiliveryChallanInvoiceListScreenState
    extends State<DiliveryChallanInvoiceListScreen> {
  final repo = GLobalRepository();

  /// 🔑 Key to access TransactionListScreen state
  final GlobalKey<TransactionListScreenState<DiliveryChallanData>> listKey =
      GlobalKey<TransactionListScreenState<DiliveryChallanData>>();

  @override
  Widget build(BuildContext context) {
    return TransactionListScreen<DiliveryChallanData>(
      key: listKey, // 👈 IMPORTANT
      title: "Dilivery Challan",
      fetchData: repo.getDiliveryChallan,
      onView: (e) {
        print("VIEW Challan PDF: ${e.baseNumber}");
      },
      onEdit: (e) async {
        final result = await pushTo(
          CreateDiliveryChallanFullScreen(diliveryChallanData: e),
        );

        if (result == true) {
          listKey.currentState?.load(); // ✅ reload list
        }
      },
      onDelete: repo.deleteDiliveryChallan,
      onCreate: () async {
        final result = await pushTo(CreateDiliveryChallanFullScreen());

        if (result == true) {
          listKey.currentState?.load(); // ✅ reload list
        }
      },
      idGetter: (e) => e.id,
      dateGetter: (e) => e.diliveryChallanDate,
      numberGetter: (e) => "${e.prefix} ${e.no}",
      customerGetter: (e) => e.customerName,
      amountGetter: (e) => e.totalAmount,
      addressGetter: (e) => e.address0,
      gstGetter: (e) => e.subGst,
      basicGetter: (e) => e.baseAmount,
    );
  }
}
