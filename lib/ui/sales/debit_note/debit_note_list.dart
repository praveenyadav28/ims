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

class DebitNoteInvoiceListScreen extends StatelessWidget {
  final repo = GLobalRepository();

  DebitNoteInvoiceListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return TransactionListScreen<DebitNoteData>(
      title: "Debit Note",
      fetchData: repo.getDebitNote,
      onView: (e) {
        print("VIEW Debit Note PDF: ${e.baseNumber}");
      },
      onEdit: (e) => pushTo(CreateDebitNoteFullScreen(debitNoteData: e)),
      onDelete: repo.deleteDebitNote,
      onCreate: () => pushTo(CreateDebitNoteFullScreen()),
      idGetter: (e) => e.id,
      dateGetter: (e) => e.debitNoteDate,
      numberGetter: (e) => "${e.prefix} ${e.no}",
      customerGetter: (e) => e.customerName,
      amountGetter: (e) => e.totalAmount,
    );
  }
}
