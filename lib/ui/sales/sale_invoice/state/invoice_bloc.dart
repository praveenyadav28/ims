// sale_invoice_bloc.dart
import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ims/model/ledger_model.dart';
import 'package:ims/ui/master/company/company_api.dart';
import 'package:ims/ui/sales/data/global_repository.dart';
import 'package:ims/ui/sales/data/reuse_print.dart';
import 'package:ims/ui/sales/models/common_data.dart';
import 'package:ims/ui/sales/models/global_models.dart';
import 'package:ims/ui/master/misc/misc_charge_model.dart';
import 'package:ims/ui/sales/models/sale_invoice_data.dart';
import 'package:ims/utils/api.dart';
import 'package:ims/utils/prefence.dart';
import 'package:ims/utils/print_mapper.dart';
import 'package:ims/utils/snackbar.dart';
import 'package:intl/intl.dart';

/// ------------------- EVENTS -------------------
abstract class SaleInvoiceEvent {}

class SaleInvoiceLoadInit extends SaleInvoiceEvent {
  final SaleInvoiceData? existing;
  SaleInvoiceLoadInit({this.existing});
}

class SaleInvoiceSelectCustomer extends SaleInvoiceEvent {
  final LedgerModelDrop? c;
  SaleInvoiceSelectCustomer(this.c);
}

class SaleInvoiceToggleCashSale extends SaleInvoiceEvent {
  final bool enabled;
  SaleInvoiceToggleCashSale(this.enabled);
}

class SaleInvoiceAddRow extends SaleInvoiceEvent {}

class SaleInvoiceRemoveRow extends SaleInvoiceEvent {
  final String id;
  SaleInvoiceRemoveRow(this.id);
}

class SaleInvoiceUpdateRow extends SaleInvoiceEvent {
  final GlobalItemRow row;
  SaleInvoiceUpdateRow(this.row);
}

class SaleInvoiceSelectCatalogForRow extends SaleInvoiceEvent {
  final String rowId;
  final ItemServiceModel item;
  SaleInvoiceSelectCatalogForRow(this.rowId, this.item);
}

class SaleInvoiceSelectVariantForRow extends SaleInvoiceEvent {
  final String rowId;
  final VariantModel variant;
  SaleInvoiceSelectVariantForRow(this.rowId, this.variant);
}

class SaleInvoiceToggleUnitForRow extends SaleInvoiceEvent {
  final String rowId;
  final bool sellInBase;
  SaleInvoiceToggleUnitForRow(this.rowId, this.sellInBase);
}

class SaleInvoiceApplyHsnToRow extends SaleInvoiceEvent {
  final String rowId;
  final HsnModel hsn;
  SaleInvoiceApplyHsnToRow(this.rowId, this.hsn);
}

class SaleInvoiceAddCharge extends SaleInvoiceEvent {
  final AdditionalCharge charge;
  SaleInvoiceAddCharge(this.charge);
}

class SaleInvoiceRemoveCharge extends SaleInvoiceEvent {
  final String id;
  SaleInvoiceRemoveCharge(this.id);
}

class SaleInvoiceUpdateCharge extends SaleInvoiceEvent {
  final AdditionalCharge charge;
  SaleInvoiceUpdateCharge(this.charge);
}

class SaleInvoiceAddDiscount extends SaleInvoiceEvent {
  final DiscountLine d;
  SaleInvoiceAddDiscount(this.d);
}

class SaleInvoiceRemoveDiscount extends SaleInvoiceEvent {
  final String id;
  SaleInvoiceRemoveDiscount(this.id);
}

/// ---------- NEW: misc charges events ----------
class SaleInvoiceAddMiscCharge extends SaleInvoiceEvent {
  final GlobalMiscChargeEntry m;
  SaleInvoiceAddMiscCharge(this.m);
}

class SaleInvoiceRemoveMiscCharge extends SaleInvoiceEvent {
  final String id;
  SaleInvoiceRemoveMiscCharge(this.id);
}

class SaleInvoiceUpdateMiscCharge extends SaleInvoiceEvent {
  final GlobalMiscChargeEntry m;
  SaleInvoiceUpdateMiscCharge(this.m);
}

/// ----------------------------------------------
class SaleInvoiceCalculate extends SaleInvoiceEvent {}

class SaleInvoiceSave extends SaleInvoiceEvent {}

class SaleInvoiceToggleRoundOff extends SaleInvoiceEvent {
  final bool value;
  SaleInvoiceToggleRoundOff(this.value);
}

// ---- new events for transaction search
class SaleInvoiceSetTransType extends SaleInvoiceEvent {
  final String type;
  SaleInvoiceSetTransType(this.type);
}

class SaleInvoiceSetTransNo extends SaleInvoiceEvent {
  final String number;
  SaleInvoiceSetTransNo(this.number);
}

class SaleInvoiceSearchTransaction extends SaleInvoiceEvent {}

class SaleInvoiceSavePayment extends SaleInvoiceEvent {
  final String amount;
  final String voucherNo;
  final LedgerListModel ledger;
  final DateTime date;

  SaleInvoiceSavePayment({
    required this.amount,
    required this.voucherNo,
    required this.ledger,
    required this.date,
  });
}

/// ------------------- STATE -------------------
class SaleInvoiceState {
  final List<LedgerModelDrop> customers;
  final LedgerModelDrop? selectedCustomer;
  final bool cashSaleDefault;
  final String? transPlaceOfSupply;
  final List<HsnModel> hsnMaster;
  final String prefix;
  final String saleInvoiceNo;
  final DateTime? saleInvoiceDate;
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

  // ---- transaction search state
  final String transType; // e.g. "Estimate", "Performa", "Challan"
  final String transNo; // user input number as string
  final String? transId; // loaded transaction id (from backend) if any

  SaleInvoiceState({
    this.customers = const [],
    this.selectedCustomer,
    this.cashSaleDefault = false,
    this.prefix = '',
    this.saleInvoiceNo = '',
    this.hsnMaster = const [],
    this.saleInvoiceDate,
    this.transPlaceOfSupply,
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
    this.transType = "Estimate",
    this.transNo = "",
    this.transId,
  });

  SaleInvoiceState copyWith({
    List<LedgerModelDrop>? customers,
    LedgerModelDrop? selectedCustomer,
    bool? cashSaleDefault,
    String? prefix,
    String? saleInvoiceNo,
    DateTime? saleInvoiceDate,
    String? transPlaceOfSupply,
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
    String? transType,
    String? transNo,
    String? transId,
  }) {
    return SaleInvoiceState(
      customers: customers ?? this.customers,
      selectedCustomer: selectedCustomer ?? this.selectedCustomer,
      cashSaleDefault: cashSaleDefault ?? this.cashSaleDefault,
      prefix: prefix ?? this.prefix,
      saleInvoiceNo: saleInvoiceNo ?? this.saleInvoiceNo,
      saleInvoiceDate: saleInvoiceDate ?? this.saleInvoiceDate,
      transPlaceOfSupply: transPlaceOfSupply ?? this.transPlaceOfSupply,
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
      transType: transType ?? this.transType,
      transNo: transNo ?? this.transNo,
      transId: transId ?? this.transId,
    );
  }
}

/// ------------------- SAVE EVENT (UI) -------------------
class SaleInvoiceSaveWithUIData extends SaleInvoiceEvent {
  final String customerName;
  final String? updateId;
  final String mobile;
  final String billingAddress;
  final String shippingAddress;
  final String stateName; // ✅ ADD
  final List<String> notes;
  final List<String> terms;
  final Uint8List? signatureImage; // NEW
  final bool printAfterSave;

  SaleInvoiceSaveWithUIData({
    required this.customerName,
    required this.mobile,
    required this.billingAddress,
    required this.shippingAddress,
    required this.stateName, // ✅,
    required this.notes,
    required this.printAfterSave,
    required this.terms,
    this.updateId,
    this.signatureImage,
  });
}

final GlobalKey<NavigatorState> saleInvoiceNavigatorKey =
    GlobalKey<NavigatorState>();

/// ------------------- BLOC -------------------
class SaleInvoiceBloc extends Bloc<SaleInvoiceEvent, SaleInvoiceState> {
  final GLobalRepository repo;
  SaleInvoiceBloc({required this.repo}) : super(SaleInvoiceState()) {
    on<SaleInvoiceLoadInit>((event, emit) async {
      await _onLoad(event, emit);

      if (event.existing != null) {
        emit(_prefillSaleInvoice(event.existing!, state));
        add(SaleInvoiceCalculate());
      }
    });
    on<SaleInvoiceSelectCustomer>(_onSelectCustomer);
    on<SaleInvoiceToggleCashSale>(_onToggleCashSale);
    on<SaleInvoiceAddRow>(_onAddRow);
    on<SaleInvoiceRemoveRow>(_onRemoveRow);
    on<SaleInvoiceUpdateRow>(_onUpdateRow);
    on<SaleInvoiceSelectCatalogForRow>(_onSelectCatalogForRow);
    on<SaleInvoiceSelectVariantForRow>(_onSelectVariantForRow);
    on<SaleInvoiceToggleUnitForRow>(_onToggleUnitForRow);
    on<SaleInvoiceSaveWithUIData>(_onSaveWithUIData);
    on<SaleInvoiceApplyHsnToRow>(_onApplyHsnToRow);
    on<SaleInvoiceAddCharge>(_onAddCharge);
    on<SaleInvoiceRemoveCharge>(_onRemoveCharge);
    on<SaleInvoiceUpdateCharge>(_onUpdateCharge);
    on<SaleInvoiceAddDiscount>(_onAddDiscount);
    on<SaleInvoiceRemoveDiscount>(_onRemoveDiscount);

    // misc
    on<SaleInvoiceAddMiscCharge>(_onAddMiscCharge);
    on<SaleInvoiceRemoveMiscCharge>(_onRemoveMiscCharge);
    on<SaleInvoiceUpdateMiscCharge>(_onUpdateMiscCharge);

    on<SaleInvoiceToggleRoundOff>(_onToggleRoundOff);
    on<SaleInvoiceCalculate>(_onCalculate);

    // ----- transaction related handlers -----
    on<SaleInvoiceSetTransType>((e, emit) {
      emit(state.copyWith(transType: e.type));
    });

    on<SaleInvoiceSetTransNo>((e, emit) {
      emit(state.copyWith(transNo: e.number));
    });

    on<SaleInvoiceSearchTransaction>(_onSearchTransaction);
    on<SaleInvoiceSavePayment>(_onSaveRecieptVoucher);
  }

  Future<void> _onLoad(
    SaleInvoiceLoadInit e,
    Emitter<SaleInvoiceState> emit,
  ) async {
    try {
      final customers = await repo.fetchLedger(true);
      final saleInvoiceNo = await repo.fetchSaleInvoiceNo();
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
          saleInvoiceNo: saleInvoiceNo,
          catalogue: catalogue,
          hsnMaster: hsnList,
          miscMasterList: miscMaster,
          // ensure UI has at least one empty row to start
          rows: [GlobalItemRow(localId: UniqueKey().toString())],
        ),
      );

      add(SaleInvoiceCalculate());
    } catch (err) {}
  }

  void _onSelectCustomer(
    SaleInvoiceSelectCustomer e,
    Emitter<SaleInvoiceState> emit,
  ) => emit(state.copyWith(selectedCustomer: e.c));
  void _onToggleCashSale(
    SaleInvoiceToggleCashSale e,
    Emitter<SaleInvoiceState> emit,
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

  void _onAddRow(SaleInvoiceAddRow e, Emitter<SaleInvoiceState> emit) {
    emit(
      state.copyWith(
        rows: [
          ...state.rows,
          GlobalItemRow(localId: UniqueKey().toString()),
        ],
      ),
    );
  }

  void _onRemoveRow(SaleInvoiceRemoveRow e, Emitter<SaleInvoiceState> emit) {
    emit(
      state.copyWith(rows: state.rows.where((r) => r.localId != e.id).toList()),
    );
    add(SaleInvoiceCalculate());
  }

  void _onUpdateRow(SaleInvoiceUpdateRow e, Emitter<SaleInvoiceState> emit) {
    emit(
      state.copyWith(
        rows: state.rows.map((r) {
          if (r.localId == e.row.localId) return e.row.recalc();
          return r;
        }).toList(),
      ),
    );
    add(SaleInvoiceCalculate());
  }

  void _onSelectCatalogForRow(
    SaleInvoiceSelectCatalogForRow e,
    Emitter<SaleInvoiceState> emit,
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
    add(SaleInvoiceCalculate());
  }

  void _onSelectVariantForRow(
    SaleInvoiceSelectVariantForRow e,
    Emitter<SaleInvoiceState> emit,
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
    add(SaleInvoiceCalculate());
  }

  void _onToggleUnitForRow(
    SaleInvoiceToggleUnitForRow e,
    Emitter<SaleInvoiceState> emit,
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
    add(SaleInvoiceCalculate());
  }

  void _onApplyHsnToRow(
    SaleInvoiceApplyHsnToRow e,
    Emitter<SaleInvoiceState> emit,
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
    add(SaleInvoiceCalculate());
  }

  void _onAddCharge(SaleInvoiceAddCharge e, Emitter<SaleInvoiceState> emit) {
    emit(state.copyWith(charges: [...state.charges, e.charge]));
    add(SaleInvoiceCalculate());
  }

  void _onRemoveCharge(
    SaleInvoiceRemoveCharge e,
    Emitter<SaleInvoiceState> emit,
  ) {
    emit(
      state.copyWith(
        charges: state.charges.where((c) => c.id != e.id).toList(),
      ),
    );
    add(SaleInvoiceCalculate());
  }

  void _onUpdateCharge(
    SaleInvoiceUpdateCharge e,
    Emitter<SaleInvoiceState> emit,
  ) {
    emit(
      state.copyWith(
        charges: state.charges.map((c) {
          if (c.id == e.charge.id) return e.charge;
          return c;
        }).toList(),
      ),
    );
    add(SaleInvoiceCalculate());
  }

  void _onAddDiscount(
    SaleInvoiceAddDiscount e,
    Emitter<SaleInvoiceState> emit,
  ) {
    emit(state.copyWith(discounts: [...state.discounts, e.d]));
    add(SaleInvoiceCalculate());
  }

  void _onRemoveDiscount(
    SaleInvoiceRemoveDiscount e,
    Emitter<SaleInvoiceState> emit,
  ) {
    emit(
      state.copyWith(
        discounts: state.discounts.where((d) => d.id != e.id).toList(),
      ),
    );
    add(SaleInvoiceCalculate());
  }

  void _onToggleRoundOff(
    SaleInvoiceToggleRoundOff e,
    Emitter<SaleInvoiceState> emit,
  ) {
    emit(state.copyWith(autoRound: e.value));
    add(SaleInvoiceCalculate());
  }

  // ------------------- MISC CHARGE HANDLERS -------------------
  void _onAddMiscCharge(
    SaleInvoiceAddMiscCharge e,
    Emitter<SaleInvoiceState> emit,
  ) {
    // When adding from UI, user may select an item from master list or create custom.
    // We'll accept the provided GlobalMiscChargeEntry as-is (it should already include gst/ledger if selected)
    emit(state.copyWith(miscCharges: [...state.miscCharges, e.m]));
    add(SaleInvoiceCalculate());
  }

  void _onRemoveMiscCharge(
    SaleInvoiceRemoveMiscCharge e,
    Emitter<SaleInvoiceState> emit,
  ) {
    emit(
      state.copyWith(
        miscCharges: state.miscCharges.where((m) => m.id != e.id).toList(),
      ),
    );
    add(SaleInvoiceCalculate());
  }

  void _onUpdateMiscCharge(
    SaleInvoiceUpdateMiscCharge e,
    Emitter<SaleInvoiceState> emit,
  ) {
    emit(
      state.copyWith(
        miscCharges: state.miscCharges.map((m) {
          if (m.id == e.m.id) return e.m;
          return m;
        }).toList(),
      ),
    );
    add(SaleInvoiceCalculate());
  }

  // ------------------- CALCULATION -------------------
  void _onCalculate(SaleInvoiceCalculate e, Emitter<SaleInvoiceState> emit) {
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
    SaleInvoiceSearchTransaction e,
    Emitter<SaleInvoiceState> emit,
  ) async {
    try {
      final transNoInt = int.tryParse(state.transNo) ?? 0;
      if (transNoInt == 0) {
        showCustomSnackbarError(
          saleInvoiceNavigatorKey.currentContext!,
          "Enter a valid number",
        );
        return;
      }

      // call repo method provided by you
      final GlobalDataAll estimate = await repo.getTransByNumber(
        transNo: transNoInt,
        transType: state.transType,
      );

      // map estimate -> saleInvoice state (without touching prefix, saleInvoiceNo, saleInvoiceDate)
      final newState = _prefillSaleInvoiceFromTrans(estimate, state).copyWith(
        transId: estimate.id,
        transNo: state.transNo,
        transType: state.transType,
        transPlaceOfSupply: estimate.placeOFSupply,
      );

      emit(newState);
      add(SaleInvoiceCalculate());
      showCustomSnackbarSuccess(
        saleInvoiceNavigatorKey.currentContext!,
        "Transaction loaded",
      );
    } catch (err) {
      showCustomSnackbarError(
        saleInvoiceNavigatorKey.currentContext!,
        "Transaction not found",
      );
    }
  }

  Future<void> _onSaveRecieptVoucher(
    SaleInvoiceSavePayment e,
    Emitter<SaleInvoiceState> emit,
  ) async {
    final ctx = saleInvoiceNavigatorKey.currentContext!;
    final state = this.state;

    // ---------- VALIDATIONS ----------
    if (e.amount.trim().isEmpty || double.tryParse(e.amount) == null) return;
    if (double.parse(e.amount) <= 0) return;

    if (state.cashSaleDefault == false && state.selectedCustomer == null) {
      showCustomSnackbarError(ctx, "Select customer");
      return;
    }

    try {
      final body = {
        "licence_no": Preference.getint(PrefKeys.licenseNo),
        "branch_id": Preference.getString(PrefKeys.locationId),

        "ledger_id": e.ledger.id,
        "ledger_name": e.ledger.ledgerName,

        "customer_id": state.cashSaleDefault
            ? null
            : state.selectedCustomer!.id,
        "customer_name": state.cashSaleDefault
            ? "Cash"
            : state.selectedCustomer!.name,

        "amount": double.parse(e.amount),
        "invoice_no": state.saleInvoiceNo,

        "date":
            "${e.date.year}-${e.date.month.toString().padLeft(2, '0')}-${e.date.day.toString().padLeft(2, '0')}",

        "prefix": state.prefix,
        "vouncher_no": e.voucherNo,
        "type": "Sale Invoice",
      };

      final res = await ApiService.postData(
        "reciept",
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
    SaleInvoiceSaveWithUIData e,
    Emitter<SaleInvoiceState> emit,
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
        "no": int.tryParse(state.saleInvoiceNo),
        "invoice_date": DateFormat(
          'yyyy-MM-dd',
        ).format(state.saleInvoiceDate ?? DateTime.now()),
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

      // include trans fields only if present (from search)
      if (state.transId != null && state.transId!.isNotEmpty) {
        payload["trans_id"] = state.transId;
      }
      if (state.transNo.isNotEmpty) {
        payload["trans_no"] = int.tryParse(state.transNo) ?? state.transNo;
      }
      if (state.transType.isNotEmpty) {
        payload["trans_type"] = state.transType;
      }

      if (itemRows.isEmpty && serviceRows.isEmpty) {
        showCustomSnackbarError(
          saleInvoiceNavigatorKey.currentContext!,
          "Add atleast one item or service",
        );
        return;
      } else {
        final res = await repo.saveSaleInvoice(
          payload: payload,
          signatureFile: e.signatureImage,
          updateId: e.updateId,
        );

        if (res?['status'] == true) {
          final ctx = saleInvoiceNavigatorKey.currentContext!;
          showCustomSnackbarSuccess(
            saleInvoiceNavigatorKey.currentContext!,
            res?['message'] ?? "Saved",
          );
          if (e.printAfterSave) {
            final data = SaleInvoiceData.fromJson(res!['data']);

            final doc = data.toPrintModel(); // ✅ no dynamic

            final companyApi = await CompanyProfileAPi.getCompanyProfile();
            final company = CompanyPrintProfile.fromApi(companyApi["data"][0]);

            await PdfEngine.printPremiumInvoice(doc: doc, company: company);
          }
          Navigator.of(ctx).pop(true);
        } else {
          showCustomSnackbarError(
            saleInvoiceNavigatorKey.currentContext!,
            res?['message'] ?? "Save failed",
          );
        }
      }
    } catch (err) {
      showCustomSnackbarError(
        saleInvoiceNavigatorKey.currentContext!,
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

// ------------------ PREFILL FROM ESTIMATE (or similar transaction) ------------------
// This maps EstimateData -> SaleInvoiceState but intentionally DOES NOT
// overwrite prefix, saleInvoiceNo, saleInvoiceDate (per requirement).
SaleInvoiceState _prefillSaleInvoiceFromTrans(
  GlobalDataAll data,
  SaleInvoiceState s,
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
      state: data.placeOFSupply,
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
    final nameFromSaleInvoice = (m.name).trim().toLowerCase();
    if (nameFromSaleInvoice.isEmpty) continue;

    // try to find in misc master list safely
    MiscChargeModelList? match;
    try {
      match = s.miscMasterList.firstWhere(
        (mx) => (mx.name).trim().toLowerCase() == nameFromSaleInvoice,
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
      baseSalePrice: 0,
      gstRate: 0,
      gstIncluded: false,
      gstIncludedPurchase: false,
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
    // NOTE: Intentionally NOT overwriting prefix, saleInvoiceNo, saleInvoiceDate
    rows: rows,
    charges: mappedCharges,
    discounts: mappedDiscounts,
    miscCharges: mappedMisc,
    transPlaceOfSupply: data.placeOFSupply,
    subtotal: (data.subTotal).toDouble(),
    totalGst: (data.subGst).toDouble(),
    totalAmount: (data.totalAmount).toDouble(),
    autoRound: data.autoRound,
    cashSaleDefault: data.caseSale,
  );
}

// ------------------ PREFILL FROM EXISTING SALE INVOICE ------------------
// Map SaleInvoiceData -> SaleInvoiceState (used when editing an existing sale invoice)
SaleInvoiceState _prefillSaleInvoice(SaleInvoiceData data, SaleInvoiceState s) {
  // find customer from loaded list (or create fallback)
  final selectedCustomer = s.customers.firstWhere(
    (c) => c.id == data.customerId,
    orElse: () => LedgerModelDrop(
      id: data.customerId ?? "",
      name: data.customerName,
      mobile: data.mobile,
      billingAddress: data.address0,
      shippingAddress: data.address1,
      state: data.placeOfSupply,
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
    final nameFromSaleInvoice = (m.name).trim().toLowerCase();
    if (nameFromSaleInvoice.isEmpty) continue;

    // try to find in misc master list safely
    MiscChargeModelList? match;
    try {
      match = s.miscMasterList.firstWhere(
        (mx) => (mx.name).trim().toLowerCase() == nameFromSaleInvoice,
      );
    } catch (_) {
      match = null;
    }

    if (match == null) {
      // Option chosen: SKIP misc charge if master not found.
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
      gstIncludedPurchase: false,
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
    saleInvoiceNo: data.no.toString(),
    rows: rows,
    charges: mappedCharges,
    discounts: mappedDiscounts,
    miscCharges: mappedMisc,
    subtotal: (data.subTotal).toDouble(),
    totalGst: (data.subGst).toDouble(),
    totalAmount: (data.totalAmount).toDouble(),
    autoRound: data.autoRound,
    saleInvoiceDate: data.saleInvoiceDate,
    cashSaleDefault: data.caseSale,
  );
}
