import 'package:flutter/material.dart';
import 'package:ims/ui/sales/data/transection_list.dart';
import 'package:ims/ui/sales/data/global_repository.dart';
import 'package:ims/ui/sales/debit_note/create_debitnote.dart';
import 'package:ims/ui/sales/models/debitnote_model.dart';
import 'package:ims/utils/navigation.dart';

// import 'package:ims/utils/navigation.dart';
extension DebitNoteMapper on DebitNoteData {
  String get baseId => id;
  DateTime get baseDate => debitNoteDate;
  String get baseNumber => "$prefix-$no";
  String get baseCustomer => customerName;
  double get baseAmount => totalAmount;
}

class DebitNoteInvoiceListScreen extends StatefulWidget {
  DebitNoteInvoiceListScreen({super.key});

  @override
  State<DebitNoteInvoiceListScreen> createState() =>
      _DebitNoteInvoiceListScreenState();
}

class _DebitNoteInvoiceListScreenState
    extends State<DebitNoteInvoiceListScreen> {
  final repo = GLobalRepository();

  /// 🔑 Key to access TransactionListScreen state
  final GlobalKey<TransactionListScreenState<DebitNoteData>> listKey =
      GlobalKey<TransactionListScreenState<DebitNoteData>>();

  @override
  Widget build(BuildContext context) {
    return TransactionListScreen<DebitNoteData>(
      key: listKey,
      title: "Credit Note",
      fetchData: repo.getDebitNote,
      onView: (e) {
        print("VIEW Credit Note PDF: ${e.baseNumber}");
      },
      onEdit: (e) async {
        final result = await pushTo(
          CreateDebitNoteFullScreen(debitNoteData: e),
        );

        if (result == true) {
          listKey.currentState?.load();
        }
      },
      onCreate: () async {
        final result = await pushTo(CreateDebitNoteFullScreen());

        if (result == true) {
          listKey.currentState?.load();
        }
      },
      onDelete: repo.deleteDebitNote,
      idGetter: (e) => e.id,
      dateGetter: (e) => e.debitNoteDate,
      numberGetter: (e) => "${e.prefix} ${e.no}",
      customerGetter: (e) => e.customerName,
      amountGetter: (e) => e.totalAmount,
      mobile: (e) => e.mobile,
      gstGetter: (e) => e.subGst,
      basicGetter: (e) => e.baseAmount,
    );
  }
}
