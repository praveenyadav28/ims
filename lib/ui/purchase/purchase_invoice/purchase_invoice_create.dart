import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:ims/model/ledger_model.dart';
import 'package:ims/ui/master/misc/misc_charge_model.dart';
import 'package:ims/ui/purchase/purchase_invoice/state/p_invoice_bloc.dart';
import 'package:ims/ui/purchase/purchase_invoice/widgets/p_invoice_details.dart';
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
import 'package:ims/ui/sales/models/global_models.dart';
import 'package:ims/ui/sales/data/globalsummary_card.dart';
import 'package:ims/ui/sales/models/purcahseinvoice_data.dart';
import 'package:ims/ui/sales/sale_invoice/saleinvoice_create.dart';
import 'package:ims/utils/api.dart';
import 'package:ims/utils/button.dart';
import 'package:ims/utils/colors.dart';
import 'package:ims/utils/prefence.dart';
import 'package:ims/utils/sizes.dart';
import 'package:ims/utils/state_cities.dart';
import 'package:ims/utils/textfield.dart';
import 'package:searchfield/searchfield.dart';

class CreatePurchaseInvoiceFullScreen extends StatelessWidget {
  final GLobalRepository repo;
  final PurchaseInvoiceData? purchaseInvoiceData;

  CreatePurchaseInvoiceFullScreen({
    Key? key,
    GLobalRepository? repo,
    this.purchaseInvoiceData,
  }) : repo = repo ?? GLobalRepository(),
       super(key: key);

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) =>
          PurchaseInvoiceBloc(repo: repo)
            ..add(PurchaseInvoiceLoadInit(existing: purchaseInvoiceData)),
      child: CreatePurchaseInvoiceView(
        purchaseInvoiceData: purchaseInvoiceData,
      ),
    );
  }
}

class CreatePurchaseInvoiceView extends StatefulWidget {
  final PurchaseInvoiceData? purchaseInvoiceData;

  const CreatePurchaseInvoiceView({Key? key, this.purchaseInvoiceData})
    : super(key: key);

  @override
  State<CreatePurchaseInvoiceView> createState() =>
      _CreatePurchaseInvoiceViewState();
}

class _CreatePurchaseInvoiceViewState extends State<CreatePurchaseInvoiceView> {
  final GLobalRepository repo;
  _CreatePurchaseInvoiceViewState({GLobalRepository? repo})
    : repo = repo ?? GLobalRepository();
  final prefixController = TextEditingController(text: "");
  final purchaseInvoiceNoController = TextEditingController();
  final cusNameController = TextEditingController();
  final cashMobileController = TextEditingController();
  final cashBillingController = TextEditingController();
  final cashShippingController = TextEditingController();
  final voucherNoController = TextEditingController();
  DateTime pickedPurchaseInvoiceDate = DateTime.now();
  final noteController = TextEditingController();
  final transNoController = TextEditingController();
  final prefixTransController = TextEditingController();
  final voucherPrefixController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final stateController = TextEditingController();
  SearchFieldListItem<String>? selectedState;
  late List<String> statesSuggestions;
  List<LedgerListModel> ledgerList = [];
  Timer? _ledgerDebounce;
  Timer? _itemDebounce;

  List<String> selectedNotesList = [];
  List<String> selectedTermsList = [];
  List<MiscChargeModelList> miscList = [];

  bool printAfterSave = false;
  bool fullyPaid = false;

  String balanceAmt = "";

  void onToggleFPaid(bool value) {
    setState(() {
      fullyPaid = value;
    });
  }

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
  List<InvoicePaymentRow> paymentRows = [];
  final reminderController = TextEditingController();
  @override
  void initState() {
    super.initState();

    statesSuggestions = stateCities.keys.toList();
    if (widget.purchaseInvoiceData != null) {
      final e = widget.purchaseInvoiceData!;

      // Prefill names / mobile
      cusNameController.text = e.supplierName;
      cashMobileController.text = e.mobile;

      cashBillingController.text = e.address0;
      cashShippingController.text = e.address1;
      stateController.text = e.placeOfSupply;

      pickedPurchaseInvoiceDate = e.purchaseInvoiceDate;
      transNoController.text = e.purchaseorderNo.toString() == "0"
          ? ""
          : e.purchaseorderNo.toString();
      prefixTransController.text = e.purchaseorderPre.toString();
      if (widget.purchaseInvoiceData != null) {
        noteController.text = widget.purchaseInvoiceData!.notes.join(", ");
      }
      selectedTermsList = e.terms;

      if (e.caseSale == true) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          context.read<PurchaseInvoiceBloc>().add(
            PurchaseInvoiceToggleCashSale(true),
          );
        });
      } else {
        // Ensure BLoC reflects non-cash mode for editing
        WidgetsBinding.instance.addPostFrameCallback((_) {
          context.read<PurchaseInvoiceBloc>().add(
            PurchaseInvoiceToggleCashSale(false),
          );
          if (e.supplierId != null && e.supplierId!.isNotEmpty) {
            // find customer from loaded list (may be empty until load completes)
            final cands = context.read<PurchaseInvoiceBloc>().state.customers;
            final found = cands.firstWhere(
              (c) => c.id == e.supplierId,
              orElse: () => LedgerModelDrop(
                id: e.supplierId ?? "",
                name: e.supplierName,
                mobile: e.mobile,
                billingAddress: e.address0,
                shippingAddress: e.address1,
              ),
            );
            context.read<PurchaseInvoiceBloc>().add(
              PurchaseInvoiceSelectCustomer(found),
            );
          }
        });
      }
    }
    if (paymentRows.isEmpty) {
      paymentRows.add(InvoicePaymentRow());
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _customerFocus.requestFocus();
    });

    getAutoVoucherApi();
    ledgerApi();
    // fetch misc etc.
    fetchMiscCharges();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    prefixController.dispose();
    purchaseInvoiceNoController.dispose();
    cusNameController.dispose();
    cashMobileController.dispose();
    cashBillingController.dispose();
    cashShippingController.dispose();
    super.dispose();
  }

  Future<void> _pickPurchaseInvoiceDate(
    BuildContext ctx,
    PurchaseInvoiceBloc bloc,
  ) async {
    final date = await showDatePicker(
      context: ctx,
      initialDate: pickedPurchaseInvoiceDate,
      firstDate: DateTime(1990),
      lastDate: DateTime(2100),
    );
    if (date != null) {
      pickedPurchaseInvoiceDate = date;

      bloc.emit(bloc.state.copyWith(purchaseInvoiceDate: date));
      bloc.add(PurchaseInvoiceCalculate());
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
    final bloc = context.read<PurchaseInvoiceBloc>();

    return BlocListener<PurchaseInvoiceBloc, PurchaseInvoiceState>(
      listenWhen: (previous, current) {
        // Only listen when selectedCustomer or cashSaleDefault or purchaseInvoiceNo changes
        return previous.selectedCustomer != current.selectedCustomer ||
            previous.cashSaleDefault != current.cashSaleDefault ||
            previous.purchaseInvoiceNo != current.purchaseInvoiceNo;
      },
      listener: (context, state) {
        // When customer selected via dropdown, autofill name/mobile/address fields
        bool isUpdateMode = widget.purchaseInvoiceData != null;

        final customer = state.selectedCustomer;
        if (purchaseInvoiceNoController.text !=
            state.purchaseInvoiceNo.toString()) {
          purchaseInvoiceNoController.text = state.purchaseInvoiceNo.toString();
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
        key: purchaseInvoiceNavigatorKey,
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
            '${widget.purchaseInvoiceData == null ? "Create" : "Update"} Purchase Invoice',
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
                      "${widget.purchaseInvoiceData == null ? "Save" : "Update"} Purchase Invoice",
                  height: 40,
                  width: 200,
                  onTap: () {
                    final validRows = paymentRows.where((e) {
                      return e.ledger?.id != null &&
                          e.ledger?.ledgerName != null &&
                          e.amountController.text.trim().isNotEmpty &&
                          double.tryParse(e.amountController.text) != null &&
                          double.parse(e.amountController.text) > 0;
                    }).toList();

                    final ledgerDetails = validRows.map((e) {
                      return {
                        "ledger_id": e.ledger?.id,
                        "ledger_name": e.ledger?.ledgerName,
                        "amount": double.parse(e.amountController.text.trim()),
                      };
                    }).toList();

                    bloc.add(
                      PurchaseInvoiceSaveWithUIData(
                        supplierName: cusNameController.text,
                        mobile: cashMobileController.text,
                        billingAddress: cashBillingController.text,
                        shippingAddress: cashShippingController.text,
                        stateName: stateController.text,
                        notes: noteController.text.trim().isEmpty
                            ? []
                            : [noteController.text.trim()],
                        terms: selectedTermsList,
                        signatureImage: null,
                        updateId: widget.purchaseInvoiceData?.id,
                        printAfterSave: printAfterSave,
                        printSignature: printSignature,

                        // ✅ condition applied
                        ledgerDetails: ledgerDetails,
                        voucherNo: voucherNoController.text,
                        date: pickedPurchaseInvoiceDate,
                        prefix: voucherPrefixController.text,
                      ),
                    );
                  },
                ),
                const SizedBox(width: 10),
              ],
            ),
          ],
        ),
        body: BlocBuilder<PurchaseInvoiceBloc, PurchaseInvoiceState>(
          builder: (context, state) {
            return Scrollbar(
              controller: _scrollController,
              thumbVisibility: true,
              trackVisibility: true,
              child: SingleChildScrollView(
                controller: _scrollController,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    GlobalHeaderCard(
                      billTo: GlobalBillToCard(
                        isCashSale: state.cashSaleDefault,
                        customers: state.customers,
                        focusNode: _customerFocus,
                        selectedCustomer: state.selectedCustomer,
                        stateController: stateController,
                        onSearchLedger: (text) => _searchLedgerDebounced(text),
                        cusNameController: cusNameController,
                        mobileController: cashMobileController,
                        billingController: cashBillingController,
                        shippingController: cashShippingController,

                        onToggleCashSale: () {
                          bloc.add(
                            PurchaseInvoiceToggleCashSale(
                              !state.cashSaleDefault,
                            ),
                          );

                          if (state.cashSaleDefault) {
                            cusNameController.clear();
                            cashMobileController.clear();
                            cashBillingController.clear();
                            cashShippingController.clear();
                          }
                        },

                        onCustomerSelected: (customer) {
                          bloc.add(PurchaseInvoiceSelectCustomer(customer));
                          cashMobileController.text = customer.mobile;
                          cashBillingController.text = customer.billingAddress;
                          cashShippingController.text =
                              customer.shippingAddress;
                          stateController.text = customer.state ?? "";
                        },

                        onCreateCustomer: () => showCreateCustomerDialog(
                          context: context,
                          onCustomerCreated: () {
                            bloc.add(PurchaseInvoiceLoadInit());
                          },
                          isCustomer: false,
                        ),
                        ispurchase: true,
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

                      details: PurchaseInvoiceDetailsCard(
                        prefixController: prefixController,
                        purchaseInvoiceNoController:
                            purchaseInvoiceNoController,
                        pickedPurchaseInvoiceDate: pickedPurchaseInvoiceDate,
                        onTapPurchaseInvoiceDate: () =>
                            _pickPurchaseInvoiceDate(
                              context,
                              context.read<PurchaseInvoiceBloc>(),
                            ),
                        transNoController: transNoController,
                        prefixTransController: prefixTransController,
                      ),
                    ),

                    SizedBox(height: Sizes.height * .02),
                    GlobalItemsTableSection(
                      rows: state.rows,
                      ledgerType:
                          state.selectedCustomer?.ledgerType ?? 'Individual',
                      catalogue: state.catalogue,
                      hsnList: state.hsnMaster,
                      onAddRow: () {
                        bloc.add(PurchaseInvoiceAddRow());
                      },
                      onRemoveRow: (id) =>
                          bloc.add(PurchaseInvoiceRemoveRow(id)),
                      onAddNextRow: () =>
                          bloc.add(PurchaseInvoiceAddRow()), // ✅ ADD THIS
                      onUpdateRow: (row) =>
                          bloc.add(PurchaseInvoiceUpdateRow(row)),
                      onSelectCatalog: (rowId, item) {
                        bloc.add(
                          PurchaseInvoiceSelectCatalogForRow(rowId, item),
                        );

                        WidgetsBinding.instance.addPostFrameCallback((_) {
                          if (_scrollController.hasClients) {
                            _scrollController.animateTo(
                              _scrollController.offset + 75,
                              duration: const Duration(milliseconds: 200),
                              curve: Curves.ease,
                            );
                          }
                        });
                      },
                      onSearchItem: (text) => _searchItemDebounced(text),
                      onSelectHsn: (id, hsn) =>
                          bloc.add(PurchaseInvoiceApplyHsnToRow(id, hsn)),
                      onToggleUnit: (id, value) =>
                          bloc.add(PurchaseInvoiceToggleUnitForRow(id, value)),
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
                            termId: '8',
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
                                    bloc.add(PurchaseInvoiceToggleRoundOff(v)),

                                additionalChargesSection:
                                    GlobalAdditionalChargesSection(
                                      charges: state.charges,
                                      onAddCharge: (c) =>
                                          bloc.add(PurchaseInvoiceAddCharge(c)),
                                      onRemoveCharge: (id) => bloc.add(
                                        PurchaseInvoiceRemoveCharge(id),
                                      ),
                                    ),

                                miscChargesSection: GlobalMiscChargesSection(
                                  miscCharges: state.miscCharges,
                                  miscList: miscList,
                                  onAddMisc: (m) =>
                                      bloc.add(PurchaseInvoiceAddMiscCharge(m)),
                                  onRemoveMisc: (id) => bloc.add(
                                    PurchaseInvoiceRemoveMiscCharge(id),
                                  ),
                                ),

                                discountSection: GlobalDiscountsSection(
                                  discounts: state.discounts,
                                  onAddDiscount: (d) =>
                                      bloc.add(PurchaseInvoiceAddDiscount(d)),
                                  onRemoveDiscount: (id) => bloc.add(
                                    PurchaseInvoiceRemoveDiscount(id),
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
                                ],
                              ),
                              if (widget.purchaseInvoiceData == null)
                                Container(
                                  padding: const EdgeInsets.all(16),
                                  margin: const EdgeInsets.only(top: 10),
                                  decoration: BoxDecoration(
                                    color: AppColor.white,
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(
                                      color: AppColor.borderColor,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: const Color(0xff171a1f14),
                                        blurRadius: 4,
                                        offset: const Offset(0, .5),
                                      ),
                                    ],
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Text(
                                            "Payment Details",
                                            style: GoogleFonts.inter(
                                              fontSize: 16,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                          const Spacer(),

                                          /// FULLY PAID
                                          Row(
                                            children: [
                                              Text(
                                                "Fully Paid",
                                                style: GoogleFonts.inter(
                                                  fontSize: 14,
                                                ),
                                              ),
                                              Checkbox(
                                                value: fullyPaid,
                                                onChanged: (v) {
                                                  onToggleFPaid(v ?? true);
                                                  setState(() {});

                                                  if (fullyPaid) {
                                                    final total =
                                                        state.totalAmount;

                                                    if (paymentRows
                                                        .isNotEmpty) {
                                                      paymentRows
                                                          .first
                                                          .amountController
                                                          .text = total
                                                          .toString();
                                                    }
                                                  }
                                                },
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 14),

                                      /// 🔥 PAYMENT ROWS
                                      ListView.builder(
                                        shrinkWrap: true,
                                        physics:
                                            const NeverScrollableScrollPhysics(),
                                        itemCount: paymentRows.length,
                                        itemBuilder: (context, index) {
                                          final row = paymentRows[index];

                                          return Padding(
                                            padding: const EdgeInsets.only(
                                              bottom: 10,
                                            ),
                                            child: Row(
                                              children: [
                                                /// LEDGER
                                                Expanded(
                                                  flex: 3,
                                                  child:
                                                      CommonDropdownField<
                                                        LedgerListModel
                                                      >(
                                                        value: row.ledger,

                                                        hintText:
                                                            "Payment Mode",

                                                        items: ledgerList.map((
                                                          e,
                                                        ) {
                                                          return DropdownMenuItem(
                                                            value: e,
                                                            child: Text(
                                                              e.ledgerName ??
                                                                  "",
                                                            ),
                                                          );
                                                        }).toList(),
                                                        onChanged: (v) {
                                                          setState(
                                                            () =>
                                                                row.ledger = v,
                                                          );
                                                        },
                                                      ),
                                                ),

                                                const SizedBox(width: 10),

                                                /// AMOUNT
                                                Expanded(
                                                  flex: 2,
                                                  child: CommonTextField(
                                                    controller:
                                                        row.amountController,

                                                    hintText: "Amount",

                                                    onChanged: (v) {
                                                      final amt =
                                                          double.tryParse(v) ??
                                                          0;
                                                      setState(() {
                                                        balanceAmt =
                                                            (state.totalAmount -
                                                                    amt)
                                                                .toStringAsFixed(
                                                                  2,
                                                                );
                                                      });
                                                    },
                                                  ),
                                                ),

                                                /// DELETE
                                                if (paymentRows.length > 1)
                                                  IconButton(
                                                    icon: const Icon(
                                                      Icons.delete,
                                                      color: Colors.red,
                                                    ),
                                                    onPressed: () {
                                                      setState(() {
                                                        paymentRows.removeAt(
                                                          index,
                                                        );
                                                      });
                                                    },
                                                  ),
                                              ],
                                            ),
                                          );
                                        },
                                      ),
                                    ],
                                  ),
                                ),

                              /// ADD BUTTON
                              Align(
                                alignment: Alignment.centerLeft,
                                child: TextButton.icon(
                                  onPressed: () {
                                    setState(() {
                                      paymentRows.add(InvoicePaymentRow());
                                    });
                                  },
                                  icon: const Icon(Icons.add),
                                  label: const Text("Add Receive Mode"),
                                ),
                              ),
                              const SizedBox(height: 10),

                              Row(
                                children: [
                                  Expanded(
                                    child: TitleTextFeild(
                                      controller: voucherPrefixController,
                                      hintText: "Prefix",
                                      titleText: "Prefix",
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: TitleTextFeild(
                                      controller: voucherNoController,
                                      hintText: "Voucher No",
                                      titleText: "Voucher No",
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

  void _editAddresses(PurchaseInvoiceState state, PurchaseInvoiceBloc bloc) {
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

  Future ledgerApi() async {
    var response = await ApiService.fetchData(
      "get/ledger",
      licenceNo: Preference.getint(PrefKeys.licenseNo),
    );

    List responseData = response['data'];

    setState(() {
      ledgerList = responseData
          .where(
            (e) =>
                e['ledger_group'] == 'Bank Account' ||
                e['ledger_group'] == 'Cash In Hand',
          )
          .map((e) => LedgerListModel.fromJson(e))
          .toList();
    });
  }

  Future<List<LedgerModelDrop>> _searchLedgerDebounced(String text) async {
    if (_ledgerDebounce?.isActive ?? false) _ledgerDebounce!.cancel();

    final completer = Completer<List<LedgerModelDrop>>();

    _ledgerDebounce = Timer(const Duration(milliseconds: 200), () async {
      final result = await repo.searchLedger(text, false);
      completer.complete(result);
    });

    return completer.future;
  }

  Future<List<ItemServiceModel>> _searchItemDebounced(String text) async {
    if (_itemDebounce?.isActive ?? false) _itemDebounce!.cancel();

    final completer = Completer<List<ItemServiceModel>>();

    _itemDebounce = Timer(const Duration(milliseconds: 200), () async {
      final result = await repo.searchItems(text);
      completer.complete(result);
    });

    return completer.future;
  }

  Future getAutoVoucherApi() async {
    var response = await ApiService.fetchData(
      "get/autono",
      licenceNo: Preference.getint(PrefKeys.licenseNo),
    );
    if (response['status'] == true) {
      voucherNoController.text = response['next_no'].toString();
      voucherPrefixController.text = response['prefix'].toString();
    }
  }
}
