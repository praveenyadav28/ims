import 'dart:convert';

import 'package:ims/ui/sales/models/globalget_model.dart';

PurchaseReturnListResponse purchaseReturnListResponseFromJson(String str) =>
    PurchaseReturnListResponse.fromJson(json.decode(str));

class PurchaseReturnListResponse {
  final bool status;
  final String? message;
  final List<PurchaseReturnData> data;

  PurchaseReturnListResponse({
    required this.status,
    this.message,
    required this.data,
  });

  factory PurchaseReturnListResponse.fromJson(Map<String, dynamic> json) =>
      PurchaseReturnListResponse(
        status: json["status"] ?? false,
        message: json["message"],
        data: json["data"] == null
            ? []
            : List<PurchaseReturnData>.from(
                json["data"].map((x) => PurchaseReturnData.fromJson(x)),
              ),
      );
}

class PurchaseReturnData {
  final String id;
  final int licenceNo;
  final String branchId;

  final String? supplierId;
  final String supplierName;
  final String address0;
  final String address1;
  final String mobile;

  final String prefix;
  final int no;
  final DateTime purchaseReturnDate;

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

  PurchaseReturnData({
    required this.id,
    required this.licenceNo,
    required this.branchId,
    this.supplierId,
    required this.supplierName,
    required this.address0,
    required this.address1,
    required this.mobile,
    required this.prefix,
    required this.no,
    required this.purchaseReturnDate,
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
  });

  factory PurchaseReturnData.fromJson(Map<String, dynamic> j) =>
      PurchaseReturnData(
        id: j["_id"],
        licenceNo: j["licence_no"],
        branchId: j["branch_id"],
        supplierId: j["supplier_id"],
        supplierName: j["supplier_name"],
        address0: j["address_0"],
        address1: j["address_1"],
        mobile: j["mobile"].toString(),

        prefix: j["prefix"],
        no: j["no"],
        purchaseReturnDate: DateTime.parse(j["purchasereturn_date"]),

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
      );
}
