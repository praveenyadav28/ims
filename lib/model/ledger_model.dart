class LedgerListModel {
  String? id;
  int? licenceNo;
  String? branchId;
  String? customerId;
  String? ledgerName;
  int? contactNo;
  int? whatsAppNo;
  String? email;
  String? ledgerGroup;
  int? openingBalance;
  String? openingType;
  int? closingBalance;
  dynamic gstNo;
  String? address;
  String? town;
  String? state;
  String? city;
  int? v;

  LedgerListModel({
    this.id,
    this.licenceNo,
    this.branchId,
    this.customerId,
    this.ledgerName,
    this.contactNo,
    this.whatsAppNo,
    this.email,
    this.ledgerGroup,
    this.openingBalance,
    this.openingType,
    this.closingBalance,
    this.gstNo,
    this.address,
    this.town,
    this.state,
    this.city,
    this.v,
  });

  factory LedgerListModel.fromJson(Map<String, dynamic> json) =>
      LedgerListModel(
        id: json["_id"],
        licenceNo: json["licence_no"],
        branchId: json["branch_id"],
        customerId: json["customer_id"],
        ledgerName: json["ledger_name"],
        contactNo: json["contact_no"],
        whatsAppNo: json["whatapp_no"],
        email: json["email"],
        ledgerGroup: json["ledger_group"],
        openingBalance: json["opening_balance"],
        openingType: json["opening_type"],
        closingBalance: json["closing_balance"],
        gstNo: json["gst_no"],
        address: json["address"],
        town: json["town"],
        state: json["state"],
        city: json["city"],
        v: json["__v"],
      );

  Map<String, dynamic> toJson() => {
    "_id": id,
    "licence_no": licenceNo,
    "branch_id": branchId,
    "customer_id": customerId,
    "ledger_name": ledgerName,
    "contact_no": contactNo,
    "whatapp_no": whatsAppNo,
    "email": email,
    "ledger_group": ledgerGroup,
    "opening_balance": openingBalance,
    "opening_type": openingType,
    "closing_balance": closingBalance,
    "gst_no": gstNo,
    "address": address,
    "town": town,
    "state": state,
    "city": city,
    "__v": v,
  };
}
