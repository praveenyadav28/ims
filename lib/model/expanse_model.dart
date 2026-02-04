class ExpanseModel {
  final String id;
  final String ledgerName;
  final String supplierName;
  final double amount;
  final DateTime date;
  final String prefix;
  final int voucherNo;
  final String note;
  final String docu;

  ExpanseModel({
    required this.id,
    required this.ledgerName,
    required this.supplierName,
    required this.amount,
    required this.date,
    required this.prefix,
    required this.voucherNo,
    required this.note,
    required this.docu,
  });

  factory ExpanseModel.fromJson(Map<String, dynamic> json) {
    return ExpanseModel(
      id: json['_id'],
      ledgerName: json['ledger_name'],
      supplierName: json['account_name'],
      amount: double.parse(json['amount'].toString()),
      date: DateTime.parse(json['date']),
      prefix: json['prefix'],
      voucherNo: json['vouncher_no'],
      note: json['note'] ?? '',
      docu: json['docu'] ?? '',
    );
  }
}
