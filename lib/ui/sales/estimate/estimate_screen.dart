import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:ims/model/employee_model.dart';
import 'package:ims/ui/master/misc/misc_charge_model.dart';
import 'package:ims/ui/sales/data/create_cust_dialogue.dart';
import 'package:ims/ui/sales/data/global_additionalcharge.dart';
import 'package:ims/ui/sales/data/global_billto.dart';
import 'package:ims/ui/sales/data/global_discount.dart';
import 'package:ims/ui/sales/data/global_item_table.dart';
import 'package:ims/ui/sales/data/global_repository.dart';
import 'package:ims/ui/sales/data/global_shipto.dart';
import 'package:ims/ui/sales/data/globalheader.dart';
import 'package:ims/ui/sales/data/globalnotes_section.dart';
import 'package:ims/ui/sales/data/globalmisc_charge.dart';
import 'package:ims/ui/sales/models/estimate_data.dart';
import 'package:ims/ui/sales/models/global_models.dart';
import 'package:ims/ui/sales/estimate/state/estimate_bloc.dart';
import 'package:ims/ui/sales/estimate/widgets/estimate_details_card.dart';
import 'package:ims/ui/sales/data/globalsummary_card.dart';
import 'package:ims/utils/api.dart';
import 'package:ims/utils/button.dart';
import 'package:ims/utils/colors.dart';
import 'package:ims/utils/prefence.dart';
import 'package:ims/utils/sizes.dart';
import 'package:ims/utils/state_cities.dart';
import 'package:intl/intl.dart';
import 'package:searchfield/searchfield.dart';

class CreateEstimateFullScreen extends StatelessWidget {
  final GLobalRepository repo;
  final EstimateData? estimateData;

  CreateEstimateFullScreen({
    Key? key,
    GLobalRepository? repo,
    this.estimateData,
  }) : repo = repo ?? GLobalRepository(),
       super(key: key);

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) =>
          EstBloc(repo: repo)..add(EstLoadInit(existing: estimateData)),
      child: CreateEstimateView(estimateData: estimateData),
    );
  }
}

class CreateEstimateView extends StatefulWidget {
  final EstimateData? estimateData;

  const CreateEstimateView({Key? key, this.estimateData}) : super(key: key);

  @override
  State<CreateEstimateView> createState() => _CreateEstimateViewState();
}

class _CreateEstimateViewState extends State<CreateEstimateView> {
  final GLobalRepository repo;
  _CreateEstimateViewState({GLobalRepository? repo})
    : repo = repo ?? GLobalRepository();

  final prefixController = TextEditingController(text: "");
  final estimateNoController = TextEditingController();
  final cusNameController = TextEditingController();
  final cashMobileController = TextEditingController();
  final cashBillingController = TextEditingController();
  final cashShippingController = TextEditingController();
  final noteController = TextEditingController();
  final validForController = TextEditingController();
  final salesPersonController = TextEditingController();
  DateTime pickedEstimateDate = DateTime.now();
  final ScrollController _scrollController = ScrollController();
  final stateController = TextEditingController();
  SearchFieldListItem<String>? selectedState;
  late List<String> statesSuggestions;
  DateTime? pickedValidityDate;

  Timer? _ledgerDebounce;
  Timer? _itemDebounce;
  List<String> selectedNotesList = [];
  List<String> selectedTermsList = [];
  List<MiscChargeModelList> miscList = [];

  bool printAfterSave = false;
  void onTogglePrint(bool value) {
    setState(() {
      printAfterSave = value;
    });
  }

  bool sendWhatsApp = false;
  void onToggleWhatsApp(bool value) {
    setState(() {
      sendWhatsApp = value;
    });
  }

  bool printSignature = true;
  void onToggleSignature(bool value) {
    setState(() {
      printSignature = value;
    });
  }

  final estimateDateController = TextEditingController();
  final validityDateController = TextEditingController();

  final FocusNode _customerFocus = FocusNode();
  @override
  void initState() {
    super.initState();

    statesSuggestions = stateCities.keys.toList();
    // NEW: If editing an existing estimate, prefill fields from the estimate payload.
    if (widget.estimateData != null) {
      final e = widget.estimateData!;

      // always set payment terms field (so UI shows days)
      validForController.text = e.paymentTerms.toString();

      // Prefill names / mobile
      cusNameController.text = e.customerName;
      cashMobileController.text = e.mobile;

      cashBillingController.text = e.address0;
      cashShippingController.text = e.address1;
      salesPersonController.text = e.other1;
      stateController.text = e.placeOfSupply;

      // set estimate dates & validity
      pickedEstimateDate = e.estimateDate;
      pickedValidityDate = e.estimateDate.add(Duration(days: e.paymentTerms));
      if (widget.estimateData != null) {
        noteController.text = widget.estimateData!.notes.join(", ");
      }
      selectedTermsList = e.terms;

      // If the estimate is a direct sale, enable direct sale mode in BLoC.
      if (e.caseSale == true) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          context.read<EstBloc>().add(EstToggleCashSale(true));
        });
      } else {
        // Ensure BLoC reflects non-cash mode for editing
        WidgetsBinding.instance.addPostFrameCallback((_) {
          context.read<EstBloc>().add(EstToggleCashSale(false));
          // also select the customer in BLoC (optional) if you want UI to show selection
          // but don't change addresses here (we already used estimate addresses).
          if (e.customerId != null && e.customerId!.isNotEmpty) {
            // find customer from loaded list (may be empty until load completes)
            final cands = context.read<EstBloc>().state.customers;
            final found = cands.firstWhere(
              (c) => c.id == e.customerId,
              orElse: () => LedgerModelDrop(
                id: e.customerId ?? "",
                name: e.customerName,
                mobile: e.mobile,
                billingAddress: e.address0,
                shippingAddress: e.address1,
              ),
            );
            context.read<EstBloc>().add(EstSelectCustomer(found));
          }
        });
      }
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _customerFocus.requestFocus();
    });
    // fetch misc etc.
    fetchMiscCharges();
    fetchEmployee();
    estimateDateController.text = DateFormat(
      'yyyy-MM-dd',
    ).format(pickedEstimateDate);

    if (pickedValidityDate != null) {
      validityDateController.text = DateFormat(
        'yyyy-MM-dd',
      ).format(pickedValidityDate!);
    }
  }

  @override
  void dispose() {
    prefixController.dispose();
    estimateNoController.dispose();
    cusNameController.dispose();
    cashMobileController.dispose();
    cashBillingController.dispose();
    cashShippingController.dispose();
    validForController.dispose();
    super.dispose();
  }

  Future<void> _pickEstimateDate(BuildContext ctx, EstBloc bloc) async {
    final date = await showDatePicker(
      context: ctx,
      initialDate: pickedEstimateDate,
      firstDate: DateTime(1990),
      lastDate: DateTime(2100),
    );
    if (date != null) {
      pickedEstimateDate = date;
      final days = int.tryParse(validForController.text) ?? 0;
      pickedValidityDate = days > 0
          ? date.add(Duration(days: days))
          : pickedValidityDate;
      bloc.emit(
        bloc.state.copyWith(
          estimateDate: date,
          validityDate: pickedValidityDate,
        ),
      );
      bloc.add(EstCalculate());
      setState(() {});
    }
  }

  Future<void> _pickValidityDate(BuildContext ctx, EstBloc bloc) async {
    final date = await showDatePicker(
      context: ctx,
      initialDate: pickedValidityDate ?? pickedEstimateDate,
      firstDate: pickedEstimateDate,
      lastDate: DateTime(2100),
    );
    if (date != null) {
      pickedValidityDate = date;
      validForController.text = date
          .difference(pickedEstimateDate)
          .inDays
          .toString();
      bloc.emit(
        bloc.state.copyWith(
          estimateDate: pickedEstimateDate,
          validityDate: pickedValidityDate,
        ),
      );
      bloc.add(EstCalculate());
      setState(() {});
    }
  }

  // ---------------- misc fetch ----------------
  Future<void> fetchMiscCharges() async {
    final res = await ApiService.fetchData(
      "get/misccharge",
      licenceNo: Preference.getint(PrefKeys.licenseNo),
    );

    if (res != null && res["status"] == true) {
      miscList = (res["data"] as List)
          .map((e) => MiscChargeModelList.fromJson(e))
          .toList();
      setState(() {});
    }
  }

  List<EmployeeModel> employeeList = [];
  Future<void> fetchEmployee() async {
    var response = await ApiService.fetchData(
      "get/employee",
      licenceNo: Preference.getint(PrefKeys.licenseNo),
    );

    List responseData = response['data'] ?? [];
    setState(() {
      employeeList = responseData
          .map((e) => EmployeeModel.fromJson(e))
          .toList();
    });
  }

  // ---------------- UI ----------------
  @override
  Widget build(BuildContext context) {
    final bloc = context.read<EstBloc>();

    return BlocListener<EstBloc, EstState>(
      listenWhen: (previous, current) {
        // Only listen when selectedCustomer or cashSaleDefault or estimateNo changes
        return previous.selectedCustomer != current.selectedCustomer ||
            previous.cashSaleDefault != current.cashSaleDefault ||
            previous.estimateNo != current.estimateNo;
      },
      listener: (context, state) {
        if (estimateNoController.text != state.estimateNo.toString()) {
          estimateNoController.text = state.estimateNo.toString();
        }
        if (prefixController.text != state.prefix) {
          prefixController.text = state.prefix;
        }
        // When customer selected via dropdown, autofill name/mobile/address fields
        bool isUpdateMode = widget.estimateData != null;

        final customer = state.selectedCustomer;

        // Only autofill addresses when user selects customer in CREATE mode
        if (!isUpdateMode && customer != null && !state.cashSaleDefault) {
          cusNameController.text = customer.name;
          cashMobileController.text = customer.mobile;
          cashBillingController.text = customer.billingAddress;
          cashShippingController.text = customer.shippingAddress;
        }
        if (state.cashSaleDefault) {
          // If a selectedCustomer existed earlier, use that name as default cash name
          if (state.selectedCustomer != null) {
            cusNameController.text = state.selectedCustomer!.name;
            cashMobileController.text = state.selectedCustomer!.mobile;
            cashBillingController.text = state.selectedCustomer!.billingAddress;
            cashShippingController.text =
                state.selectedCustomer!.shippingAddress;
          }
        }

        // validity days sync (if BLoC has validForDays)
        validForController.text = state.validForDays.toString();
      },
      child: Scaffold(
        key: estimateNavigatorKey,
        backgroundColor: AppColor.white,
        appBar: AppBar(
          backgroundColor: AppColor.white,
          elevation: 0.5,
          leading: IconButton(
            icon: const Icon(
              Icons.arrow_back_ios_new_rounded,
              size: 18,
              color: Colors.black87,
            ),
            onPressed: () => Navigator.of(context).pop(),
          ),
          titleSpacing: 0,
          title: Text(
            '${widget.estimateData == null ? "Create" : "Update"} Estimate',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppColor.blackText,
            ),
          ),
          actions: [
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                defaultButton(
                  buttonColor: const Color(0xffE11414),
                  text: "Cancel",
                  height: 40,
                  width: 93,
                  onTap: () => Navigator.of(context).pop(),
                ),
                const SizedBox(width: 18),
                defaultButton(
                  buttonColor: const Color(0xff8947E5),
                  text:
                      "${widget.estimateData == null ? "Create" : "Update"} Estimate",
                  height: 40,
                  width: 160,
                  onTap: () {
                    bloc.add(
                      EstSaveWithUIData(
                        customerName: cusNameController.text,
                        mobile: cashMobileController.text,
                        billingAddress: cashBillingController.text,
                        shippingAddress: cashShippingController.text,
                        notes: noteController.text.trim().isEmpty
                            ? []
                            : [noteController.text.trim()],
                        terms: selectedTermsList,
                        signatureImage: null,
                        updateId: widget.estimateData?.id,
                        stateName: stateController.text,
                        printAfterSave: printAfterSave,
                        printSignature: printSignature,
                        sendWhatsApp: sendWhatsApp,
                      ),
                    );
                  },
                ),
                const SizedBox(width: 10),
              ],
            ),
          ],
        ),
        body: BlocBuilder<EstBloc, EstState>(
          builder: (context, state) {
            // keep estimate number in sync (repo may set it)

            return Scrollbar(
              controller: _scrollController,
              thumbVisibility: true,
              trackVisibility: true,
              child: SingleChildScrollView(
                controller: _scrollController,
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    GlobalHeaderCard(
                      billTo: GlobalBillToCard(
                        ispurchase: false,
                        isCashSale: state.cashSaleDefault,
                        customers: state.customers,
                        focusNode: _customerFocus,
                        selectedCustomer: state.selectedCustomer,
                        onSearchLedger: (text) => _searchLedgerDebounced(text),
                        cusNameController: cusNameController,
                        mobileController: cashMobileController,
                        billingController: cashBillingController,
                        shippingController: cashShippingController,
                        stateController: stateController,

                        onToggleCashSale: () {
                          bloc.add(EstToggleCashSale(!state.cashSaleDefault));

                          if (state.cashSaleDefault) {
                            cusNameController.clear();
                            cashMobileController.clear();
                            cashBillingController.clear();
                            cashShippingController.clear();
                          }
                        },

                        onCustomerSelected: (customer) {
                          bloc.add(EstSelectCustomer(customer));
                          cashMobileController.text = customer.mobile;
                          cashBillingController.text = customer.billingAddress;
                          cashShippingController.text =
                              customer.shippingAddress;
                          stateController.text =
                              customer.state ??
                              Preference.getString(PrefKeys.state);
                        },
                        onCreateCustomer: () => showCreateCustomerDialog(
                          context: context,
                          onCustomerCreated: () {
                            bloc.add(EstLoadInit());
                          },
                        ),
                      ),

                      shipTo: GlobalShipToCard(
                        billingController: cashBillingController,
                        shippingController: cashShippingController,
                        onEditAddresses: () => _editAddresses(state, bloc),
                        stateController: stateController,
                        statesSuggestions: statesSuggestions,
                        onStateSelected: (state) {
                          selectedState = SearchFieldListItem(state);
                        },
                      ),

                      details: EstimateDetailsCard(
                        prefixController: prefixController,
                        estimateNoController: estimateNoController,
                        validForController: validForController,
                        pickedEstimateDate: pickedEstimateDate,
                        pickedValidityDate: pickedValidityDate,
                        salesPersonController: salesPersonController,
                        employeeList: employeeList,
                        estimateDateController: estimateDateController,
                        validityDateController: validityDateController,
                        onTapEstimateDate: () =>
                            _pickEstimateDate(context, context.read<EstBloc>()),
                        onTapValidityDate: () =>
                            _pickValidityDate(context, context.read<EstBloc>()),

                        onValidForChanged: (value) {
                          final days = int.tryParse(value) ?? 0;
                          pickedValidityDate = pickedEstimateDate.add(
                            Duration(days: days),
                          );
                          // inform bloc about validForDays (keep state consistent)
                          bloc.emit(
                            state.copyWith(
                              validForDays: days,
                              validityDate: pickedValidityDate,
                            ),
                          );
                          bloc.add(EstCalculate());
                          setState(() {});
                        },
                      ),
                    ),

                    SizedBox(height: Sizes.height * .03),
                    GlobalItemsTableSection(
                      rows: state.rows,
                      ledgerType:
                          state.selectedCustomer?.ledgerType ?? 'Individual',
                      catalogue: state.catalogue,
                      hsnList: state.hsnMaster,
                      onAddNextRow: () => bloc.add(EstAddRow()), // ✅ ADD THIS
                      onAddRow: () => bloc.add(EstAddRow()),
                      onRemoveRow: (id) => bloc.add(EstRemoveRow(id)),
                      onUpdateRow: (row) => bloc.add(EstUpdateRow(row)),
                      onSearchItem: (text) => _searchItemDebounced(text),
                      onSelectCatalog: (rowId, item) {
                        bloc.add(EstSelectCatalogForRow(rowId, item));

                        WidgetsBinding.instance.addPostFrameCallback((_) {
                          if (_scrollController.hasClients) {
                            _scrollController.animateTo(
                              _scrollController.offset + 75,
                              duration: const Duration(milliseconds: 300),
                              curve: Curves.ease,
                            );
                          }
                        });
                      },
                      onSelectHsn: (id, hsn) =>
                          bloc.add(EstApplyHsnToRow(id, hsn)),
                      onToggleUnit: (id, value) =>
                          bloc.add(EstToggleUnitForRow(id, value)),
                    ),
                    SizedBox(height: Sizes.height * .02),

                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          flex: 10,
                          child: GlobalNotesSection(
                            initialTerms: selectedTermsList,
                            noteController: noteController,
                            onTermsChanged: (list) => selectedTermsList = list,
                            termId: '5',
                          ),
                        ),

                        const SizedBox(width: 12),
                        Expanded(
                          flex: 9,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              GlobalSummaryCard(
                                subtotal: state.subtotal,
                                totalGst: state.totalGst,
                                sgst: state.sgst,
                                cgst: state.cgst,
                                totalAmount: state.totalAmount,

                                autoRound: state.autoRound,
                                onToggleRound: (v) =>
                                    bloc.add(EstToggleRoundOff(v)),

                                additionalChargesSection:
                                    GlobalAdditionalChargesSection(
                                      charges: state.charges,
                                      onAddCharge: (c) =>
                                          bloc.add(EstAddCharge(c)),
                                      onRemoveCharge: (id) =>
                                          bloc.add(EstRemoveCharge(id)),
                                    ),

                                miscChargesSection: GlobalMiscChargesSection(
                                  miscCharges: state.miscCharges,
                                  miscList: miscList,
                                  onAddMisc: (m) =>
                                      bloc.add(EstAddMiscCharge(m)),
                                  onRemoveMisc: (id) =>
                                      bloc.add(EstRemoveMiscCharge(id)),
                                ),

                                discountSection: GlobalDiscountsSection(
                                  discounts: state.discounts,
                                  onAddDiscount: (d) =>
                                      bloc.add(EstAddDiscount(d)),
                                  onRemoveDiscount: (id) =>
                                      bloc.add(EstRemoveDiscount(id)),
                                ),
                              ),

                              SizedBox(height: Sizes.height * .02),
                              Row(
                                children: [
                                  SizedBox(width: 10),
                                  Expanded(
                                    child: Row(
                                      children: [
                                        Checkbox(
                                          fillColor: WidgetStatePropertyAll(
                                            AppColor.primary,
                                          ),
                                          shape: ContinuousRectangleBorder(
                                            borderRadius:
                                                BorderRadiusGeometry.circular(
                                                  5,
                                                ),
                                          ),
                                          value: printAfterSave,
                                          onChanged: (v) {
                                            onTogglePrint(v ?? true);
                                            setState(() {});
                                          },
                                        ),
                                        Text(
                                          "Print PDF on save",
                                          style: GoogleFonts.inter(
                                            fontSize: 14,
                                            color: AppColor.black,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Expanded(
                                    child: Row(
                                      children: [
                                        Checkbox(
                                          fillColor: WidgetStatePropertyAll(
                                            AppColor.primary,
                                          ),
                                          shape: ContinuousRectangleBorder(
                                            borderRadius:
                                                BorderRadiusGeometry.circular(
                                                  5,
                                                ),
                                          ),
                                          value: printSignature,
                                          onChanged: (v) {
                                            onToggleSignature(v ?? true);
                                            setState(() {});
                                          },
                                        ),
                                        Text(
                                          "Print Signature in PDF",
                                          style: GoogleFonts.inter(
                                            fontSize: 14,
                                            color: AppColor.black,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),

                                  Expanded(
                                    child: Row(
                                      children: [
                                        Checkbox(
                                          fillColor: WidgetStatePropertyAll(
                                            AppColor.primary,
                                          ),
                                          shape: ContinuousRectangleBorder(
                                            borderRadius:
                                                BorderRadiusGeometry.circular(
                                                  5,
                                                ),
                                          ),
                                          value: sendWhatsApp,
                                          onChanged: (v) {
                                            onToggleWhatsApp(v ?? true);
                                            setState(() {});
                                          },
                                        ),
                                        Text(
                                          "Send PdF on Whatsapp",
                                          style: GoogleFonts.inter(
                                            fontSize: 14,
                                            color: AppColor.black,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  void _editAddresses(EstState state, EstBloc bloc) {
    final billing = TextEditingController(
      text: state.cashSaleDefault
          ? cashBillingController.text
          : state.selectedCustomer?.billingAddress ?? '',
    );
    final shipping = TextEditingController(
      text: state.cashSaleDefault
          ? cashShippingController.text
          : state.selectedCustomer?.shippingAddress ?? '',
    );

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Edit Addresses'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: billing,
              decoration: const InputDecoration(labelText: 'Billing Address'),
            ),
            TextField(
              controller: shipping,
              decoration: const InputDecoration(labelText: 'Shipping Address'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (state.cashSaleDefault) {
                cashBillingController.text = billing.text;
                cashShippingController.text = shipping.text;
              } else if (state.selectedCustomer != null) {
                final index = state.customers.indexWhere(
                  (c) => c.id == state.selectedCustomer!.id,
                );
                final updatedList = List<LedgerModelDrop>.from(state.customers);
                updatedList[index] = LedgerModelDrop(
                  id: state.selectedCustomer!.id,
                  name: state.selectedCustomer!.name,
                  mobile: state.selectedCustomer!.mobile,
                  billingAddress: billing.text,
                  shippingAddress: shipping.text,
                );
                // emit updated customers + selectedCustomer
                bloc.emit(
                  state.copyWith(
                    customers: updatedList,
                    selectedCustomer: updatedList[index],
                  ),
                );
              }
              setState(() {});
              Navigator.pop(context);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  Future<List<LedgerModelDrop>> _searchLedgerDebounced(String text) async {
    if (_ledgerDebounce?.isActive ?? false) _ledgerDebounce!.cancel();

    final completer = Completer<List<LedgerModelDrop>>();

    _ledgerDebounce = Timer(const Duration(milliseconds: 500), () async {
      final result = await repo.searchLedger(text, true);
      completer.complete(result);
    });

    return completer.future;
  }

  Future<List<ItemServiceModel>> _searchItemDebounced(String text) async {
    if (_itemDebounce?.isActive ?? false) _itemDebounce!.cancel();

    final completer = Completer<List<ItemServiceModel>>();

    _itemDebounce = Timer(const Duration(milliseconds: 500), () async {
      final result = await repo.searchItems(text);
      completer.complete(result);
    });

    return completer.future;
  }
}
