import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:ims/ui/master/misc/misc_charge_model.dart';
import 'package:ims/ui/sales/data/create_cust_dialogue.dart';
import 'package:ims/ui/sales/data/global_additionalcharge.dart';
import 'package:ims/ui/sales/data/global_billto.dart';
import 'package:ims/ui/sales/data/global_discount.dart';
import 'package:ims/ui/sales/data/global_item_table.dart';
import 'package:ims/ui/sales/data/global_repository.dart';
import 'package:ims/ui/sales/data/global_shipto.dart';
import 'package:ims/ui/sales/data/globalmisc_charge.dart';
import 'package:ims/ui/sales/data/globalnotes_section.dart';
import 'package:ims/ui/sales/data/globalsummary_card.dart';
import 'package:ims/ui/sales/dilivery_chalan/state/dilivery_bloc.dart';
import 'package:ims/ui/sales/dilivery_chalan/widgets/detials.dart';
import 'package:ims/ui/sales/models/dilivery_data.dart';
import 'package:ims/ui/sales/models/global_models.dart';
import 'package:ims/ui/sales/data/globalheader.dart';
import 'package:ims/utils/api.dart';
import 'package:ims/utils/button.dart';
import 'package:ims/utils/colors.dart';
import 'package:ims/utils/prefence.dart';
import 'package:ims/utils/sizes.dart';
import 'package:ims/utils/state_cities.dart';
import 'package:searchfield/searchfield.dart';

class CreateDiliveryChallanFullScreen extends StatelessWidget {
  final GLobalRepository repo;
  final DiliveryChallanData? diliveryChallanData;

  CreateDiliveryChallanFullScreen({
    Key? key,
    GLobalRepository? repo,
    this.diliveryChallanData,
  }) : repo = repo ?? GLobalRepository(),
       super(key: key);

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) =>
          DiliveryChallanBloc(repo: repo)
            ..add(DiliveryChallanLoadInit(existing: diliveryChallanData)),
      child: CreateDiliveryChallanView(
        diliveryChallanData: diliveryChallanData,
      ),
    );
  }
}

class CreateDiliveryChallanView extends StatefulWidget {
  final DiliveryChallanData? diliveryChallanData;

  const CreateDiliveryChallanView({Key? key, this.diliveryChallanData})
    : super(key: key);

  @override
  State<CreateDiliveryChallanView> createState() =>
      _CreateDiliveryChallanViewState();
}

class _CreateDiliveryChallanViewState extends State<CreateDiliveryChallanView> {
  final GLobalRepository repo;
  _CreateDiliveryChallanViewState({GLobalRepository? repo})
    : repo = repo ?? GLobalRepository();
  final prefixController = TextEditingController();
  final invoiceNoController = TextEditingController();
  final cusNameController = TextEditingController();
  final cashMobileController = TextEditingController();
  final cashBillingController = TextEditingController();
  final cashShippingController = TextEditingController();
  final noteController = TextEditingController();
  final transNoController = TextEditingController();
  final prefixTransController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  DateTime pickedInvoiceDate = DateTime.now();
  final stateController = TextEditingController();
  SearchFieldListItem<String>? selectedState;
  late List<String> statesSuggestions;

  List<String> selectedNotesList = [];
  List<String> selectedTermsList = [];
  List<MiscChargeModelList> miscList = [];

  Timer? _ledgerDebounce;
  Timer? _itemDebounce;
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

  final FocusNode _customerFocus = FocusNode();
  @override
  void initState() {
    super.initState();

    statesSuggestions = stateCities.keys.toList();
    if (widget.diliveryChallanData != null) {
      final e = widget.diliveryChallanData!;
      cusNameController.text = e.customerName;
      cashMobileController.text = e.mobile;
      cashBillingController.text = e.address0;
      cashShippingController.text = e.address1;
      stateController.text = e.placeOfSupply;
      pickedInvoiceDate = e.diliveryChallanDate;
      if (widget.diliveryChallanData != null) {
        noteController.text = widget.diliveryChallanData!.notes.join(", ");
      }
      selectedTermsList = e.terms;
      transNoController.text = e.transNo.toString();
      prefixTransController.text = e.transPre.toString();
      if (e.caseSale == true) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          context.read<DiliveryChallanBloc>().add(
            DiliveryChallanToggleCashSale(true),
          );
        });
      } else {
        // Ensure BLoC reflects non-cash mode for editing
        WidgetsBinding.instance.addPostFrameCallback((_) {
          context.read<DiliveryChallanBloc>().add(
            DiliveryChallanToggleCashSale(false),
          );
          if (e.customerId != null && e.customerId!.isNotEmpty) {
            // find customer from loaded list (may be empty until load completes)
            final cands = context.read<DiliveryChallanBloc>().state.customers;
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
            context.read<DiliveryChallanBloc>().add(
              DiliveryChallanSelectCustomer(found),
            );
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
    invoiceNoController.dispose();
    cusNameController.dispose();
    cashMobileController.dispose();
    cashBillingController.dispose();
    cashShippingController.dispose();
    super.dispose();
  }

  Future<void> _pickChallanDate(
    BuildContext ctx,
    DiliveryChallanBloc bloc,
  ) async {
    final date = await showDatePicker(
      context: ctx,
      initialDate: pickedInvoiceDate,
      firstDate: DateTime(1990),
      lastDate: DateTime(2100),
    );
    if (date != null) {
      pickedInvoiceDate = date;
      bloc.add(DiliveryChallanCalculate());
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
    final bloc = context.read<DiliveryChallanBloc>();

    return BlocListener<DiliveryChallanBloc, DiliveryChallanState>(
      listenWhen: (previous, current) {
        // Only listen when selectedCustomer or cashSaleDefault or DiliveryChallanNo changes
        return previous.selectedCustomer != current.selectedCustomer ||
            previous.cashSaleDefault != current.cashSaleDefault ||
            previous.diliveryChallanNo != current.diliveryChallanNo;
      },
      listener: (context, state) {
        // When customer selected via dropdown, autofill name/mobile/address fields
        bool isUpdateMode = widget.diliveryChallanData != null;

        final customer = state.selectedCustomer;
        if (invoiceNoController.text != state.diliveryChallanNo.toString()) {
          invoiceNoController.text = state.diliveryChallanNo.toString();
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
      },
      child: Scaffold(
        key: diliveryChallanNavigatorKey,
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
            '${widget.diliveryChallanData == null ? "Create" : "Update"} Dilivery Challan',
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
                      "${widget.diliveryChallanData == null ? "Create" : "Update"} Dilivery Challan",
                  height: 40,
                  width: 190,
                  onTap: () {
                    bloc.add(
                      DiliveryChallanSaveWithUIData(
                        customerName: cusNameController.text,
                        mobile: cashMobileController.text,
                        billingAddress: cashBillingController.text,
                        shippingAddress: cashShippingController.text,
                        stateName: stateController.text,
                        notes: noteController.text.trim().isEmpty
                            ? []
                            : [noteController.text.trim()],
                        terms: selectedTermsList,
                        signatureImage: null,
                        updateId: widget.diliveryChallanData?.id,

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
        body: BlocBuilder<DiliveryChallanBloc, DiliveryChallanState>(
          builder: (context, state) {
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
                        // --------- STATE VALUES ---------
                        isCashSale: state.cashSaleDefault,
                        customers: state.customers,
                        selectedCustomer: state.selectedCustomer,
                        onSearchLedger: (text) => _searchLedgerDebounced(text),
                        focusNode: _customerFocus,

                        // --------- CONTROLLERS ---------
                        cusNameController: cusNameController,
                        mobileController: cashMobileController,
                        billingController: cashBillingController,
                        shippingController: cashShippingController,
                        stateController: stateController,

                        // --------- LOGIC CALLBACKS ---------
                        onToggleCashSale: () {
                          bloc.add(
                            DiliveryChallanToggleCashSale(
                              !state.cashSaleDefault,
                            ),
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
                          bloc.add(DiliveryChallanSelectCustomer(customer));

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
                            bloc.add(DiliveryChallanLoadInit());
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
                      details: DiliveryChallanDetailsCard(
                        prefixController: prefixController,
                        invoiceNoController: invoiceNoController,
                        pickedInvoiceDate: pickedInvoiceDate,
                        onTapInvoiceDate: () => _pickChallanDate(
                          context,
                          context.read<DiliveryChallanBloc>(),
                        ),
                        transNoController: transNoController,
                        prefixTransController: prefixTransController,
                      ),
                    ),

                    SizedBox(height: Sizes.height * .03),
                    GlobalItemsTableSection(
                      ledgerType:
                          state.selectedCustomer?.ledgerType ?? 'Individual',
                      rows: state.rows, // list of GlobalItemRow
                      catalogue: state.catalogue, // list of ItemServiceModel
                      hsnList: state.hsnMaster, // list of HsnModel

                      onAddNextRow: () =>
                          bloc.add(DiliveryChallanAddRow()), // ✅ ADD THIS
                      onAddRow: () => bloc.add(DiliveryChallanAddRow()),

                      onRemoveRow: (id) =>
                          bloc.add(DiliveryChallanRemoveRow(id)),
                      onSearchItem: (text) => _searchItemDebounced(text),
                      onUpdateRow: (row) =>
                          bloc.add(DiliveryChallanUpdateRow(row)),

                      onSelectCatalog: (rowId, item) {
                        bloc.add(
                          DiliveryChallanSelectCatalogForRow(rowId, item),
                        );

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
                      onSelectHsn: (rowId, hsn) =>
                          bloc.add(DiliveryChallanApplyHsnToRow(rowId, hsn)),

                      onToggleUnit: (rowId, value) => bloc.add(
                        DiliveryChallanToggleUnitForRow(rowId, value),
                      ),
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
                            termId: '4',
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
                                    bloc.add(DiliveryChallanToggleRoundOff(v)),

                                additionalChargesSection:
                                    GlobalAdditionalChargesSection(
                                      charges: state.charges,
                                      onAddCharge: (c) =>
                                          bloc.add(DiliveryChallanAddCharge(c)),
                                      onRemoveCharge: (id) => bloc.add(
                                        DiliveryChallanRemoveCharge(id),
                                      ),
                                    ),

                                miscChargesSection: GlobalMiscChargesSection(
                                  miscCharges: state.miscCharges,
                                  miscList: miscList,
                                  onAddMisc: (m) =>
                                      bloc.add(DiliveryChallanAddMiscCharge(m)),
                                  onRemoveMisc: (id) => bloc.add(
                                    DiliveryChallanRemoveMiscCharge(id),
                                  ),
                                ),

                                discountSection: GlobalDiscountsSection(
                                  discounts: state.discounts,
                                  onAddDiscount: (d) =>
                                      bloc.add(DiliveryChallanAddDiscount(d)),
                                  onRemoveDiscount: (id) => bloc.add(
                                    DiliveryChallanRemoveDiscount(id),
                                  ),
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

  void _editAddresses(DiliveryChallanState state, DiliveryChallanBloc bloc) {
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
