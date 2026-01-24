import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:ims/model/ledger_model.dart';
import 'package:ims/ui/sales/data/global_repository.dart';
import 'package:ims/ui/sales/models/common_data.dart';
import 'package:ims/ui/sales/models/global_models.dart';
import 'package:ims/ui/master/misc/misc_charge_model.dart';
import 'package:ims/ui/sales/models/purcahseinvoice_data.dart';
import 'package:ims/utils/api.dart';
import 'package:ims/utils/prefence.dart';
import 'package:ims/utils/snackbar.dart';
import 'package:intl/intl.dart';

/// ------------------- EVENTS -------------------
abstract class PurchaseInvoiceEvent {}

class PurchaseInvoiceLoadInit extends PurchaseInvoiceEvent {
  final PurchaseInvoiceData? existing;
  PurchaseInvoiceLoadInit({this.existing});
}

class PurchaseInvoiceSelectCustomer extends PurchaseInvoiceEvent {
  final LedgerModelDrop? c;
  PurchaseInvoiceSelectCustomer(this.c);
}

class PurchaseInvoiceToggleCashSale extends PurchaseInvoiceEvent {
  final bool enabled;
  PurchaseInvoiceToggleCashSale(this.enabled);
}

class PurchaseInvoiceAddRow extends PurchaseInvoiceEvent {}

class PurchaseInvoiceRemoveRow extends PurchaseInvoiceEvent {
  final String id;
  PurchaseInvoiceRemoveRow(this.id);
}

class PurchaseInvoiceUpdateRow extends PurchaseInvoiceEvent {
  final GlobalItemRow row;
  PurchaseInvoiceUpdateRow(this.row);
}

class PurchaseInvoiceSelectCatalogForRow extends PurchaseInvoiceEvent {
  final String rowId;
  final ItemServiceModel item;
  PurchaseInvoiceSelectCatalogForRow(this.rowId, this.item);
}

class PurchaseInvoiceSelectVariantForRow extends PurchaseInvoiceEvent {
  final String rowId;
  final VariantModel variant;
  PurchaseInvoiceSelectVariantForRow(this.rowId, this.variant);
}

class PurchaseInvoiceToggleUnitForRow extends PurchaseInvoiceEvent {
  final String rowId;
  final bool sellInBase;
  PurchaseInvoiceToggleUnitForRow(this.rowId, this.sellInBase);
}

class PurchaseInvoiceApplyHsnToRow extends PurchaseInvoiceEvent {
  final String rowId;
  final HsnModel hsn;
  PurchaseInvoiceApplyHsnToRow(this.rowId, this.hsn);
}

class PurchaseInvoiceAddCharge extends PurchaseInvoiceEvent {
  final AdditionalCharge charge;
  PurchaseInvoiceAddCharge(this.charge);
}

class PurchaseInvoiceRemoveCharge extends PurchaseInvoiceEvent {
  final String id;
  PurchaseInvoiceRemoveCharge(this.id);
}

class PurchaseInvoiceUpdateCharge extends PurchaseInvoiceEvent {
  final AdditionalCharge charge;
  PurchaseInvoiceUpdateCharge(this.charge);
}

class PurchaseInvoiceAddDiscount extends PurchaseInvoiceEvent {
  final DiscountLine d;
  PurchaseInvoiceAddDiscount(this.d);
}

class PurchaseInvoiceRemoveDiscount extends PurchaseInvoiceEvent {
  final String id;
  PurchaseInvoiceRemoveDiscount(this.id);
}

/// ---------- NEW: misc charges events ----------
class PurchaseInvoiceAddMiscCharge extends PurchaseInvoiceEvent {
  final GlobalMiscChargeEntry m;
  PurchaseInvoiceAddMiscCharge(this.m);
}

class PurchaseInvoiceRemoveMiscCharge extends PurchaseInvoiceEvent {
  final String id;
  PurchaseInvoiceRemoveMiscCharge(this.id);
}

class PurchaseInvoiceUpdateMiscCharge extends PurchaseInvoiceEvent {
  final GlobalMiscChargeEntry m;
  PurchaseInvoiceUpdateMiscCharge(this.m);
}

/// ----------------------------------------------
class PurchaseInvoiceCalculate extends PurchaseInvoiceEvent {}

class PurchaseInvoiceSave extends PurchaseInvoiceEvent {}

class PurchaseInvoiceToggleRoundOff extends PurchaseInvoiceEvent {
  final bool value;
  PurchaseInvoiceToggleRoundOff(this.value);
}

class PurchaseInvoiceSetTransNo extends PurchaseInvoiceEvent {
  final String number;
  PurchaseInvoiceSetTransNo(this.number);
}

class PurchaseInvoiceSearchTransaction extends PurchaseInvoiceEvent {}

class PurchaseInvoiceSavePayment extends PurchaseInvoiceEvent {
  final String amount;
  final String voucherNo;
  final LedgerListModel ledger;
  final DateTime date;

  PurchaseInvoiceSavePayment({
    required this.amount,
    required this.voucherNo,
    required this.ledger,
    required this.date,
  });
}

/// ------------------- STATE -------------------
class PurchaseInvoiceState {
  final List<LedgerModelDrop> customers;
  final LedgerModelDrop? selectedCustomer;
  final bool cashSaleDefault;
  final List<HsnModel> hsnMaster;
  final String prefix;
  final String transNo; // user input number as string
  final String? transId; // loaded transaction id (from backend) if any
  final String purchaseInvoiceNo;
  final DateTime? purchaseInvoiceDate;
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

  PurchaseInvoiceState({
    this.customers = const [],
    this.selectedCustomer,
    this.cashSaleDefault = false,
    this.prefix = 'PO',
    this.purchaseInvoiceNo = '',
    this.hsnMaster = const [],
    this.purchaseInvoiceDate,
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

  PurchaseInvoiceState copyWith({
    List<LedgerModelDrop>? customers,
    LedgerModelDrop? selectedCustomer,
    bool? cashSaleDefault,
    String? prefix,
    String? purchaseInvoiceNo,
    DateTime? purchaseInvoiceDate,
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
    return PurchaseInvoiceState(
      customers: customers ?? this.customers,
      selectedCustomer: selectedCustomer ?? this.selectedCustomer,
      cashSaleDefault: cashSaleDefault ?? this.cashSaleDefault,
      prefix: prefix ?? this.prefix,
      purchaseInvoiceNo: purchaseInvoiceNo ?? this.purchaseInvoiceNo,
      purchaseInvoiceDate: purchaseInvoiceDate ?? this.purchaseInvoiceDate,
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
class PurchaseInvoiceSaveWithUIData extends PurchaseInvoiceEvent {
  final String supplierName;
  final String? updateId;
  final String mobile;
  final String billingAddress;
  final String shippingAddress;
  final List<String> notes;
  final List<String> terms;
  final File? signatureImage; // NEW

  PurchaseInvoiceSaveWithUIData({
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

final GlobalKey<NavigatorState> purchaseInvoiceNavigatorKey =
    GlobalKey<NavigatorState>();

/// ------------------- BLOC -------------------
class PurchaseInvoiceBloc
    extends Bloc<PurchaseInvoiceEvent, PurchaseInvoiceState> {
  final GLobalRepository repo;
  PurchaseInvoiceBloc({required this.repo}) : super(PurchaseInvoiceState()) {
    on<PurchaseInvoiceLoadInit>((event, emit) async {
      await _onLoad(event, emit);

      if (event.existing != null) {
        emit(_prefillPurchaseInvoice(event.existing!, state));
        add(PurchaseInvoiceCalculate());
      }
    });
    on<PurchaseInvoiceSelectCustomer>(_onSelectCustomer);
    on<PurchaseInvoiceToggleCashSale>(_onToggleCashSale);
    on<PurchaseInvoiceAddRow>(_onAddRow);
    on<PurchaseInvoiceRemoveRow>(_onRemoveRow);
    on<PurchaseInvoiceUpdateRow>(_onUpdateRow);
    on<PurchaseInvoiceSelectCatalogForRow>(_onSelectCatalogForRow);
    on<PurchaseInvoiceSelectVariantForRow>(_onSelectVariantForRow);
    on<PurchaseInvoiceToggleUnitForRow>(_onToggleUnitForRow);
    on<PurchaseInvoiceSaveWithUIData>(_onSaveWithUIData);
    on<PurchaseInvoiceApplyHsnToRow>(_onApplyHsnToRow);
    on<PurchaseInvoiceAddCharge>(_onAddCharge);
    on<PurchaseInvoiceRemoveCharge>(_onRemoveCharge);
    on<PurchaseInvoiceUpdateCharge>(_onUpdateCharge);
    on<PurchaseInvoiceAddDiscount>(_onAddDiscount);
    on<PurchaseInvoiceRemoveDiscount>(_onRemoveDiscount);

    // misc
    on<PurchaseInvoiceAddMiscCharge>(_onAddMiscCharge);
    on<PurchaseInvoiceRemoveMiscCharge>(_onRemoveMiscCharge);
    on<PurchaseInvoiceUpdateMiscCharge>(_onUpdateMiscCharge);

    on<PurchaseInvoiceToggleRoundOff>(_onToggleRoundOff);
    on<PurchaseInvoiceCalculate>(_onCalculate);

    on<PurchaseInvoiceSetTransNo>((e, emit) {
      emit(state.copyWith(transNo: e.number));
    });

    on<PurchaseInvoiceSearchTransaction>(_onSearchTransaction);

    on<PurchaseInvoiceSavePayment>(_onSavePaymentVoucher);
  }

  Future<void> _onLoad(
    PurchaseInvoiceLoadInit e,
    Emitter<PurchaseInvoiceState> emit,
  ) async {
    try {
      final customers = await repo.fetchLedger(false);
      final purchaseInvoiceNo = await repo.fetchPurchaseInvoiceNo();
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
          purchaseInvoiceNo: purchaseInvoiceNo,
          catalogue: catalogue,
          hsnMaster: hsnList,
          miscMasterList: miscMaster,
          // ensure UI has at least one empty row to start
          rows: [GlobalItemRow(localId: UniqueKey().toString())],
        ),
      );

      add(PurchaseInvoiceCalculate());
    } catch (err) {
      print("❌ Load error: $err");
    }
  }

  void _onSelectCustomer(
    PurchaseInvoiceSelectCustomer e,
    Emitter<PurchaseInvoiceState> emit,
  ) => emit(state.copyWith(selectedCustomer: e.c));
  void _onToggleCashSale(
    PurchaseInvoiceToggleCashSale e,
    Emitter<PurchaseInvoiceState> emit,
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

  void _onAddRow(PurchaseInvoiceAddRow e, Emitter<PurchaseInvoiceState> emit) {
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
    PurchaseInvoiceRemoveRow e,
    Emitter<PurchaseInvoiceState> emit,
  ) {
    emit(
      state.copyWith(rows: state.rows.where((r) => r.localId != e.id).toList()),
    );
    add(PurchaseInvoiceCalculate());
  }

  void _onUpdateRow(
    PurchaseInvoiceUpdateRow e,
    Emitter<PurchaseInvoiceState> emit,
  ) {
    emit(
      state.copyWith(
        rows: state.rows.map((r) {
          if (r.localId == e.row.localId) return e.row.recalc();
          return r;
        }).toList(),
      ),
    );
    add(PurchaseInvoiceCalculate());
  }

  void _onSelectCatalogForRow(
    PurchaseInvoiceSelectCatalogForRow e,
    Emitter<PurchaseInvoiceState> emit,
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
    add(PurchaseInvoiceCalculate());
  }

  void _onSelectVariantForRow(
    PurchaseInvoiceSelectVariantForRow e,
    Emitter<PurchaseInvoiceState> emit,
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
    add(PurchaseInvoiceCalculate());
  }

  void _onToggleUnitForRow(
    PurchaseInvoiceToggleUnitForRow e,
    Emitter<PurchaseInvoiceState> emit,
  ) {
    emit(
      state.copyWith(
        rows: state.rows.map((r) {
          if (r.localId == e.rowId) {
            final basePrice =
                r.selectedVariant?.purchasePrice ?? r.product?.basePurchasePrice ?? 0;

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
    add(PurchaseInvoiceCalculate());
  }

  void _onApplyHsnToRow(
    PurchaseInvoiceApplyHsnToRow e,
    Emitter<PurchaseInvoiceState> emit,
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
    add(PurchaseInvoiceCalculate());
  }

  void _onAddCharge(
    PurchaseInvoiceAddCharge e,
    Emitter<PurchaseInvoiceState> emit,
  ) {
    emit(state.copyWith(charges: [...state.charges, e.charge]));
    add(PurchaseInvoiceCalculate());
  }

  void _onRemoveCharge(
    PurchaseInvoiceRemoveCharge e,
    Emitter<PurchaseInvoiceState> emit,
  ) {
    emit(
      state.copyWith(
        charges: state.charges.where((c) => c.id != e.id).toList(),
      ),
    );
    add(PurchaseInvoiceCalculate());
  }

  void _onUpdateCharge(
    PurchaseInvoiceUpdateCharge e,
    Emitter<PurchaseInvoiceState> emit,
  ) {
    emit(
      state.copyWith(
        charges: state.charges.map((c) {
          if (c.id == e.charge.id) return e.charge;
          return c;
        }).toList(),
      ),
    );
    add(PurchaseInvoiceCalculate());
  }

  void _onAddDiscount(
    PurchaseInvoiceAddDiscount e,
    Emitter<PurchaseInvoiceState> emit,
  ) {
    emit(state.copyWith(discounts: [...state.discounts, e.d]));
    add(PurchaseInvoiceCalculate());
  }

  void _onRemoveDiscount(
    PurchaseInvoiceRemoveDiscount e,
    Emitter<PurchaseInvoiceState> emit,
  ) {
    emit(
      state.copyWith(
        discounts: state.discounts.where((d) => d.id != e.id).toList(),
      ),
    );
    add(PurchaseInvoiceCalculate());
  }

  void _onToggleRoundOff(
    PurchaseInvoiceToggleRoundOff e,
    Emitter<PurchaseInvoiceState> emit,
  ) {
    emit(state.copyWith(autoRound: e.value));
    add(PurchaseInvoiceCalculate());
  }

  // ------------------- MISC CHARGE HANDLERS -------------------
  void _onAddMiscCharge(
    PurchaseInvoiceAddMiscCharge e,
    Emitter<PurchaseInvoiceState> emit,
  ) {
    // When adding from UI, user may select an item from master list or create custom.
    // We'll accept the provided MiscChargeEntry as-is (it should already include gst/ledger if selected)
    emit(state.copyWith(miscCharges: [...state.miscCharges, e.m]));
    add(PurchaseInvoiceCalculate());
  }

  void _onRemoveMiscCharge(
    PurchaseInvoiceRemoveMiscCharge e,
    Emitter<PurchaseInvoiceState> emit,
  ) {
    emit(
      state.copyWith(
        miscCharges: state.miscCharges.where((m) => m.id != e.id).toList(),
      ),
    );
    add(PurchaseInvoiceCalculate());
  }

  void _onUpdateMiscCharge(
    PurchaseInvoiceUpdateMiscCharge e,
    Emitter<PurchaseInvoiceState> emit,
  ) {
    emit(
      state.copyWith(
        miscCharges: state.miscCharges.map((m) {
          if (m.id == e.m.id) return e.m;
          return m;
        }).toList(),
      ),
    );
    add(PurchaseInvoiceCalculate());
  }

  // ------------------- CALCULATION -------------------
  void _onCalculate(
    PurchaseInvoiceCalculate e,
    Emitter<PurchaseInvoiceState> emit,
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
    PurchaseInvoiceSearchTransaction e,
    Emitter<PurchaseInvoiceState> emit,
  ) async {
    try {
      final transNoInt = int.tryParse(state.transNo) ?? 0;
      if (transNoInt == 0) {
        showCustomSnackbarError(
          purchaseInvoiceNavigatorKey.currentContext!,
          "Enter a valid number",
        );
        return;
      }

      // call repo method provided by you
      final GlobalDataAllPurchase estimate = await repo
          .getTransByNumberPurchase(
            transNo: transNoInt,
            transType: 'Purchaseoder',
          );

      // map estimate -> PurchaseInvoice state (without touching prefix, PurchaseInvoiceNo, PurchaseInvoiceDate)
      final newState = _prefillPurchaseInvoiceFromTrans(
        estimate,
        state,
      ).copyWith(transId: estimate.id, transNo: state.transNo);

      emit(newState);
      add(PurchaseInvoiceCalculate());
      showCustomSnackbarSuccess(
        purchaseInvoiceNavigatorKey.currentContext!,
        "Transaction loaded",
      );
    } catch (err) {
      print("❌ transaction fetch error: $err");
      showCustomSnackbarError(
        purchaseInvoiceNavigatorKey.currentContext!,
        "Transaction not found",
      );
    }
  }

  Future<void> _onSavePaymentVoucher(
    PurchaseInvoiceSavePayment e,
    Emitter<PurchaseInvoiceState> emit,
  ) async {
    final ctx = purchaseInvoiceNavigatorKey.currentContext!;
    final state = this.state;

    // ---------- VALIDATIONS ----------
    if (e.amount.trim().isEmpty || double.tryParse(e.amount) == null) return;
    if (double.parse(e.amount) <= 0) return;

    if (state.cashSaleDefault == false && state.selectedCustomer == null) {
      showCustomSnackbarError(ctx, "Select supplier");
      return;
    }

    try {
      final body = {
        "licence_no": Preference.getint(PrefKeys.licenseNo),
        "branch_id": Preference.getString(PrefKeys.locationId),

        "ledger_id": e.ledger.id,
        "ledger_name": e.ledger.ledgerName,

        "supplier_id": state.cashSaleDefault
            ? null
            : state.selectedCustomer!.id,
        "supplier_name": state.cashSaleDefault
            ? "Cash"
            : state.selectedCustomer!.name,

        "amount": double.parse(e.amount),
        "invoice_no": state.purchaseInvoiceNo,

        "date":
            "${e.date.year}-${e.date.month.toString().padLeft(2, '0')}-${e.date.day.toString().padLeft(2, '0')}",

        "prefix": state.prefix,
        "vouncher_no": e.voucherNo,
        "type": "Purchase Invoice",
      };

      final res = await ApiService.postData(
        "payment",
        body,
        licenceNo: Preference.getint(PrefKeys.licenseNo),
      );

      if (res?['status'] == true) {
        showCustomSnackbarSuccess(ctx, res['message'] ?? "Payment saved");
      } else {
        showCustomSnackbarError(ctx, res?['message'] ?? "Payment failed");
      }
    } catch (e) {
      showCustomSnackbarError(ctx, e.toString());
    }
  }

  // ------------------- SAVE -------------------
  Future<void> _onSaveWithUIData(
    PurchaseInvoiceSaveWithUIData e,
    Emitter<PurchaseInvoiceState> emit,
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
        "mobile": mobile,
        "address_0": billing,
        "address_1": shipping,
        "prefix": state.prefix,
        "no": int.tryParse(state.purchaseInvoiceNo),
        "purchaseinvoice_date": DateFormat(
          'yyyy-MM-dd',
        ).format(state.purchaseInvoiceDate ?? DateTime.now()),
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
        payload["purchaseorder_id"] = state.transId;
      }
      if (state.transNo.isNotEmpty) {
        payload["purchaseorder_no"] =
            int.tryParse(state.transNo) ?? state.transNo;
      }

      if (itemRows.isEmpty) {
        showCustomSnackbarError(
          purchaseInvoiceNavigatorKey.currentContext!,
          "Add atleast one item",
        );
        return;
      } else {
        final res = await repo.savePurchaseInvoice(
          payload: payload,
          signatureFile: e.signatureImage != null
              ? XFile(e.signatureImage!.path)
              : null,
          updateId: e.updateId,
        );

        if (res?['status'] == true) {
          showCustomSnackbarSuccess(
            purchaseInvoiceNavigatorKey.currentContext!,
            res?['message'] ?? "Saved",
          );

          final ctx = purchaseInvoiceNavigatorKey.currentContext!;
          Navigator.of(ctx).pop(true);
        } else {
          showCustomSnackbarError(
            purchaseInvoiceNavigatorKey.currentContext!,
            res?['message'] ?? "Save failed",
          );
        }
      }
    } catch (err) {
      showCustomSnackbarError(
        purchaseInvoiceNavigatorKey.currentContext!,
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

PurchaseInvoiceState _prefillPurchaseInvoiceFromTrans(
  GlobalDataAllPurchase data,
  PurchaseInvoiceState s,
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
    final nameFromPurchaseInvoice = (m.name).trim().toLowerCase();
    if (nameFromPurchaseInvoice.isEmpty) continue;

    // try to find in misc master list safely
    MiscChargeModelList? match;
    try {
      match = s.miscMasterList.firstWhere(
        (mx) => (mx.name).trim().toLowerCase() == nameFromPurchaseInvoice,
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
    // NOTE: Intentionally NOT overwriting prefix, PurchaseInvoiceNo, PurchaseInvoiceDate
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
PurchaseInvoiceState _prefillPurchaseInvoice(
  PurchaseInvoiceData data,
  PurchaseInvoiceState s,
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
    final nameFromPurchaseInvoice = (m.name).trim().toLowerCase();
    if (nameFromPurchaseInvoice.isEmpty) continue;

    // try to find in misc master list safely
    MiscChargeModelList? match;
    try {
      match = s.miscMasterList.firstWhere(
        (mx) => (mx.name).trim().toLowerCase() == nameFromPurchaseInvoice,
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
    purchaseInvoiceNo: data.no.toString(),
    rows: rows,
    charges: mappedCharges,
    discounts: mappedDiscounts,
    miscCharges: mappedMisc,
    subtotal: (data.subTotal).toDouble(),
    totalGst: (data.subGst).toDouble(),
    totalAmount: (data.totalAmount).toDouble(),
    autoRound: data.autoRound,
    purchaseInvoiceDate: data.purchaseInvoiceDate,
    cashSaleDefault: data.caseSale,
  );
}
