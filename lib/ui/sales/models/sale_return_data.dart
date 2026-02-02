import 'dart:convert';

import 'package:ims/ui/sales/models/globalget_model.dart';

SaleReturnListResponse saleReturnListResponseFromJson(String str) =>
    SaleReturnListResponse.fromJson(json.decode(str));

class SaleReturnListResponse {
  final bool status;
  final String? message;
  final List<SaleReturnData> data;

  SaleReturnListResponse({
    required this.status,
    this.message,
    required this.data,
  });

  factory SaleReturnListResponse.fromJson(Map<String, dynamic> json) =>
      SaleReturnListResponse(
        status: json["status"] ?? false,
        message: json["message"],
        data: json["data"] == null
            ? []
            : List<SaleReturnData>.from(
                json["data"].map((x) => SaleReturnData.fromJson(x)),
              ),
      );
}

class SaleReturnData {
  final String id;
  final int licenceNo;
  final String branchId;

  final String? customerId;
  final String customerName;
  final String address0;
  final String address1;
  final String placeOfSupply;
  final String mobile;

  final String prefix;
  final int no;
  final DateTime saleReturnDate;

  final int paymentTerms;
  final bool caseSale;
  final int transNo;
  final String transId;

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
  final DateTime createdAt;
  final DateTime updatedAt;

  SaleReturnData({
    required this.id,
    required this.licenceNo,
    required this.branchId,
    this.customerId,
    required this.customerName,
    required this.address0,
    required this.address1,
    required this.placeOfSupply,
    required this.mobile,
    required this.prefix,
    required this.transNo,
    required this.transId,
    required this.no,
    required this.saleReturnDate,
    required this.paymentTerms,
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
    required this.createdAt,
    required this.updatedAt,
  });

  factory SaleReturnData.fromJson(Map<String, dynamic> j) => SaleReturnData(
    id: j["_id"],
    licenceNo: j["licence_no"],
    branchId: j["branch_id"],
    customerId: j["customer_id"],
    customerName: j["customer_name"],
    address0: j["address_0"],
    address1: j["address_1"],
    placeOfSupply: j["place_of_supply"],
    mobile: (j["mobile"] ?? "").toString(),

    prefix: j["prefix"],
    no: j["no"],
    saleReturnDate: DateTime.parse(j["returnsale_date"]),

    paymentTerms: j["payment_terms"] ?? 0,
    caseSale: j["case_sale"] ?? false,

    notes: List<String>.from(j["add_note"] ?? []),
    terms: List<String>.from(j["te_co"] ?? []),

    transId: j["invoice_id"] ?? "",
    transNo: j["invoice_no"] ?? 0,
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
    createdAt: DateTime.parse(j["createdAt"]),
    updatedAt: DateTime.parse(j["updatedAt"]),
  );
}
