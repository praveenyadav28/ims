class PaymentModel {
  final String id;
  final String ledgerName;
  final String supplierName;
  final double amount;
  final int invoiceNo;
  final DateTime date;
  final String prefix;
  final int voucherNo;
  final String note;
  final String docu;
  final String type;
  final String other1;

  PaymentModel({
    required this.id,
    required this.ledgerName,
    required this.supplierName,
    required this.amount,
    required this.invoiceNo,
    required this.date,
    required this.prefix,
    required this.voucherNo,
    required this.note,
    required this.docu,
    required this.type,
    required this.other1,
  });

  factory PaymentModel.fromJson(Map<String, dynamic> json) {
    return PaymentModel(
      id: json['_id'],
      ledgerName: json['ledger_name'],
      supplierName: json['supplier_name'] ?? json['customer_name'],
      amount: (json['amount'] as num).toDouble(),
      invoiceNo: json['invoice_no'] ?? 0,
      date: DateTime.parse(json['date']),
      prefix: json['prefix'],
      voucherNo: json['vouncher_no'],
      note: json['note'] ?? '',
      type: json['type'] ?? '',
      docu: json['docu'] ?? "",
      other1: json['other1'] ?? '',
    );
  }
}
