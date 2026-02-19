import 'dart:convert';

import 'package:ims/ui/sales/models/globalget_model.dart';

CreditNoteListResponse creditNoteListResponseFromJson(String str) =>
    CreditNoteListResponse.fromJson(json.decode(str));

class CreditNoteListResponse {
  final bool status;
  final String? message;
  final List<CreditNoteData> data;

  CreditNoteListResponse({
    required this.status,
    this.message,
    required this.data,
  });

  factory CreditNoteListResponse.fromJson(Map<String, dynamic> json) =>
      CreditNoteListResponse(
        status: json["status"] ?? false,
        message: json["message"],
        data: json["data"] == null
            ? []
            : List<CreditNoteData>.from(
                json["data"].map((x) => CreditNoteData.fromJson(x)),
              ),
      );
}

class CreditNoteData {
  final String id;
  final int licenceNo;
  final String branchId;

  final String? ledgerId;
  final String ledgerName;
  final String address0;
  final String address1;
  final String placeOfSupply;
  final String mobile;

  final String prefix;
  final int no;
  final String transId;
  final int transNo;
  final DateTime creditNoteDate;

  final bool caseSale;

  final List<String> notes;
  final List<String> terms;

  final double subTotal;
  final double subGst;
  final bool autoRound;
  final double totalAmount;

  final List<ChargeModel> additionalCharges;
  final List<DiscountModel> discountLines;
  final List<MiscChargeModel> miscCharges;

  final List<ItemDetail> itemDetails;

  final String signature;
  final DateTime createdAt;
  final DateTime updatedAt;

  CreditNoteData({
    required this.id,
    required this.licenceNo,
    required this.branchId,
    this.ledgerId,
    required this.ledgerName,
    required this.address0,
    required this.address1,
    required this.placeOfSupply,
    required this.mobile,
    required this.prefix,
    required this.no,
    required this.transId,
    required this.transNo,
    required this.creditNoteDate,
    required this.caseSale,
    required this.notes,
    required this.terms,
    required this.subTotal,
    required this.subGst,
    required this.autoRound,
    required this.totalAmount,
    required this.additionalCharges,
    required this.discountLines,
    required this.miscCharges,
    required this.itemDetails,
    required this.signature,
    required this.createdAt,
    required this.updatedAt,
  });

  factory CreditNoteData.fromJson(Map<String, dynamic> j) => CreditNoteData(
    id: j["_id"],
    licenceNo: j["licence_no"],
    branchId: j["branch_id"],
    ledgerId: j["supplier_id"],
    ledgerName: j["supplier_name"],
    address0: j["address_0"],
    address1: j["address_1"],
    placeOfSupply: j["place_of_supply"],
    mobile: (j["mobile"] ?? "").toString(),

    prefix: j["prefix"],
    no: j["no"],
    transId: j["purchaseinvoice_id"],
    transNo: j["purchaseinvoice_no"],
    creditNoteDate: DateTime.parse(j["purchasenote_date"]),

    caseSale: j["case_sale"] ?? false,

    notes: List<String>.from(j["add_note"] ?? []),
    terms: List<String>.from(j["te_co"] ?? []),

    subTotal: (j["sub_totle"] ?? 0).toDouble(),
    subGst: (j["sub_gst"] ?? 0).toDouble(),
    autoRound: j["auto_ro"] ?? false,
    totalAmount: (j["totle_amo"] ?? 0).toDouble(),

    additionalCharges: (j["additional_charges"] as List)
        .map((e) => ChargeModel.fromJson(e))
        .toList(),

    discountLines: (j["discount"] as List)
        .map((e) => DiscountModel.fromJson(e))
        .toList(),

    miscCharges: (j["misccharge"] as List)
        .map((e) => MiscChargeModel.fromJson(e))
        .toList(),

    itemDetails: (j["item_details"] as List)
        .map((e) => ItemDetail.fromJson(e))
        .toList(),

    signature: j["signature"] ?? "",
    createdAt: DateTime.parse(j["createdAt"]),
    updatedAt: DateTime.parse(j["updatedAt"]),
  );

  toPrintModel() {}
}
