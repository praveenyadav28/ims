import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:ims/ui/sales/data/global_repository.dart';
import 'package:ims/ui/sales/debit_note/widgets/item_model.dart';
import 'package:ims/ui/sales/models/common_data.dart';
import 'package:ims/ui/sales/models/credit_note_data.dart';
import 'package:ims/ui/sales/models/global_models.dart';
import 'package:ims/ui/master/misc/misc_charge_model.dart';
import 'package:ims/utils/prefence.dart';
import 'package:ims/utils/snackbar.dart';
import 'package:intl/intl.dart';

/// ------------------- EVENTS -------------------
abstract class CreditNoteEvent {}

class CreditNoteLoadInit extends CreditNoteEvent {
  final CreditNoteData? existing;
  CreditNoteLoadInit({this.existing});
}

class CreditNoteSelectLedger extends CreditNoteEvent {
  final LedgerModelDrop? c;
  CreditNoteSelectLedger(this.c);
}

class CreditNoteToggleCashSale extends CreditNoteEvent {
  final bool enabled;
  CreditNoteToggleCashSale(this.enabled);
}

class CreditNoteAddRow extends CreditNoteEvent {}

class CreditNoteRemoveRow extends CreditNoteEvent {
  final String id;
  CreditNoteRemoveRow(this.id);
}

class CreditNoteUpdateRow extends CreditNoteEvent {
  final NoteModelItem row;
  CreditNoteUpdateRow(this.row);
}

class CreditNoteApplyHsnToRow extends CreditNoteEvent {
  final String rowId;
  final HsnModel hsn;
  CreditNoteApplyHsnToRow(this.rowId, this.hsn);
}

class CreditNoteAddCharge extends CreditNoteEvent {
  final AdditionalCharge charge;
  CreditNoteAddCharge(this.charge);
}

class CreditNoteRemoveCharge extends CreditNoteEvent {
  final String id;
  CreditNoteRemoveCharge(this.id);
}

class CreditNoteUpdateCharge extends CreditNoteEvent {
  final AdditionalCharge charge;
  CreditNoteUpdateCharge(this.charge);
}

class CreditNoteAddDiscount extends CreditNoteEvent {
  final DiscountLine d;
  CreditNoteAddDiscount(this.d);
}

class CreditNoteRemoveDiscount extends CreditNoteEvent {
  final String id;
  CreditNoteRemoveDiscount(this.id);
}

/// ---------- NEW: misc charges events ----------
class CreditNoteAddMiscCharge extends CreditNoteEvent {
  final GlobalMiscChargeEntry m;
  CreditNoteAddMiscCharge(this.m);
}

class CreditNoteRemoveMiscCharge extends CreditNoteEvent {
  final String id;
  CreditNoteRemoveMiscCharge(this.id);
}

class CreditNoteUpdateMiscCharge extends CreditNoteEvent {
  final GlobalMiscChargeEntry m;
  CreditNoteUpdateMiscCharge(this.m);
}

/// ----------------------------------------------
class CreditNoteCalculate extends CreditNoteEvent {}

class CreditNoteSave extends CreditNoteEvent {}

class CreditNoteToggleRoundOff extends CreditNoteEvent {
  final bool value;
  CreditNoteToggleRoundOff(this.value);
}

class CreditNoteSetTransNo extends CreditNoteEvent {
  final String number;
  CreditNoteSetTransNo(this.number);
}

class CreditNoteSearchTransaction extends CreditNoteEvent {}

/// ------------------- STATE -------------------
class CreditNoteState {
  final List<LedgerModelDrop> ledgers;
  final LedgerModelDrop? selectedLedger;
  final bool cashSaleDefault;
  final List<HsnModel> hsnMaster;
  final String prefix;
  final String creditNoteNo;
  final String? transPlaceOfSupply; // ✅ NEW

  final DateTime? creditNoteDate;
  final String transNo; // user input number as string
  final String? transId; // loaded transaction id (from backend) if any
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

  CreditNoteState({
    this.ledgers = const [],
    this.selectedLedger,
    this.cashSaleDefault = false,
    this.prefix = "",
    this.creditNoteNo = '',
    this.transPlaceOfSupply,
    this.hsnMaster = const [],
    this.creditNoteDate,
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

  CreditNoteState copyWith({
    List<LedgerModelDrop>? ledgers,
    LedgerModelDrop? selectedLedger,
    bool? cashSaleDefault,
    String? prefix,
    String? creditNoteNo,
    String? transPlaceOfSupply,
    DateTime? creditNoteDate,
    List<HsnModel>? hsnMaster,
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
    return CreditNoteState(
      ledgers: ledgers ?? this.ledgers,
      selectedLedger: selectedLedger ?? this.selectedLedger,
      cashSaleDefault: cashSaleDefault ?? this.cashSaleDefault,
      prefix: prefix ?? this.prefix,
      creditNoteNo: creditNoteNo ?? this.creditNoteNo,
      transPlaceOfSupply: transPlaceOfSupply ?? this.transPlaceOfSupply,
      creditNoteDate: creditNoteDate ?? this.creditNoteDate,
      hsnMaster: hsnMaster ?? this.hsnMaster,
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
class CreditNoteSaveWithUIData extends CreditNoteEvent {
  final String ledgerName;
  final String? updateId;
  final String mobile;
  final String billingAddress;
  final String shippingAddress;
  final List<String> notes;
  final List<String> terms;
  final File? signatureImage; // NEW

  CreditNoteSaveWithUIData({
    required this.ledgerName,
    required this.mobile,
    required this.billingAddress,
    required this.shippingAddress,
    required this.notes,
    required this.terms,
    this.updateId,
    this.signatureImage,
  });
}

final GlobalKey<NavigatorState> creditNoteNavigatorKey =
    GlobalKey<NavigatorState>();

/// ------------------- BLOC -------------------
class CreditNoteBloc extends Bloc<CreditNoteEvent, CreditNoteState> {
  final GLobalRepository repo;
  CreditNoteBloc({required this.repo}) : super(CreditNoteState()) {
    on<CreditNoteLoadInit>((event, emit) async {
      await _onLoad(event, emit);

      if (event.existing != null) {
        emit(_prefillCreditNote(event.existing!, state));
        add(CreditNoteCalculate());
      }
    });
    on<CreditNoteSelectLedger>(_onSelectLedger);
    on<CreditNoteToggleCashSale>(_onToggleCashSale);
    on<CreditNoteAddRow>(_onAddRow);
    on<CreditNoteRemoveRow>(_onRemoveRow);
    on<CreditNoteUpdateRow>(_onUpdateRow);
    on<CreditNoteSaveWithUIData>(_onSaveWithUIData);
    on<CreditNoteApplyHsnToRow>(_onApplyHsnToRow);
    on<CreditNoteAddCharge>(_onAddCharge);
    on<CreditNoteRemoveCharge>(_onRemoveCharge);
    on<CreditNoteUpdateCharge>(_onUpdateCharge);
    on<CreditNoteAddDiscount>(_onAddDiscount);
    on<CreditNoteRemoveDiscount>(_onRemoveDiscount);

    // misc
    on<CreditNoteAddMiscCharge>(_onAddMiscCharge);
    on<CreditNoteRemoveMiscCharge>(_onRemoveMiscCharge);
    on<CreditNoteUpdateMiscCharge>(_onUpdateMiscCharge);

    on<CreditNoteToggleRoundOff>(_onToggleRoundOff);
    on<CreditNoteCalculate>(_onCalculate);

    on<CreditNoteSetTransNo>((e, emit) {
      emit(state.copyWith(transNo: e.number));
    });

    on<CreditNoteSearchTransaction>(_onSearchTransaction);
  }

  Future<void> _onLoad(
    CreditNoteLoadInit e,
    Emitter<CreditNoteState> emit,
  ) async {
    try {
      final ledgers = await repo.fetchLedger(false);
      final creditNoteNo = await repo.fetchCreditNoteNo();
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
          ledgers: ledgers,
          creditNoteNo: creditNoteNo,
          hsnMaster: hsnList,
          miscMasterList: miscMaster,
          // ensure UI has at least one empty row to start
          rows: [NoteModelItem(localId: UniqueKey().toString())],
        ),
      );

      add(CreditNoteCalculate());
    } catch (err) {
      print("❌ Load error: $err");
    }
  }

  void _onSelectLedger(
    CreditNoteSelectLedger e,
    Emitter<CreditNoteState> emit,
  ) => emit(state.copyWith(selectedLedger: e.c));
  void _onToggleCashSale(
    CreditNoteToggleCashSale e,
    Emitter<CreditNoteState> emit,
  ) {
    if (e.enabled) {
      emit(
        state.copyWith(
          cashSaleDefault: true,
          selectedLedger: null, // MUST CLEAR
        ),
      );
    } else {
      emit(
        state.copyWith(
          cashSaleDefault: false,
          // Do NOT set selectedLedger here; UI will set when user picks
        ),
      );
    }
  }

  void _onAddRow(CreditNoteAddRow e, Emitter<CreditNoteState> emit) {
    emit(
      state.copyWith(
        rows: [
          ...state.rows,
          NoteModelItem(localId: UniqueKey().toString()),
        ],
      ),
    );
  }

  void _onRemoveRow(CreditNoteRemoveRow e, Emitter<CreditNoteState> emit) {
    emit(
      state.copyWith(rows: state.rows.where((r) => r.localId != e.id).toList()),
    );
    add(CreditNoteCalculate());
  }

  void _onUpdateRow(CreditNoteUpdateRow e, Emitter<CreditNoteState> emit) {
    emit(
      state.copyWith(
        rows: state.rows.map((r) {
          if (r.localId == e.row.localId) return e.row.recalc();
          return r;
        }).toList(),
      ),
    );
    add(CreditNoteCalculate());
  }

  void _onApplyHsnToRow(
    CreditNoteApplyHsnToRow e,
    Emitter<CreditNoteState> emit,
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
    add(CreditNoteCalculate());
  }

  void _onAddCharge(CreditNoteAddCharge e, Emitter<CreditNoteState> emit) {
    emit(state.copyWith(charges: [...state.charges, e.charge]));
    add(CreditNoteCalculate());
  }

  void _onRemoveCharge(
    CreditNoteRemoveCharge e,
    Emitter<CreditNoteState> emit,
  ) {
    emit(
      state.copyWith(
        charges: state.charges.where((c) => c.id != e.id).toList(),
      ),
    );
    add(CreditNoteCalculate());
  }

  void _onUpdateCharge(
    CreditNoteUpdateCharge e,
    Emitter<CreditNoteState> emit,
  ) {
    emit(
      state.copyWith(
        charges: state.charges.map((c) {
          if (c.id == e.charge.id) return e.charge;
          return c;
        }).toList(),
      ),
    );
    add(CreditNoteCalculate());
  }

  void _onAddDiscount(CreditNoteAddDiscount e, Emitter<CreditNoteState> emit) {
    emit(state.copyWith(discounts: [...state.discounts, e.d]));
    add(CreditNoteCalculate());
  }

  void _onRemoveDiscount(
    CreditNoteRemoveDiscount e,
    Emitter<CreditNoteState> emit,
  ) {
    emit(
      state.copyWith(
        discounts: state.discounts.where((d) => d.id != e.id).toList(),
      ),
    );
    add(CreditNoteCalculate());
  }

  void _onToggleRoundOff(
    CreditNoteToggleRoundOff e,
    Emitter<CreditNoteState> emit,
  ) {
    emit(state.copyWith(autoRound: e.value));
    add(CreditNoteCalculate());
  }

  // ------------------- MISC CHARGE HANDLERS -------------------
  void _onAddMiscCharge(
    CreditNoteAddMiscCharge e,
    Emitter<CreditNoteState> emit,
  ) {
    // When adding from UI, user may select an item from master list or create custom.
    // We'll accept the provided MiscChargeEntry as-is (it should already include gst/ledger if selected)
    emit(state.copyWith(miscCharges: [...state.miscCharges, e.m]));
    add(CreditNoteCalculate());
  }

  void _onRemoveMiscCharge(
    CreditNoteRemoveMiscCharge e,
    Emitter<CreditNoteState> emit,
  ) {
    emit(
      state.copyWith(
        miscCharges: state.miscCharges.where((m) => m.id != e.id).toList(),
      ),
    );
    add(CreditNoteCalculate());
  }

  void _onUpdateMiscCharge(
    CreditNoteUpdateMiscCharge e,
    Emitter<CreditNoteState> emit,
  ) {
    emit(
      state.copyWith(
        miscCharges: state.miscCharges.map((m) {
          if (m.id == e.m.id) return e.m;
          return m;
        }).toList(),
      ),
    );
    add(CreditNoteCalculate());
  }

  // ------------------- CALCULATION -------------------
  void _onCalculate(CreditNoteCalculate e, Emitter<CreditNoteState> emit) {
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
    CreditNoteSearchTransaction e,
    Emitter<CreditNoteState> emit,
  ) async {
    try {
      final transNoInt = int.tryParse(state.transNo) ?? 0;
      if (transNoInt == 0) {
        showCustomSnackbarError(
          creditNoteNavigatorKey.currentContext!,
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

      // map estimate -> CreditNote state (without touching prefix, CreditNoteNo, CreditNoteDate)
      final newState = _prefillCreditNoteFromTrans(estimate, state).copyWith(
        transId: estimate.id,
        transNo: state.transNo,
        transPlaceOfSupply: estimate.placeOfSupply,
      );

      emit(newState);
      add(CreditNoteCalculate());
      showCustomSnackbarSuccess(
        creditNoteNavigatorKey.currentContext!,
        "Transaction loaded",
      );
    } catch (err) {
      print("❌ transaction fetch error: $err");
      showCustomSnackbarError(
        creditNoteNavigatorKey.currentContext!,
        "Transaction not found",
      );
    }
  }

  // ------------------- SAVE -------------------
  Future<void> _onSaveWithUIData(
    CreditNoteSaveWithUIData e,
    Emitter<CreditNoteState> emit,
  ) async {
    try {
      final state = this.state;

      final bool isCash = state.cashSaleDefault;

      // ---------------- Ledger ----------------
      final ledgerId = isCash ? null : state.selectedLedger?.id;

      final ledgerName = isCash
          ? e.ledgerName
          : state.selectedLedger?.name ?? "";

      final mobile = isCash ? e.mobile : state.selectedLedger?.mobile ?? "";

      // Address — prefer selectedLedger's addresses (autofill). If cash sale use provided fields.
      final billing = isCash
          ? e.billingAddress
          : state.selectedLedger?.billingAddress ?? e.billingAddress;
      final shipping = isCash
          ? e.shippingAddress
          : state.selectedLedger?.shippingAddress ?? e.shippingAddress;

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
        "supplier_id": ledgerId,
        "supplier_name": ledgerName,
        if (mobile.isNotEmpty) "mobile": mobile,
        "address_0": billing,
        "address_1": shipping,
        "prefix": state.prefix,
        "no": int.tryParse(state.creditNoteNo),
        "purchasenote_date": DateFormat(
          'yyyy-MM-dd',
        ).format(state.creditNoteDate ?? DateTime.now()),
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
          creditNoteNavigatorKey.currentContext!,
          "Add atleast one note",
        );
        return;
      } else {
        final res = await repo.saveCreditNote(
          payload: payload,
          signatureFile: e.signatureImage != null
              ? XFile(e.signatureImage!.path)
              : null,
          updateId: e.updateId,
        );

        if (res?['status'] == true) {
          showCustomSnackbarSuccess(
            creditNoteNavigatorKey.currentContext!,
            res?['message'] ?? "Saved",
          );
          final ctx = creditNoteNavigatorKey.currentContext!;
          Navigator.of(ctx).pop(true);
        } else {
          showCustomSnackbarError(
            creditNoteNavigatorKey.currentContext!,
            res?['message'] ?? "Save failed",
          );
        }
      }
    } catch (err) {
      showCustomSnackbarError(
        creditNoteNavigatorKey.currentContext!,
        err.toString(),
      );
    }
  }
}

/// ------------------- IMMUTABLE CALC EXT -------------------
extension GlobalItemRowCalc on NoteModelItem {
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

CreditNoteState _prefillCreditNoteFromTrans(
  GlobalDataAllPurchase data,
  CreditNoteState s,
) {
  // find ledger from loaded list (or create fallback)
  final selectedLedger = s.ledgers.firstWhere(
    (c) => c.id == data.ledgerId,
    orElse: () => LedgerModelDrop(
      id: data.ledgerId ?? "",
      name: data.ledgerName,
      mobile: data.mobile,
      billingAddress: data.address0,
      shippingAddress: data.address1,
      state: data.placeOfSupply,
    ),
  );

  return s.copyWith(
    ledgers: s.ledgers,
    selectedLedger: data.caseSale ? null : selectedLedger,
    cashSaleDefault: data.caseSale,
  );
}

/// ------------------- PREFILL HELPER -------------------
CreditNoteState _prefillCreditNote(CreditNoteData data, CreditNoteState s) {
  // find ledger from loaded list (or create fallback)
  final selectedLedger = s.ledgers.firstWhere(
    (c) => c.id == data.ledgerId,
    orElse: () => LedgerModelDrop(
      id: data.ledgerId ?? "",
      name: data.ledgerName,
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
    final nameFromCreditNote = (m.name).trim().toLowerCase();
    if (nameFromCreditNote.isEmpty) continue;

    // try to find in misc master list safely
    MiscChargeModelList? match;
    try {
      match = s.miscMasterList.firstWhere(
        (mx) => (mx.name).trim().toLowerCase() == nameFromCreditNote,
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
    ledgers: s.ledgers,
    selectedLedger: data.caseSale ? null : selectedLedger,
    prefix: data.prefix,
    creditNoteNo: data.no.toString(),
    rows: rows,
    charges: mappedCharges,
    discounts: mappedDiscounts,
    miscCharges: mappedMisc,
    subtotal: (data.subTotal).toDouble(),
    totalGst: (data.subGst).toDouble(),
    totalAmount: (data.totalAmount).toDouble(),
    autoRound: data.autoRound,
    creditNoteDate: data.creditNoteDate,
    cashSaleDefault: data.caseSale,
  );
}
