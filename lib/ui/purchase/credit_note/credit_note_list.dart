import 'package:flutter/material.dart';
import 'package:ims/ui/purchase/credit_note/credit_note_create.dart';
import 'package:ims/ui/sales/data/global_repository.dart';
import 'package:ims/ui/sales/data/transection_list.dart';
import 'package:ims/ui/sales/models/credit_note_data.dart';
import '../../../utils/navigation.dart';

class CreditNoteListScreen extends StatefulWidget {
  CreditNoteListScreen({super.key});

  @override
  State<CreditNoteListScreen> createState() => _CreditNoteListScreenState();
}

class _CreditNoteListScreenState extends State<CreditNoteListScreen> {
  final repo = GLobalRepository();

  /// 🔑 Key to access TransactionListScreen state
  final GlobalKey<TransactionListScreenState<CreditNoteData>> listKey =
      GlobalKey<TransactionListScreenState<CreditNoteData>>();

  @override
  Widget build(BuildContext context) {
    return TransactionListScreen<CreditNoteData>(
      key: listKey,
      title: "Credit Note",
      fetchData: repo.getCreditNote,
      onView: (e) {
        print("VIEW Credit Note PDF: ${e.no}");
      },
      onEdit: (e) async {
        final result = await pushTo(
          CreateCreditNoteFullScreen(creditNoteData: e),
        );
        if (result == true) {
          listKey.currentState?.load(); // ✅ reload list
        }
      },
      onCreate: () async {
        final result = await pushTo(CreateCreditNoteFullScreen());

        if (result == true) {
          listKey.currentState?.load(); // ✅ reload list
        }
      },
      onDelete: repo.deleteCreditNote,

      /// EXTRACTORS — REQUIRED
      idGetter: (e) => e.id,
      dateGetter: (e) => e.creditNoteDate,
      numberGetter: (e) => "${e.prefix} ${e.no}",
      customerGetter: (e) => e.supplierName,
      amountGetter: (e) => e.totalAmount,
      addressGetter: (e) => e.address0,
    );
  }
}
