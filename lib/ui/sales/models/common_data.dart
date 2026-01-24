import 'package:ims/ui/sales/models/globalget_model.dart';

class GlobalDataAll {
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

  final bool caseSale;

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

  GlobalDataAll({
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
    required this.caseSale,
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

  factory GlobalDataAll.fromJson(Map<String, dynamic> j) => GlobalDataAll(
    id: j["_id"] ?? "",
    licenceNo: j["licence_no"],
    branchId: j["branch_id"] ?? "",
    customerId: j["customer_id"] ?? "",
    customerName: j["customer_name"] ?? "",
    address0: j["address_0"] ?? "",
    address1: j["address_1"] ?? "",
    mobile: j["mobile"].toString(),

    prefix: j["prefix"] ?? "",
    no: j["no"] ?? 0,
    caseSale: j["case_sale"] ?? false,

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

class GlobalDataAllPurchase {
  final String id;
  final int licenceNo;
  final String branchId;

  final String? ledgerId;
  final String ledgerName;
  final String address0;
  final String address1;
  final String mobile;

  final String prefix;
  final int no;

  final bool caseSale;

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

  GlobalDataAllPurchase({
    required this.id,
    required this.licenceNo,
    required this.branchId,
    this.ledgerId,
    required this.ledgerName,
    required this.address0,
    required this.address1,
    required this.mobile,
    required this.prefix,
    required this.no,
    required this.caseSale,
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

  factory GlobalDataAllPurchase.fromJson(Map<String, dynamic> j) =>
      GlobalDataAllPurchase(
        id: j["_id"] ?? "",
        licenceNo: j["licence_no"],
        branchId: j["branch_id"] ?? "",
        ledgerId: j["supplier_id"] ?? "",
        ledgerName: j["supplier_name"] ?? "",
        address0: j["address_0"] ?? "",
        address1: j["address_1"] ?? "",
        mobile: j["mobile"].toString(),

        prefix: j["prefix"] ?? "",
        no: j["no"] ?? 0,
        caseSale: j["case_sale"] ?? false,

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
}
