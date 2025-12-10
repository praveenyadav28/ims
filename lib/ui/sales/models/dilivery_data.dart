import 'dart:convert';

import 'package:ims/ui/sales/models/globalget_model.dart';

DiliveryChallanListResponse diliveryChallanListResponseFromJson(String str) =>
    DiliveryChallanListResponse.fromJson(json.decode(str));

class DiliveryChallanListResponse {
  final bool status;
  final String? message;
  final List<DiliveryChallanData> data;

  DiliveryChallanListResponse({
    required this.status,
    this.message,
    required this.data,
  });

  factory DiliveryChallanListResponse.fromJson(Map<String, dynamic> json) =>
      DiliveryChallanListResponse(
        status: json["status"] ?? false,
        message: json["message"],
        data: json["data"] == null
            ? []
            : List<DiliveryChallanData>.from(
                json["data"].map((x) => DiliveryChallanData.fromJson(x)),
              ),
      );
}

class DiliveryChallanData {
  final String id;
  final int licenceNo;
  final String branchId;

  final String? customerId;
  final String customerName;
  final String address0;
  final String address1;
  final String mobile;

  final String prefix;
  final int no;
  final DateTime diliveryChallanDate;

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
  final List<ServiceDetail> serviceDetails;

  final String signature;

  DiliveryChallanData({
    required this.id,
    required this.licenceNo,
    required this.branchId,
    this.customerId,
    required this.customerName,
    required this.address0,
    required this.address1,
    required this.mobile,
    required this.prefix,
    required this.no,
    required this.diliveryChallanDate,
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
    required this.serviceDetails,
    required this.signature,
  });

  factory DiliveryChallanData.fromJson(Map<String, dynamic> j) =>
      DiliveryChallanData(
        id: j["_id"],
        licenceNo: j["licence_no"],
        branchId: j["branch_id"],
        customerId: j["customer_id"],
        customerName: j["customer_name"],
        address0: j["address_0"],
        address1: j["address_1"],
        mobile: j["mobile"].toString(),

        prefix: j["prefix"],
        no: j["no"],
        diliveryChallanDate: DateTime.parse(j["dilvery_date"]),

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

        serviceDetails: (j["service_details"] as List)
            .map((e) => ServiceDetail.fromJson(e))
            .toList(),

        signature: j["signature"] ?? "",
      );
}
