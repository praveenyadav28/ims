import 'package:flutter/material.dart';
import 'package:ims/ui/purchase/credit_note/credit_note_create.dart';
import 'package:ims/ui/sales/data/global_repository.dart';
import 'package:ims/ui/sales/data/transection_list.dart';
import 'package:ims/ui/sales/models/credit_note_data.dart';
import '../../../utils/navigation.dart';

class CreditNoteListScreen extends StatelessWidget {
  final repo = GLobalRepository();

  CreditNoteListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return TransactionListScreen<CreditNoteData>(
      title: "Credit Note",
      fetchData: repo.getCreditNote,
      onView: (e) {
        print("VIEW Credit Note PDF: ${e.no}");
      },
      onEdit: (e) => pushTo(CreateCreditNoteFullScreen(creditNoteData: e)),
      onDelete: repo.deleteCreditNote,
      onCreate: () => pushTo(CreateCreditNoteFullScreen()),

      /// EXTRACTORS — REQUIRED
      idGetter: (e) => e.id,
      dateGetter: (e) => e.creditNoteDate,
      numberGetter: (e) => "${e.prefix} ${e.no}",
      customerGetter: (e) => e.supplierName,
      amountGetter: (e) => e.totalAmount,
    );
  }
}
