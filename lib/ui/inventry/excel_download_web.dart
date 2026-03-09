import 'dart:html' as html;

void downloadExcel(List<int> bytes) {
  final blob = html.Blob([bytes]);
  final url = html.Url.createObjectUrlFromBlob(blob);
  // ignore: unused_local_variable
  final anchor = html.AnchorElement(href: url)
    ..setAttribute("download", "Inventory.xlsx")
    ..click();
  html.Url.revokeObjectUrl(url);
}
