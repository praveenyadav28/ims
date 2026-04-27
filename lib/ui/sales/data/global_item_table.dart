// global_items_table_section.dart
// ignore_for_file: must_be_immutable

import 'package:dotted_border/dotted_border.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:ims/ui/inventry/item/create.dart';
import 'package:ims/utils/colors.dart';
import 'package:ims/utils/navigation.dart';
import 'package:ims/utils/prefence.dart';
import 'package:ims/utils/textfield.dart';
import 'package:searchfield/searchfield.dart';
import '../models/global_models.dart';

class GlobalItemsTableSection extends StatefulWidget {
  final String ledgerType;
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
    required this.ledgerType, // 👈
    required this.onSearchItem,
    required this.onAddNextRow,
    this.isReturn,
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
  final Future<List<ItemServiceModel>> Function(String)? onSearchItem;
  final bool? isReturn;
  final Function()? onAddNextRow;

  @override
  State<GlobalItemsTableSection> createState() =>
      _GlobalItemsTableSectionState();
}

class _GlobalItemsTableSectionState extends State<GlobalItemsTableSection> {
  bool showBin = false;
  bool showUnit = false;
  @override
  void initState() {
    super.initState();

    showBin = Preference.getBool("show_bin");
    showUnit = Preference.getBool("show_unit");
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 20),
      decoration: BoxDecoration(
        color: AppColor.white,

        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColor.borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(),
          const Divider(),
          Column(
            children: widget.rows.map((r) {
              return _GlobalItemRowWidget(
                key: ValueKey(r.localId),
                row: r,
                rows: widget.rows,
                catalogue: widget.catalogue,
                hsnList: widget.hsnList,
                onUpdate: widget.onUpdateRow,
                onRemove: () => widget.onRemoveRow(r.localId),
                onSelectCatalog: (item) =>
                    widget.onSelectCatalog(r.localId, item),
                onSelectHsn: (hsn) => widget.onSelectHsn(r.localId, hsn),
                onToggleUnit: (v) => widget.onToggleUnit(r.localId, v),
                isReturn: widget.isReturn,
                ledgerType: widget.ledgerType,
                onSearchItem: widget.onSearchItem,
                onAddNextRow: widget.onAddNextRow,
                showBin: showBin,
                showUnit: showUnit,
              );
            }).toList(),
          ),
          const SizedBox(height: 10),
          if (widget.isReturn ?? true == true)
            DottedBorder(
              options: RectDottedBorderOptions(
                color: AppColor.primarydark,
                dashPattern: [2, 4],
              ),

              child: InkWell(
                onTap: widget.onAddRow,
                child: Container(
                  height: 35,
                  alignment: Alignment.center,
                  child: const Text(
                    '+ Add Items',
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
      decoration: BoxDecoration(
        color: const Color(0xffF3F4F6),
        borderRadius: BorderRadius.circular(10),
      ),
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Expanded(flex: 2, child: Text('Item', textAlign: TextAlign.center)),
          _gap(),
          Expanded(child: Text('HSN/SAC', textAlign: TextAlign.center)),
          _gap(),
          Expanded(child: Text('QTY', textAlign: TextAlign.center)),
          _gap(),
          if (showUnit) ...[
            Expanded(child: Text('UNIT', textAlign: TextAlign.center)),
            _gap(),
          ],

          if (showBin) ...[
            Expanded(child: Text('BIN No.', textAlign: TextAlign.center)),
            _gap(),
          ],
          Expanded(child: Text('PRICE', textAlign: TextAlign.center)),
          _gap(),
          Expanded(child: Text('DISCOUNT', textAlign: TextAlign.center)),
          _gap(),
          Expanded(child: Text('TAX', textAlign: TextAlign.center)),
          _gap(),
          Expanded(child: Text('AMOUNT (₹)', textAlign: TextAlign.center)),
          SizedBox(
            width: 50,
            child: Center(
              child: PopupMenuButton<String>(
                onSelected: (value) {
                  if (value == "bin") {
                    setState(() => showBin = !showBin);
                    Preference.setBool("show_bin", showBin);
                  }

                  if (value == "unit") {
                    setState(() => showUnit = !showUnit);
                    Preference.setBool("show_unit", showUnit);
                  }
                },
                itemBuilder: (context) => [
                  CheckedPopupMenuItem(
                    value: "bin",
                    checked: showBin,
                    child: const Text("Show Bin"),
                  ),
                  CheckedPopupMenuItem(
                    value: "unit",
                    checked: showUnit,
                    child: const Text("Show Unit"),
                  ),
                ],
                child: Container(
                  height: 32,
                  width: 32,
                  decoration: BoxDecoration(
                    border: Border.all(color: AppColor.primary.withOpacity(.6)),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(Icons.tune, color: AppColor.primary, size: 18),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _GlobalItemRowWidget extends StatefulWidget {
  final String ledgerType;
  _GlobalItemRowWidget({
    super.key,
    required this.row,
    required this.rows, // 👈 add
    required this.catalogue,
    required this.hsnList,
    required this.onUpdate,
    required this.onAddNextRow,
    required this.onRemove,
    required this.onSelectCatalog,
    required this.onSelectHsn,
    required this.onToggleUnit,
    required this.isReturn,
    required this.ledgerType,
    required this.onSearchItem,
    required this.showBin,
    required this.showUnit,
  });
  final bool showBin;
  final bool showUnit;
  final GlobalItemRow row;
  final List<GlobalItemRow> rows;
  final List<ItemServiceModel> catalogue;
  final List<HsnModel> hsnList;
  final VoidCallback? onAddNextRow;
  final Function(GlobalItemRow) onUpdate;
  final VoidCallback onRemove;
  final Function(ItemServiceModel) onSelectCatalog;
  final Function(HsnModel) onSelectHsn;
  final Function(bool) onToggleUnit;
  final Future<List<ItemServiceModel>> Function(String)? onSearchItem;
  final bool? isReturn;

  @override
  State<_GlobalItemRowWidget> createState() => _GlobalItemRowWidgetState();
}

class _GlobalItemRowWidgetState extends State<_GlobalItemRowWidget> {
  late TextEditingController qtyCtrl;
  late TextEditingController priceCtrl;
  late TextEditingController discCtrl;
  late TextEditingController taxCtrl;
  late TextEditingController hsnCtrl;

  SearchFieldListItem<ItemServiceModel>? highlightedSuggestion;
  final TextEditingController itemController = TextEditingController();
  late FocusNode qtyF;
  late FocusNode priceF;
  late FocusNode discF;
  final FocusNode itemFocus = FocusNode();
  List<SearchFieldListItem<ItemServiceModel>> initialSuggestions = [];
  int highlightedIndex = -1;
  @override
  void initState() {
    super.initState();
    if (widget.row.product != null) {
      itemController.text =
          "${widget.row.product!.name} - ${widget.row.product!.itemNo}";
    }

    itemFocus.addListener(() async {
      if (itemFocus.hasFocus) {
        final items = await widget.onSearchItem?.call("") ?? [];

        final selectedIds = widget.rows
            .where((e) => e.product != null)
            .map((e) => e.product!.id)
            .toSet();

        setState(() {
          initialSuggestions = items
              .where(
                (i) =>
                    !selectedIds.contains(i.id) ||
                    widget.row.product?.id == i.id,
              )
              .map((i) {
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
                      "${i.name} • ${i.itemNo}",
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    subtitle: i.variantValue.isEmpty
                        ? null
                        : Text(i.variantValue),
                    trailing: Text(
                      i.stockQty ?? "0",
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: (int.tryParse(i.stockQty ?? "0") ?? 0) <= 0
                            ? AppColor.red
                            : AppColor.darkGreen,
                      ),
                    ),
                  ),
                );
              })
              .toList();
        });
      }
    });
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
    if (r.product != null) {
      itemController.text = "${r.product!.name} - ${r.product!.itemNo}";
    }
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
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          // ITEM SELECTOR
          Expanded(
            flex: 2,
            child: widget.isReturn == false
                ? _readonlyItemField(r)
                : _searchableItemField(r, input),
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
                  focusNode: FocusNode(skipTraversal: true),
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
                    onChanged: (value) {
                      final q = int.tryParse(value) ?? r.qty;
                      final updated = r.copyWith(qty: q).recalc();
                      widget.onUpdate(updated);
                    },
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(
                        RegExp(r'^\d*\.?\d{0,2}'),
                      ),
                    ],
                    decoration: input.copyWith(labelText: "Qty"),
                  ),
                ),
                IconButton(
                  focusNode: FocusNode(skipTraversal: true),
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

          if (widget.showUnit) ...[
            Expanded(child: _buildUnitDropdown(r)),
            _gap(),
          ],

          if (widget.showBin) ...[
            Expanded(
              child: CommonTextField(
                controller: TextEditingController(text: r.product?.binNo ?? ""),
                readOnly: true,
              ),
            ),
            _gap(),
          ],
          // PRICE
          Expanded(
            child: TextField(
              controller: priceCtrl,
              focusNode: priceF,
              onChanged: (value) {
                final p = double.tryParse(value) ?? r.pricePerSelectedUnit;
                final updated = r.copyWith(pricePerSelectedUnit: p).recalc();
                widget.onUpdate(updated);
              },
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
              ],
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
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
              ],
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
                    focusNode: FocusNode(skipTraversal: true),
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
          SizedBox(
            width: 50,
            child: TextButton(
              onPressed: widget.onRemove,
              child: Icon(Icons.cancel, color: AppColor.red),
            ),
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

  Widget _readonlyItemField(GlobalItemRow r) {
    return CommonTextField(
      readOnly: true,
      hintText: "Item",
      controller: itemController
        ..text = r.product != null
            ? "${r.product!.name} - ${r.product!.itemNo}"
            : "",
    );
  }

  Widget _searchableItemField(GlobalItemRow r, SearchInputDecoration input) {
    final selectedIds = widget.rows
        .where((e) => e.product != null)
        .map((e) => e.product!.id)
        .toSet();

    return RawKeyboardListener(
      focusNode: FocusNode(),
      onKey: (event) {
        if (event is! RawKeyDownEvent) return;

        if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
          if (initialSuggestions.isEmpty) return;

          highlightedIndex = (highlightedIndex + 1) % initialSuggestions.length;
          highlightedSuggestion = initialSuggestions[highlightedIndex];
        }

        if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
          if (initialSuggestions.isEmpty) return;

          highlightedIndex = (highlightedIndex - 1) < 0
              ? initialSuggestions.length - 1
              : highlightedIndex - 1;

          highlightedSuggestion = initialSuggestions[highlightedIndex];
        }

        if (event.logicalKey == LogicalKeyboardKey.tab) {
          if (initialSuggestions.isEmpty) return;

          final selected = highlightedSuggestion ?? initialSuggestions.first;

          widget.onSelectCatalog(selected.item!);

          WidgetsBinding.instance.addPostFrameCallback((_) {
            final index = widget.rows.indexWhere(
              (e) => e.localId == widget.row.localId,
            );

            final isLastRow = index == widget.rows.length - 1;

            if (isLastRow) {
              widget.onAddNextRow?.call();
            }
          });
        }
      },
      child: SearchField<ItemServiceModel>(
        key: ValueKey(r.localId + "_item"),
        itemHeight: 68,
        suggestions: initialSuggestions,
        focusNode: itemFocus,
        autofocus: r.product == null,
        onSearchTextChanged: (text) async {
          highlightedIndex = 0;
          highlightedSuggestion = null;
          final items =
              await (widget.onSearchItem?.call(text.trim()) ??
                  Future.value([]));
          final list = items
              .where(
                (i) => !selectedIds.contains(i.id) || r.product?.id == i.id,
              )
              .map((i) {
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
                      "${i.name} • ${i.itemNo}",
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    subtitle: i.variantValue.isEmpty
                        ? null
                        : Text(i.variantValue),
                    trailing: Text(
                      i.stockQty ?? "0",
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: (int.tryParse(i.stockQty ?? "0") ?? 0) <= 0
                            ? AppColor.red
                            : AppColor.darkGreen,
                      ),
                    ),
                  ),
                );
              })
              .toList();

          initialSuggestions = list; // arrow navigation
          return list; // dropdown show
        },

        searchInputDecoration: input.copyWith(
          labelText: "Item / Service",
          suffixIcon: InkWell(
            focusNode: FocusNode(skipTraversal: true),
            onTap: () async {
              await pushTo(CreateNewItemScreen());
            },
            child: Container(
              margin: EdgeInsets.all(5),
              decoration: BoxDecoration(
                color: AppColor.primary.withValues(alpha: .2),
                borderRadius: BorderRadius.circular(5),
              ),
              child: Icon(Icons.add, color: AppColor.primarydark),
            ),
          ),
        ),

        suggestionStyle: GoogleFonts.inter(
          color: const Color(0xFF565D6D),
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
        selectedValue: null,

        controller: itemController,

        onSuggestionTap: (s) {
          itemController.text = "${s.item!.name} - ${s.item!.itemNo}";
          highlightedIndex = 0;
          highlightedSuggestion = s;
          widget.onSelectCatalog(s.item!);

          WidgetsBinding.instance.addPostFrameCallback((_) {
            final index = widget.rows.indexWhere(
              (e) => e.localId == widget.row.localId,
            );

            final isLastRow = index == widget.rows.length - 1;

            if (isLastRow) {
              widget.onAddNextRow?.call();
            }
          });
        },
      ),
    );
  }
}
