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
      id: json['_id']?.toString() ?? "",

      supplierName:
          json['supplier_name']?.toString() ??
          json['customer_name']?.toString() ??
          "",

      amount: (json['amount'] ?? 0).toDouble(),

      invoiceNo: json['invoice_no']?.toString() ?? "",

      date: json['date'] != null
          ? DateTime.parse(json['date'])
          : DateTime.now(),

      reminderDate:
          json['reminder_date'] != null &&
              json['reminder_date'].toString().isNotEmpty
          ? DateTime.parse(json['reminder_date'])
          : null,

      ledgerDetails: json["ledger_details"] == null
          ? <VoucherLedgerDetail>[]
          : List<VoucherLedgerDetail>.from(
              json["ledger_details"].map(
                (x) => VoucherLedgerDetail.fromJson(x),
              ),
            ),

      prefix: json['prefix']?.toString() ?? "",

      voucherNo: int.tryParse(json['vouncher_no']?.toString() ?? "0") ?? 0,

      note: json['note']?.toString() ?? "",

      type: json['type']?.toString() ?? "",

      docu: json['docu']?.toString() ?? "",

      other1: json['other1']?.toString() ?? "",
    );
  }
}

class VoucherLedgerDetail {
  String? ledgerId;
  String? ledgerName;
  double? amount;

  VoucherLedgerDetail({this.ledgerId, this.ledgerName, this.amount});

  factory VoucherLedgerDetail.fromJson(Map<String, dynamic> json) {
    return VoucherLedgerDetail(
      ledgerId: json["ledger_id"]?.toString(),
      ledgerName: json["ledger_name"]?.toString(),
      amount: (json["amount"] ?? 0).toDouble(),
    );
  }
}
