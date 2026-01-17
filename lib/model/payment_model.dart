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
  });

  factory PaymentModel.fromJson(Map<String, dynamic> json) {
    return PaymentModel(
      id: json['_id'],
      ledgerName: json['ledger_name'],
      supplierName: json['supplier_name'] ?? json['customer_name'],
      amount: (json['amount'] as num).toDouble(),
      invoiceNo: json['invoice_no'],
      date: DateTime.parse(json['date']),
      prefix: json['prefix'],
      voucherNo: json['vouncher_no'],
      note: json['note'] ?? '',
    );
  }
}
