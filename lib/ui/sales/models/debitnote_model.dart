import 'dart:convert';

import 'package:ims/ui/sales/models/globalget_model.dart';

DebitNoteListResponse debitNoteListResponseFromJson(String str) =>
    DebitNoteListResponse.fromJson(json.decode(str));

class DebitNoteListResponse {
  final bool status;
  final String? message;
  final List<DebitNoteData> data;

  DebitNoteListResponse({
    required this.status,
    this.message,
    required this.data,
  });

  factory DebitNoteListResponse.fromJson(Map<String, dynamic> json) =>
      DebitNoteListResponse(
        status: json["status"] ?? false,
        message: json["message"],
        data: json["data"] == null
            ? []
            : List<DebitNoteData>.from(
                json["data"].map((x) => DebitNoteData.fromJson(x)),
              ),
      );
}

class DebitNoteData {
  final String id;
  final int licenceNo;
  final String branchId;

  final String? customerId;
  final String customerName;
  final String address0;
  final String address1;
  final String placeOfSupply;
  final String mobile;
  final int invoiceNo;
  final String invoiceId;

  final String prefix;
  final int no;
  final DateTime debitNoteDate;

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

  final List<NoteItemDetail> itemDetails;

  final String signature;

  DebitNoteData({
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
    required this.no,
    required this.debitNoteDate,
    required this.invoiceNo,
    required this.invoiceId,
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

  factory DebitNoteData.fromJson(Map<String, dynamic> j) => DebitNoteData(
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
    invoiceId: j["invoice_id"],
    invoiceNo: j["invoice_no"],
    debitNoteDate: DateTime.parse(j["debitnote_date"]),

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
        .map((e) => NoteItemDetail.fromJson(e))
        .toList(),

    signature: j["signature"] ?? "",
  );

  toPrintModel() {}
}

class NoteItemDetail {
  final String id;
  final String name;
  final double price;
  final String hsn;
  final double gstRate;
  final double qty;
  final double amount;
  final double discount;
  final bool inclusive;

  NoteItemDetail({
    required this.id,
    required this.name,
    required this.price,
    required this.hsn,
    required this.gstRate,
    required this.qty,
    required this.amount,
    required this.discount,
    required this.inclusive,
  });

  factory NoteItemDetail.fromJson(Map<String, dynamic> j) => NoteItemDetail(
    id: j["_id"],
    name: j["item_name"],
    price: (j["price"] ?? 0).toDouble(),
    hsn: j["hsn_code"],
    gstRate: (j["gst_tax_rate"] ?? 0).toDouble(),
    qty: (j["qty"] ?? 0).toDouble(),
    amount: (j["amount"] ?? 0).toDouble(),
    discount: (j["discount"] ?? 0).toDouble(),
    inclusive: j["in_ex"] ?? false,
  );
}
