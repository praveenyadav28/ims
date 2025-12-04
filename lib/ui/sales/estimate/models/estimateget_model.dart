import 'dart:convert';

EstimateListResponse estimateListResponseFromJson(String str) =>
    EstimateListResponse.fromJson(json.decode(str));

class EstimateListResponse {
  final bool status;
  final String? message;
  final List<EstimateData> data;

  EstimateListResponse({
    required this.status,
    this.message,
    required this.data,
  });

  factory EstimateListResponse.fromJson(Map<String, dynamic> json) =>
      EstimateListResponse(
        status: json["status"] ?? false,
        message: json["message"],
        data: json["data"] == null
            ? []
            : List<EstimateData>.from(
                json["data"].map((x) => EstimateData.fromJson(x)),
              ),
      );
}

// --------------------------------------------------------------------
//                          MAIN ESTIMATE DATA
// --------------------------------------------------------------------

class EstimateData {
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
  final DateTime estimateDate;

  final int paymentTerms;
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
  final DateTime createdAt;
  final DateTime updatedAt;

  EstimateData({
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
    required this.estimateDate,
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

  factory EstimateData.fromJson(Map<String, dynamic> j) => EstimateData(
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
    estimateDate: DateTime.parse(j["estimate_date"]),

    paymentTerms: j["payment_terms"] ?? 0,
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
    createdAt: DateTime.parse(j["createdAt"]),
    updatedAt: DateTime.parse(j["updatedAt"]),
  );
}

// --------------------------------------------------------------------
//                          ITEM DETAILS
// --------------------------------------------------------------------

class ItemDetail {
  final String id;
  final String itemId;
  final String name;
  final int itemNo;
  final double price;
  final String hsn;
  final double gstRate;
  final String unit;
  final double qty;
  final double amount;
  final double discount;
  final bool inclusive;

  ItemDetail({
    required this.id,
    required this.itemId,
    required this.name,
    required this.itemNo,
    required this.price,
    required this.hsn,
    required this.gstRate,
    required this.unit,
    required this.qty,
    required this.amount,
    required this.discount,
    required this.inclusive,
  });

  factory ItemDetail.fromJson(Map<String, dynamic> j) => ItemDetail(
    id: j["_id"],
    itemId: j["item_id"],
    name: j["item_name"],
    itemNo: j["item_no"],
    price: (j["price"] ?? 0).toDouble(),
    hsn: j["hsn_code"],
    gstRate: (j["gst_tax_rate"] ?? 0).toDouble(),
    unit: j["measuring_unit"] ?? "",
    qty: (j["qty"] ?? 0).toDouble(),
    amount: (j["amount"] ?? 0).toDouble(),
    discount: (j["discount"] ?? 0).toDouble(),
    inclusive: j["in_ex"] ?? false,
  );
}

// --------------------------------------------------------------------
//                          SERVICE DETAILS
// --------------------------------------------------------------------

class ServiceDetail {
  final String id;
  final String serviceId;
  final String name;
  final int serviceNo;
  final double price;
  final String hsn;
  final double gstRate;
  final String unit;
  final double qty;
  final double amount;
  final double discount;
  final bool inclusive;

  ServiceDetail({
    required this.id,
    required this.serviceId,
    required this.name,
    required this.serviceNo,
    required this.price,
    required this.hsn,
    required this.gstRate,
    required this.unit,
    required this.qty,
    required this.amount,
    required this.discount,
    required this.inclusive,
  });

  factory ServiceDetail.fromJson(Map<String, dynamic> j) => ServiceDetail(
    id: j["_id"],
    serviceId: j["service_id"],
    name: j["service_name"],
    serviceNo: j["service_no"],
    price: (j["price"] ?? 0).toDouble(),
    hsn: j["hsn_code"],
    gstRate: (j["gst_tax_rate"] ?? 0).toDouble(),
    unit: j["measuring_unit"],
    qty: (j["qty"] ?? 0).toDouble(),
    amount: (j["amount"] ?? 0).toDouble(),
    discount: (j["discount"] ?? 0).toDouble(),
    inclusive: j["in_ex"] ?? false,
  );
}

// --------------------------------------------------------------------
//                           CHARGES
// --------------------------------------------------------------------

class ChargeModel {
  final String id;
  final String name;
  final double amount;

  ChargeModel({required this.id, required this.name, required this.amount});

  factory ChargeModel.fromJson(Map<String, dynamic> j) => ChargeModel(
    id: j["_id"],
    name: j["name"],
    amount: (j["amount"] ?? 0).toDouble(),
  );
}

class DiscountModel {
  final String id;
  final String name;
  final double amount;
  final String type;

  DiscountModel({
    required this.id,
    required this.name,
    required this.amount,
    required this.type,
  });

  factory DiscountModel.fromJson(Map<String, dynamic> j) => DiscountModel(
    id: j["_id"],
    name: j["name"],
    amount: (j["amount"] ?? 0).toDouble(),
    type: j["type"] ?? "amount",
  );
}

class MiscChargeModel {
  final String id;
  final String name;
  final double amount;
  final String type;

  MiscChargeModel({
    required this.id,
    required this.name,
    required this.amount,
    required this.type,
  });

  factory MiscChargeModel.fromJson(Map<String, dynamic> j) => MiscChargeModel(
    id: j["_id"],
    name: j["name"],
    amount: (j["amount"] ?? 0).toDouble(),
    type: j["type"] ?? "",
  );
}
