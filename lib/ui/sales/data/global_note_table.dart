// global_items_table_section.dart
import 'package:dotted_border/dotted_border.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:ims/ui/sales/debit_note/widgets/item_model.dart';
import 'package:ims/utils/colors.dart';
import 'package:searchfield/searchfield.dart';
import '../models/global_models.dart';

class NoteItemsTableSection extends StatelessWidget {
  const NoteItemsTableSection({
    super.key,
    required this.rows,
    required this.hsnList,
    required this.onAddRow,
    required this.onRemoveRow,
    required this.onUpdateRow,
    required this.onSelectHsn,
  });

  final List<NoteModelItem> rows;
  final List<HsnModel> hsnList;

  final VoidCallback onAddRow;
  final Function(String rowId) onRemoveRow;
  final Function(NoteModelItem row) onUpdateRow;
  final Function(String rowId, HsnModel hsn) onSelectHsn;

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
            'Notes',
            style: GoogleFonts.roboto(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppColor.textColor,
            ),
          ),
          const SizedBox(height: 10),
          _buildHeader(),
          const Divider(),
          SizedBox(
            height: rows.length <= 3 ? rows.length * 70 : 200,
            child: SingleChildScrollView(
              child: Column(
                children: rows.map((r) {
                  return _NoteItemRowWidget(
                    key: ValueKey(r.localId),
                    row: r,
                    hsnList: hsnList,
                    onUpdate: onUpdateRow,
                    onRemove: () => onRemoveRow(r.localId),
                    onSelectHsn: (hsn) => onSelectHsn(r.localId, hsn),
                  );
                }).toList(),
              ),
            ),
          ),
          const SizedBox(height: 12),
          DottedBorder(
            options: RectDottedBorderOptions(
              color: AppColor.primarydark,
              dashPattern: [2, 4],
            ),

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
          Icon(Icons.cancel, color: Colors.transparent),
        ],
      ),
    );
  }
}

class _NoteItemRowWidget extends StatefulWidget {
  const _NoteItemRowWidget({
    super.key,
    required this.row,
    required this.hsnList,
    required this.onUpdate,
    required this.onRemove,
    required this.onSelectHsn,
  });

  final NoteModelItem row;
  final List<HsnModel> hsnList;

  final Function(NoteModelItem) onUpdate;
  final VoidCallback onRemove;
  final Function(HsnModel) onSelectHsn;

  @override
  State<_NoteItemRowWidget> createState() => _NoteItemRowWidgetState();
}

class _NoteItemRowWidgetState extends State<_NoteItemRowWidget> {
  late TextEditingController nameCtrl;
  late TextEditingController qtyCtrl;
  late TextEditingController priceCtrl;
  late TextEditingController discCtrl;
  late TextEditingController taxCtrl;
  late TextEditingController hsnCtrl;

  late FocusNode qtyF;
  late FocusNode priceF;
  late FocusNode nameF;
  late FocusNode discF;

  @override
  void initState() {
    super.initState();
    qtyF = FocusNode();
    priceF = FocusNode();
    discF = FocusNode();
    nameF = FocusNode();

    _initControllers();

    qtyF.addListener(_pushUpdateOnBlur);
    priceF.addListener(_pushUpdateOnBlur);
    discF.addListener(_pushUpdateOnBlur);
    nameF.addListener(_pushUpdateOnBlur);
  }

  void _initControllers() {
    final r = widget.row;
    nameCtrl = TextEditingController(text: r.itemName.toString());
    qtyCtrl = TextEditingController(text: r.qty.toString());
    priceCtrl = TextEditingController(text: r.price.toStringAsFixed(2));
    discCtrl = TextEditingController(text: r.discountPercent.toString());
    taxCtrl = TextEditingController(text: r.taxPercent.toStringAsFixed(2));
    hsnCtrl = TextEditingController(text: r.hsnCode);
  }

  @override
  void didUpdateWidget(covariant _NoteItemRowWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    final r = widget.row;

    // Only overwrite controllers when user is not editing (preserve focus)
    if (!qtyF.hasFocus) qtyCtrl.text = r.qty.toString();
    if (!priceF.hasFocus) priceCtrl.text = r.price.toStringAsFixed(2);
    if (!discF.hasFocus) discCtrl.text = r.discountPercent.toString();
    taxCtrl.text = r.taxPercent.toStringAsFixed(2);
    hsnCtrl.text = r.hsnCode;
  }

  void _pushUpdateOnBlur() {
    if (qtyF.hasFocus || priceF.hasFocus || discF.hasFocus) return;

    final r = widget.row;

    final name = nameCtrl.text;
    final q = int.tryParse(qtyCtrl.text) ?? r.qty;
    final p = double.tryParse(priceCtrl.text) ?? r.price;
    final d = double.tryParse(discCtrl.text) ?? r.discountPercent;

    final updated = r
        .copyWith(itemName: name, qty: q, price: p, discountPercent: d)
        .recalc();

    widget.onUpdate(updated);
  }

  @override
  void dispose() {
    qtyF.dispose();
    priceF.dispose();
    discF.dispose();
    nameCtrl.dispose();
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
            child: TextField(
              controller: nameCtrl,
              focusNode: nameF,
              decoration: input.copyWith(labelText: "Note Type"),
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
                  value: r.gstInclusive,
                  onChanged: (val) {
                    final updated = r
                        .copyWith(gstInclusive: val ?? false)
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
            icon: const Icon(Icons.cancel, color: Colors.red),
          ),
        ],
      ),
    );
  }
}
