import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:ims/ui/master/misc/misc_charge_model.dart';
import 'package:ims/ui/purchase/credit_note/state/credit_note_bloc.dart';
import 'package:ims/ui/purchase/credit_note/widgets/credit_note_details.dart';
import 'package:ims/ui/sales/data/global_additionalcharge.dart';
import 'package:ims/ui/sales/data/global_billto.dart';
import 'package:ims/ui/sales/data/global_discount.dart';
import 'package:ims/ui/sales/data/global_note_table.dart';
import 'package:ims/ui/sales/data/global_repository.dart';
import 'package:ims/ui/sales/data/global_shipto.dart';
import 'package:ims/ui/sales/data/globalheader.dart';
import 'package:ims/ui/sales/data/globalnotes_section.dart';
import 'package:ims/ui/sales/data/globalmisc_charge.dart';
import 'package:ims/ui/sales/models/credit_note_data.dart';
import 'package:ims/ui/sales/models/global_models.dart';
import 'package:ims/ui/sales/data/globalsummary_card.dart';
import 'package:ims/utils/api.dart';
import 'package:ims/utils/button.dart';
import 'package:ims/utils/colors.dart';
import 'package:ims/utils/prefence.dart';
import 'package:ims/utils/sizes.dart';
import 'package:ims/utils/snackbar.dart';
import 'package:ims/utils/state_cities.dart';
import 'package:searchfield/searchfield.dart';

class CreateCreditNoteFullScreen extends StatelessWidget {
  final GLobalRepository repo;
  final CreditNoteData? creditNoteData;

  CreateCreditNoteFullScreen({
    super.key,
    GLobalRepository? repo,
    this.creditNoteData,
  }) : repo = repo ?? GLobalRepository();

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) =>
          CreditNoteBloc(repo: repo)
            ..add(CreditNoteLoadInit(existing: creditNoteData)),
      child: CreateCreditNoteView(creditNoteData: creditNoteData),
    );
  }
}

class CreateCreditNoteView extends StatefulWidget {
  final CreditNoteData? creditNoteData;

  const CreateCreditNoteView({super.key, this.creditNoteData});

  @override
  State<CreateCreditNoteView> createState() => _CreateCreditNoteViewState();
}

class _CreateCreditNoteViewState extends State<CreateCreditNoteView> {
  final prefixController = TextEditingController(text: "");
  final creditNoteNoController = TextEditingController();
  final cusNameController = TextEditingController();
  final cashMobileController = TextEditingController();
  final cashBillingController = TextEditingController();
  final cashShippingController = TextEditingController();
  DateTime pickedCreditNoteDate = DateTime.now();
  final noteController = TextEditingController();
  final transNoController = TextEditingController();
  final prefixTransController = TextEditingController();
  final stateController = TextEditingController();
  SearchFieldListItem<String>? selectedState;
  late List<String> statesSuggestions;

  List<String> selectedNotesList = [];
  List<String> selectedTermsList = [];
  List<MiscChargeModelList> miscList = [];

  bool printAfterSave = false;
  void onTogglePrint(bool value) {
    setState(() {
      printAfterSave = value;
    });
  }

  bool printSignature = true;
  void onToggleSignature(bool value) {
    setState(() {
      printSignature = value;
    });
  }

  final FocusNode _customerFocus = FocusNode();
  @override
  void initState() {
    super.initState();

    statesSuggestions = stateCities.keys.toList();
    if (widget.creditNoteData != null) {
      final e = widget.creditNoteData!;

      // Prefill names / mobile
      cusNameController.text = e.ledgerName;
      cashMobileController.text = e.mobile;

      cashBillingController.text = e.address0;
      cashShippingController.text = e.address1;
      stateController.text = e.placeOfSupply;

      pickedCreditNoteDate = e.creditNoteDate;
      if (widget.creditNoteData != null) {
        noteController.text = widget.creditNoteData!.notes.join(", ");
      }
      transNoController.text = e.transNo.toString() == "0"
          ? ""
          : e.transNo.toString();
      prefixTransController.text = e.transPre.toString();

      selectedTermsList = e.terms;

      if (e.caseSale == true) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          context.read<CreditNoteBloc>().add(CreditNoteToggleCashSale(true));
        });
      } else {
        // Ensure BLoC reflects non-cash mode for editing
        WidgetsBinding.instance.addPostFrameCallback((_) {
          context.read<CreditNoteBloc>().add(CreditNoteToggleCashSale(false));
          if (e.ledgerId != null && e.ledgerId!.isNotEmpty) {
            // find customer from loaded list (may be empty until load completes)
            final cands = context.read<CreditNoteBloc>().state.ledgers;
            final found = cands.firstWhere(
              (c) => c.id == e.ledgerId,
              orElse: () => LedgerModelDrop(
                id: e.ledgerId ?? "",
                name: e.ledgerName,
                mobile: e.mobile,
                billingAddress: e.address0,
                shippingAddress: e.address1,
                state: e.placeOfSupply,
              ),
            );
            context.read<CreditNoteBloc>().add(CreditNoteSelectLedger(found));
          }
        });
      }
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _customerFocus.requestFocus();
    });
    // fetch misc etc.
    fetchMiscCharges();
  }

  @override
  void dispose() {
    prefixController.dispose();
    creditNoteNoController.dispose();
    cusNameController.dispose();
    cashMobileController.dispose();
    cashBillingController.dispose();
    cashShippingController.dispose();
    super.dispose();
  }

  Future<void> _pickCreditNotereditNoteDate(
    BuildContext ctx,
    CreditNoteBloc bloc,
  ) async {
    final date = await showDatePicker(
      context: ctx,
      initialDate: pickedCreditNoteDate,
      firstDate: DateTime(1990),
      lastDate: DateTime(2100),
    );
    if (date != null) {
      pickedCreditNoteDate = date;

      bloc.emit(bloc.state.copyWith(creditNoteDate: date));
      bloc.add(CreditNoteCalculate());
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

  // ---------------- UI ----------------
  @override
  Widget build(BuildContext context) {
    final bloc = context.read<CreditNoteBloc>();

    return BlocListener<CreditNoteBloc, CreditNoteState>(
      listenWhen: (previous, current) {
        // Only listen when selectedLedger or cashSaleDefault or creditNoteNo changes
        return previous.selectedLedger != current.selectedLedger ||
            previous.cashSaleDefault != current.cashSaleDefault ||
            previous.creditNoteNo != current.creditNoteNo;
      },
      listener: (context, state) {
        // When customer selected via dropdown, autofill name/mobile/address fields
        bool isUpdateMode = widget.creditNoteData != null;

        final customer = state.selectedLedger;
        if (creditNoteNoController.text != state.creditNoteNo.toString()) {
          creditNoteNoController.text = state.creditNoteNo.toString();
        }
        if (prefixController.text != state.prefix) {
          prefixController.text = state.prefix;
        }
        // Only autofill addresses when user selects customer in CREATE mode
        if (!isUpdateMode && customer != null && !state.cashSaleDefault) {
          cusNameController.text = customer.name;
          cashMobileController.text = customer.mobile;
          cashBillingController.text = customer.billingAddress;
          cashShippingController.text = customer.shippingAddress;
        }
        if (state.cashSaleDefault) {
          // If a selectedLedger existed earlier, use that name as default cash name
          if (state.selectedLedger != null) {
            cusNameController.text = state.selectedLedger!.name;
            cashMobileController.text = state.selectedLedger!.mobile;
            cashBillingController.text = state.selectedLedger!.billingAddress;
            cashShippingController.text = state.selectedLedger!.shippingAddress;
          }
        }
        if (state.transPlaceOfSupply != null &&
            state.transPlaceOfSupply!.isNotEmpty) {
          stateController.text = state.transPlaceOfSupply!;
          return; // 🚨 customer logic SKIP
        }
      },
      child: Scaffold(
        key: creditNoteNavigatorKey,
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
            '${widget.creditNoteData == null ? "Create" : "Update"} Debit Note',
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
                      "${widget.creditNoteData == null ? "Save" : "Update"} Debit Note",
                  height: 40,
                  width: 200,
                  onTap: () {
                    bloc.add(
                      CreditNoteSaveWithUIData(
                        ledgerName: cusNameController.text,
                        mobile: cashMobileController.text,
                        billingAddress: cashBillingController.text,
                        shippingAddress: cashShippingController.text,
                        stateName: stateController.text,
                        notes: noteController.text.trim().isEmpty
                            ? []
                            : [noteController.text.trim()],
                        terms: selectedTermsList,
                        signatureImage: null,
                        updateId: widget.creditNoteData?.id,
                        printAfterSave: printAfterSave,
                        printSignatue: printSignature,
                      ),
                    );
                  },
                ),
                const SizedBox(width: 10),
              ],
            ),
          ],
        ),
        body: BlocBuilder<CreditNoteBloc, CreditNoteState>(
          builder: (context, state) {
            return SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  GlobalHeaderCard(
                    billTo: GlobalBillToCard(
                      isCashSale: state.cashSaleDefault,
                      customers: state.ledgers,
                      selectedCustomer: state.selectedLedger,
                      onSearchLedger: (text) async => [],
                      cusNameController: cusNameController,
                      focusNode: _customerFocus,
                      mobileController: cashMobileController,
                      billingController: cashBillingController,
                      shippingController: cashShippingController,
                      stateController: stateController,

                      onToggleCashSale: () {
                        bloc.add(
                          CreditNoteToggleCashSale(!state.cashSaleDefault),
                        );

                        if (state.cashSaleDefault) {
                          cusNameController.clear();
                          cashMobileController.clear();
                          cashBillingController.clear();
                          cashShippingController.clear();
                        }
                      },

                      onCustomerSelected: (customer) {
                        bloc.add(CreditNoteSelectLedger(customer));
                        cashMobileController.text = customer.mobile;
                        cashBillingController.text = customer.billingAddress;
                        cashShippingController.text = customer.shippingAddress;
                        stateController.text =
                            customer.state ??
                            Preference.getString(PrefKeys.state);
                      },

                      onCreateCustomer: () => _showCreateCustomerDialog(
                        context.read<CreditNoteBloc>(),
                      ),
                      ispurchase: true,
                      isReturn: false,
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

                    details: CreditNoteDetailsCard(
                      prefixController: prefixController,
                      creditNoteNoController: creditNoteNoController,
                      pickedCreditNoteDate: pickedCreditNoteDate,
                      onTapCreditNoteDate: () => _pickCreditNotereditNoteDate(
                        context,
                        context.read<CreditNoteBloc>(),
                      ),
                      transNoController: transNoController,
                      prefixTransController: prefixTransController,
                    ),
                  ),

                  SizedBox(height: Sizes.height * .02),
                  NoteItemsTableSection(
                    rows: state.rows,
                    hsnList: state.hsnMaster,
                    onAddRow: () => bloc.add(CreditNoteAddRow()),
                    onRemoveRow: (id) => bloc.add(CreditNoteRemoveRow(id)),
                    onUpdateRow: (row) => bloc.add(CreditNoteUpdateRow(row)),
                    onSelectHsn: (id, hsn) =>
                        bloc.add(CreditNoteApplyHsnToRow(id, hsn)),
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
                          termId: '10',
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
                                  bloc.add(CreditNoteToggleRoundOff(v)),

                              additionalChargesSection:
                                  GlobalAdditionalChargesSection(
                                    charges: state.charges,
                                    onAddCharge: (c) =>
                                        bloc.add(CreditNoteAddCharge(c)),
                                    onRemoveCharge: (id) =>
                                        bloc.add(CreditNoteRemoveCharge(id)),
                                  ),

                              miscChargesSection: GlobalMiscChargesSection(
                                miscCharges: state.miscCharges,
                                miscList: miscList,
                                onAddMisc: (m) =>
                                    bloc.add(CreditNoteAddMiscCharge(m)),
                                onRemoveMisc: (id) =>
                                    bloc.add(CreditNoteRemoveMiscCharge(id)),
                              ),

                              discountSection: GlobalDiscountsSection(
                                discounts: state.discounts,
                                onAddDiscount: (d) =>
                                    bloc.add(CreditNoteAddDiscount(d)),
                                onRemoveDiscount: (id) =>
                                    bloc.add(CreditNoteRemoveDiscount(id)),
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
                                              BorderRadiusGeometry.circular(5),
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
                                          fontSize: 15,
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
                                              BorderRadiusGeometry.circular(5),
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
                                          fontSize: 15,
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
            );
          },
        ),
      ),
    );
  }

  void _showCreateCustomerDialog(CreditNoteBloc bloc) {
    final nameCtrl = TextEditingController();
    final stateCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Create Supplier'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameCtrl,
              decoration: const InputDecoration(labelText: 'Name'),
            ),
            TextField(
              controller: stateCtrl,
              decoration: const InputDecoration(labelText: 'State'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (nameCtrl.text.trim().isEmpty) return;
              final res = await ApiService.postData('supplier', {
                "customer_type": "Individual",
                'company_name': nameCtrl.text.trim(),
                'state': stateCtrl.text.trim(),
                'licence_no': Preference.getint(PrefKeys.licenseNo).toString(),
                'branch_id': Preference.getString(PrefKeys.locationId),
              }, licenceNo: Preference.getint(PrefKeys.licenseNo));
              if (res != null && res['status'] == true) {
                showCustomSnackbarSuccess(context, 'Supplier created');
                bloc.add(
                  CreditNoteLoadInit(),
                ); // reload state so new customer is available
                Navigator.pop(context);
              } else {
                showCustomSnackbarError(context, res?['message'] ?? 'Failed');
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _editAddresses(CreditNoteState state, CreditNoteBloc bloc) {
    final billing = TextEditingController(
      text: state.cashSaleDefault
          ? cashBillingController.text
          : state.selectedLedger?.billingAddress ?? '',
    );
    final shipping = TextEditingController(
      text: state.cashSaleDefault
          ? cashShippingController.text
          : state.selectedLedger?.shippingAddress ?? '',
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
              } else if (state.selectedLedger != null) {
                final index = state.ledgers.indexWhere(
                  (c) => c.id == state.selectedLedger!.id,
                );
                final updatedList = List<LedgerModelDrop>.from(state.ledgers);
                updatedList[index] = LedgerModelDrop(
                  id: state.selectedLedger!.id,
                  name: state.selectedLedger!.name,
                  mobile: state.selectedLedger!.mobile,
                  billingAddress: billing.text,
                  shippingAddress: shipping.text,
                );
                // emit updated customers + selectedLedger
                bloc.emit(
                  state.copyWith(
                    ledgers: updatedList,
                    selectedLedger: updatedList[index],
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
}
