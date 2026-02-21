import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ims/ui/sales/data/global_repository.dart';
import 'package:ims/ui/sales/models/dilivery_data.dart';
import 'package:ims/ui/sales/models/global_models.dart';
import 'package:ims/ui/master/misc/misc_charge_model.dart';
import 'package:ims/utils/prefence.dart';
import 'package:ims/utils/snackbar.dart';
import 'package:intl/intl.dart';

/// ------------------- EVENTS -------------------
abstract class DiliveryChallanEvent {}

class DiliveryChallanLoadInit extends DiliveryChallanEvent {
  final DiliveryChallanData? existing;
  DiliveryChallanLoadInit({this.existing});
}

class DiliveryChallanSelectCustomer extends DiliveryChallanEvent {
  final LedgerModelDrop? c;
  DiliveryChallanSelectCustomer(this.c);
}

class DiliveryChallanToggleCashSale extends DiliveryChallanEvent {
  final bool enabled;
  DiliveryChallanToggleCashSale(this.enabled);
}

class DiliveryChallanAddRow extends DiliveryChallanEvent {}

class DiliveryChallanRemoveRow extends DiliveryChallanEvent {
  final String id;
  DiliveryChallanRemoveRow(this.id);
}

class DiliveryChallanUpdateRow extends DiliveryChallanEvent {
  final GlobalItemRow row;
  DiliveryChallanUpdateRow(this.row);
}

class DiliveryChallanSelectCatalogForRow extends DiliveryChallanEvent {
  final String rowId;
  final ItemServiceModel item;
  DiliveryChallanSelectCatalogForRow(this.rowId, this.item);
}

class DiliveryChallanSelectVariantForRow extends DiliveryChallanEvent {
  final String rowId;
  final VariantModel variant;
  DiliveryChallanSelectVariantForRow(this.rowId, this.variant);
}

class DiliveryChallanToggleUnitForRow extends DiliveryChallanEvent {
  final String rowId;
  final bool sellInBase;
  DiliveryChallanToggleUnitForRow(this.rowId, this.sellInBase);
}

class DiliveryChallanApplyHsnToRow extends DiliveryChallanEvent {
  final String rowId;
  final HsnModel hsn;
  DiliveryChallanApplyHsnToRow(this.rowId, this.hsn);
}

class DiliveryChallanAddCharge extends DiliveryChallanEvent {
  final AdditionalCharge charge;
  DiliveryChallanAddCharge(this.charge);
}

class DiliveryChallanRemoveCharge extends DiliveryChallanEvent {
  final String id;
  DiliveryChallanRemoveCharge(this.id);
}

class DiliveryChallanUpdateCharge extends DiliveryChallanEvent {
  final AdditionalCharge charge;
  DiliveryChallanUpdateCharge(this.charge);
}

class DiliveryChallanAddDiscount extends DiliveryChallanEvent {
  final DiscountLine d;
  DiliveryChallanAddDiscount(this.d);
}

class DiliveryChallanRemoveDiscount extends DiliveryChallanEvent {
  final String id;
  DiliveryChallanRemoveDiscount(this.id);
}

/// ---------- NEW: misc charges events ----------
class DiliveryChallanAddMiscCharge extends DiliveryChallanEvent {
  final GlobalMiscChargeEntry m;
  DiliveryChallanAddMiscCharge(this.m);
}

class DiliveryChallanRemoveMiscCharge extends DiliveryChallanEvent {
  final String id;
  DiliveryChallanRemoveMiscCharge(this.id);
}

class DiliveryChallanUpdateMiscCharge extends DiliveryChallanEvent {
  final GlobalMiscChargeEntry m;
  DiliveryChallanUpdateMiscCharge(this.m);
}

/// ----------------------------------------------
class DiliveryChallanCalculate extends DiliveryChallanEvent {}

class DiliveryChallanSave extends DiliveryChallanEvent {}

class DiliveryChallanToggleRoundOff extends DiliveryChallanEvent {
  final bool value;
  DiliveryChallanToggleRoundOff(this.value);
}

/// ------------------- STATE -------------------
class DiliveryChallanState {
  final List<LedgerModelDrop> customers;
  final LedgerModelDrop? selectedCustomer;
  final bool cashSaleDefault;
  final List<HsnModel> hsnMaster;
  final String prefix;
  final String diliveryChallanNo;
  final DateTime? diliveryChallanDate;
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

  DiliveryChallanState({
    this.customers = const [],
    this.selectedCustomer,
    this.cashSaleDefault = false,
    this.prefix = '',
    this.diliveryChallanNo = '',
    this.hsnMaster = const [],
    this.diliveryChallanDate,
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

  DiliveryChallanState copyWith({
    List<LedgerModelDrop>? customers,
    LedgerModelDrop? selectedCustomer,
    bool? cashSaleDefault,
    String? prefix,
    String? diliveryChallanNo,
    DateTime? diliveryChallanDate,
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
    return DiliveryChallanState(
      customers: customers ?? this.customers,
      selectedCustomer: selectedCustomer ?? this.selectedCustomer,
      cashSaleDefault: cashSaleDefault ?? this.cashSaleDefault,
      prefix: prefix ?? this.prefix,
      diliveryChallanNo: diliveryChallanNo ?? this.diliveryChallanNo,
      diliveryChallanDate: diliveryChallanDate ?? this.diliveryChallanDate,
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
class DiliveryChallanSaveWithUIData extends DiliveryChallanEvent {
  final String customerName;
  final String? updateId;
  final String mobile;
  final String billingAddress;
  final String shippingAddress;
  final String stateName; // ✅ ADD
  final List<String> notes;
  final List<String> terms;
  final Uint8List? signatureImage; // NEW

  DiliveryChallanSaveWithUIData({
    required this.customerName,
    required this.mobile,
    required this.billingAddress,
    required this.shippingAddress,
    required this.stateName, // ✅
    required this.notes,
    required this.terms,
    this.updateId,
    this.signatureImage,
  });
}

final GlobalKey<NavigatorState> diliveryChallanNavigatorKey =
    GlobalKey<NavigatorState>();

/// ------------------- BLOC -------------------
class DiliveryChallanBloc
    extends Bloc<DiliveryChallanEvent, DiliveryChallanState> {
  final GLobalRepository repo;
  DiliveryChallanBloc({required this.repo}) : super(DiliveryChallanState()) {
    on<DiliveryChallanLoadInit>((event, emit) async {
      await _onLoad(event, emit);

      if (event.existing != null) {
        emit(_prefillDiliveryChallan(event.existing!, state));
        add(DiliveryChallanCalculate());
      }
    });
    on<DiliveryChallanSelectCustomer>(_onSelectCustomer);
    on<DiliveryChallanToggleCashSale>(_onToggleCashSale);
    on<DiliveryChallanAddRow>(_onAddRow);
    on<DiliveryChallanRemoveRow>(_onRemoveRow);
    on<DiliveryChallanUpdateRow>(_onUpdateRow);
    on<DiliveryChallanSelectCatalogForRow>(_onSelectCatalogForRow);
    on<DiliveryChallanSelectVariantForRow>(_onSelectVariantForRow);
    on<DiliveryChallanToggleUnitForRow>(_onToggleUnitForRow);
    on<DiliveryChallanSaveWithUIData>(_onSaveWithUIData);
    on<DiliveryChallanApplyHsnToRow>(_onApplyHsnToRow);
    on<DiliveryChallanAddCharge>(_onAddCharge);
    on<DiliveryChallanRemoveCharge>(_onRemoveCharge);
    on<DiliveryChallanUpdateCharge>(_onUpdateCharge);
    on<DiliveryChallanAddDiscount>(_onAddDiscount);
    on<DiliveryChallanRemoveDiscount>(_onRemoveDiscount);

    // misc
    on<DiliveryChallanAddMiscCharge>(_onAddMiscCharge);
    on<DiliveryChallanRemoveMiscCharge>(_onRemoveMiscCharge);
    on<DiliveryChallanUpdateMiscCharge>(_onUpdateMiscCharge);

    on<DiliveryChallanToggleRoundOff>(_onToggleRoundOff);
    on<DiliveryChallanCalculate>(_onCalculate);
  }

  Future<void> _onLoad(
    DiliveryChallanLoadInit e,
    Emitter<DiliveryChallanState> emit,
  ) async {
    try {
      final customers = await repo.fetchLedger(true);
      final diliveryChallanNo = await repo.fetchDiliveryChallanNo();
      final catalogue = await repo.fetchCatalogue();
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
          diliveryChallanNo: diliveryChallanNo,
          catalogue: catalogue,
          hsnMaster: hsnList,
          miscMasterList: miscMaster,
          // ensure UI has at least one empty row to start
          rows: [GlobalItemRow(localId: UniqueKey().toString())],
        ),
      );

      add(DiliveryChallanCalculate());
    } catch (err) {
      print("❌ Load error: $err");
    }
  }

  void _onSelectCustomer(
    DiliveryChallanSelectCustomer e,
    Emitter<DiliveryChallanState> emit,
  ) => emit(state.copyWith(selectedCustomer: e.c));
  void _onToggleCashSale(
    DiliveryChallanToggleCashSale e,
    Emitter<DiliveryChallanState> emit,
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

  void _onAddRow(DiliveryChallanAddRow e, Emitter<DiliveryChallanState> emit) {
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
    DiliveryChallanRemoveRow e,
    Emitter<DiliveryChallanState> emit,
  ) {
    emit(
      state.copyWith(rows: state.rows.where((r) => r.localId != e.id).toList()),
    );
    add(DiliveryChallanCalculate());
  }

  void _onUpdateRow(
    DiliveryChallanUpdateRow e,
    Emitter<DiliveryChallanState> emit,
  ) {
    emit(
      state.copyWith(
        rows: state.rows.map((r) {
          if (r.localId == e.row.localId) return e.row.recalc();
          return r;
        }).toList(),
      ),
    );
    add(DiliveryChallanCalculate());
  }

  void _onSelectCatalogForRow(
    DiliveryChallanSelectCatalogForRow e,
    Emitter<DiliveryChallanState> emit,
  ) {
    final ledgerType = state.selectedCustomer?.ledgerType ?? "Individual";

    emit(
      state.copyWith(
        rows: state.rows.map((r) {
          if (r.localId == e.rowId) {
            final item = e.item;
            final variant = item.variants.isNotEmpty
                ? item.variants.first
                : null;
            final isWholesale = ledgerType.toLowerCase() != "individual";
            final price = isWholesale
                ? (item.wholesalePrice ?? item.baseSalePrice ?? 0)
                : (item.baseSalePrice ?? 0);

            return r
                .copyWith(
                  product: item,
                  selectedVariant: variant,
                  qty: r.qty == 0 ? 1 : r.qty,
                  pricePerSelectedUnit: price,
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
    add(DiliveryChallanCalculate());
  }

  void _onSelectVariantForRow(
    DiliveryChallanSelectVariantForRow e,
    Emitter<DiliveryChallanState> emit,
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
    add(DiliveryChallanCalculate());
  }

  void _onToggleUnitForRow(
    DiliveryChallanToggleUnitForRow e,
    Emitter<DiliveryChallanState> emit,
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
    add(DiliveryChallanCalculate());
  }

  void _onApplyHsnToRow(
    DiliveryChallanApplyHsnToRow e,
    Emitter<DiliveryChallanState> emit,
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
    add(DiliveryChallanCalculate());
  }

  void _onAddCharge(
    DiliveryChallanAddCharge e,
    Emitter<DiliveryChallanState> emit,
  ) {
    emit(state.copyWith(charges: [...state.charges, e.charge]));
    add(DiliveryChallanCalculate());
  }

  void _onRemoveCharge(
    DiliveryChallanRemoveCharge e,
    Emitter<DiliveryChallanState> emit,
  ) {
    emit(
      state.copyWith(
        charges: state.charges.where((c) => c.id != e.id).toList(),
      ),
    );
    add(DiliveryChallanCalculate());
  }

  void _onUpdateCharge(
    DiliveryChallanUpdateCharge e,
    Emitter<DiliveryChallanState> emit,
  ) {
    emit(
      state.copyWith(
        charges: state.charges.map((c) {
          if (c.id == e.charge.id) return e.charge;
          return c;
        }).toList(),
      ),
    );
    add(DiliveryChallanCalculate());
  }

  void _onAddDiscount(
    DiliveryChallanAddDiscount e,
    Emitter<DiliveryChallanState> emit,
  ) {
    emit(state.copyWith(discounts: [...state.discounts, e.d]));
    add(DiliveryChallanCalculate());
  }

  void _onRemoveDiscount(
    DiliveryChallanRemoveDiscount e,
    Emitter<DiliveryChallanState> emit,
  ) {
    emit(
      state.copyWith(
        discounts: state.discounts.where((d) => d.id != e.id).toList(),
      ),
    );
    add(DiliveryChallanCalculate());
  }

  void _onToggleRoundOff(
    DiliveryChallanToggleRoundOff e,
    Emitter<DiliveryChallanState> emit,
  ) {
    emit(state.copyWith(autoRound: e.value));
    add(DiliveryChallanCalculate());
  }

  // ------------------- MISC CHARGE HANDLERS -------------------
  void _onAddMiscCharge(
    DiliveryChallanAddMiscCharge e,
    Emitter<DiliveryChallanState> emit,
  ) {
    // When adding from UI, user may select an item from master list or create custom.
    // We'll accept the provided GlobalMiscChargeEntry as-is (it should already include gst/ledger if selected)
    emit(state.copyWith(miscCharges: [...state.miscCharges, e.m]));
    add(DiliveryChallanCalculate());
  }

  void _onRemoveMiscCharge(
    DiliveryChallanRemoveMiscCharge e,
    Emitter<DiliveryChallanState> emit,
  ) {
    emit(
      state.copyWith(
        miscCharges: state.miscCharges.where((m) => m.id != e.id).toList(),
      ),
    );
    add(DiliveryChallanCalculate());
  }

  void _onUpdateMiscCharge(
    DiliveryChallanUpdateMiscCharge e,
    Emitter<DiliveryChallanState> emit,
  ) {
    emit(
      state.copyWith(
        miscCharges: state.miscCharges.map((m) {
          if (m.id == e.m.id) return e.m;
          return m;
        }).toList(),
      ),
    );
    add(DiliveryChallanCalculate());
  }

  // ------------------- CALCULATION -------------------
  void _onCalculate(
    DiliveryChallanCalculate e,
    Emitter<DiliveryChallanState> emit,
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
    DiliveryChallanSaveWithUIData e,
    Emitter<DiliveryChallanState> emit,
  ) async {
    try {
      final state = this.state;

      final bool isCash = state.cashSaleDefault;

      // ---------------- CUSTOMER ----------------
      final customerId = state.selectedCustomer?.id;

      final customerName = isCash
          ? e.customerName
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
      final serviceRows = <Map<String, dynamic>>[];

      for (final r in state.rows) {
        if (r.product == null) continue;

        if (r.product!.type == ItemServiceType.item) {
          itemRows.add({
            "item_id": r.product!.id,
            "item_name": r.product!.name,
            "item_no": r.product!.itemNo,
            "price": r.pricePerSelectedUnit,
            "hsn_code": r.hsnOverride.isNotEmpty
                ? r.hsnOverride
                : r.product!.hsn,
            "gst_tax_rate": r.taxPercent,
            "measuring_unit": r.sellInBaseUnit
                ? r.product!.baseUnit
                : r.product!.secondaryUnit,
            "qty": r.qty,
            "amount": r.gross,
            "discount": r.discountPercent,
            "in_ex": r.gstInclusiveToggle,
          });
        } else {
          serviceRows.add({
            "service_id": r.product!.id,
            "service_name": r.product!.name,
            "service_no": r.product!.itemNo,
            "amount": r.gross,
            "price": r.pricePerSelectedUnit,
            "hsn_code": r.hsnOverride.isNotEmpty
                ? r.hsnOverride
                : r.product!.hsn,
            "measuring_unit": r.product!.baseUnit,
            "gst_tax_rate": r.taxPercent,
            "qty": r.qty,
            "discount": r.discountPercent,
            "in_ex": r.gstInclusiveToggle,
          });
        }
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
        "customer_id": customerId,
        "customer_name": customerName,
        if (mobile.isNotEmpty) "mobile": mobile,
        "address_0": billing,
        "address_1": shipping,
        "place_of_supply": e.stateName,
        "prefix": state.prefix,
        "no": int.tryParse(state.diliveryChallanNo),
        "dilvery_date": DateFormat(
          'yyyy-MM-dd',
        ).format(state.diliveryChallanDate ?? DateTime.now()),
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
        "service_details": serviceRows,
      };

      if (itemRows.isEmpty && serviceRows.isEmpty) {
        showCustomSnackbarError(
          diliveryChallanNavigatorKey.currentContext!,
          "Add atleast one item or service",
        );
        return;
      } else {
        final res = await repo.saveDiliveryChallan(
          payload: payload,
          signatureFile: e.signatureImage,
          updateId: e.updateId,
        );

        if (res?['status'] == true) {
          final ctx = diliveryChallanNavigatorKey.currentContext!;
          showCustomSnackbarSuccess(
            diliveryChallanNavigatorKey.currentContext!,
            res?['message'] ?? "Saved",
          );
          Navigator.of(ctx).pop(true);
        } else {
          showCustomSnackbarError(
            diliveryChallanNavigatorKey.currentContext!,
            res?['message'] ?? "Save failed",
          );
        }
      }
    } catch (err) {
      showCustomSnackbarError(
        diliveryChallanNavigatorKey.currentContext!,
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

DiliveryChallanState _prefillDiliveryChallan(
  DiliveryChallanData data,
  DiliveryChallanState s,
) {
  // find customer from loaded list (or create fallback)
  final selectedCustomer = s.customers.firstWhere(
    (c) => c.id == data.customerId,
    orElse: () => LedgerModelDrop(
      id: data.customerId ?? "",
      name: data.customerName,
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
    final nameFromDiliveryChallan = (m.name).trim().toLowerCase();
    if (nameFromDiliveryChallan.isEmpty) continue;

    // try to find in misc master list safely
    MiscChargeModelList? match;
    try {
      match = s.miscMasterList.firstWhere(
        (mx) => (mx.name).trim().toLowerCase() == nameFromDiliveryChallan,
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

  // Convert serviceDetails -> GlobalItemRow
  final serviceRows = (data.serviceDetails).map((i) {
    final catalogService = s.catalogue.firstWhere(
      (c) => c.id == (i.serviceId),
      orElse: () => emptyItem(),
    );

    return GlobalItemRow(
      localId: UniqueKey().toString(),
      product: catalogService,
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
    ...serviceRows,
    if (itemRows.isEmpty && serviceRows.isEmpty)
      GlobalItemRow(localId: UniqueKey().toString()),
  ];

  return s.copyWith(
    customers: s.customers,
    selectedCustomer: data.caseSale ? null : selectedCustomer,
    prefix: data.prefix,
    diliveryChallanNo: data.no.toString(),
    rows: rows,
    charges: mappedCharges,
    discounts: mappedDiscounts,
    miscCharges: mappedMisc,
    subtotal: (data.subTotal).toDouble(),
    totalGst: (data.subGst).toDouble(),
    totalAmount: (data.totalAmount).toDouble(),
    autoRound: data.autoRound,
    diliveryChallanDate: data.diliveryChallanDate,
    cashSaleDefault: data.caseSale,
  );
}
