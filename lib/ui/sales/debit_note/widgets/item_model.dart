class NoteModelItem {
  final String localId;

  final String itemName;
  final String hsnCode;

  final int qty;
  final double price;
  final double discountPercent;
  final double taxPercent;

  final bool gstInclusive;

  final double taxable;
  final double taxAmount;
  final double gross;

  NoteModelItem({
    required this.localId,
    this.itemName = '',
    this.hsnCode = '',
    this.qty = 1,
    this.price = 0,
    this.discountPercent = 0,
    this.taxPercent = 0,
    this.gstInclusive = true,
    this.taxable = 0,
    this.taxAmount = 0,
    this.gross = 0,
  });

  NoteModelItem copyWith({
    String? itemName,
    String? hsnCode,
    int? qty,
    double? price,
    double? discountPercent,
    double? taxPercent,
    bool? gstInclusive,
    double? taxable,
    double? taxAmount,
    double? gross,
  }) {
    return NoteModelItem(
      localId: localId,
      itemName: itemName ?? this.itemName,
      hsnCode: hsnCode ?? this.hsnCode,
      qty: qty ?? this.qty,
      price: price ?? this.price,
      discountPercent: discountPercent ?? this.discountPercent,
      taxPercent: taxPercent ?? this.taxPercent,
      gstInclusive: gstInclusive ?? this.gstInclusive,
      taxable: taxable ?? this.taxable,
      taxAmount: taxAmount ?? this.taxAmount,
      gross: gross ?? this.gross,
    );
  }

  /// 🔥 core calculation
  NoteModelItem recalc() {
    final base = price * qty;
    final discountValue = base * (discountPercent / 100);
    final afterDiscount = base - discountValue;

    double newTaxable;
    double newTax;
    double newGross;

    if (gstInclusive) {
      final divisor = 1 + (taxPercent / 100);
      newTaxable = afterDiscount / divisor;
      newTax = afterDiscount - newTaxable;
      newGross = afterDiscount;
    } else {
      newTaxable = afterDiscount;
      newTax = newTaxable * (taxPercent / 100);
      newGross = newTaxable + newTax;
    }

    return copyWith(
      taxable: newTaxable,
      taxAmount: newTax,
      gross: newGross,
    );
  }
}
