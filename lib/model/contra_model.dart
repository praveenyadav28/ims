class ContraModel {
  final String id;
  final String ledgerName;
  final String supplierName;
  final double amount;
  final DateTime date;
  final String prefix;
  final int voucherNo;
  final String note;

  ContraModel({
    required this.id,
    required this.ledgerName,
    required this.supplierName,
    required this.amount,
    required this.date,
    required this.prefix,
    required this.voucherNo,
    required this.note,
  });

  factory ContraModel.fromJson(Map<String, dynamic> json) {
    return ContraModel(
      id: json['_id'],
      ledgerName: json['ledger_name'],
      supplierName: json['account_name'] ?? json['customer_name'],
      amount: double.parse(json['amount'].toString()),
      date: DateTime.parse(json['date']),
      prefix: json['prefix'],
      voucherNo: json['vouncher_no'],
      note: json['note'] ?? '',
    );
  }
}
