class MiscChargeModel {
  String id;
  int licenceNo;
  String branchId;
  String ledgerId;
  String ledgerName;
  String name;
  bool rePay;
  bool printIn;
  bool tax;
  String? hsn;
  double? gst;

  MiscChargeModel({
    required this.id,
    required this.licenceNo,
    required this.branchId,
    required this.ledgerId,
    required this.ledgerName,
    required this.name,
    required this.rePay,
    required this.printIn,
    required this.tax,
    this.hsn,
    this.gst,
  });

  factory MiscChargeModel.fromJson(Map<String, dynamic> json) {
    return MiscChargeModel(
      id: json["_id"] ?? "",
      licenceNo: json["licence_no"] ?? 0,
      branchId: json["branch_id"] ?? "",
      ledgerId: json["ledger_id"] ?? "",
      ledgerName: json["ledger_name"] ?? "",
      name: json["name"] ?? "",
      rePay: json["re_pay"] ?? false,
      printIn: json["print_in"] ?? false,
      tax: json["tax"] ?? false,
      hsn: json["hsn"] ?? "",
      gst: (json["gst"] ?? 0).toDouble(),
    );
  }
}
