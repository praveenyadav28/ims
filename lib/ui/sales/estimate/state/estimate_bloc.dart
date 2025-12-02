import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ims/ui/sales/estimate/data/estimate_repository.dart';
import 'package:ims/ui/sales/estimate/models/estimate_models.dart';
import 'package:ims/utils/prefence.dart';
import 'package:ims/utils/snackbar.dart';
import 'package:intl/intl.dart';

///
/// EVENTS
///
abstract class EstEvent {}

class EstLoadInit extends EstEvent {}

class EstSelectCustomer extends EstEvent {
  final CustomerModel? c;
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
  final EstimateRow row;
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

class EstCalculate extends EstEvent {}

class EstSave extends EstEvent {}

class EstToggleRoundOff extends EstEvent {
  final bool value;
  EstToggleRoundOff(this.value);
}

///
/// STATE
///
class EstState {
  final List<CustomerModel> customers;
  final CustomerModel? selectedCustomer;
  final bool cashSaleDefault;
  final List<HsnModel> hsnMaster;
  final String prefix;
  final String estimateNo;
  final DateTime? estimateDate;
  final DateTime? validityDate;
  final int validForDays;
  final List<ItemServiceModel> catalogue;
  final List<EstimateRow> rows;
  final List<AdditionalCharge> charges;
  final List<DiscountLine> discounts;
  final double subtotal;
  final double totalGst;
  final double sgst;
  final double cgst;
  final double totalAmount;
  final bool autoRound;

  EstState({
    this.customers = const [],
    this.selectedCustomer,
    this.cashSaleDefault = false,
    this.prefix = 'EST',
    this.estimateNo = '',
    this.hsnMaster = const [],
    this.estimateDate,
    this.validityDate,
    this.validForDays = 0,
    this.catalogue = const [],
    this.rows = const [],
    this.charges = const [],
    this.discounts = const [],
    this.subtotal = 0,
    this.totalGst = 0,
    this.sgst = 0,
    this.cgst = 0,
    this.totalAmount = 0,
    this.autoRound = true,
  });

  EstState copyWith({
    List<CustomerModel>? customers,
    CustomerModel? selectedCustomer,
    bool? cashSaleDefault,
    String? prefix,
    String? estimateNo,
    DateTime? estimateDate,
    List<HsnModel>? hsnMaster,
    DateTime? validityDate,
    int? validForDays,
    List<ItemServiceModel>? catalogue,
    List<EstimateRow>? rows,
    List<AdditionalCharge>? charges,
    List<DiscountLine>? discounts,
    double? subtotal,
    double? totalGst,
    double? sgst,
    double? cgst,
    double? totalAmount,
    bool? autoRound,
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
      discounts: discounts ?? this.discounts,
      subtotal: subtotal ?? this.subtotal,
      totalGst: totalGst ?? this.totalGst,
      sgst: sgst ?? this.sgst,
      cgst: cgst ?? this.cgst,
      totalAmount: totalAmount ?? this.totalAmount,
      autoRound: autoRound ?? this.autoRound,
    );
  }
}

class EstSaveWithUIData extends EstEvent {
  final String customerName;
  final String mobile;
  final String billingAddress;
  final String shippingAddress;
  final List<String> notes;
  final List<String> terms;
  final String signatureUrl;

  EstSaveWithUIData({
    required this.customerName,
    required this.mobile,
    required this.billingAddress,
    required this.shippingAddress,
    required this.notes,
    required this.terms,
    required this.signatureUrl,
  });
}

final GlobalKey<NavigatorState> estimateNavigatorKey =
    GlobalKey<NavigatorState>();

///
/// BLOC
///
class EstBloc extends Bloc<EstEvent, EstState> {
  final EstimateRepository repo;
  EstBloc({required this.repo}) : super(EstState()) {
    on<EstLoadInit>(_onLoad);
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
    on<EstToggleRoundOff>(_onToggleRoundOff);
    on<EstCalculate>(_onCalculate);
  }

  Future<void> _onLoad(EstLoadInit e, Emitter<EstState> emit) async {
    try {
      final customers = await repo.fetchCustomers();
      final catalogue = await repo.fetchCatalogue();
      final hsnList = await repo.fetchHsnList();

      emit(
        state.copyWith(
          customers: customers,
          catalogue: catalogue,
          hsnMaster: hsnList,
          rows: [EstimateRow(localId: UniqueKey().toString())],
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
          selectedCustomer: CustomerModel(
            id: "cash_sale",
            name: "Cash Sale",
            mobile: "",
            billingAddress: "",
            shippingAddress: "",
          ),
        ),
      );
    } else {
      emit(state.copyWith(cashSaleDefault: false, selectedCustomer: null));
    }
  }

  void _onAddRow(EstAddRow e, Emitter<EstState> emit) {
    emit(
      state.copyWith(
        rows: [
          ...state.rows,
          EstimateRow(localId: UniqueKey().toString()),
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

  void _onCalculate(EstCalculate e, Emitter<EstState> emit) {
    final updatedRows = state.rows.map((r) => r.recalc()).toList();

    double subtotal = 0;
    double gst = 0;

    for (final r in updatedRows) {
      subtotal += r.taxable;
      gst += r.taxAmount;
    }

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

    for (final d in state.discounts) {
      subtotal -= d.isPercent ? subtotal * (d.amount / 100) : d.amount;
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

  Future<void> _onSaveWithUIData(
    EstSaveWithUIData e,
    Emitter<EstState> emit,
  ) async {
    try {
      final state = this.state;

      final bool isCash = state.cashSaleDefault;

      // ---------------- CUSTOMER ----------------
      final customerId = isCash ? null : state.selectedCustomer?.id;

      final customerName = isCash
          ? e.customerName
          : state.selectedCustomer?.name ?? "";

      final mobile = isCash ? e.mobile : state.selectedCustomer?.mobile ?? "";

      final billing = isCash
          ? e.billingAddress
          : state.selectedCustomer?.billingAddress ?? "";

      final shipping = isCash
          ? e.shippingAddress
          : state.selectedCustomer?.shippingAddress ?? "";

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

      // ---------------- FINAL PAYLOAD ----------------
      final payload = {
        "licence_no": Preference.getint(PrefKeys.licenseNo),
        "branch_id": Preference.getString(PrefKeys.locationId),
        "customer_id": customerId,
        "customer_name": customerName,
        "mobile": mobile,
        "address_0": billing,
        "address_1": shipping,
        "prefix": state.prefix,
        "no": int.tryParse(state.estimateNo) ?? 0,
        "estimate_date": DateFormat('yyyy-MM-dd').format(state.estimateDate!),
        "payment_terms": state.validForDays,
        "due_date": DateFormat('yyyy-MM-dd').format(state.validityDate!),
        "case_sale": isCash,
        "add_note": e.notes,
        "te_co": e.terms,
        "sub_totle": state.subtotal,
        "sub_gst": state.totalGst,
        "auto_ro": state.autoRound,
        "totle_amo": state.totalAmount,
        "additional_charges": charges,
        "discount": discounts,
        "item_details": itemRows,
        "service_details": serviceRows,
        "signature": e.signatureUrl,
      };
      final res = await repo.saveEstimate(payload);

      if (res?['status'] == true) {
        showCustomSnackbarSuccess(
          estimateNavigatorKey.currentContext!,
          res?['message'] ?? "Saved",
        );
      } else {
        showCustomSnackbarError(
          estimateNavigatorKey.currentContext!,
          res?['message'] ?? "Save failed",
        );
      }
    } catch (err) {
      showCustomSnackbarError(
        estimateNavigatorKey.currentContext!,
        err.toString(),
      );
    }
  }
}

///
/// ✅ IMMUTABLE CALCULATION EXTENSION
///
extension EstimateRowCalc on EstimateRow {
  EstimateRow recalc() {
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
//