import 'package:ims/ui/sales/data/download_csv.dart';
import 'package:intl/intl.dart';

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
  final buffer = StringBuffer();

  buffer.writeln("Date,Number,Party,Mobile,State,Basic,GST,Final Amount");

  for (final item in list) {
    buffer.writeln(
      "${DateFormat("dd-MM-yyyy").format(dateGetter(item))},"
      "${numberGetter(item)},"
      "${customerGetter(item)},"
      "${mobile(item)},"
      "${placeOfSupply(item)},"
      "${basicGetter(item)},"
      "${gstGetter(item)},"
      "${amountGetter(item)}",
    );
  }

  downloadCsv(buffer.toString(), "${title}_Report.csv");
}
