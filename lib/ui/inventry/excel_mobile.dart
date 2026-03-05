import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:open_filex/open_filex.dart';

Future<void> downloadExcel(List<int> bytes) async {
  final dir = await getApplicationDocumentsDirectory();
  final file = File("${dir.path}/Inventory.xlsx");
  await file.writeAsBytes(bytes);
  await OpenFilex.open(file.path);
}