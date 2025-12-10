import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:ims/ui/sales/data/global_repository.dart';
import 'package:ims/ui/sales/models/global_models.dart';
import 'package:ims/ui/master/misc/misc_charge_model.dart';
import 'package:ims/ui/sales/models/purchaseorder_model.dart';
import 'package:ims/utils/prefence.dart';
import 'package:ims/utils/snackbar.dart';
import 'package:intl/intl.dart';

/// ------------------- EVENTS -------------------
abstract class PurchaseOrderEvent {}

class PurchaseOrderLoadInit extends PurchaseOrderEvent {
  final PurchaseOrderData? existing;
  PurchaseOrderLoadInit({this.existing});
}

class PurchaseOrderSelectCustomer extends PurchaseOrderEvent {
  final CustomerModel? c;
  PurchaseOrderSelectCustomer(this.c);
}

class PurchaseOrderToggleCashSale extends PurchaseOrderEvent {
  final bool enabled;
  PurchaseOrderToggleCashSale(this.enabled);
}

class PurchaseOrderAddRow extends PurchaseOrderEvent {}

class PurchaseOrderRemoveRow extends PurchaseOrderEvent {
  final String id;
  PurchaseOrderRemoveRow(this.id);
}

class PurchaseOrderUpdateRow extends PurchaseOrderEvent {
  final GlobalItemRow row;
  PurchaseOrderUpdateRow(this.row);
}

class PurchaseOrderSelectCatalogForRow extends PurchaseOrderEvent {
  final String rowId;
  final ItemServiceModel item;
  PurchaseOrderSelectCatalogForRow(this.rowId, this.item);
}

class PurchaseOrderSelectVariantForRow extends PurchaseOrderEvent {
  final String rowId;
  final VariantModel variant;
  PurchaseOrderSelectVariantForRow(this.rowId, this.variant);
}

class PurchaseOrderToggleUnitForRow extends PurchaseOrderEvent {
  final String rowId;
  final bool sellInBase;
  PurchaseOrderToggleUnitForRow(this.rowId, this.sellInBase);
}

class PurchaseOrderApplyHsnToRow extends PurchaseOrderEvent {
  final String rowId;
  final HsnModel hsn;
  PurchaseOrderApplyHsnToRow(this.rowId, this.hsn);
}

class PurchaseOrderAddCharge extends PurchaseOrderEvent {
  final AdditionalCharge charge;
  PurchaseOrderAddCharge(this.charge);
}

class PurchaseOrderRemoveCharge extends PurchaseOrderEvent {
  final String id;
  PurchaseOrderRemoveCharge(this.id);
}

class PurchaseOrderUpdateCharge extends PurchaseOrderEvent {
  final AdditionalCharge charge;
  PurchaseOrderUpdateCharge(this.charge);
}

class PurchaseOrderAddDiscount extends PurchaseOrderEvent {
  final DiscountLine d;
  PurchaseOrderAddDiscount(this.d);
}

class PurchaseOrderRemoveDiscount extends PurchaseOrderEvent {
  final String id;
  PurchaseOrderRemoveDiscount(this.id);
}

/// ---------- NEW: misc charges events ----------
class PurchaseOrderAddMiscCharge extends PurchaseOrderEvent {
  final GlobalMiscChargeEntry m;
  PurchaseOrderAddMiscCharge(this.m);
}

class PurchaseOrderRemoveMiscCharge extends PurchaseOrderEvent {
  final String id;
  PurchaseOrderRemoveMiscCharge(this.id);
}

class PurchaseOrderUpdateMiscCharge extends PurchaseOrderEvent {
  final GlobalMiscChargeEntry m;
  PurchaseOrderUpdateMiscCharge(this.m);
}

/// ----------------------------------------------
class PurchaseOrderCalculate extends PurchaseOrderEvent {}

class PurchaseOrderSave extends PurchaseOrderEvent {}

class PurchaseOrderToggleRoundOff extends PurchaseOrderEvent {
  final bool value;
  PurchaseOrderToggleRoundOff(this.value);
}

/// ------------------- STATE -------------------
class PurchaseOrderState {
  final List<CustomerModel> customers;
  final CustomerModel? selectedCustomer;
  final bool cashSaleDefault;
  final List<HsnModel> hsnMaster;
  final String prefix;
  final String purchaseOrderNo;
  final DateTime? purchaseOrderDate;
  final DateTime? validityDate;
  final int validForDays;
  final List<ItemServiceModel> catalogue;
  final List<GlobalItemRow> rows;
  final List<AdditionalCharge> charges;
  final List<GlobalMiscChargeEntry> miscCharges; // UI entries
  final List<DiscountLine> discounts;
  final double subtotal;
  final double totalGst;
  final double sgst;
  final double cgst;
  final double totalAmount;
  final bool autoRound;

  // master list from get/misccharge (for lookup)
  final List<MiscChargeModelList> miscMasterList;

  // notes & terms (so UI can display when editing)
  final List<String> notes;
  final List<String> terms;

  PurchaseOrderState({
    this.customers = const [],
    this.selectedCustomer,
    this.cashSaleDefault = false,
    this.prefix = 'PO',
    this.purchaseOrderNo = '',
    this.hsnMaster = const [],
    this.purchaseOrderDate,
    this.validityDate,
    this.validForDays = 0,
    this.catalogue = const [],
    this.rows = const [],
    this.charges = const [],
    this.miscCharges = const [],
    this.discounts = const [],
    this.subtotal = 0,
    this.totalGst = 0,
    this.sgst = 0,
    this.cgst = 0,
    this.totalAmount = 0,
    this.autoRound = true,
    this.miscMasterList = const [],
    this.notes = const [],
    this.terms = const [],
  });

  PurchaseOrderState copyWith({
    List<CustomerModel>? customers,
    CustomerModel? selectedCustomer,
    bool? cashSaleDefault,
    String? prefix,
    String? purchaseOrderNo,
    DateTime? purchaseOrderDate,
    List<HsnModel>? hsnMaster,
    DateTime? validityDate,
    int? validForDays,
    List<ItemServiceModel>? catalogue,
    List<GlobalItemRow>? rows,
    List<AdditionalCharge>? charges,
    List<GlobalMiscChargeEntry>? miscCharges,
    List<DiscountLine>? discounts,
    double? subtotal,
    double? totalGst,
    double? sgst,
    double? cgst,
    double? totalAmount,
    bool? autoRound,
    List<MiscChargeModelList>? miscMasterList,
    List<String>? notes,
    List<String>? terms,
  }) {
    return PurchaseOrderState(
      customers: customers ?? this.customers,
      selectedCustomer: selectedCustomer ?? this.selectedCustomer,
      cashSaleDefault: cashSaleDefault ?? this.cashSaleDefault,
      prefix: prefix ?? this.prefix,
      purchaseOrderNo: purchaseOrderNo ?? this.purchaseOrderNo,
      purchaseOrderDate: purchaseOrderDate ?? this.purchaseOrderDate,
      hsnMaster: hsnMaster ?? this.hsnMaster,
      validityDate: validityDate ?? this.validityDate,
      validForDays: validForDays ?? this.validForDays,
      catalogue: catalogue ?? this.catalogue,
      rows: rows ?? this.rows,
      charges: charges ?? this.charges,
      miscCharges: miscCharges ?? this.miscCharges,
      discounts: discounts ?? this.discounts,
      subtotal: subtotal ?? this.subtotal,
      totalGst: totalGst ?? this.totalGst,
      sgst: sgst ?? this.sgst,
      cgst: cgst ?? this.cgst,
      totalAmount: totalAmount ?? this.totalAmount,
      autoRound: autoRound ?? this.autoRound,
      miscMasterList: miscMasterList ?? this.miscMasterList,
      notes: notes ?? this.notes,
      terms: terms ?? this.terms,
    );
  }
}

/// ------------------- SAVE EVENT (UI) -------------------
class PurchaseOrderSaveWithUIData extends PurchaseOrderEvent {
  final String supplierName;
  final String? updateId;
  final String mobile;
  final String billingAddress;
  final String shippingAddress;
  final List<String> notes;
  final List<String> terms;
  final File? signatureImage; // NEW

  PurchaseOrderSaveWithUIData({
    required this.supplierName,
    required this.mobile,
    required this.billingAddress,
    required this.shippingAddress,
    required this.notes,
    required this.terms,
    this.updateId,
    this.signatureImage,
  });
}

final GlobalKey<NavigatorState> purchaseOrderNavigatorKey =
    GlobalKey<NavigatorState>();

/// ------------------- BLOC -------------------
class PurchaseOrderBloc extends Bloc<PurchaseOrderEvent, PurchaseOrderState> {
  final GLobalRepository repo;
  PurchaseOrderBloc({required this.repo}) : super(PurchaseOrderState()) {
    on<PurchaseOrderLoadInit>((event, emit) async {
      await _onLoad(event, emit);

      if (event.existing != null) {
        emit(_prefillPurchaseOrder(event.existing!, state));
        add(PurchaseOrderCalculate());
      }
    });
    on<PurchaseOrderSelectCustomer>(_onSelectCustomer);
    on<PurchaseOrderToggleCashSale>(_onToggleCashSale);
    on<PurchaseOrderAddRow>(_onAddRow);
    on<PurchaseOrderRemoveRow>(_onRemoveRow);
    on<PurchaseOrderUpdateRow>(_onUpdateRow);
    on<PurchaseOrderSelectCatalogForRow>(_onSelectCatalogForRow);
    on<PurchaseOrderSelectVariantForRow>(_onSelectVariantForRow);
    on<PurchaseOrderToggleUnitForRow>(_onToggleUnitForRow);
    on<PurchaseOrderSaveWithUIData>(_onSaveWithUIData);
    on<PurchaseOrderApplyHsnToRow>(_onApplyHsnToRow);
    on<PurchaseOrderAddCharge>(_onAddCharge);
    on<PurchaseOrderRemoveCharge>(_onRemoveCharge);
    on<PurchaseOrderUpdateCharge>(_onUpdateCharge);
    on<PurchaseOrderAddDiscount>(_onAddDiscount);
    on<PurchaseOrderRemoveDiscount>(_onRemoveDiscount);

    // misc
    on<PurchaseOrderAddMiscCharge>(_onAddMiscCharge);
    on<PurchaseOrderRemoveMiscCharge>(_onRemoveMiscCharge);
    on<PurchaseOrderUpdateMiscCharge>(_onUpdateMiscCharge);

    on<PurchaseOrderToggleRoundOff>(_onToggleRoundOff);
    on<PurchaseOrderCalculate>(_onCalculate);
  }

  Future<void> _onLoad(
    PurchaseOrderLoadInit e,
    Emitter<PurchaseOrderState> emit,
  ) async {
    try {
      final customers = await repo.fetchSupplier();
      final purchaseOrderNo = await repo.fetchPurchaseOrderNo();
      final catalogue = await repo.fetchOnyItem();
      final hsnList = await repo.fetchHsnList();

      // fetch misc master list
      List<MiscChargeModelList> miscMaster = [];
      try {
        miscMaster = await repo.fetchMiscMaster();
      } catch (_) {
        miscMaster = [];
      }

      emit(
        state.copyWith(
          customers: customers,
          purchaseOrderNo: purchaseOrderNo,
          catalogue: catalogue,
          hsnMaster: hsnList,
          miscMasterList: miscMaster,
          // ensure UI has at least one empty row to start
          rows: [GlobalItemRow(localId: UniqueKey().toString())],
        ),
      );

      add(PurchaseOrderCalculate());
    } catch (err) {
      print("❌ Load error: $err");
    }
  }

  void _onSelectCustomer(
    PurchaseOrderSelectCustomer e,
    Emitter<PurchaseOrderState> emit,
  ) => emit(state.copyWith(selectedCustomer: e.c));
  void _onToggleCashSale(
    PurchaseOrderToggleCashSale e,
    Emitter<PurchaseOrderState> emit,
  ) {
    if (e.enabled) {
      emit(
        state.copyWith(
          cashSaleDefault: true,
          selectedCustomer: null, // MUST CLEAR
        ),
      );
    } else {
      emit(
        state.copyWith(
          cashSaleDefault: false,
          // Do NOT set selectedCustomer here; UI will set when user picks
        ),
      );
    }
  }

  void _onAddRow(PurchaseOrderAddRow e, Emitter<PurchaseOrderState> emit) {
    emit(
      state.copyWith(
        rows: [
          ...state.rows,
          GlobalItemRow(localId: UniqueKey().toString()),
        ],
      ),
    );
  }

  void _onRemoveRow(
    PurchaseOrderRemoveRow e,
    Emitter<PurchaseOrderState> emit,
  ) {
    emit(
      state.copyWith(rows: state.rows.where((r) => r.localId != e.id).toList()),
    );
    add(PurchaseOrderCalculate());
  }

  void _onUpdateRow(
    PurchaseOrderUpdateRow e,
    Emitter<PurchaseOrderState> emit,
  ) {
    emit(
      state.copyWith(
        rows: state.rows.map((r) {
          if (r.localId == e.row.localId) return e.row.recalc();
          return r;
        }).toList(),
      ),
    );
    add(PurchaseOrderCalculate());
  }

  void _onSelectCatalogForRow(
    PurchaseOrderSelectCatalogForRow e,
    Emitter<PurchaseOrderState> emit,
  ) {
    emit(
      state.copyWith(
        rows: state.rows.map((r) {
          if (r.localId == e.rowId) {
            final item = e.item;
            final variant = item.variants.isNotEmpty
                ? item.variants.first
                : null;

            return r
                .copyWith(
                  product: item,
                  selectedVariant: variant,
                  qty: r.qty == 0 ? 1 : r.qty,
                  pricePerSelectedUnit:
                      variant?.salePrice ?? item.baseSalePrice,
                  discountPercent: 0,
                  hsnOverride: item.hsn,
                  taxPercent: item.gstRate,
                  gstInclusiveToggle: item.gstIncluded,
                )
                .recalc();
          }
          return r;
        }).toList(),
      ),
    );
    add(PurchaseOrderCalculate());
  }

  void _onSelectVariantForRow(
    PurchaseOrderSelectVariantForRow e,
    Emitter<PurchaseOrderState> emit,
  ) {
    emit(
      state.copyWith(
        rows: state.rows.map((r) {
          if (r.localId == e.rowId) {
            return r
                .copyWith(
                  selectedVariant: e.variant,
                  pricePerSelectedUnit: r.sellInBaseUnit
                      ? e.variant.salePrice * (r.product?.conversion ?? 1)
                      : e.variant.salePrice,
                )
                .recalc();
          }
          return r;
        }).toList(),
      ),
    );
    add(PurchaseOrderCalculate());
  }

  void _onToggleUnitForRow(
    PurchaseOrderToggleUnitForRow e,
    Emitter<PurchaseOrderState> emit,
  ) {
    emit(
      state.copyWith(
        rows: state.rows.map((r) {
          if (r.localId == e.rowId) {
            final basePrice =
                r.selectedVariant?.salePrice ?? r.product?.baseSalePrice ?? 0;

            return r
                .copyWith(
                  sellInBaseUnit: e.sellInBase,
                  pricePerSelectedUnit: e.sellInBase
                      ? basePrice * (r.product?.conversion ?? 1)
                      : basePrice,
                )
                .recalc();
          }
          return r;
        }).toList(),
      ),
    );
    add(PurchaseOrderCalculate());
  }

  void _onApplyHsnToRow(
    PurchaseOrderApplyHsnToRow e,
    Emitter<PurchaseOrderState> emit,
  ) {
    emit(
      state.copyWith(
        rows: state.rows.map((r) {
          if (r.localId == e.rowId) {
            return r
                .copyWith(
                  hsnOverride: e.hsn.code,
                  taxPercent: e.hsn.igst,
                  gstInclusiveToggle: false,
                )
                .recalc();
          }
          return r;
        }).toList(),
      ),
    );
    add(PurchaseOrderCalculate());
  }

  void _onAddCharge(
    PurchaseOrderAddCharge e,
    Emitter<PurchaseOrderState> emit,
  ) {
    emit(state.copyWith(charges: [...state.charges, e.charge]));
    add(PurchaseOrderCalculate());
  }

  void _onRemoveCharge(
    PurchaseOrderRemoveCharge e,
    Emitter<PurchaseOrderState> emit,
  ) {
    emit(
      state.copyWith(
        charges: state.charges.where((c) => c.id != e.id).toList(),
      ),
    );
    add(PurchaseOrderCalculate());
  }

  void _onUpdateCharge(
    PurchaseOrderUpdateCharge e,
    Emitter<PurchaseOrderState> emit,
  ) {
    emit(
      state.copyWith(
        charges: state.charges.map((c) {
          if (c.id == e.charge.id) return e.charge;
          return c;
        }).toList(),
      ),
    );
    add(PurchaseOrderCalculate());
  }

  void _onAddDiscount(
    PurchaseOrderAddDiscount e,
    Emitter<PurchaseOrderState> emit,
  ) {
    emit(state.copyWith(discounts: [...state.discounts, e.d]));
    add(PurchaseOrderCalculate());
  }

  void _onRemoveDiscount(
    PurchaseOrderRemoveDiscount e,
    Emitter<PurchaseOrderState> emit,
  ) {
    emit(
      state.copyWith(
        discounts: state.discounts.where((d) => d.id != e.id).toList(),
      ),
    );
    add(PurchaseOrderCalculate());
  }

  void _onToggleRoundOff(
    PurchaseOrderToggleRoundOff e,
    Emitter<PurchaseOrderState> emit,
  ) {
    emit(state.copyWith(autoRound: e.value));
    add(PurchaseOrderCalculate());
  }

  // ------------------- MISC CHARGE HANDLERS -------------------
  void _onAddMiscCharge(
    PurchaseOrderAddMiscCharge e,
    Emitter<PurchaseOrderState> emit,
  ) {
    // When adding from UI, user may select an item from master list or create custom.
    // We'll accept the provided MiscChargeEntry as-is (it should already include gst/ledger if selected)
    emit(state.copyWith(miscCharges: [...state.miscCharges, e.m]));
    add(PurchaseOrderCalculate());
  }

  void _onRemoveMiscCharge(
    PurchaseOrderRemoveMiscCharge e,
    Emitter<PurchaseOrderState> emit,
  ) {
    emit(
      state.copyWith(
        miscCharges: state.miscCharges.where((m) => m.id != e.id).toList(),
      ),
    );
    add(PurchaseOrderCalculate());
  }

  void _onUpdateMiscCharge(
    PurchaseOrderUpdateMiscCharge e,
    Emitter<PurchaseOrderState> emit,
  ) {
    emit(
      state.copyWith(
        miscCharges: state.miscCharges.map((m) {
          if (m.id == e.m.id) return e.m;
          return m;
        }).toList(),
      ),
    );
    add(PurchaseOrderCalculate());
  }

  // ------------------- CALCULATION -------------------
  void _onCalculate(
    PurchaseOrderCalculate e,
    Emitter<PurchaseOrderState> emit,
  ) {
    final updatedRows = state.rows.map((r) => r.recalc()).toList();

    double subtotal = 0;
    double gst = 0;

    // rows taxable + tax
    for (final r in updatedRows) {
      subtotal += r.taxable;
      gst += r.taxAmount;
    }

    // additional charges (existing)
    for (final ch in state.charges) {
      if (ch.taxIncluded) {
        final divisor = 1 + (ch.taxPercent / 100);
        final base = ch.amount / divisor;
        subtotal += base;
        gst += ch.amount - base;
      } else {
        subtotal += ch.amount;
        gst += ch.amount * (ch.taxPercent / 100);
      }
    }

    // discounts (applied on current subtotal)
    for (final d in state.discounts) {
      subtotal -= d.isPercent ? subtotal * (d.amount / 100) : d.amount;
    }

    // ------------------- MISC CHARGES (NEW) -------------------
    for (final m in state.miscCharges) {
      final gstRate = m.gst;
      if (m.taxIncluded) {
        final divisor = 1 + (gstRate / 100);
        final base = m.amount / divisor;
        subtotal += base;
        gst += m.amount - base;
      } else {
        subtotal += m.amount;
        gst += m.amount * (gstRate / 100);
      }
    }

    final total = state.autoRound
        ? (subtotal + gst).roundToDouble()
        : subtotal + gst;

    emit(
      state.copyWith(
        rows: updatedRows,
        subtotal: subtotal,
        totalGst: gst,
        sgst: gst / 2,
        cgst: gst / 2,
        totalAmount: total,
      ),
    );
  }

  // ------------------- SAVE -------------------
  Future<void> _onSaveWithUIData(
    PurchaseOrderSaveWithUIData e,
    Emitter<PurchaseOrderState> emit,
  ) async {
    try {
      final state = this.state;

      final bool isCash = state.cashSaleDefault;

      // ---------------- CUSTOMER ----------------
      final supplierId = isCash ? null : state.selectedCustomer?.id;

      final supplierName = isCash
          ? e.supplierName
          : state.selectedCustomer?.name ?? "";

      final mobile = isCash ? e.mobile : state.selectedCustomer?.mobile ?? "";

      // Address — prefer selectedCustomer's addresses (autofill). If cash sale use provided fields.
      final billing = isCash
          ? e.billingAddress
          : state.selectedCustomer?.billingAddress ?? e.billingAddress;
      final shipping = isCash
          ? e.shippingAddress
          : state.selectedCustomer?.shippingAddress ?? e.shippingAddress;

      // ---------------- ROWS ----------------
      final itemRows = <Map<String, dynamic>>[];

      for (final r in state.rows) {
        if (r.product == null) continue;

        itemRows.add({
          "item_id": r.product!.id,
          "item_name": r.product!.name,
          "item_no": r.product!.itemNo,
          "price": r.pricePerSelectedUnit,
          "hsn_code": r.hsnOverride.isNotEmpty ? r.hsnOverride : r.product!.hsn,
          "gst_tax_rate": r.taxPercent,
          "measuring_unit": r.sellInBaseUnit
              ? r.product!.baseUnit
              : r.product!.secondaryUnit,
          "qty": r.qty,
          "amount": r.gross,
          "discount": r.discountPercent,
          "in_ex": r.gstInclusiveToggle,
        });
      }

      // ---------------- DISCOUNTS ----------------
      final discounts = state.discounts.map((d) {
        return {
          "name": d.name,
          "amount": d.amount,
          "type": d.isPercent ? "percent" : "amount",
        };
      }).toList();

      // ---------------- CHARGES ----------------
      final charges = state.charges.map((c) {
        return {"name": c.name, "amount": c.amount};
      }).toList();

      // ---------------- MISC CHARGES (NEW) ----------------
      // When saving, backend expects only name, amount, type (true => inclusive).
      final miscCharges = state.miscCharges.map((m) {
        return {
          "name": m.name,
          "amount": m.amount,
          "type": m.taxIncluded, // send boolean or string as backend expects
        };
      }).toList();

      // ---------------- FINAL PAYLOAD ----------------

      Map<String, dynamic> payload = {
        "licence_no": Preference.getint(PrefKeys.licenseNo),
        "branch_id": Preference.getString(PrefKeys.locationId),
        "supplier_id": supplierId,
        "supplier_name": supplierName,
        "mobile": mobile,
        "address_0": billing,
        "address_1": shipping,
        "prefix": state.prefix,
        "no": int.tryParse(state.purchaseOrderNo),
        "purchaseoder_date": DateFormat(
          'yyyy-MM-dd',
        ).format(state.purchaseOrderDate ?? DateTime.now()),
        "payment_terms": state.validForDays,
        if (state.validityDate != null)
          "due_date": DateFormat('yyyy-MM-dd').format(state.validityDate!),
        "case_sale": isCash,
        "add_note": jsonEncode(e.notes),
        "te_co": jsonEncode(e.terms),
        "sub_totle": state.subtotal,
        "sub_gst": state.totalGst,
        "auto_ro": state.autoRound,
        "totle_amo": state.totalAmount,
        "additional_charges": charges,
        "misccharge": miscCharges,
        "discount": discounts,
        "item_details": itemRows,
      };

      if (itemRows.isEmpty) {
        showCustomSnackbarError(
          purchaseOrderNavigatorKey.currentContext!,
          "Add atleast one item",
        );
        return;
      } else {
        final res = await repo.savePurchaseOrder(
          payload: payload,
          signatureFile: e.signatureImage != null
              ? XFile(e.signatureImage!.path)
              : null,
          updateId: e.updateId,
        );

        if (res?['status'] == true) {
          showCustomSnackbarSuccess(
            purchaseOrderNavigatorKey.currentContext!,
            res?['message'] ?? "Saved",
          );
        } else {
          showCustomSnackbarError(
            purchaseOrderNavigatorKey.currentContext!,
            res?['message'] ?? "Save failed",
          );
        }
      }
    } catch (err) {
      showCustomSnackbarError(
        purchaseOrderNavigatorKey.currentContext!,
        err.toString(),
      );
    }
  }
}

/// ------------------- IMMUTABLE CALC EXT -------------------
extension GlobalItemRowCalc on GlobalItemRow {
  GlobalItemRow recalc() {
    final base = pricePerSelectedUnit * qty;
    final discountValue = base * (discountPercent / 100);
    final afterDiscount = base - discountValue;

    if (gstInclusiveToggle) {
      final divisor = 1 + (taxPercent / 100);
      final taxable = afterDiscount / divisor;
      final tax = afterDiscount - taxable;

      return copyWith(taxable: taxable, taxAmount: tax, gross: afterDiscount);
    } else {
      final taxable = afterDiscount;
      final tax = taxable * (taxPercent / 100);
      return copyWith(taxable: taxable, taxAmount: tax, gross: taxable + tax);
    }
  }
}

/// ------------------- PREFILL HELPER -------------------
PurchaseOrderState _prefillPurchaseOrder(
  PurchaseOrderData data,
  PurchaseOrderState s,
) {
  // find customer from loaded list (or create fallback)
  final selectedCustomer = s.customers.firstWhere(
    (c) => c.id == data.supplierId,
    orElse: () => CustomerModel(
      id: data.supplierId ?? "",
      name: data.supplierName,
      mobile: data.mobile,
      billingAddress: data.address0,
      shippingAddress: data.address1,
    ),
  );

  // ---------------- ADDITIONAL CHARGES ----------------
  final mappedCharges = (data.additionalCharges)
      .map(
        (c) => AdditionalCharge(
          id: c.id,
          name: c.name,
          amount: (c.amount).toDouble(),
          taxPercent: 0,
          taxIncluded: false,
        ),
      )
      .toList();

  // ---------------- DISCOUNTS ----------------
  final mappedDiscounts = (data.discountLines)
      .map(
        (d) => DiscountLine(
          id: d.id,
          name: d.name,
          amount: (d.amount).toDouble(),
          isPercent: (d.type).toString().toLowerCase() == "percent",
        ),
      )
      .toList();

  // ---------------- MISC CHARGES (match by name with master) ----------------
  final mappedMisc = <GlobalMiscChargeEntry>[];
  for (final m in data.miscCharges) {
    final nameFromPurchaseOrder = (m.name).trim().toLowerCase();
    if (nameFromPurchaseOrder.isEmpty) continue;

    // try to find in misc master list safely
    MiscChargeModelList? match;
    try {
      match = s.miscMasterList.firstWhere(
        (mx) => (mx.name).trim().toLowerCase() == nameFromPurchaseOrder,
      );
    } catch (_) {
      match = null;
    }

    if (match == null) {
      // Option chosen: SKIP misc charge if master not found.
      // If you prefer to include anyway with defaults, replace continue with default mapping.
      continue;
    }

    double gst = 0;
    try {
      gst = match.gst != null ? double.tryParse(match.gst.toString()) ?? 0 : 0;
    } catch (_) {
      gst = 0;
    }
    final ledgerId = match.ledgerId;
    final hsn = match.hsn;

    final taxIncluded =
        (m.type == true) || (m.type.toString().toLowerCase() == "true");

    mappedMisc.add(
      GlobalMiscChargeEntry(
        id: UniqueKey().toString(),
        miscId: match.id,
        ledgerId: ledgerId,
        name: m.name,
        hsn: hsn,
        gst: gst,
        amount: (m.amount).toDouble(),
        taxIncluded: taxIncluded,
      ),
    );
  }

  // empty fallback item (if catalogue doesn't contain item/service)
  ItemServiceModel emptyItem() {
    return ItemServiceModel(
      id: "",
      type: ItemServiceType.item,
      name: "",
      hsn: "",
      variantValue: '',
      baseSalePrice: 0,
      gstRate: 0,
      gstIncluded: false,
      baseUnit: '',
      secondaryUnit: '',
      conversion: 1,
      variants: [],
      itemNo: '',
      group: '',
    );
  }

  // Convert itemDetails -> GlobalItemRow
  final itemRows = (data.itemDetails).map((i) {
    final catalogItem = s.catalogue.firstWhere(
      (c) => c.id == (i.itemId),
      orElse: () => emptyItem(),
    );

    return GlobalItemRow(
      localId: UniqueKey().toString(),
      product: catalogItem,
      selectedVariant: null,
      qty: (i.qty).toInt(),
      pricePerSelectedUnit: (i.price).toDouble(),
      discountPercent: (i.discount).toDouble(),
      hsnOverride: (i.hsn),
      taxPercent: (i.gstRate).toDouble(),
      gstInclusiveToggle: i.inclusive,
      sellInBaseUnit: false,
    ).recalc();
  }).toList();

  final rows = <GlobalItemRow>[
    ...itemRows,
    if (itemRows.isEmpty) GlobalItemRow(localId: UniqueKey().toString()),
  ];

  return s.copyWith(
    customers: s.customers,
    selectedCustomer: data.caseSale ? null : selectedCustomer,
    prefix: data.prefix,
    purchaseOrderNo: data.no.toString(),
    rows: rows,
    charges: mappedCharges,
    discounts: mappedDiscounts,
    miscCharges: mappedMisc,
    subtotal: (data.subTotal).toDouble(),
    totalGst: (data.subGst).toDouble(),
    totalAmount: (data.totalAmount).toDouble(),
    autoRound: data.autoRound,
    purchaseOrderDate: data.purchaseOrderDate,
    validityDate: data.purchaseOrderDate.add(Duration(days: data.paymentTerms)),
    validForDays: data.paymentTerms,
    cashSaleDefault: data.caseSale,
  );
}
