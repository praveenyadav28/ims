import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:ims/model/ledger_model.dart';
import 'package:ims/ui/sales/data/global_repository.dart';
import 'package:ims/ui/sales/debit_note/widgets/item_model.dart';
import 'package:ims/ui/sales/models/common_data.dart';
import 'package:ims/ui/sales/models/debitnote_model.dart';
import 'package:ims/ui/sales/models/global_models.dart';
import 'package:ims/ui/master/misc/misc_charge_model.dart';
import 'package:ims/utils/api.dart';
import 'package:ims/utils/prefence.dart';
import 'package:ims/utils/snackbar.dart';
import 'package:intl/intl.dart';

/// ------------------- EVENTS -------------------
abstract class DebitNoteEvent {}

class DebitNoteLoadInit extends DebitNoteEvent {
  final DebitNoteData? existing;
  DebitNoteLoadInit({this.existing});
}

class DebitNoteSelectCustomer extends DebitNoteEvent {
  final LedgerModelDrop? c;
  DebitNoteSelectCustomer(this.c);
}

class DebitNoteToggleCashSale extends DebitNoteEvent {
  final bool enabled;
  DebitNoteToggleCashSale(this.enabled);
}

class DebitNoteAddRow extends DebitNoteEvent {}

class DebitNoteRemoveRow extends DebitNoteEvent {
  final String id;
  DebitNoteRemoveRow(this.id);
}

class DebitNoteUpdateRow extends DebitNoteEvent {
  final NoteModelItem row;
  DebitNoteUpdateRow(this.row);
}

class DebitNoteApplyHsnToRow extends DebitNoteEvent {
  final String rowId;
  final HsnModel hsn;
  DebitNoteApplyHsnToRow(this.rowId, this.hsn);
}

class DebitNoteAddCharge extends DebitNoteEvent {
  final AdditionalCharge charge;
  DebitNoteAddCharge(this.charge);
}

class DebitNoteRemoveCharge extends DebitNoteEvent {
  final String id;
  DebitNoteRemoveCharge(this.id);
}

class DebitNoteUpdateCharge extends DebitNoteEvent {
  final AdditionalCharge charge;
  DebitNoteUpdateCharge(this.charge);
}

class DebitNoteAddDiscount extends DebitNoteEvent {
  final DiscountLine d;
  DebitNoteAddDiscount(this.d);
}

class DebitNoteRemoveDiscount extends DebitNoteEvent {
  final String id;
  DebitNoteRemoveDiscount(this.id);
}

/// ---------- NEW: misc charges events ----------
class DebitNoteAddMiscCharge extends DebitNoteEvent {
  final GlobalMiscChargeEntry m;
  DebitNoteAddMiscCharge(this.m);
}

class DebitNoteRemoveMiscCharge extends DebitNoteEvent {
  final String id;
  DebitNoteRemoveMiscCharge(this.id);
}

class DebitNoteUpdateMiscCharge extends DebitNoteEvent {
  final GlobalMiscChargeEntry m;
  DebitNoteUpdateMiscCharge(this.m);
}

/// ----------------------------------------------
class DebitNoteCalculate extends DebitNoteEvent {}

class DebitNoteSave extends DebitNoteEvent {}

class DebitNoteToggleRoundOff extends DebitNoteEvent {
  final bool value;
  DebitNoteToggleRoundOff(this.value);
}

class DebitNoteSetTransNo extends DebitNoteEvent {
  final String number;
  DebitNoteSetTransNo(this.number);
}

class DebitNoteSearchTransaction extends DebitNoteEvent {}

class DebitNoteSavePayment extends DebitNoteEvent {
  final String amount;
  final String voucherNo;
  final LedgerListModel ledger;
  final DateTime date;

  DebitNoteSavePayment({
    required this.amount,
    required this.voucherNo,
    required this.ledger,
    required this.date,
  });
}

/// ------------------- STATE -------------------
class DebitNoteState {
  final List<LedgerModelDrop> customers;
  final LedgerModelDrop? selectedCustomer;
  final bool cashSaleDefault;
  final List<HsnModel> hsnMaster;
  final String prefix;
  final String debitNoteNo;
  final String? transPlaceOfSupply; // ✅ NEW
  final String transNo; // user input number as string
  final String? transId; // loaded transaction id (from backend) if any
  final DateTime? debitNoteDate;
  final DateTime? validityDate;
  final int validForDays;
  final List<NoteModelItem> rows;
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

  DebitNoteState({
    this.customers = const [],
    this.selectedCustomer,
    this.cashSaleDefault = false,
    this.prefix = '',
    this.debitNoteNo = '',
    this.transPlaceOfSupply,
    this.hsnMaster = const [],
    this.debitNoteDate,
    this.validityDate,
    this.validForDays = 0,
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

  DebitNoteState copyWith({
    List<LedgerModelDrop>? customers,
    LedgerModelDrop? selectedCustomer,
    bool? cashSaleDefault,
    String? prefix,
    String? debitNoteNo,
    String? transPlaceOfSupply, // ✅ NEW
    DateTime? debitNoteDate,
    List<HsnModel>? hsnMaster,
    DateTime? validityDate,
    int? validForDays,
    List<NoteModelItem>? rows,
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
    return DebitNoteState(
      customers: customers ?? this.customers,
      selectedCustomer: selectedCustomer ?? this.selectedCustomer,
      cashSaleDefault: cashSaleDefault ?? this.cashSaleDefault,
      prefix: prefix ?? this.prefix,
      debitNoteNo: debitNoteNo ?? this.debitNoteNo,
      transPlaceOfSupply: transPlaceOfSupply ?? this.transPlaceOfSupply,
      debitNoteDate: debitNoteDate ?? this.debitNoteDate,
      hsnMaster: hsnMaster ?? this.hsnMaster,
      validityDate: validityDate ?? this.validityDate,
      validForDays: validForDays ?? this.validForDays,
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
class DebitNoteSaveWithUIData extends DebitNoteEvent {
  final String customerName;
  final String? updateId;
  final String mobile;
  final String billingAddress;
  final String shippingAddress;
  final String stateName; // ✅ ADD
  final List<String> notes;
  final List<String> terms;
  final File? signatureImage; // NEW

  DebitNoteSaveWithUIData({
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

final GlobalKey<NavigatorState> debitNoteNavigatorKey =
    GlobalKey<NavigatorState>();

/// ------------------- BLOC -------------------
class DebitNoteBloc extends Bloc<DebitNoteEvent, DebitNoteState> {
  final GLobalRepository repo;
  DebitNoteBloc({required this.repo}) : super(DebitNoteState()) {
    on<DebitNoteLoadInit>((event, emit) async {
      await _onLoad(event, emit);

      if (event.existing != null) {
        emit(_prefillDebitNote(event.existing!, state));
        add(DebitNoteCalculate());
      }
    });
    on<DebitNoteSelectCustomer>(_onSelectCustomer);
    on<DebitNoteToggleCashSale>(_onToggleCashSale);
    on<DebitNoteAddRow>(_onAddRow);
    on<DebitNoteRemoveRow>(_onRemoveRow);
    on<DebitNoteUpdateRow>(_onUpdateRow);
    on<DebitNoteSaveWithUIData>(_onSaveWithUIData);
    on<DebitNoteApplyHsnToRow>(_onApplyHsnToRow);
    on<DebitNoteAddCharge>(_onAddCharge);
    on<DebitNoteRemoveCharge>(_onRemoveCharge);
    on<DebitNoteUpdateCharge>(_onUpdateCharge);
    on<DebitNoteAddDiscount>(_onAddDiscount);
    on<DebitNoteRemoveDiscount>(_onRemoveDiscount);

    // misc
    on<DebitNoteAddMiscCharge>(_onAddMiscCharge);
    on<DebitNoteRemoveMiscCharge>(_onRemoveMiscCharge);
    on<DebitNoteUpdateMiscCharge>(_onUpdateMiscCharge);

    on<DebitNoteToggleRoundOff>(_onToggleRoundOff);
    on<DebitNoteCalculate>(_onCalculate);

    on<DebitNoteSetTransNo>((e, emit) {
      emit(state.copyWith(transNo: e.number));
    });

    on<DebitNoteSearchTransaction>(_onSearchTransaction);
    on<DebitNoteSavePayment>(_onSavePaymentVoucher);
  }

  Future<void> _onLoad(
    DebitNoteLoadInit e,
    Emitter<DebitNoteState> emit,
  ) async {
    try {
      final customers = await repo.fetchLedger(true);
      final debitNoteNo = await repo.fetchDebitNoteNo();
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
          debitNoteNo: debitNoteNo,
          hsnMaster: hsnList,
          miscMasterList: miscMaster,
          // ensure UI has at least one empty row to start
          rows: [NoteModelItem(localId: UniqueKey().toString())],
        ),
      );

      add(DebitNoteCalculate());
    } catch (err) {
      print("❌ Load error: $err");
    }
  }

  void _onSelectCustomer(
    DebitNoteSelectCustomer e,
    Emitter<DebitNoteState> emit,
  ) => emit(state.copyWith(selectedCustomer: e.c));
  void _onToggleCashSale(
    DebitNoteToggleCashSale e,
    Emitter<DebitNoteState> emit,
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

  void _onAddRow(DebitNoteAddRow e, Emitter<DebitNoteState> emit) {
    emit(
      state.copyWith(
        rows: [
          ...state.rows,
          NoteModelItem(localId: UniqueKey().toString()),
        ],
      ),
    );
  }

  void _onRemoveRow(DebitNoteRemoveRow e, Emitter<DebitNoteState> emit) {
    emit(
      state.copyWith(rows: state.rows.where((r) => r.localId != e.id).toList()),
    );
    add(DebitNoteCalculate());
  }

  void _onUpdateRow(DebitNoteUpdateRow e, Emitter<DebitNoteState> emit) {
    emit(
      state.copyWith(
        rows: state.rows.map((r) {
          if (r.localId == e.row.localId) return e.row.recalc();
          return r;
        }).toList(),
      ),
    );
    add(DebitNoteCalculate());
  }

  void _onApplyHsnToRow(
    DebitNoteApplyHsnToRow e,
    Emitter<DebitNoteState> emit,
  ) {
    emit(
      state.copyWith(
        rows: state.rows.map((r) {
          if (r.localId == e.rowId) {
            return r
                .copyWith(
                  hsnCode: e.hsn.code,
                  taxPercent: e.hsn.igst,
                  gstInclusive: false,
                )
                .recalc();
          }
          return r;
        }).toList(),
      ),
    );
    add(DebitNoteCalculate());
  }

  void _onAddCharge(DebitNoteAddCharge e, Emitter<DebitNoteState> emit) {
    emit(state.copyWith(charges: [...state.charges, e.charge]));
    add(DebitNoteCalculate());
  }

  void _onRemoveCharge(DebitNoteRemoveCharge e, Emitter<DebitNoteState> emit) {
    emit(
      state.copyWith(
        charges: state.charges.where((c) => c.id != e.id).toList(),
      ),
    );
    add(DebitNoteCalculate());
  }

  void _onUpdateCharge(DebitNoteUpdateCharge e, Emitter<DebitNoteState> emit) {
    emit(
      state.copyWith(
        charges: state.charges.map((c) {
          if (c.id == e.charge.id) return e.charge;
          return c;
        }).toList(),
      ),
    );
    add(DebitNoteCalculate());
  }

  void _onAddDiscount(DebitNoteAddDiscount e, Emitter<DebitNoteState> emit) {
    emit(state.copyWith(discounts: [...state.discounts, e.d]));
    add(DebitNoteCalculate());
  }

  void _onRemoveDiscount(
    DebitNoteRemoveDiscount e,
    Emitter<DebitNoteState> emit,
  ) {
    emit(
      state.copyWith(
        discounts: state.discounts.where((d) => d.id != e.id).toList(),
      ),
    );
    add(DebitNoteCalculate());
  }

  void _onToggleRoundOff(
    DebitNoteToggleRoundOff e,
    Emitter<DebitNoteState> emit,
  ) {
    emit(state.copyWith(autoRound: e.value));
    add(DebitNoteCalculate());
  }

  // ------------------- MISC CHARGE HANDLERS -------------------
  void _onAddMiscCharge(
    DebitNoteAddMiscCharge e,
    Emitter<DebitNoteState> emit,
  ) {
    // When adding from UI, user may select an item from master list or create custom.
    // We'll accept the provided GlobalMiscChargeEntry as-is (it should already include gst/ledger if selected)
    emit(state.copyWith(miscCharges: [...state.miscCharges, e.m]));
    add(DebitNoteCalculate());
  }

  void _onRemoveMiscCharge(
    DebitNoteRemoveMiscCharge e,
    Emitter<DebitNoteState> emit,
  ) {
    emit(
      state.copyWith(
        miscCharges: state.miscCharges.where((m) => m.id != e.id).toList(),
      ),
    );
    add(DebitNoteCalculate());
  }

  void _onUpdateMiscCharge(
    DebitNoteUpdateMiscCharge e,
    Emitter<DebitNoteState> emit,
  ) {
    emit(
      state.copyWith(
        miscCharges: state.miscCharges.map((m) {
          if (m.id == e.m.id) return e.m;
          return m;
        }).toList(),
      ),
    );
    add(DebitNoteCalculate());
  }

  // ------------------- CALCULATION -------------------
  void _onCalculate(DebitNoteCalculate e, Emitter<DebitNoteState> emit) {
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
    DebitNoteSearchTransaction e,
    Emitter<DebitNoteState> emit,
  ) async {
    try {
      final transNoInt = int.tryParse(state.transNo) ?? 0;
      if (transNoInt == 0) {
        showCustomSnackbarError(
          debitNoteNavigatorKey.currentContext!,
          "Enter a valid number",
        );
        return;
      }

      // call repo method provided by you
      final GlobalDataAll estimate = await repo.getTransByNumber(
        transNo: transNoInt,
        transType: 'Invoice',
      );

      // map estimate -> DebitNote state (without touching prefix, DebitNoteNo, DebitNoteDate)
      final newState = _prefillDebitNoteFromTrans(estimate, state).copyWith(
        transId: estimate.id,
        transNo: state.transNo,
        transPlaceOfSupply: estimate.placeOFSupply,
      );

      emit(newState);
      showCustomSnackbarSuccess(
        debitNoteNavigatorKey.currentContext!,
        "Transaction loaded",
      );
    } catch (err) {
      print("❌ transaction fetch error: $err");
      showCustomSnackbarError(
        debitNoteNavigatorKey.currentContext!,
        "Transaction not found",
      );
    }
  }

  Future<void> _onSavePaymentVoucher(
    DebitNoteSavePayment e,
    Emitter<DebitNoteState> emit,
  ) async {
    final ctx = debitNoteNavigatorKey.currentContext!;
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
        "invoice_no": state.debitNoteNo,

        "date":
            "${e.date.year}-${e.date.month.toString().padLeft(2, '0')}-${e.date.day.toString().padLeft(2, '0')}",

        "prefix": state.prefix,
        "vouncher_no": e.voucherNo,
        "type": "Debit Note",
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
    DebitNoteSaveWithUIData e,
    Emitter<DebitNoteState> emit,
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

      for (final r in state.rows) {
        if (r.itemName.isEmpty) continue;

        itemRows.add({
          "item_name": r.itemName,
          "price": r.price,
          "hsn_code": r.hsnCode,
          "gst_tax_rate": r.taxPercent,
          "qty": r.qty,
          "amount": r.gross,
          "discount": r.discountPercent,
          "in_ex": r.gstInclusive,
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
        "customer_id": customerId,
        "customer_name": customerName,
        if (mobile.isNotEmpty) "mobile": mobile,
        "address_0": billing,
        "address_1": shipping,
        "place_of_supply": e.stateName,
        "prefix": state.prefix,
        "no": int.tryParse(state.debitNoteNo),
        "debitnote_date": DateFormat(
          'yyyy-MM-dd',
        ).format(state.debitNoteDate ?? DateTime.now()),
        "case_sale": isCash,
        // "invoice_no": 1,
        // "invoice_id": "6937ccd3e69951d95725956a",
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
        payload["invoice_id"] = state.transId;
      }
      if (state.transNo.isNotEmpty) {
        payload["invoice_no"] = int.tryParse(state.transNo) ?? state.transNo;
      }
      final res = await repo.saveDebitNote(
        payload: payload,
        signatureFile: e.signatureImage != null
            ? XFile(e.signatureImage!.path)
            : null,
        updateId: e.updateId,
      );

      if (res?['status'] == true) {
        final ctx = debitNoteNavigatorKey.currentContext!;
        showCustomSnackbarSuccess(
          debitNoteNavigatorKey.currentContext!,
          res?['message'] ?? "Saved",
        );
        Navigator.of(ctx).pop(true);
      } else {
        showCustomSnackbarError(
          debitNoteNavigatorKey.currentContext!,
          res?['message'] ?? "Save failed",
        );
      }
    } catch (err) {
      showCustomSnackbarError(
        debitNoteNavigatorKey.currentContext!,
        err.toString(),
      );
    }
  }
}

/// ------------------- IMMUTABLE CALC EXT -------------------
extension NoteItemRowCalc on NoteModelItem {
  NoteModelItem recalc() {
    final base = qty;
    final discountValue = base * (discountPercent / 100);
    final afterDiscount = base - discountValue;

    if (gstInclusive) {
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

DebitNoteState _prefillDebitNoteFromTrans(
  GlobalDataAll data,
  DebitNoteState s,
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

  return s.copyWith(
    customers: s.customers,
    selectedCustomer: data.caseSale ? null : selectedCustomer,
    cashSaleDefault: data.caseSale,
  );
}

DebitNoteState _prefillDebitNote(DebitNoteData data, DebitNoteState s) {
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
    final nameFromDebitNote = (m.name).trim().toLowerCase();
    if (nameFromDebitNote.isEmpty) continue;

    // try to find in misc master list safely
    MiscChargeModelList? match;
    try {
      match = s.miscMasterList.firstWhere(
        (mx) => (mx.name).trim().toLowerCase() == nameFromDebitNote,
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

  final itemRows = (data.itemDetails).map((i) {
    return NoteModelItem(
      localId: UniqueKey().toString(),
      itemName: i.name,
      qty: (i.qty).toInt(),
      price: (i.price).toDouble(),
      discountPercent: (i.discount).toDouble(),
      hsnCode: (i.hsn),
      taxPercent: (i.gstRate).toDouble(),
      gstInclusive: i.inclusive,
    ).recalc();
  }).toList();

  final rows = <NoteModelItem>[
    ...itemRows,
    if (itemRows.isEmpty) NoteModelItem(localId: UniqueKey().toString()),
  ];

  return s.copyWith(
    customers: s.customers,
    selectedCustomer: data.caseSale ? null : selectedCustomer,
    prefix: data.prefix,
    debitNoteNo: data.no.toString(),
    rows: rows,
    charges: mappedCharges,
    discounts: mappedDiscounts,
    miscCharges: mappedMisc,
    subtotal: (data.subTotal).toDouble(),
    totalGst: (data.subGst).toDouble(),
    totalAmount: (data.totalAmount).toDouble(),
    autoRound: data.autoRound,
    debitNoteDate: data.debitNoteDate,
    cashSaleDefault: data.caseSale,
  );
}
