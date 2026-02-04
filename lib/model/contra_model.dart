class ContraModel {
  final String id;
  final String fromAccount;
  final String toAccount;
  final double amount;
  final DateTime date;
  final String prefix;
  final int voucherNo;
  final String note;
  final String docu;

  ContraModel({
    required this.id,
    required this.fromAccount,
    required this.toAccount,
    required this.amount,
    required this.date,
    required this.prefix,
    required this.voucherNo,
    required this.note,
    required this.docu,
  });

  factory ContraModel.fromJson(Map<String, dynamic> json) {
    return ContraModel(
      id: json['_id'],
      fromAccount: json['ledger_name'],
      toAccount: json['account_name'] ?? json['customer_name'],
      amount: double.parse(json['amount'].toString()),
      date: DateTime.parse(json['date']),
      prefix: json['prefix'],
      voucherNo: json['vouncher_no'],
      note: json['note'] ?? '',
      docu: json['docu'] ?? '',
    );
  }
}
