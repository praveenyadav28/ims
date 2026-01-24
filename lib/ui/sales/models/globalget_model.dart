// --------------------------------------------------------------------
//                          ITEM DETAILS
// --------------------------------------------------------------------

class ItemDetail {
  final String id;
  final String itemId;
  final String name;
  final String itemNo;
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
    itemId: j["item_id"] ?? "",
    name: j["item_name"],
    itemNo: j["item_no"].toString(),
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
    unit: j["measuring_unit"] ?? "",
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
