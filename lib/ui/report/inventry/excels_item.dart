import 'dart:io';
import 'package:excel/excel.dart';
import 'package:ims/ui/report/inventry/item_party.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:open_filex/open_filex.dart';

class PartyLedgerExcel {
  static Future<void> export({
    required String partyName,
    required DateTime from,
    required DateTime to,
    required List<PartyLedgerRow> rows,
    required double total,
  }) async {
    final excel = Excel.createExcel();
    final sheet = excel['Party Ledger'];

    final df = DateFormat("dd-MM-yyyy");

    // ================= HEADER =================
    sheet.appendRow([
      TextCellValue("Party Ledger Report"),
    ]);

    sheet.appendRow([
      TextCellValue("Party"),
      TextCellValue(partyName),
    ]);

    sheet.appendRow([
      TextCellValue("From"),
      TextCellValue(df.format(from)),
      TextCellValue("To"),
      TextCellValue(df.format(to)),
    ]);

    sheet.appendRow([]); // space

    // ================= TABLE HEADER =================
    sheet.appendRow([
      TextCellValue("Date"),
      TextCellValue("Invoice No"),
      TextCellValue("Type"),
      TextCellValue("Item"),
      TextCellValue("Qty"),
      TextCellValue("Rate"),
      TextCellValue("Amount"),
    ]);

    // ================= DATA =================
    for (final r in rows) {
      sheet.appendRow([
        TextCellValue(df.format(r.date)),
        TextCellValue(r.invoiceNo),
        TextCellValue(r.type),
        TextCellValue(r.itemName),
        DoubleCellValue(r.qty),
        DoubleCellValue(r.rate),
        DoubleCellValue(r.amount),
      ]);
    }

    // ================= TOTAL =================
    sheet.appendRow([]);
    sheet.appendRow([
      TextCellValue(""),
      TextCellValue(""),
      TextCellValue(""),
      TextCellValue("NET TOTAL"),
      TextCellValue(""),
      TextCellValue(""),
      DoubleCellValue(total),
    ]);

    // ================= SAVE FILE =================
    final dir = await getApplicationDocumentsDirectory();
    final file = File(
      "${dir.path}/party_ledger_${DateTime.now().millisecondsSinceEpoch}.xlsx",
    );

    final bytes = excel.save();
    await file.writeAsBytes(bytes!);

    await OpenFilex.open(file.path);
  }
}
