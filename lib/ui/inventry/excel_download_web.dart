import 'dart:html' as html;

void downloadExcel(List<int> bytes, {String fileName = "Inventory.xlsx"}) {
  final blob = html.Blob([bytes]);
  final url = html.Url.createObjectUrlFromBlob(blob);

  final anchor = html.AnchorElement(href: url)
    ..setAttribute("download", fileName)
    ..click();
  html.Url.revokeObjectUrl(url);
}
