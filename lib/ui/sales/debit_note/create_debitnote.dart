import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:ims/ui/master/misc/misc_charge_model.dart';
import 'package:ims/ui/sales/data/global_additionalcharge.dart';
import 'package:ims/ui/sales/data/global_billto.dart';
import 'package:ims/ui/sales/data/global_discount.dart';
import 'package:ims/ui/sales/data/global_note_table.dart';
import 'package:ims/ui/sales/data/global_repository.dart';
import 'package:ims/ui/sales/data/global_shipto.dart';
import 'package:ims/ui/sales/data/globalmisc_charge.dart';
import 'package:ims/ui/sales/data/globalnotes_section.dart';
import 'package:ims/ui/sales/data/globalsummary_card.dart';
import 'package:ims/ui/sales/debit_note/state/debitnote_bloc.dart';
import 'package:ims/ui/sales/debit_note/widgets/details.dart';
import 'package:ims/ui/sales/models/debitnote_model.dart';
import 'package:ims/ui/sales/models/global_models.dart';
import 'package:ims/ui/sales/data/globalheader.dart';
import 'package:ims/utils/api.dart';
import 'package:ims/utils/button.dart';
import 'package:ims/utils/colors.dart';
import 'package:ims/utils/prefence.dart';
import 'package:ims/utils/sizes.dart';
import 'package:ims/utils/snackbar.dart';
import 'package:ims/utils/state_cities.dart';
import 'package:searchfield/searchfield.dart';

class CreateDebitNoteFullScreen extends StatelessWidget {
  final GLobalRepository repo;
  final DebitNoteData? debitNoteData;

  CreateDebitNoteFullScreen({
    Key? key,
    GLobalRepository? repo,
    this.debitNoteData,
  }) : repo = repo ?? GLobalRepository(),
       super(key: key);

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) =>
          DebitNoteBloc(repo: repo)
            ..add(DebitNoteLoadInit(existing: debitNoteData)),
      child: CreateDebitNoteView(debitNoteData: debitNoteData),
    );
  }
}

class CreateDebitNoteView extends StatefulWidget {
  final DebitNoteData? debitNoteData;

  const CreateDebitNoteView({Key? key, this.debitNoteData}) : super(key: key);

  @override
  State<CreateDebitNoteView> createState() => _CreateDebitNoteViewState();
}

class _CreateDebitNoteViewState extends State<CreateDebitNoteView> {
  final prefixController = TextEditingController();
  final debitNoteNoController = TextEditingController();
  final cusNameController = TextEditingController();
  final cashMobileController = TextEditingController();
  final cashBillingController = TextEditingController();
  final cashShippingController = TextEditingController();
  DateTime pickedInvoiceDate = DateTime.now();
  final stateController = TextEditingController();
  SearchFieldListItem<String>? selectedState;
  late List<String> statesSuggestions;
  final noteController = TextEditingController();
  final transNoController = TextEditingController();
  final prefixTransController = TextEditingController();

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
    if (widget.debitNoteData != null) {
      final e = widget.debitNoteData!;
      cusNameController.text = e.customerName;
      cashMobileController.text = e.mobile;
      cashBillingController.text = e.address0;
      cashShippingController.text = e.address1;
      stateController.text = e.placeOfSupply;
      pickedInvoiceDate = e.debitNoteDate;
      if (widget.debitNoteData != null) {
        noteController.text = widget.debitNoteData!.notes.join(", ");
      }
      transNoController.text = e.transNo.toString() == "0"
          ? ""
          : e.transNo.toString();
      prefixTransController.text = e.transPre.toString();

      selectedTermsList = e.terms;

      if (e.caseSale == true) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          context.read<DebitNoteBloc>().add(DebitNoteToggleCashSale(true));
        });
      } else {
        // Ensure BLoC reflects non-cash mode for editing
        WidgetsBinding.instance.addPostFrameCallback((_) {
          context.read<DebitNoteBloc>().add(DebitNoteToggleCashSale(false));
          if (e.customerId != null && e.customerId!.isNotEmpty) {
            // find customer from loaded list (may be empty until load completes)
            final cands = context.read<DebitNoteBloc>().state.customers;
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
            context.read<DebitNoteBloc>().add(DebitNoteSelectCustomer(found));
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
    debitNoteNoController.dispose();
    cusNameController.dispose();
    cashMobileController.dispose();
    cashBillingController.dispose();
    cashShippingController.dispose();
    super.dispose();
  }

  Future<void> _pickDebitNoteDate(BuildContext ctx, DebitNoteBloc bloc) async {
    final date = await showDatePicker(
      context: ctx,
      initialDate: pickedInvoiceDate,
      firstDate: DateTime(1990),
      lastDate: DateTime(2100),
    );
    if (date != null) {
      pickedInvoiceDate = date;
      bloc.add(DebitNoteSetDate(date));
      bloc.add(DebitNoteCalculate());
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
    final bloc = context.read<DebitNoteBloc>();

    return BlocListener<DebitNoteBloc, DebitNoteState>(
      listenWhen: (previous, current) {
        // Only listen when selectedCustomer or cashSaleDefault or debitNoteNo changes
        return previous.selectedCustomer != current.selectedCustomer ||
            previous.cashSaleDefault != current.cashSaleDefault ||
            previous.debitNoteNo != current.debitNoteNo;
      },
      listener: (context, state) {
        // When customer selected via dropdown, autofill name/mobile/address fields
        bool isUpdateMode = widget.debitNoteData != null;

        final customer = state.selectedCustomer;
        if (debitNoteNoController.text != state.debitNoteNo.toString()) {
          debitNoteNoController.text = state.debitNoteNo.toString();
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
          // If a selectedCustomer existed earlier, use that name as default cash name
          if (state.selectedCustomer != null) {
            cusNameController.text = state.selectedCustomer!.name;
            cashMobileController.text = state.selectedCustomer!.mobile;
            cashBillingController.text = state.selectedCustomer!.billingAddress;
            cashShippingController.text =
                state.selectedCustomer!.shippingAddress;
          }
        }
        if (state.transPlaceOfSupply != null &&
            state.transPlaceOfSupply!.isNotEmpty) {
          stateController.text = state.transPlaceOfSupply!;
          return; // 🚨 customer logic SKIP
        }
      },
      child: Scaffold(
        key: debitNoteNavigatorKey,
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
            '${widget.debitNoteData == null ? "Create" : "Update"} Credit Note',
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
                      "${widget.debitNoteData == null ? "Save" : "Update"} Credit Note",
                  height: 40,
                  width: 190,
                  onTap: () {
                    bloc.add(
                      DebitNoteSaveWithUIData(
                        customerName: cusNameController.text,
                        mobile: cashMobileController.text,
                        billingAddress: cashBillingController.text,
                        shippingAddress: cashShippingController.text,
                        notes: noteController.text.trim().isEmpty
                            ? []
                            : [noteController.text.trim()],
                        terms: selectedTermsList,
                        signatureImage: null,
                        updateId: widget.debitNoteData?.id,
                        stateName: stateController.text,
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
        body: BlocBuilder<DebitNoteBloc, DebitNoteState>(
          builder: (context, state) {
            return SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  GlobalHeaderCard(
                    billTo: GlobalBillToCard(
                      ispurchase: false,
                      // --------- STATE VALUES ---------
                      isCashSale: state.cashSaleDefault,
                      focusNode: _customerFocus,
                      customers: state.customers,
                      selectedCustomer: state.selectedCustomer,
                      onSearchLedger: (text) async => [],

                      // --------- CONTROLLERS ---------
                      cusNameController: cusNameController,
                      mobileController: cashMobileController,
                      billingController: cashBillingController,
                      shippingController: cashShippingController,
                      stateController: stateController,

                      // --------- LOGIC CALLBACKS ---------
                      onToggleCashSale: () {
                        bloc.add(
                          DebitNoteToggleCashSale(!state.cashSaleDefault),
                        );

                        if (state.cashSaleDefault) {
                          // clearing when disabling direct sale
                          cusNameController.clear();
                          cashMobileController.clear();
                          cashBillingController.clear();
                          cashShippingController.clear();
                        }
                      },

                      onCustomerSelected: (customer) {
                        bloc.add(DebitNoteSelectCustomer(customer));

                        cashMobileController.text = customer.mobile;
                        cashBillingController.text = customer.billingAddress;
                        cashShippingController.text = customer.shippingAddress;
                        stateController.text =
                            customer.state ??
                            Preference.getString(PrefKeys.state);
                      },

                      onCreateCustomer: () => _showCreateCustomerDialog(
                        context.read<DebitNoteBloc>(),
                      ),
                      isReturn: false,
                      isSaleReturn: true,
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
                    details: DebitNoteDetailsCard(
                      prefixController: prefixController,
                      noteNoController: debitNoteNoController,
                      pickedInvoiceDate: pickedInvoiceDate,
                      onTapInvoiceDate: () => _pickDebitNoteDate(
                        context,
                        context.read<DebitNoteBloc>(),
                      ),
                      transNoController: transNoController,
                      prefixTransController: prefixTransController,
                    ),
                  ),

                  SizedBox(height: Sizes.height * .02),
                  NoteItemsTableSection(
                    rows: state.rows, // list of GlobalItemRow
                    hsnList: state.hsnMaster, // list of HsnModel

                    onAddRow: () => bloc.add(DebitNoteAddRow()),

                    onRemoveRow: (id) => bloc.add(DebitNoteRemoveRow(id)),

                    onUpdateRow: (row) => bloc.add(DebitNoteUpdateRow(row)),

                    onSelectHsn: (rowId, hsn) =>
                        bloc.add(DebitNoteApplyHsnToRow(rowId, hsn)),
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
                          termId: '6',
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
                                  bloc.add(DebitNoteToggleRoundOff(v)),

                              additionalChargesSection:
                                  GlobalAdditionalChargesSection(
                                    charges: state.charges,
                                    onAddCharge: (c) =>
                                        bloc.add(DebitNoteAddCharge(c)),
                                    onRemoveCharge: (id) =>
                                        bloc.add(DebitNoteRemoveCharge(id)),
                                  ),

                              miscChargesSection: GlobalMiscChargesSection(
                                miscCharges: state.miscCharges,
                                miscList: miscList,
                                onAddMisc: (m) =>
                                    bloc.add(DebitNoteAddMiscCharge(m)),
                                onRemoveMisc: (id) =>
                                    bloc.add(DebitNoteRemoveMiscCharge(id)),
                              ),

                              discountSection: GlobalDiscountsSection(
                                discounts: state.discounts,
                                onAddDiscount: (d) =>
                                    bloc.add(DebitNoteAddDiscount(d)),
                                onRemoveDiscount: (id) =>
                                    bloc.add(DebitNoteRemoveDiscount(id)),
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

  void _showCreateCustomerDialog(DebitNoteBloc bloc) {
    final nameCtrl = TextEditingController();
    final stateCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Create Customer'),
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
              final res = await ApiService.postData('customer', {
                "customer_type": "Individual",
                'company_name': nameCtrl.text.trim(),
                'state': stateCtrl.text.trim(),
                'licence_no': Preference.getint(PrefKeys.licenseNo).toString(),
                'branch_id': Preference.getString(PrefKeys.locationId),
              }, licenceNo: Preference.getint(PrefKeys.licenseNo));
              if (res != null && res['status'] == true) {
                showCustomSnackbarSuccess(context, 'Customer created');
                bloc.add(
                  DebitNoteLoadInit(),
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

  void _editAddresses(DebitNoteState state, DebitNoteBloc bloc) {
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
}
