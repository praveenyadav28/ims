class ItemModel {
  final String id;
  final String itemType;
  final String itemName;
  final String itemNo;
  final String group;
  final String salesPrice;
  final String purchasePrice;
  final String hsnCode;
  final String baseUnit;
  final String secondaryUnit;
  final String conversionAmount;
  final bool gstInclude;
  final bool gstIncludePurchase;
  final String gstRate;
  final String openingStock;
  final String closingStock;
  final String inword;
  final String outword;
  final String varientName;
  final String stockQty;
  final String minOrderQty;
  final String minStockQty;
  final String mfgDate;
  final String expiryDate;
  final String margin;
  final String marginAmt;
  final String reorderLevel;

  ItemModel({
    required this.id,
    required this.itemType,
    required this.itemName,
    required this.itemNo,
    required this.group,
    required this.salesPrice,
    required this.purchasePrice,
    required this.hsnCode,
    required this.baseUnit,
    required this.secondaryUnit,
    required this.conversionAmount,
    required this.gstInclude,
    required this.gstIncludePurchase,
    required this.gstRate,
    required this.openingStock,
    required this.inword,
    required this.outword,
    required this.closingStock,
    required this.varientName,
    required this.stockQty,
    required this.minOrderQty,
    required this.minStockQty,
    required this.mfgDate,
    required this.expiryDate,
    required this.margin,
    required this.marginAmt,
    required this.reorderLevel,
  });

  factory ItemModel.fromJson(Map<String, dynamic> json) {
    return ItemModel(
      id: json['_id']?.toString() ?? '',
      itemType: json['item_type']?.toString() ?? '',
      itemName: json['item_name']?.toString() ?? '',
      itemNo: json['item_no']?.toString() ?? '',
      group: (json['group'] ?? json['Group'])?.toString() ?? '',
      salesPrice: json['sales_price']?.toString() ?? '0',
      purchasePrice: json['purchase_price']?.toString() ?? '0',
      hsnCode: json['hsn_code']?.toString() ?? '',
      baseUnit: json['baseunit']?.toString() ?? '',
      secondaryUnit: json['secondryunit']?.toString() ?? '',
      conversionAmount: json['convertion_amount']?.toString() ?? '1',
      gstInclude: json['gst_include'] == true,
      gstIncludePurchase: json['gstinclude_purchase'] == true,
      gstRate: json['gst_tax_rate']?.toString() ?? '',
      openingStock: json['opening_stock']?.toString() ?? '0',
      inword: json['inward']?.toString() ?? '0',
      outword: json['outward']?.toString() ?? '0',
      closingStock: json['closing_stock']?.toString() ?? '0',
      varientName: json['varient_name']?.toString() ?? '',
      stockQty: json['stock_qty']?.toString() ?? '0',
      minOrderQty: json['m_o_qty']?.toString() ?? '0',
      minStockQty: json['m_s_qty']?.toString() ?? '0',
      mfgDate: json['mfg_date']?.toString() ?? '',
      expiryDate: json['expiry_date']?.toString() ?? '',
      margin: json['margin']?.toString() ?? '0',
      marginAmt: json['margin_amt']?.toString() ?? '0',
      reorderLevel: json['re_o_level']?.toString() ?? '0',
    );
  }
}
