import 'package:ims/ui/sales/models/globalget_model.dart';

class PrintDocModel {
  final String title; // Sale Invoice / Estimate / etc
  final String number;
  final DateTime date;

  final String partyName;
  final String mobile;
  final String address0;
  final String address1;
  final String placeOfSupply;

  final List<ItemDetail> items;

  final double subTotal;
  final double gstTotal;
  final double grandTotal;

  final List<String> notes;
  final List<String> terms;

  PrintDocModel({
    required this.title,
    required this.number,
    required this.date,
    required this.partyName,
    required this.mobile,
    required this.address0,
    required this.address1,
    required this.placeOfSupply,
    required this.items,
    required this.subTotal,
    required this.gstTotal,
    required this.grandTotal,
    required this.notes,
    required this.terms,
  });
}
