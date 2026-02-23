import 'dart:io';

import 'package:excel/excel.dart';
import 'package:intl/intl.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';

Future<void> exportTransactionsExcel<T>({
  required String title,
  required List<T> list,
  required DateTime Function(T) dateGetter,
  required String Function(T) numberGetter,
  required String Function(T) customerGetter,
  required String Function(T) mobile,
  required String Function(T) placeOfSupply,
  required double Function(T) basicGetter,
  required double Function(T) gstGetter,
  required double Function(T) amountGetter,
}) async {
  final excel = Excel.createExcel();
  final sheet = excel['Transactions'];

  sheet.appendRow([
    TextCellValue('Date'),
    TextCellValue('Number'),
    TextCellValue('Party'),
    TextCellValue('Mobile'),
    TextCellValue('State'),
    TextCellValue('Basic'),
    TextCellValue('GST'),
    TextCellValue('Final Amount'),
  ]);

  for (final item in list) {
    sheet.appendRow([
      TextCellValue(DateFormat("dd-MM-yyyy").format(dateGetter(item))),
      TextCellValue(numberGetter(item)),
      TextCellValue(customerGetter(item)),
      TextCellValue(mobile(item)),
      TextCellValue(placeOfSupply(item)),
      DoubleCellValue(basicGetter(item)),
      DoubleCellValue(gstGetter(item)),
      DoubleCellValue(amountGetter(item)),
    ]);
  }

  final dir = await getApplicationDocumentsDirectory();
  final file = File("${dir.path}/${title}_Report.xlsx");

  final bytes = excel.encode();
  await file.writeAsBytes(bytes!);

  await OpenFilex.open(file.path);
}
