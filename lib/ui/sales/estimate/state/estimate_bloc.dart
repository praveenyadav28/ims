// estimate_bloc.dart
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ims/ui/sales/data/global_repository.dart';
import 'package:ims/ui/sales/models/estimate_data.dart';
import 'package:ims/ui/sales/models/global_models.dart';
import 'package:ims/ui/master/misc/misc_charge_model.dart';
import 'package:ims/utils/prefence.dart';
import 'package:ims/utils/snackbar.dart';
import 'package:intl/intl.dart';

/// ------------------- EVENTS -------------------
abstract class EstEvent {}

class EstLoadInit extends EstEvent {
  final EstimateData? existing;
  EstLoadInit({this.existing});
}

class EstSelectCustomer extends EstEvent {
  final LedgerModelDrop? c;
  EstSelectCustomer(this.c);
}

class EstToggleCashSale extends EstEvent {
  final bool enabled;
  EstToggleCashSale(this.enabled);
}

class EstAddRow extends EstEvent {}

class EstRemoveRow extends EstEvent {
  final String id;
  EstRemoveRow(this.id);
}

class EstUpdateRow extends EstEvent {
  final GlobalItemRow row;
  EstUpdateRow(this.row);
}

class EstSelectCatalogForRow extends EstEvent {
  final String rowId;
  final ItemServiceModel item;
  EstSelectCatalogForRow(this.rowId, this.item);
}

class EstSelectVariantForRow extends EstEvent {
  final String rowId;
  final VariantModel variant;
  EstSelectVariantForRow(this.rowId, this.variant);
}

class EstToggleUnitForRow extends EstEvent {
  final String rowId;
  final bool sellInBase;
  EstToggleUnitForRow(this.rowId, this.sellInBase);
}

class EstApplyHsnToRow extends EstEvent {
  final String rowId;
  final HsnModel hsn;
  EstApplyHsnToRow(this.rowId, this.hsn);
}

class EstAddCharge extends EstEvent {
  final AdditionalCharge charge;
  EstAddCharge(this.charge);
}

class EstRemoveCharge extends EstEvent {
  final String id;
  EstRemoveCharge(this.id);
}

class EstUpdateCharge extends EstEvent {
  final AdditionalCharge charge;
  EstUpdateCharge(this.charge);
}

class EstAddDiscount extends EstEvent {
  final DiscountLine d;
  EstAddDiscount(this.d);
}

class EstRemoveDiscount extends EstEvent {
  final String id;
  EstRemoveDiscount(this.id);
}

/// ---------- NEW: misc charges events ----------
class EstAddMiscCharge extends EstEvent {
  final GlobalMiscChargeEntry m;
  EstAddMiscCharge(this.m);
}

class EstRemoveMiscCharge extends EstEvent {
  final String id;
  EstRemoveMiscCharge(this.id);
}

class EstUpdateMiscCharge extends EstEvent {
  final GlobalMiscChargeEntry m;
  EstUpdateMiscCharge(this.m);
}

/// ----------------------------------------------
class EstCalculate extends EstEvent {}

class EstSave extends EstEvent {}

class EstToggleRoundOff extends EstEvent {
  final bool value;
  EstToggleRoundOff(this.value);
}

/// ------------------- STATE -------------------
class EstState {
  final List<LedgerModelDrop> customers;
  final LedgerModelDrop? selectedCustomer;
  final bool cashSaleDefault;
  final List<HsnModel> hsnMaster;
  final String prefix;
  final String estimateNo;
  final DateTime? estimateDate;
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

  EstState({
    this.customers = const [],
    this.selectedCustomer,
    this.cashSaleDefault = false,
    this.prefix = "",
    this.estimateNo = '',
    this.hsnMaster = const [],
    this.estimateDate,
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

  EstState copyWith({
    List<LedgerModelDrop>? customers,
    LedgerModelDrop? selectedCustomer,
    bool? cashSaleDefault,
    String? prefix,
    String? estimateNo,
    DateTime? estimateDate,
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
    return EstState(
      customers: customers ?? this.customers,
      selectedCustomer: selectedCustomer ?? this.selectedCustomer,
      cashSaleDefault: cashSaleDefault ?? this.cashSaleDefault,
      prefix: prefix ?? this.prefix,
      estimateNo: estimateNo ?? this.estimateNo,
      estimateDate: estimateDate ?? this.estimateDate,
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
class EstSaveWithUIData extends EstEvent {
  final String customerName;
  final String? updateId;
  final String mobile;
  final String billingAddress;
  final String shippingAddress;
  final String stateName; // ✅ ADD
  final List<String> notes;
  final List<String> terms;
  final Uint8List? signatureImage; // NEW

  EstSaveWithUIData({
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

final GlobalKey<NavigatorState> estimateNavigatorKey =
    GlobalKey<NavigatorState>();

/// ------------------- BLOC -------------------
class EstBloc extends Bloc<EstEvent, EstState> {
  final GLobalRepository repo;
  EstBloc({required this.repo}) : super(EstState()) {
    on<EstLoadInit>((event, emit) async {
      await _onLoad(event, emit);

      if (event.existing != null) {
        emit(_prefillEstimate(event.existing!, state));
        add(EstCalculate());
      }
    });
    on<EstSelectCustomer>(_onSelectCustomer);
    on<EstToggleCashSale>(_onToggleCashSale);
    on<EstAddRow>(_onAddRow);
    on<EstRemoveRow>(_onRemoveRow);
    on<EstUpdateRow>(_onUpdateRow);
    on<EstSelectCatalogForRow>(_onSelectCatalogForRow);
    on<EstSelectVariantForRow>(_onSelectVariantForRow);
    on<EstToggleUnitForRow>(_onToggleUnitForRow);
    on<EstSaveWithUIData>(_onSaveWithUIData);
    on<EstApplyHsnToRow>(_onApplyHsnToRow);
    on<EstAddCharge>(_onAddCharge);
    on<EstRemoveCharge>(_onRemoveCharge);
    on<EstUpdateCharge>(_onUpdateCharge);
    on<EstAddDiscount>(_onAddDiscount);
    on<EstRemoveDiscount>(_onRemoveDiscount);

    // misc
    on<EstAddMiscCharge>(_onAddMiscCharge);
    on<EstRemoveMiscCharge>(_onRemoveMiscCharge);
    on<EstUpdateMiscCharge>(_onUpdateMiscCharge);

    on<EstToggleRoundOff>(_onToggleRoundOff);
    on<EstCalculate>(_onCalculate);
  }

  Future<void> _onLoad(EstLoadInit e, Emitter<EstState> emit) async {
    try {
      final customers = await repo.fetchLedger(true);
      final estimateNo = await repo.fetchEstimateNo();
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
          estimateNo: estimateNo,
          catalogue: catalogue,
          hsnMaster: hsnList,
          miscMasterList: miscMaster,
          // ensure UI has at least one empty row to start
          rows: [GlobalItemRow(localId: UniqueKey().toString())],
        ),
      );

      add(EstCalculate());
    } catch (err) {
      print("❌ Load error: $err");
    }
  }

  void _onSelectCustomer(EstSelectCustomer e, Emitter<EstState> emit) =>
      emit(state.copyWith(selectedCustomer: e.c));
  void _onToggleCashSale(EstToggleCashSale e, Emitter<EstState> emit) {
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

  void _onAddRow(EstAddRow e, Emitter<EstState> emit) {
    emit(
      state.copyWith(
        rows: [
          ...state.rows,
          GlobalItemRow(localId: UniqueKey().toString()),
        ],
      ),
    );
  }

  void _onRemoveRow(EstRemoveRow e, Emitter<EstState> emit) {
    emit(
      state.copyWith(rows: state.rows.where((r) => r.localId != e.id).toList()),
    );
    add(EstCalculate());
  }

  void _onUpdateRow(EstUpdateRow e, Emitter<EstState> emit) {
    emit(
      state.copyWith(
        rows: state.rows.map((r) {
          if (r.localId == e.row.localId) return e.row.recalc();
          return r;
        }).toList(),
      ),
    );
    add(EstCalculate());
  }

  void _onSelectCatalogForRow(
    EstSelectCatalogForRow e,
    Emitter<EstState> emit,
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
    add(EstCalculate());
  }

  void _onSelectVariantForRow(
    EstSelectVariantForRow e,
    Emitter<EstState> emit,
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
    add(EstCalculate());
  }

  void _onToggleUnitForRow(EstToggleUnitForRow e, Emitter<EstState> emit) {
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
    add(EstCalculate());
  }

  void _onApplyHsnToRow(EstApplyHsnToRow e, Emitter<EstState> emit) {
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
    add(EstCalculate());
  }

  void _onAddCharge(EstAddCharge e, Emitter<EstState> emit) {
    emit(state.copyWith(charges: [...state.charges, e.charge]));
    add(EstCalculate());
  }

  void _onRemoveCharge(EstRemoveCharge e, Emitter<EstState> emit) {
    emit(
      state.copyWith(
        charges: state.charges.where((c) => c.id != e.id).toList(),
      ),
    );
    add(EstCalculate());
  }

  void _onUpdateCharge(EstUpdateCharge e, Emitter<EstState> emit) {
    emit(
      state.copyWith(
        charges: state.charges.map((c) {
          if (c.id == e.charge.id) return e.charge;
          return c;
        }).toList(),
      ),
    );
    add(EstCalculate());
  }

  void _onAddDiscount(EstAddDiscount e, Emitter<EstState> emit) {
    emit(state.copyWith(discounts: [...state.discounts, e.d]));
    add(EstCalculate());
  }

  void _onRemoveDiscount(EstRemoveDiscount e, Emitter<EstState> emit) {
    emit(
      state.copyWith(
        discounts: state.discounts.where((d) => d.id != e.id).toList(),
      ),
    );
    add(EstCalculate());
  }

  void _onToggleRoundOff(EstToggleRoundOff e, Emitter<EstState> emit) {
    emit(state.copyWith(autoRound: e.value));
    add(EstCalculate());
  }

  // ------------------- MISC CHARGE HANDLERS -------------------
  void _onAddMiscCharge(EstAddMiscCharge e, Emitter<EstState> emit) {
    // When adding from UI, user may select an item from master list or create custom.
    // We'll accept the provided MiscChargeEntry as-is (it should already include gst/ledger if selected)
    emit(state.copyWith(miscCharges: [...state.miscCharges, e.m]));
    add(EstCalculate());
  }

  void _onRemoveMiscCharge(EstRemoveMiscCharge e, Emitter<EstState> emit) {
    emit(
      state.copyWith(
        miscCharges: state.miscCharges.where((m) => m.id != e.id).toList(),
      ),
    );
    add(EstCalculate());
  }

  void _onUpdateMiscCharge(EstUpdateMiscCharge e, Emitter<EstState> emit) {
    emit(
      state.copyWith(
        miscCharges: state.miscCharges.map((m) {
          if (m.id == e.m.id) return e.m;
          return m;
        }).toList(),
      ),
    );
    add(EstCalculate());
  }

  // ------------------- CALCULATION -------------------
  void _onCalculate(EstCalculate e, Emitter<EstState> emit) {
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
    EstSaveWithUIData e,
    Emitter<EstState> emit,
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
        "no": int.tryParse(state.estimateNo),
        "estimate_date": DateFormat(
          'yyyy-MM-dd',
        ).format(state.estimateDate ?? DateTime.now()),
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
        "service_details": serviceRows,
      };

      if (itemRows.isEmpty && serviceRows.isEmpty) {
        showCustomSnackbarError(
          estimateNavigatorKey.currentContext!,
          "Add atleast one item or service",
        );
        return;
      } else {
        final res = await repo.saveEstimate(
          payload: payload,
          signatureFile: e.signatureImage,
          updateId: e.updateId,
        );

        if (res?['status'] == true) {
          final ctx = estimateNavigatorKey.currentContext!;

          showCustomSnackbarSuccess(ctx, res?['message'] ?? "Saved");

          // 🔥 GO BACK TO PREVIOUS SCREEN
          Navigator.of(ctx).pop(true); // true = success result
        } else {
          showCustomSnackbarError(
            estimateNavigatorKey.currentContext!,
            res?['message'] ?? "Save failed",
          );
        }
      }
    } catch (err) {
      showCustomSnackbarError(
        estimateNavigatorKey.currentContext!,
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
/// Map server EstimateData -> UI state; lookup misc master list for gst/ledger/hsn
EstState _prefillEstimate(EstimateData data, EstState s) {
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
    final nameFromEstimate = (m.name).trim().toLowerCase();
    if (nameFromEstimate.isEmpty) continue;

    // try to find in misc master list safely
    MiscChargeModelList? match;
    try {
      match = s.miscMasterList.firstWhere(
        (mx) => (mx.name).trim().toLowerCase() == nameFromEstimate,
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
    estimateNo: data.no.toString(),
    rows: rows,
    charges: mappedCharges,
    discounts: mappedDiscounts,
    miscCharges: mappedMisc,
    subtotal: (data.subTotal).toDouble(),
    totalGst: (data.subGst).toDouble(),
    totalAmount: (data.totalAmount).toDouble(),
    autoRound: data.autoRound,
    estimateDate: data.estimateDate,
    validityDate: data.estimateDate.add(Duration(days: data.paymentTerms)),
    validForDays: data.paymentTerms,
    cashSaleDefault: data.caseSale,
  );
}
