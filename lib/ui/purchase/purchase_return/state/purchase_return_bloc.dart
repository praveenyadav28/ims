import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:ims/ui/sales/data/global_repository.dart';
import 'package:ims/ui/sales/models/common_data.dart';
import 'package:ims/ui/sales/models/global_models.dart';
import 'package:ims/ui/master/misc/misc_charge_model.dart';
import 'package:ims/ui/sales/models/purchase_return_data.dart';
import 'package:ims/utils/prefence.dart';
import 'package:ims/utils/snackbar.dart';
import 'package:intl/intl.dart';

/// ------------------- EVENTS -------------------
abstract class PurchaseReturnEvent {}

class PurchaseReturnLoadInit extends PurchaseReturnEvent {
  final PurchaseReturnData? existing;
  PurchaseReturnLoadInit({this.existing});
}

class PurchaseReturnSelectCustomer extends PurchaseReturnEvent {
  final LedgerModelDrop? c;
  PurchaseReturnSelectCustomer(this.c);
}

class PurchaseReturnToggleCashSale extends PurchaseReturnEvent {
  final bool enabled;
  PurchaseReturnToggleCashSale(this.enabled);
}

class PurchaseReturnAddRow extends PurchaseReturnEvent {}

class PurchaseReturnRemoveRow extends PurchaseReturnEvent {
  final String id;
  PurchaseReturnRemoveRow(this.id);
}

class PurchaseReturnUpdateRow extends PurchaseReturnEvent {
  final GlobalItemRow row;
  PurchaseReturnUpdateRow(this.row);
}

class PurchaseReturnSelectCatalogForRow extends PurchaseReturnEvent {
  final String rowId;
  final ItemServiceModel item;
  PurchaseReturnSelectCatalogForRow(this.rowId, this.item);
}

class PurchaseReturnSelectVariantForRow extends PurchaseReturnEvent {
  final String rowId;
  final VariantModel variant;
  PurchaseReturnSelectVariantForRow(this.rowId, this.variant);
}

class PurchaseReturnToggleUnitForRow extends PurchaseReturnEvent {
  final String rowId;
  final bool sellInBase;
  PurchaseReturnToggleUnitForRow(this.rowId, this.sellInBase);
}

class PurchaseReturnApplyHsnToRow extends PurchaseReturnEvent {
  final String rowId;
  final HsnModel hsn;
  PurchaseReturnApplyHsnToRow(this.rowId, this.hsn);
}

class PurchaseReturnAddCharge extends PurchaseReturnEvent {
  final AdditionalCharge charge;
  PurchaseReturnAddCharge(this.charge);
}

class PurchaseReturnRemoveCharge extends PurchaseReturnEvent {
  final String id;
  PurchaseReturnRemoveCharge(this.id);
}

class PurchaseReturnUpdateCharge extends PurchaseReturnEvent {
  final AdditionalCharge charge;
  PurchaseReturnUpdateCharge(this.charge);
}

class PurchaseReturnAddDiscount extends PurchaseReturnEvent {
  final DiscountLine d;
  PurchaseReturnAddDiscount(this.d);
}

class PurchaseReturnRemoveDiscount extends PurchaseReturnEvent {
  final String id;
  PurchaseReturnRemoveDiscount(this.id);
}

/// ---------- NEW: misc charges events ----------
class PurchaseReturnAddMiscCharge extends PurchaseReturnEvent {
  final GlobalMiscChargeEntry m;
  PurchaseReturnAddMiscCharge(this.m);
}

class PurchaseReturnRemoveMiscCharge extends PurchaseReturnEvent {
  final String id;
  PurchaseReturnRemoveMiscCharge(this.id);
}

class PurchaseReturnUpdateMiscCharge extends PurchaseReturnEvent {
  final GlobalMiscChargeEntry m;
  PurchaseReturnUpdateMiscCharge(this.m);
}

/// ----------------------------------------------
class PurchaseReturnCalculate extends PurchaseReturnEvent {}

class PurchaseReturnSave extends PurchaseReturnEvent {}

class PurchaseReturnToggleRoundOff extends PurchaseReturnEvent {
  final bool value;
  PurchaseReturnToggleRoundOff(this.value);
}

class PurchaseReturnSetTransNo extends PurchaseReturnEvent {
  final String number;
  PurchaseReturnSetTransNo(this.number);
}

class PurchaseReturnSearchTransaction extends PurchaseReturnEvent {}

/// ------------------- STATE -------------------
class PurchaseReturnState {
  final List<LedgerModelDrop> customers;
  final LedgerModelDrop? selectedCustomer;
  final bool cashSaleDefault;
  final List<HsnModel> hsnMaster;
  final String prefix;
  final String purchaseReturnNo;
  final String? transPlaceOfSupply; // ✅ NEW
  final String transNo; // user input number as string
  final String? transId; // loaded transaction id (from backend) if any
  final DateTime? purchaseReturnDate;
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

  PurchaseReturnState({
    this.customers = const [],
    this.selectedCustomer,
    this.cashSaleDefault = false,
    this.prefix = "",
    this.purchaseReturnNo = '',
    this.transPlaceOfSupply,
    this.hsnMaster = const [],
    this.purchaseReturnDate,
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
    this.transNo = "",
    this.transId,
  });

  PurchaseReturnState copyWith({
    List<LedgerModelDrop>? customers,
    LedgerModelDrop? selectedCustomer,
    bool? cashSaleDefault,
    String? prefix,
    String? purchaseReturnNo,
    String? transPlaceOfSupply,
    DateTime? purchaseReturnDate,
    List<HsnModel>? hsnMaster,
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
    String? transNo,
    String? transId,
  }) {
    return PurchaseReturnState(
      customers: customers ?? this.customers,
      selectedCustomer: selectedCustomer ?? this.selectedCustomer,
      cashSaleDefault: cashSaleDefault ?? this.cashSaleDefault,
      prefix: prefix ?? this.prefix,
      purchaseReturnNo: purchaseReturnNo ?? this.purchaseReturnNo,
      transPlaceOfSupply: transPlaceOfSupply ?? this.transPlaceOfSupply,
      purchaseReturnDate: purchaseReturnDate ?? this.purchaseReturnDate,
      hsnMaster: hsnMaster ?? this.hsnMaster,
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
      transNo: transNo ?? this.transNo,
      transId: transId ?? this.transId,
    );
  }
}

/// ------------------- SAVE EVENT (UI) -------------------
class PurchaseReturnSaveWithUIData extends PurchaseReturnEvent {
  final String supplierName;
  final String? updateId;
  final String mobile;
  final String billingAddress;
  final String shippingAddress;
  final String stateName; // ✅ ADD
  final List<String> notes;
  final List<String> terms;
  final File? signatureImage; // NEW

  PurchaseReturnSaveWithUIData({
    required this.supplierName,
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

final GlobalKey<NavigatorState> purchaseReturnNavigatorKey =
    GlobalKey<NavigatorState>();

/// ------------------- BLOC -------------------
class PurchaseReturnBloc
    extends Bloc<PurchaseReturnEvent, PurchaseReturnState> {
  final GLobalRepository repo;
  PurchaseReturnBloc({required this.repo}) : super(PurchaseReturnState()) {
    on<PurchaseReturnLoadInit>((event, emit) async {
      await _onLoad(event, emit);

      if (event.existing != null) {
        emit(_prefillPurchaseReturn(event.existing!, state));
        add(PurchaseReturnCalculate());
      }
    });
    on<PurchaseReturnSelectCustomer>(_onSelectCustomer);
    on<PurchaseReturnToggleCashSale>(_onToggleCashSale);
    on<PurchaseReturnAddRow>(_onAddRow);
    on<PurchaseReturnRemoveRow>(_onRemoveRow);
    on<PurchaseReturnUpdateRow>(_onUpdateRow);
    on<PurchaseReturnSelectCatalogForRow>(_onSelectCatalogForRow);
    on<PurchaseReturnSelectVariantForRow>(_onSelectVariantForRow);
    on<PurchaseReturnToggleUnitForRow>(_onToggleUnitForRow);
    on<PurchaseReturnSaveWithUIData>(_onSaveWithUIData);
    on<PurchaseReturnApplyHsnToRow>(_onApplyHsnToRow);
    on<PurchaseReturnAddCharge>(_onAddCharge);
    on<PurchaseReturnRemoveCharge>(_onRemoveCharge);
    on<PurchaseReturnUpdateCharge>(_onUpdateCharge);
    on<PurchaseReturnAddDiscount>(_onAddDiscount);
    on<PurchaseReturnRemoveDiscount>(_onRemoveDiscount);

    // misc
    on<PurchaseReturnAddMiscCharge>(_onAddMiscCharge);
    on<PurchaseReturnRemoveMiscCharge>(_onRemoveMiscCharge);
    on<PurchaseReturnUpdateMiscCharge>(_onUpdateMiscCharge);

    on<PurchaseReturnToggleRoundOff>(_onToggleRoundOff);
    on<PurchaseReturnCalculate>(_onCalculate);

    on<PurchaseReturnSetTransNo>((e, emit) {
      emit(state.copyWith(transNo: e.number));
    });

    on<PurchaseReturnSearchTransaction>(_onSearchTransaction);
  }

  Future<void> _onLoad(
    PurchaseReturnLoadInit e,
    Emitter<PurchaseReturnState> emit,
  ) async {
    try {
      final customers = await repo.fetchLedger(false);
      final purchaseReturnNo = await repo.fetchPurchaseReturnNo();
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
          purchaseReturnNo: purchaseReturnNo,
          catalogue: catalogue,
          hsnMaster: hsnList,
          miscMasterList: miscMaster,
          // ensure UI has at least one empty row to start
          rows: [GlobalItemRow(localId: UniqueKey().toString())],
        ),
      );

      add(PurchaseReturnCalculate());
    } catch (err) {
      print("❌ Load error: $err");
    }
  }

  void _onSelectCustomer(
    PurchaseReturnSelectCustomer e,
    Emitter<PurchaseReturnState> emit,
  ) => emit(state.copyWith(selectedCustomer: e.c));
  void _onToggleCashSale(
    PurchaseReturnToggleCashSale e,
    Emitter<PurchaseReturnState> emit,
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

  void _onAddRow(PurchaseReturnAddRow e, Emitter<PurchaseReturnState> emit) {
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
    PurchaseReturnRemoveRow e,
    Emitter<PurchaseReturnState> emit,
  ) {
    emit(
      state.copyWith(rows: state.rows.where((r) => r.localId != e.id).toList()),
    );
    add(PurchaseReturnCalculate());
  }

  void _onUpdateRow(
    PurchaseReturnUpdateRow e,
    Emitter<PurchaseReturnState> emit,
  ) {
    emit(
      state.copyWith(
        rows: state.rows.map((r) {
          if (r.localId == e.row.localId) return e.row.recalc();
          return r;
        }).toList(),
      ),
    );
    add(PurchaseReturnCalculate());
  }

  void _onSelectCatalogForRow(
    PurchaseReturnSelectCatalogForRow e,
    Emitter<PurchaseReturnState> emit,
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
                      variant?.purchasePrice ?? item.basePurchasePrice,
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
    add(PurchaseReturnCalculate());
  }

  void _onSelectVariantForRow(
    PurchaseReturnSelectVariantForRow e,
    Emitter<PurchaseReturnState> emit,
  ) {
    emit(
      state.copyWith(
        rows: state.rows.map((r) {
          if (r.localId == e.rowId) {
            return r
                .copyWith(
                  selectedVariant: e.variant,
                  pricePerSelectedUnit: r.sellInBaseUnit
                      ? e.variant.purchasePrice * (r.product?.conversion ?? 1)
                      : e.variant.purchasePrice,
                )
                .recalc();
          }
          return r;
        }).toList(),
      ),
    );
    add(PurchaseReturnCalculate());
  }

  void _onToggleUnitForRow(
    PurchaseReturnToggleUnitForRow e,
    Emitter<PurchaseReturnState> emit,
  ) {
    emit(
      state.copyWith(
        rows: state.rows.map((r) {
          if (r.localId == e.rowId) {
            final basePrice =
                r.selectedVariant?.purchasePrice ??
                r.product?.basePurchasePrice ??
                0;

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
    add(PurchaseReturnCalculate());
  }

  void _onApplyHsnToRow(
    PurchaseReturnApplyHsnToRow e,
    Emitter<PurchaseReturnState> emit,
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
    add(PurchaseReturnCalculate());
  }

  void _onAddCharge(
    PurchaseReturnAddCharge e,
    Emitter<PurchaseReturnState> emit,
  ) {
    emit(state.copyWith(charges: [...state.charges, e.charge]));
    add(PurchaseReturnCalculate());
  }

  void _onRemoveCharge(
    PurchaseReturnRemoveCharge e,
    Emitter<PurchaseReturnState> emit,
  ) {
    emit(
      state.copyWith(
        charges: state.charges.where((c) => c.id != e.id).toList(),
      ),
    );
    add(PurchaseReturnCalculate());
  }

  void _onUpdateCharge(
    PurchaseReturnUpdateCharge e,
    Emitter<PurchaseReturnState> emit,
  ) {
    emit(
      state.copyWith(
        charges: state.charges.map((c) {
          if (c.id == e.charge.id) return e.charge;
          return c;
        }).toList(),
      ),
    );
    add(PurchaseReturnCalculate());
  }

  void _onAddDiscount(
    PurchaseReturnAddDiscount e,
    Emitter<PurchaseReturnState> emit,
  ) {
    emit(state.copyWith(discounts: [...state.discounts, e.d]));
    add(PurchaseReturnCalculate());
  }

  void _onRemoveDiscount(
    PurchaseReturnRemoveDiscount e,
    Emitter<PurchaseReturnState> emit,
  ) {
    emit(
      state.copyWith(
        discounts: state.discounts.where((d) => d.id != e.id).toList(),
      ),
    );
    add(PurchaseReturnCalculate());
  }

  void _onToggleRoundOff(
    PurchaseReturnToggleRoundOff e,
    Emitter<PurchaseReturnState> emit,
  ) {
    emit(state.copyWith(autoRound: e.value));
    add(PurchaseReturnCalculate());
  }

  // ------------------- MISC CHARGE HANDLERS -------------------
  void _onAddMiscCharge(
    PurchaseReturnAddMiscCharge e,
    Emitter<PurchaseReturnState> emit,
  ) {
    // When adding from UI, user may select an item from master list or create custom.
    // We'll accept the provided MiscChargeEntry as-is (it should already include gst/ledger if selected)
    emit(state.copyWith(miscCharges: [...state.miscCharges, e.m]));
    add(PurchaseReturnCalculate());
  }

  void _onRemoveMiscCharge(
    PurchaseReturnRemoveMiscCharge e,
    Emitter<PurchaseReturnState> emit,
  ) {
    emit(
      state.copyWith(
        miscCharges: state.miscCharges.where((m) => m.id != e.id).toList(),
      ),
    );
    add(PurchaseReturnCalculate());
  }

  void _onUpdateMiscCharge(
    PurchaseReturnUpdateMiscCharge e,
    Emitter<PurchaseReturnState> emit,
  ) {
    emit(
      state.copyWith(
        miscCharges: state.miscCharges.map((m) {
          if (m.id == e.m.id) return e.m;
          return m;
        }).toList(),
      ),
    );
    add(PurchaseReturnCalculate());
  }

  // ------------------- CALCULATION -------------------
  void _onCalculate(
    PurchaseReturnCalculate e,
    Emitter<PurchaseReturnState> emit,
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

  // ------------------- SEARCH TRANSACTION -------------------
  Future<void> _onSearchTransaction(
    PurchaseReturnSearchTransaction e,
    Emitter<PurchaseReturnState> emit,
  ) async {
    try {
      final transNoInt = int.tryParse(state.transNo) ?? 0;
      if (transNoInt == 0) {
        showCustomSnackbarError(
          purchaseReturnNavigatorKey.currentContext!,
          "Enter a valid number",
        );
        return;
      }

      // call repo method provided by you
      final GlobalDataAllPurchase estimate = await repo
          .getTransByNumberPurchase(
            transNo: transNoInt,
            transType: 'Purchaseinvoice',
          );

      // map estimate -> PurchaseReturn state (without touching prefix, PurchaseReturnNo, PurchaseReturnDate)
      final newState = _prefillPurchaseReturnFromTrans(estimate, state)
          .copyWith(
            transId: estimate.id,
            transNo: state.transNo,
            transPlaceOfSupply: estimate.placeOfSupply,
          );

      emit(newState);
      add(PurchaseReturnCalculate());
      showCustomSnackbarSuccess(
        purchaseReturnNavigatorKey.currentContext!,
        "Transaction loaded",
      );
    } catch (err) {
      print("❌ transaction fetch error: $err");
      showCustomSnackbarError(
        purchaseReturnNavigatorKey.currentContext!,
        "Transaction not found",
      );
    }
  }

  // ------------------- SAVE -------------------
  Future<void> _onSaveWithUIData(
    PurchaseReturnSaveWithUIData e,
    Emitter<PurchaseReturnState> emit,
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
        "supplier_id": supplierId,
        "supplier_name": supplierName,
        if (mobile.isNotEmpty) "mobile": mobile,
        "address_0": billing,
        "address_1": shipping,
        "place_of_supply": e.stateName,
        "prefix": state.prefix,
        "no": int.tryParse(state.purchaseReturnNo),
        "purchasereturn_date": DateFormat(
          'yyyy-MM-dd',
        ).format(state.purchaseReturnDate ?? DateTime.now()),
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
      // include trans fields only if present (from search)
      if (state.transId != null && state.transId!.isNotEmpty) {
        payload["purchaseinvoice_id"] = state.transId;
      }
      if (state.transNo.isNotEmpty) {
        payload["purchaseinvoice_no"] =
            int.tryParse(state.transNo) ?? state.transNo;
      }

      if (itemRows.isEmpty) {
        showCustomSnackbarError(
          purchaseReturnNavigatorKey.currentContext!,
          "Add atleast one item",
        );
        return;
      } else {
        final res = await repo.savePurchaseReturn(
          payload: payload,
          signatureFile: e.signatureImage != null
              ? XFile(e.signatureImage!.path)
              : null,
          updateId: e.updateId,
        );

        if (res?['status'] == true) {
          showCustomSnackbarSuccess(
            purchaseReturnNavigatorKey.currentContext!,
            res?['message'] ?? "Saved",
          );
          final ctx = purchaseReturnNavigatorKey.currentContext!;
          Navigator.of(ctx).pop(true);
        } else {
          showCustomSnackbarError(
            purchaseReturnNavigatorKey.currentContext!,
            res?['message'] ?? "Save failed",
          );
        }
      }
    } catch (err) {
      showCustomSnackbarError(
        purchaseReturnNavigatorKey.currentContext!,
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

PurchaseReturnState _prefillPurchaseReturnFromTrans(
  GlobalDataAllPurchase data,
  PurchaseReturnState s,
) {
  // find customer from loaded list (or create fallback)
  final selectedCustomer = s.customers.firstWhere(
    (c) => c.id == data.ledgerId,
    orElse: () => LedgerModelDrop(
      id: data.ledgerId ?? "",
      name: data.ledgerName,
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
    final nameFromPurchaseReturn = (m.name).trim().toLowerCase();
    if (nameFromPurchaseReturn.isEmpty) continue;

    // try to find in misc master list safely
    MiscChargeModelList? match;
    try {
      match = s.miscMasterList.firstWhere(
        (mx) => (mx.name).trim().toLowerCase() == nameFromPurchaseReturn,
      );
    } catch (_) {
      match = null;
    }

    if (match == null) {
      // skip if master not found
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
      basePurchasePrice: 0,
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
    // NOTE: Intentionally NOT overwriting prefix, PurchaseReturnNo, PurchaseReturnDate
    rows: rows,
    charges: mappedCharges,
    discounts: mappedDiscounts,
    miscCharges: mappedMisc,
    subtotal: (data.subTotal).toDouble(),
    totalGst: (data.subGst).toDouble(),
    totalAmount: (data.totalAmount).toDouble(),
    autoRound: data.autoRound,
    cashSaleDefault: data.caseSale,
  );
}

/// ------------------- PREFILL HELPER -------------------
PurchaseReturnState _prefillPurchaseReturn(
  PurchaseReturnData data,
  PurchaseReturnState s,
) {
  // find customer from loaded list (or create fallback)
  final selectedCustomer = s.customers.firstWhere(
    (c) => c.id == data.supplierId,
    orElse: () => LedgerModelDrop(
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
    final nameFromPurchaseReturn = (m.name).trim().toLowerCase();
    if (nameFromPurchaseReturn.isEmpty) continue;

    // try to find in misc master list safely
    MiscChargeModelList? match;
    try {
      match = s.miscMasterList.firstWhere(
        (mx) => (mx.name).trim().toLowerCase() == nameFromPurchaseReturn,
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
      basePurchasePrice: 0,
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
    purchaseReturnNo: data.no.toString(),
    rows: rows,
    charges: mappedCharges,
    discounts: mappedDiscounts,
    miscCharges: mappedMisc,
    subtotal: (data.subTotal).toDouble(),
    totalGst: (data.subGst).toDouble(),
    totalAmount: (data.totalAmount).toDouble(),
    autoRound: data.autoRound,
    purchaseReturnDate: data.purchaseReturnDate,
    cashSaleDefault: data.caseSale,
  );
}
