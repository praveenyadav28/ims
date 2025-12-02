// items_table_section.dart
import 'package:dotted_border/dotted_border.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:ims/ui/sales/estimate/models/estimate_models.dart';
import 'package:ims/ui/sales/estimate/state/estimate_bloc.dart';
import 'package:ims/utils/colors.dart';
import 'package:ims/utils/textfield.dart';
import 'package:searchfield/searchfield.dart';

class ItemsTableSection extends StatelessWidget {
  ItemsTableSection({super.key, required this.state, required this.bloc});

  final EstState state;
  final EstBloc bloc;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 20),
      decoration: BoxDecoration(
        color: AppColor.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColor.borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
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
          Container(
            color: const Color(0xffF3F4F6),
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Row(
              children: [
                Expanded(
                  flex: 2,
                  child: Text('Item/Service', textAlign: TextAlign.center),
                ),
                SizedBox(width: 8),
                Expanded(child: Text('HSN/SAC', textAlign: TextAlign.center)),
                SizedBox(width: 8),
                Expanded(child: Text('QTY', textAlign: TextAlign.center)),
                SizedBox(width: 8),
                Expanded(child: Text('UNIT', textAlign: TextAlign.center)),
                const SizedBox(width: 8),

                Expanded(child: Text('PRICE', textAlign: TextAlign.center)),
                const SizedBox(width: 8),

                Expanded(child: Text('DISCOUNT', textAlign: TextAlign.center)),
                const SizedBox(width: 8),

                Expanded(child: Text('TAX', textAlign: TextAlign.center)),
                const SizedBox(width: 8),

                Expanded(
                  child: Text('AMOUNT (₹)', textAlign: TextAlign.center),
                ),
                IconButton(
                  onPressed: () {},
                  icon: Icon(Icons.delete, color: Colors.transparent),
                ),
              ],
            ),
          ),
          const Divider(),
          Column(
            children: state.rows
                .map(
                  (row) =>
                      _EstimateRowWidget(row: row, state: state, bloc: bloc),
                )
                .toList(),
          ),
          const SizedBox(height: 12),
          DottedBorder(
            child: InkWell(
              onTap: () {
                bloc.add(EstAddRow());
              },
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
}

class _EstimateRowWidget extends StatefulWidget {
  const _EstimateRowWidget({
    Key? key,
    required this.row,
    required this.state,
    required this.bloc,
  }) : super(key: key);

  final EstimateRow row;
  final EstState state;
  final EstBloc bloc;

  @override
  State<_EstimateRowWidget> createState() => _EstimateRowWidgetState();
}

class _EstimateRowWidgetState extends State<_EstimateRowWidget> {
  late TextEditingController qtyCtrl;
  late TextEditingController priceCtrl;
  late TextEditingController discCtrl;
  late TextEditingController taxCtrl;
  late TextEditingController hsnCtrl;

  late FocusNode qtyFocus;
  late FocusNode priceFocus;
  late FocusNode discFocus;

  @override
  void initState() {
    super.initState();
    qtyFocus = FocusNode();
    priceFocus = FocusNode();
    discFocus = FocusNode();

    _initControllers();

    qtyFocus.addListener(() => _pushUpdateOnBlur());
    priceFocus.addListener(() => _pushUpdateOnBlur());
    discFocus.addListener(() => _pushUpdateOnBlur());
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
  void didUpdateWidget(covariant _EstimateRowWidget oldWidget) {
    super.didUpdateWidget(oldWidget);

    final r = widget.row;

    if (!qtyFocus.hasFocus) qtyCtrl.text = r.qty.toString();
    if (!priceFocus.hasFocus) {
      priceCtrl.text = r.pricePerSelectedUnit.toStringAsFixed(2);
    }
    if (!discFocus.hasFocus) discCtrl.text = r.discountPercent.toString();
    taxCtrl.text = r.taxPercent.toStringAsFixed(2);

    hsnCtrl.text = r.hsnOverride.isNotEmpty
        ? r.hsnOverride
        : (r.product?.hsn ?? '');
  }

  void _pushUpdateOnBlur() {
    if (qtyFocus.hasFocus || priceFocus.hasFocus || discFocus.hasFocus) return;

    final r = widget.row;

    final q = int.tryParse(qtyCtrl.text);
    final p = double.tryParse(priceCtrl.text);
    final d = double.tryParse(discCtrl.text);

    final updated = r
        .copyWith(
          qty: q ?? r.qty,
          pricePerSelectedUnit: p ?? r.pricePerSelectedUnit,
          discountPercent: d ?? r.discountPercent,
        )
        .recalc();

    widget.bloc.add(EstUpdateRow(updated));
  }

  @override
  Widget build(BuildContext context) {
    final r = widget.row;
    final s = widget.state;
    final bloc = widget.bloc;

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
        borderSide: BorderSide(color: Color(0xFFDEE1E6), width: 1),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(6),
        borderSide: BorderSide(color: Color(0xFFDEE1E6), width: 1),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(6),
        borderSide: BorderSide(color: const Color(0xFF565D6D), width: 1),
      ),
    );

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 15),
      child: Row(
        children: [
          /// ITEM
          Expanded(
            flex: 2,
            child: _ItemSelector(row: r, catalog: s.catalogue, bloc: bloc),
          ),
          const SizedBox(width: 8),

          /// HSN
          Expanded(
            child: SearchField<HsnModel>(
              key: ValueKey(r.localId + "_hsn"),
              suggestions: s.hsnMaster
                  .map((h) => SearchFieldListItem(h.code, item: h))
                  .toList(),
              searchInputDecoration: input.copyWith(labelText: "HSN"),
              selectedValue: hsnCtrl.text.isNotEmpty
                  ? SearchFieldListItem(hsnCtrl.text)
                  : null,
              onSuggestionTap: (sugg) =>
                  bloc.add(EstApplyHsnToRow(r.localId, sugg.item!)),
            ),
          ),
          const SizedBox(width: 8),

          /// QTY +/-
          Expanded(
            child: Row(
              children: [
                IconButton(
                  onPressed: () {
                    if (r.qty > 1) {
                      final updated = r.copyWith(qty: r.qty - 1).recalc();
                      bloc.add(EstUpdateRow(updated));
                    }
                  },
                  icon: const Icon(Icons.remove),
                ),
                Expanded(
                  child: TextField(
                    controller: qtyCtrl,
                    focusNode: qtyFocus,
                    textAlign: TextAlign.center,
                    keyboardType: TextInputType.number,
                    decoration: input.copyWith(labelText: "Qty"),
                  ),
                ),
                IconButton(
                  onPressed: () {
                    final updated = r.copyWith(qty: r.qty + 1).recalc();
                    bloc.add(EstUpdateRow(updated));
                  },
                  icon: const Icon(Icons.add),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),

          /// UNIT
          Expanded(
            child: _UnitDropdown(row: r, bloc: bloc),
          ),
          const SizedBox(width: 8),

          /// PRICE
          Expanded(
            child: TextField(
              controller: priceCtrl,
              focusNode: priceFocus,
              keyboardType: TextInputType.number,
              decoration: input.copyWith(labelText: "Price"),
            ),
          ),
          const SizedBox(width: 8),

          /// DISCOUNT
          Expanded(
            child: TextField(
              controller: discCtrl,
              focusNode: discFocus,
              keyboardType: TextInputType.number,
              decoration: input.copyWith(labelText: "%"),
            ),
          ),
          const SizedBox(width: 8),

          /// TAX + Inclusive toggle
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

                    bloc.add(EstUpdateRow(updated));
                  },
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),

          /// AMOUNT
          Expanded(
            child: Text(
              "₹ ${r.gross.toStringAsFixed(2)}",
              style: const TextStyle(fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
          ),

          /// DELETE
          IconButton(
            onPressed: () => bloc.add(EstRemoveRow(r.localId)),
            icon: const Icon(Icons.delete, color: Colors.red),
          ),
        ],
      ),
    );
  }
}

class _ItemSelector extends StatelessWidget {
  _ItemSelector({required this.row, required this.catalog, required this.bloc});

  final EstimateRow row;
  final List<ItemServiceModel> catalog;
  final EstBloc bloc;

  @override
  Widget build(BuildContext context) {
    return SearchField<ItemServiceModel>(
      key: ValueKey(row.localId),
      suggestions: catalog
          .map(
            (i) => SearchFieldListItem<ItemServiceModel>(
              "${i.name} - ${i.itemNo}",
              item: i,
            ),
          )
          .toList(),
      searchInputDecoration: SearchInputDecoration(
        isDense: true,
        filled: true,
        fillColor: AppColor.white,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 12,
        ),
        labelText: "Item / Service",
        labelStyle: GoogleFonts.inter(
          color: const Color(0xFF565D6D),
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6),
          borderSide: BorderSide(color: Color(0xFFDEE1E6), width: 1),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6),
          borderSide: BorderSide(color: Color(0xFFDEE1E6), width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6),
          borderSide: BorderSide(color: const Color(0xFF565D6D), width: 1),
        ),
      ),
      suggestionStyle: GoogleFonts.inter(
        color: const Color(0xFF565D6D),
        fontSize: 14,
        fontWeight: FontWeight.w500,
      ),
      suggestionItemDecoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: Color(0xFFDEE1E6).withOpacity(0.3)),
      ),
      selectedValue: row.product != null
          ? SearchFieldListItem("${row.product!.name} - ${row.product!.itemNo}")
          : null,
      onSuggestionTap: (s) {
        bloc.add(EstSelectCatalogForRow(row.localId, s.item!));
      },
    );
  }
}

class _UnitDropdown extends StatelessWidget {
  const _UnitDropdown({required this.row, required this.bloc});

  final EstimateRow row;
  final EstBloc bloc;

  @override
  Widget build(BuildContext context) {
    if (row.product == null) return const Text("");
    if (row.product!.conversion <= 1) {
      return Text(""); //row.product!.secondaryUnit
    }

    return CommonDropdownField<bool>(
      value: row.sellInBaseUnit,
      onChanged: (value) {
        bloc.add(EstToggleUnitForRow(row.localId, value ?? false));
      },
      items: [
        DropdownMenuItem(value: false, child: Text(row.product!.secondaryUnit)),
        DropdownMenuItem(value: true, child: Text(row.product!.baseUnit)),
      ],
    );
  }
}
