// global_items_table_section.dart
import 'package:dotted_border/dotted_border.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:ims/utils/colors.dart';
import 'package:ims/utils/textfield.dart';
import 'package:searchfield/searchfield.dart';
import '../models/global_models.dart';

class GlobalItemsTableSection extends StatelessWidget {
  const GlobalItemsTableSection({
    super.key,
    required this.rows,
    required this.catalogue,
    required this.hsnList,
    required this.onAddRow,
    required this.onRemoveRow,
    required this.onUpdateRow,
    required this.onSelectCatalog,
    required this.onSelectHsn,
    required this.onToggleUnit,
  });

  final List<GlobalItemRow> rows;
  final List<ItemServiceModel> catalogue;
  final List<HsnModel> hsnList;

  final VoidCallback onAddRow;
  final Function(String rowId) onRemoveRow;
  final Function(GlobalItemRow row) onUpdateRow;
  final Function(String rowId, ItemServiceModel item) onSelectCatalog;
  final Function(String rowId, HsnModel hsn) onSelectHsn;
  final Function(String rowId, bool value) onToggleUnit;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 20),
      decoration: BoxDecoration(
        color: AppColor.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColor.borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Items / Services',
            style: GoogleFonts.roboto(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppColor.textColor,
            ),
          ),
          const SizedBox(height: 10),
          _buildHeader(),
          const Divider(),
          Column(
            children: rows.map((r) {
              return _GlobalItemRowWidget(
                key: ValueKey(r.localId),
                row: r,
                catalogue: catalogue,
                hsnList: hsnList,
                onUpdate: onUpdateRow,
                onRemove: () => onRemoveRow(r.localId),
                onSelectCatalog: (item) => onSelectCatalog(r.localId, item),
                onSelectHsn: (hsn) => onSelectHsn(r.localId, hsn),
                onToggleUnit: (v) => onToggleUnit(r.localId, v),
              );
            }).toList(),
          ),
          const SizedBox(height: 12),
          DottedBorder(
            child: InkWell(
              onTap: onAddRow,
              child: Container(
                height: 46,
                alignment: Alignment.center,
                child: const Text(
                  '+ Add Item or Service',
                  style: TextStyle(color: Colors.purple),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _gap() => const SizedBox(width: 8);

  Widget _buildHeader() {
    return Container(
      color: const Color(0xffF3F4F6),
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text('Item/Service', textAlign: TextAlign.center),
          ),
          _gap(),
          Expanded(child: Text('HSN/SAC', textAlign: TextAlign.center)),
          _gap(),
          Expanded(child: Text('QTY', textAlign: TextAlign.center)),
          _gap(),
          Expanded(child: Text('UNIT', textAlign: TextAlign.center)),
          _gap(),
          Expanded(child: Text('PRICE', textAlign: TextAlign.center)),
          _gap(),
          Expanded(child: Text('DISCOUNT', textAlign: TextAlign.center)),
          _gap(),
          Expanded(child: Text('TAX', textAlign: TextAlign.center)),
          _gap(),
          Expanded(child: Text('AMOUNT (₹)', textAlign: TextAlign.center)),
          Icon(Icons.delete, color: Colors.transparent),
        ],
      ),
    );
  }
}

class _GlobalItemRowWidget extends StatefulWidget {
  const _GlobalItemRowWidget({
    super.key,
    required this.row,
    required this.catalogue,
    required this.hsnList,
    required this.onUpdate,
    required this.onRemove,
    required this.onSelectCatalog,
    required this.onSelectHsn,
    required this.onToggleUnit,
  });

  final GlobalItemRow row;
  final List<ItemServiceModel> catalogue;
  final List<HsnModel> hsnList;

  final Function(GlobalItemRow) onUpdate;
  final VoidCallback onRemove;
  final Function(ItemServiceModel) onSelectCatalog;
  final Function(HsnModel) onSelectHsn;
  final Function(bool) onToggleUnit;

  @override
  State<_GlobalItemRowWidget> createState() => _GlobalItemRowWidgetState();
}

class _GlobalItemRowWidgetState extends State<_GlobalItemRowWidget> {
  late TextEditingController qtyCtrl;
  late TextEditingController priceCtrl;
  late TextEditingController discCtrl;
  late TextEditingController taxCtrl;
  late TextEditingController hsnCtrl;

  late FocusNode qtyF;
  late FocusNode priceF;
  late FocusNode discF;

  @override
  void initState() {
    super.initState();
    qtyF = FocusNode();
    priceF = FocusNode();
    discF = FocusNode();

    _initControllers();

    qtyF.addListener(_pushUpdateOnBlur);
    priceF.addListener(_pushUpdateOnBlur);
    discF.addListener(_pushUpdateOnBlur);
  }

  void _initControllers() {
    final r = widget.row;
    qtyCtrl = TextEditingController(text: r.qty.toString());
    priceCtrl = TextEditingController(
      text: r.pricePerSelectedUnit.toStringAsFixed(2),
    );
    discCtrl = TextEditingController(text: r.discountPercent.toString());
    taxCtrl = TextEditingController(text: r.taxPercent.toStringAsFixed(2));
    hsnCtrl = TextEditingController(
      text: r.hsnOverride.isNotEmpty ? r.hsnOverride : (r.product?.hsn ?? ''),
    );
  }

  @override
  void didUpdateWidget(covariant _GlobalItemRowWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    final r = widget.row;

    // Only overwrite controllers when user is not editing (preserve focus)
    if (!qtyF.hasFocus) qtyCtrl.text = r.qty.toString();
    if (!priceF.hasFocus)
      priceCtrl.text = r.pricePerSelectedUnit.toStringAsFixed(2);
    if (!discF.hasFocus) discCtrl.text = r.discountPercent.toString();
    taxCtrl.text = r.taxPercent.toStringAsFixed(2);
    hsnCtrl.text = r.hsnOverride.isNotEmpty
        ? r.hsnOverride
        : (r.product?.hsn ?? '');
  }

  void _pushUpdateOnBlur() {
    if (qtyF.hasFocus || priceF.hasFocus || discF.hasFocus) return;

    final r = widget.row;
    final q = int.tryParse(qtyCtrl.text) ?? r.qty;
    final p = double.tryParse(priceCtrl.text) ?? r.pricePerSelectedUnit;
    final d = double.tryParse(discCtrl.text) ?? r.discountPercent;

    final updated = r
        .copyWith(qty: q, pricePerSelectedUnit: p, discountPercent: d)
        .recalc();
    widget.onUpdate(updated);
  }

  @override
  void dispose() {
    qtyF.dispose();
    priceF.dispose();
    discF.dispose();
    qtyCtrl.dispose();
    priceCtrl.dispose();
    discCtrl.dispose();
    taxCtrl.dispose();
    hsnCtrl.dispose();
    super.dispose();
  }

  Widget _gap() => const SizedBox(width: 8);

  @override
  Widget build(BuildContext context) {
    final r = widget.row;

    // Reusable SearchField decoration (keeps old look)
    final input = SearchInputDecoration(
      isDense: true,
      filled: true,
      fillColor: AppColor.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      labelStyle: GoogleFonts.inter(
        color: const Color(0xFF565D6D),
        fontSize: 14,
        fontWeight: FontWeight.w500,
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(6),
        borderSide: BorderSide(color: const Color(0xFFDEE1E6)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(6),
        borderSide: BorderSide(color: const Color(0xFFDEE1E6)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(6),
        borderSide: BorderSide(color: const Color(0xFF565D6D)),
      ),
    );

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 14),
      child: Row(
        children: [
          // ITEM SELECTOR
          Expanded(
            flex: 2,
            child: SearchField<ItemServiceModel>(
              key: ValueKey(r.localId + "_item"),
              itemHeight: 68,
              suggestions: widget.catalogue.map((i) {
                return SearchFieldListItem<ItemServiceModel>(
                  "${i.name} - ${i.itemNo}",
                  item: i,
                  child: ListTile(
                    dense: true,
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF3F4F6),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.shopping_bag_outlined, size: 20),
                    ),
                    title: Text(
                      "${i.name}  •  ${i.itemNo}",
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    subtitle: i.variantValue.isEmpty
                        ? null
                        : Text(i.variantValue),
                  ),
                );
              }).toList(),
              searchInputDecoration: input.copyWith(
                labelText: "Item / Service",
              ),
              suggestionStyle: GoogleFonts.inter(
                color: const Color(0xFF565D6D),
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
              selectedValue: r.product != null
                  ? SearchFieldListItem(
                      "${r.product!.name} - ${r.product!.itemNo}",
                    )
                  : null,
              onSuggestionTap: (s) => widget.onSelectCatalog(s.item!),
            ),
          ),
          _gap(),

          // HSN SELECT
          Expanded(
            child: SearchField<HsnModel>(
              key: ValueKey(r.localId + "_hsn"),
              suggestions: widget.hsnList
                  .map((h) => SearchFieldListItem(h.code, item: h))
                  .toList(),
              searchInputDecoration: input.copyWith(labelText: "HSN"),
              suggestionStyle: GoogleFonts.inter(fontSize: 14),
              selectedValue: hsnCtrl.text.isNotEmpty
                  ? SearchFieldListItem(hsnCtrl.text)
                  : null,
              onSuggestionTap: (s) {
                widget.onSelectHsn(s.item!);
              },
            ),
          ),
          _gap(),

          // QTY +/- and input
          Expanded(
            child: Row(
              children: [
                IconButton(
                  onPressed: () {
                    if (r.qty > 1) {
                      final updated = r.copyWith(qty: r.qty - 1).recalc();
                      widget.onUpdate(updated);
                    }
                  },
                  icon: const Icon(Icons.remove),
                ),
                Expanded(
                  child: TextField(
                    controller: qtyCtrl,
                    focusNode: qtyF,
                    textAlign: TextAlign.center,
                    keyboardType: TextInputType.number,
                    decoration: input.copyWith(labelText: "Qty"),
                  ),
                ),
                IconButton(
                  onPressed: () {
                    final updated = r.copyWith(qty: r.qty + 1).recalc();
                    widget.onUpdate(updated);
                  },
                  icon: const Icon(Icons.add),
                ),
              ],
            ),
          ),
          _gap(),

          // UNIT dropdown (only if conversion > 1)
          Expanded(child: _buildUnitDropdown(r)),
          _gap(),

          // PRICE
          Expanded(
            child: TextField(
              controller: priceCtrl,
              focusNode: priceF,
              keyboardType: TextInputType.number,
              decoration: input.copyWith(labelText: "Price"),
            ),
          ),
          _gap(),

          // DISCOUNT
          Expanded(
            child: TextField(
              controller: discCtrl,
              focusNode: discF,
              keyboardType: TextInputType.number,
              decoration: input.copyWith(labelText: "%"),
            ),
          ),
          _gap(),

          // TAX display + inclusive checkbox
          Expanded(
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: taxCtrl,
                    readOnly: true,
                    decoration: input.copyWith(
                      labelText: "Tax %",
                      fillColor: AppColor.lightblack.withValues(alpha: .04),
                    ),
                  ),
                ),
                Checkbox(
                  value: r.gstInclusiveToggle,
                  onChanged: (val) {
                    final updated = r
                        .copyWith(gstInclusiveToggle: val ?? false)
                        .recalc();
                    widget.onUpdate(updated);
                  },
                ),
              ],
            ),
          ),
          _gap(),

          // AMOUNT
          Expanded(
            child: Text(
              "₹ ${r.gross.toStringAsFixed(2)}",
              textAlign: TextAlign.center,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),

          // DELETE
          IconButton(
            onPressed: widget.onRemove,
            icon: const Icon(Icons.delete, color: Colors.red),
          ),
        ],
      ),
    );
  }

  Widget _buildUnitDropdown(GlobalItemRow r) {
    if (r.product == null) return const SizedBox();
    if (r.product!.conversion <= 1) return const SizedBox();

    return CommonDropdownField<bool>(
      value: r.sellInBaseUnit,
      items: [
        DropdownMenuItem(value: false, child: Text(r.product!.secondaryUnit)),
        DropdownMenuItem(value: true, child: Text(r.product!.baseUnit)),
      ],
      onChanged: (v) {
        final sellInBase = v ?? false;
        // Update unit and price depending on selection
        final basePrice =
            r.selectedVariant?.salePrice ?? r.product?.baseSalePrice ?? 0;
        final newPrice = sellInBase
            ? basePrice * (r.product?.conversion ?? 1)
            : basePrice;
        final updated = r
            .copyWith(
              sellInBaseUnit: sellInBase,
              pricePerSelectedUnit: newPrice,
            )
            .recalc();
        widget.onToggleUnit(sellInBase);
        widget.onUpdate(updated);
      },
    );
  }
}
