enum ItemServiceType { item, service }

class LedgerModelDrop {
  final String id;
  final String name;
  final String mobile;
  final String? closingBalance;
  final String billingAddress;
  final String shippingAddress;
  final String gstin;
  LedgerModelDrop({
    required this.id,
    required this.name,
    required this.mobile,
    this.closingBalance,
    required this.billingAddress,
    required this.shippingAddress,
    this.gstin = '',
  });

  factory LedgerModelDrop.fromMap(Map<String, dynamic> m) => LedgerModelDrop(
    id: (m['_id'] ?? '').toString(),
    name: (m['ledger_name'] ?? '').toString(),
    mobile: (m['contact_no'] ?? '').toString(),
    closingBalance: (m['closing_balance'] ?? '').toString(),
    billingAddress:
        "${(m['address'] ?? '')}, ${(m['city'] ?? "")}, ${(m['state'] ?? "")}",
    shippingAddress:
        "${(m['address'] ?? '')}, ${(m['city'] ?? "")}, ${(m['state'] ?? "")}",
    gstin: (m['gst_no'] ?? '').toString(),
  );
}

class VariantModel {
  final String id;
  final String name;
  final String itemNo;
  final double salePrice; // per secondary unit (piece)
  final double purchasePrice; // per secondary unit (piece)
  final int stockSecondary;
  VariantModel({
    required this.id,
    required this.name,
    required this.itemNo,
    required this.salePrice,
    required this.purchasePrice,
    required this.stockSecondary,
  });
  factory VariantModel.fromMap(Map<String, dynamic> m) {
    return VariantModel(
      id: (m['_id'] ?? '').toString(),
      name: (m['variant_name'] ?? m['name'] ?? '').toString(),
      itemNo: (m['item_no'] ?? '').toString(),
      salePrice:
          double.tryParse(
            (m['sales_price'] ?? m['sale_price'] ?? '0').toString(),
          ) ??
          0,
      purchasePrice:
          double.tryParse(
            (m['purchases_price'] ?? m['purchase_price'] ?? '0').toString(),
          ) ??
          0,
      stockSecondary: (m['opening_stock'] != null)
          ? int.tryParse(m['opening_stock'].toString()) ?? 0
          : 0,
    );
  }
}

class ItemServiceModel {
  final String id;
  final ItemServiceType type;
  final String name;
  final String hsn;
  final String variantValue;
  final double? baseSalePrice;
  final double? basePurchasePrice;
  final double gstRate;
  final bool gstIncluded;
  final String baseUnit;
  final String secondaryUnit;
  final String? stockQty;
  final int conversion;
  final List<VariantModel> variants;
  final String itemNo;
  final String group;
  final String reOLevel;

  ItemServiceModel({
    required this.id,
    required this.type,
    required this.name,
    required this.hsn,
    required this.variantValue,
    this.baseSalePrice,
    this.basePurchasePrice,
    required this.gstRate,
    required this.gstIncluded,
    this.stockQty,
    required this.baseUnit,
    required this.secondaryUnit,
    required this.conversion,
    required this.variants,
    this.itemNo = '',
    this.group = '',
    this.reOLevel = '',
  });

  factory ItemServiceModel.fromItem(Map<String, dynamic> m) {
    final varList = <VariantModel>[];
    if (m['variant_list'] is List) {
      for (var v in (m['variant_list'] as List)) {
        try {
          varList.add(VariantModel.fromMap(Map<String, dynamic>.from(v)));
        } catch (_) {}
      }
    }
    return ItemServiceModel(
      id: (m['_id'] ?? '').toString(),
      type: ItemServiceType.item,
      name: m['item_name']?.toString() ?? '',
      stockQty: m['stock_qty']?.toString() ?? '0',
      hsn: m['hsn_code']?.toString() ?? '',
      variantValue: m['variant_name']?.toString() ?? '',
      baseSalePrice: (m['sales_price'] != null)
          ? double.tryParse(m['sales_price'].toString()) ?? 0
          : 0,
      basePurchasePrice: (m['purchase_price_se'] != null)
          ? double.tryParse(m['purchase_price_se'].toString()) ?? 0
          : 0,
      gstRate: (m['gst_tax_rate'] != null)
          ? double.tryParse(m['gst_tax_rate'].toString()) ?? 0
          : 0,
      gstIncluded: m['gst_include'] ?? false,
      baseUnit: m['baseunit']?.toString() ?? 'Base',
      secondaryUnit: m['secondryunit']?.toString() ?? 'Unit',
      conversion: (m['convertion_amount'] != null)
          ? int.tryParse(m['convertion_amount'].toString()) ?? 1
          : 1,
      variants: varList,
      itemNo: m['item_no']?.toString() ?? '',
      group: m['group']?.toString() ?? '',
      reOLevel: m['re_o_level']?.toString() ?? '',
    );
  }

  factory ItemServiceModel.fromService(Map<String, dynamic> m) {
    return ItemServiceModel(
      id: (m['_id'] ?? '').toString(),
      type: ItemServiceType.service,
      name: m['service_name']?.toString() ?? '',
      hsn: m['hsn']?.toString() ?? '',
      stockQty: '',
      variantValue: m['variant_name']?.toString() ?? '',
      baseSalePrice: (m['basic_price'] != null)
          ? double.tryParse(m['basic_price'].toString()) ?? 0
          : 0,
      gstRate: (m['gst_rate'] != null)
          ? double.tryParse(m['gst_rate'].toString()) ?? 0
          : 0,
      gstIncluded: m['gst_include'] ?? false,
      baseUnit: m['baseunit']?.toString() ?? '',
      secondaryUnit: '',
      conversion: 1,
      variants: const [],
      itemNo: m['service_no']?.toString() ?? '',
      group: m['group']?.toString() ?? '',
    );
  }
}

class GlobalItemRow {
  final String localId;
  final ItemServiceModel? product;
  final VariantModel? selectedVariant;

  final int qty;
  final double pricePerSelectedUnit;
  final double discountPercent;

  final String hsnOverride;
  final double taxPercent;

  final bool gstInclusiveToggle;
  final bool sellInBaseUnit;

  final double taxable;
  final double taxAmount;
  final double gross;

  GlobalItemRow({
    required this.localId,
    this.product,
    this.selectedVariant,
    this.qty = 1,
    this.pricePerSelectedUnit = 0,
    this.discountPercent = 0,
    this.hsnOverride = '',
    this.taxPercent = 0,
    this.gstInclusiveToggle = true,
    this.sellInBaseUnit = false,
    this.taxable = 0,
    this.taxAmount = 0,
    this.gross = 0,
  });

  GlobalItemRow copyWith({
    ItemServiceModel? product,
    VariantModel? selectedVariant,
    int? qty,
    double? pricePerSelectedUnit,
    double? discountPercent,
    String? hsnOverride,
    double? taxPercent,
    bool? gstInclusiveToggle,
    bool? sellInBaseUnit,
    double? taxable,
    double? taxAmount,
    double? gross,
  }) {
    return GlobalItemRow(
      localId: localId,
      product: product ?? this.product,
      selectedVariant: selectedVariant ?? this.selectedVariant,
      qty: qty ?? this.qty,
      pricePerSelectedUnit: pricePerSelectedUnit ?? this.pricePerSelectedUnit,
      discountPercent: discountPercent ?? this.discountPercent,
      hsnOverride: hsnOverride ?? this.hsnOverride,
      taxPercent: taxPercent ?? this.taxPercent,
      gstInclusiveToggle: gstInclusiveToggle ?? this.gstInclusiveToggle,
      sellInBaseUnit: sellInBaseUnit ?? this.sellInBaseUnit,
      taxable: taxable ?? this.taxable,
      taxAmount: taxAmount ?? this.taxAmount,
      gross: gross ?? this.gross,
    );
  }

  /// ✅ PURE calc — returns new updated immutable row
  GlobalItemRow recalc() {
    final base = pricePerSelectedUnit * qty;
    final discountValue = base * (discountPercent / 100);
    final afterDiscount = base - discountValue;

    double newTaxable;
    double newTax;
    double newGross;

    if (gstInclusiveToggle) {
      final divisor = 1 + (taxPercent / 100);
      newTaxable = afterDiscount / divisor;
      newTax = afterDiscount - newTaxable;
      newGross = afterDiscount;
    } else {
      newTaxable = afterDiscount;
      newTax = newTaxable * (taxPercent / 100);
      newGross = newTaxable + newTax;
    }

    return copyWith(taxable: newTaxable, taxAmount: newTax, gross: newGross);
  }
}

class AdditionalCharge {
  String id;
  String name;
  double amount;
  double taxPercent;
  bool taxIncluded;
  AdditionalCharge({
    required this.id,
    required this.name,
    required this.amount,
    this.taxPercent = 0,
    this.taxIncluded = false,
  });
}

class DiscountLine {
  String id;
  String name;
  double amount;
  bool isPercent;
  DiscountLine({
    required this.id,
    required this.name,
    required this.amount,
    this.isPercent = true,
  });
}

class HsnModel {
  final String id;
  final String code;
  final double igst;
  final double cgst;
  final double sgst;

  HsnModel({
    required this.id,
    required this.code,
    required this.igst,
    required this.cgst,
    required this.sgst,
  });

  factory HsnModel.fromMap(Map<String, dynamic> map) {
    return HsnModel(
      id: map["_id"]?.toString() ?? "",
      code: map["name"] ?? "",
      igst: double.tryParse(map["igst"].toString()) ?? 0,
      cgst: double.tryParse(map["cgst"].toString()) ?? 0,
      sgst: double.tryParse(map["sgst"].toString()) ?? 0,
    );
  }
}

class GlobalMiscChargeEntry {
  String id;
  String miscId;
  String ledgerId;
  String name;
  String? hsn;
  double gst;
  double amount;
  bool taxIncluded;

  GlobalMiscChargeEntry({
    required this.id,
    required this.miscId,
    required this.ledgerId,
    required this.name,
    this.hsn,
    this.gst = 0,
    required this.amount,
    this.taxIncluded = false,
  });

  Map<String, dynamic> toJson() {
    return {
      "misc_id": miscId,
      "ledger_id": ledgerId,
      "name": name,
      "hsn": hsn ?? "",
      "gst": gst,
      "amount": amount,
      "inclusive": taxIncluded,
    };
  }
}
