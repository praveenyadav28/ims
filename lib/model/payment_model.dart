class PaymentModel {
  final String id;
  final String supplierName;
  final double amount;
  final String invoiceNo;
  final DateTime date;
  final DateTime? reminderDate;
  final String prefix;
  List<VoucherLedgerDetail>? ledgerDetails;
  final int voucherNo;
  final String note;
  final String docu;
  final String type;
  final String other1;

  PaymentModel({
    required this.id,
    required this.supplierName,
    required this.amount,
    required this.invoiceNo,
    required this.ledgerDetails,
    required this.date,
    required this.reminderDate,
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
      supplierName: json['supplier_name'] ?? json['customer_name'],
      amount: double.tryParse(json['amount2'] ?? "0") ?? 0,
      invoiceNo: json['invoice_no'] ?? "",
      date: DateTime.parse(json['date']),
      reminderDate: json['reminder_date'] != null
          ? DateTime.parse(json['reminder_date'])
          : null,
      ledgerDetails: json["ledger_details"] == null
          ? <VoucherLedgerDetail>[]
          : List<VoucherLedgerDetail>.from(
              json["ledger_details"].map(
                (x) => VoucherLedgerDetail.fromJson(x),
              ),
            ),
      prefix: json['prefix'] ?? "",
      voucherNo: json['vouncher_no'],
      note: json['note'] ?? '',
      type: json['type'] ?? '',
      docu: json['docu'] ?? "",
      other1: json['other1'] ?? '',
    );
  }
}

class VoucherLedgerDetail {
  String? ledgerId;
  String? ledgerName;
  int? amount;

  VoucherLedgerDetail({this.ledgerId, this.ledgerName, this.amount});
  factory VoucherLedgerDetail.fromJson(Map<String, dynamic> json) =>
      VoucherLedgerDetail(
        ledgerId: json["ledger_id"],
        ledgerName: json["ledger_name"],
        amount: json["amount"],
      );
}
