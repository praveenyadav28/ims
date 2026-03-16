import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:ims/model/ledger_model.dart';
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
import 'package:ims/ui/sales/models/global_models.dart';
import 'package:ims/ui/sales/data/globalheader.dart';
import 'package:ims/ui/sales/models/sale_invoice_data.dart';
import 'package:ims/ui/sales/sale_invoice/state/invoice_bloc.dart';
import 'package:ims/ui/sales/sale_invoice/widgets/detials.dart';
import 'package:ims/utils/api.dart';
import 'package:ims/utils/button.dart';
import 'package:ims/utils/colors.dart';
import 'package:ims/utils/prefence.dart';
import 'package:ims/utils/sizes.dart';
import 'package:ims/utils/state_cities.dart';
import 'package:ims/utils/textfield.dart';
import 'package:searchfield/searchfield.dart';

class CreateSaleInvoiceFullScreen extends StatelessWidget {
  final GLobalRepository repo;
  final SaleInvoiceData? saleInvoiceData;

  CreateSaleInvoiceFullScreen({
    Key? key,
    GLobalRepository? repo,
    this.saleInvoiceData,
  }) : repo = repo ?? GLobalRepository(),
       super(key: key);

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) =>
          SaleInvoiceBloc(repo: repo)
            ..add(SaleInvoiceLoadInit(existing: saleInvoiceData)),
      child: CreateSaleInvoiceView(saleInvoiceData: saleInvoiceData),
    );
  }
}

class CreateSaleInvoiceView extends StatefulWidget {
  final SaleInvoiceData? saleInvoiceData;

  const CreateSaleInvoiceView({Key? key, this.saleInvoiceData})
    : super(key: key);

  @override
  State<CreateSaleInvoiceView> createState() => _CreateSaleInvoiceViewState();
}

class _CreateSaleInvoiceViewState extends State<CreateSaleInvoiceView> {
  final GLobalRepository repo;

  _CreateSaleInvoiceViewState({GLobalRepository? repo})
    : repo = repo ?? GLobalRepository();
  final prefixController = TextEditingController();
  final invoiceNoController = TextEditingController();
  final cusNameController = TextEditingController();
  final cashMobileController = TextEditingController();
  final cashBillingController = TextEditingController();
  final payingAmtController = TextEditingController();
  final cashShippingController = TextEditingController();
  final voucherNoController = TextEditingController();
  final salesPersonController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  DateTime pickedInvoiceDate = DateTime.now();
  final stateController = TextEditingController();
  SearchFieldListItem<String>? selectedState;
  late List<String> statesSuggestions;

  List<LedgerListModel> ledgerList = [];
  LedgerListModel? selectedLedger;

  List<String> selectedNotesList = [];
  List<String> selectedTermsList = [];
  List<MiscChargeModelList> miscList = [];

  bool fullyPaid = false;

  String balanceAmt = "";

  void onToggleFPaid(bool value) {
    setState(() {
      fullyPaid = value;
    });
  }

  bool printAfterSave = false;
  void onTogglePrint(bool value) {
    setState(() {
      printAfterSave = value;
    });
  }

  final FocusNode _customerFocus = FocusNode();
  @override
  void initState() {
    super.initState();
    statesSuggestions = stateCities.keys.toList();

    if (widget.saleInvoiceData != null) {
      final e = widget.saleInvoiceData!;
      cusNameController.text = e.customerName;
      cashMobileController.text = e.mobile;
      cashBillingController.text = e.address0;
      cashShippingController.text = e.address1;
      stateController.text = e.placeOfSupply;
      pickedInvoiceDate = e.saleInvoiceDate;
      selectedNotesList = e.notes;
      selectedTermsList = e.terms;

      if (e.caseSale == true) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          context.read<SaleInvoiceBloc>().add(SaleInvoiceToggleCashSale(true));
        });
      } else {
        // Ensure BLoC reflects non-cash mode for editing
        WidgetsBinding.instance.addPostFrameCallback((_) {
          context.read<SaleInvoiceBloc>().add(SaleInvoiceToggleCashSale(false));
          if (e.customerId != null && e.customerId!.isNotEmpty) {
            // find customer from loaded list (may be empty until load completes)
            final cands = context.read<SaleInvoiceBloc>().state.customers;
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
            context.read<SaleInvoiceBloc>().add(
              SaleInvoiceSelectCustomer(found),
            );
          }
        });
      }
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _customerFocus.requestFocus();
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<SaleInvoiceBloc>().add(SaleInvoiceLoadCustomers());
    });
    // fetch misc etc.
    fetchMiscCharges();
    getAutoVoucherApi();
    ledgerApi();
  }

  @override
  void dispose() {
    prefixController.dispose();
    _customerFocus.dispose();
    invoiceNoController.dispose();
    cusNameController.dispose();
    cashMobileController.dispose();
    cashBillingController.dispose();
    cashShippingController.dispose();
    super.dispose();
  }

  Future<void> _pickSaleInvoiceDate(
    BuildContext ctx,
    SaleInvoiceBloc bloc,
  ) async {
    final date = await showDatePicker(
      context: ctx,
      initialDate: pickedInvoiceDate,
      firstDate: DateTime(1990),
      lastDate: DateTime(2100),
    );
    if (date != null) {
      pickedInvoiceDate = date;
      bloc.add(SaleInvoiceCalculate());
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
    final bloc = context.read<SaleInvoiceBloc>();

    return BlocListener<SaleInvoiceBloc, SaleInvoiceState>(
      listenWhen: (previous, current) {
        // Only listen when selectedCustomer or cashSaleDefault or saleInvoiceNo changes
        return previous.selectedCustomer != current.selectedCustomer ||
            previous.cashSaleDefault != current.cashSaleDefault ||
            previous.saleInvoiceNo != current.saleInvoiceNo;
      },
      listener: (context, state) {
        // When customer selected via dropdown, autofill name/mobile/address fields
        bool isUpdateMode = widget.saleInvoiceData != null;

        final customer = state.selectedCustomer;
        if (invoiceNoController.text != state.saleInvoiceNo) {
          invoiceNoController.text = state.saleInvoiceNo;
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
          setState(() {
            stateController.text = state.transPlaceOfSupply!;
          });
          return; // 🚨 customer logic skip
        }
      },
      child: Scaffold(
        key: saleInvoiceNavigatorKey,
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
            '${widget.saleInvoiceData == null ? "Create" : "Update"} Sale Invoice',
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
                      "${widget.saleInvoiceData == null ? "Create" : "Update"} Sale Invoice",
                  height: 40,
                  width: 190,
                  onTap: () {
                    bloc.add(
                      SaleInvoiceSaveWithUIData(
                        customerName: cusNameController.text,
                        mobile: cashMobileController.text,
                        billingAddress: cashBillingController.text,
                        shippingAddress: cashShippingController.text,
                        notes: selectedNotesList,
                        terms: selectedTermsList,
                        signatureImage: null,
                        updateId: widget.saleInvoiceData?.id,
                        stateName: stateController.text,
                        printAfterSave: printAfterSave,
                      ),
                    );

                    if (payingAmtController.text.isNotEmpty &&
                        double.tryParse(payingAmtController.text) != null &&
                        double.parse(payingAmtController.text) > 0 &&
                        selectedLedger != null) {
                      bloc.add(
                        SaleInvoiceSavePayment(
                          voucherNo: voucherNoController.text,
                          amount: payingAmtController.text,
                          ledger: selectedLedger!,
                          date: pickedInvoiceDate,
                        ),
                      );
                    }
                  },
                ),
                const SizedBox(width: 10),
                Checkbox(
                  fillColor: WidgetStatePropertyAll(AppColor.primary),
                  shape: ContinuousRectangleBorder(
                    borderRadius: BorderRadiusGeometry.circular(5),
                  ),
                  value: printAfterSave,
                  onChanged: (v) {
                    onTogglePrint(v ?? true);
                    setState(() {});
                  },
                ),
                Text(
                  "Print   ",
                  style: GoogleFonts.inter(
                    fontSize: 15,
                    color: AppColor.black,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ],
        ),
        body: BlocBuilder<SaleInvoiceBloc, SaleInvoiceState>(
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
                        focusNode: _customerFocus,
                        ispurchase: false,
                        // --------- STATE VALUES ---------
                        isCashSale: state.cashSaleDefault,
                        customers: state.customers,
                        onSearchLedger: (text) => repo.searchLedger(text, true),
                        selectedCustomer: state.selectedCustomer,

                        // --------- CONTROLLERS ---------
                        cusNameController: cusNameController,
                        mobileController: cashMobileController,
                        billingController: cashBillingController,
                        shippingController: cashShippingController,
                        stateController: stateController,

                        // --------- LOGIC CALLBACKS ---------
                        onToggleCashSale: () {
                          bloc.add(
                            SaleInvoiceToggleCashSale(!state.cashSaleDefault),
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
                          bloc.add(SaleInvoiceSelectCustomer(customer));

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
                            bloc.add(SaleInvoiceLoadInit());
                          },
                        ),
                      ),
                      shipTo: GlobalShipToCard(
                        billingController: cashBillingController,
                        shippingController: cashShippingController,
                        stateController: stateController,
                        statesSuggestions: statesSuggestions,
                        onStateSelected: (state) {
                          selectedState = SearchFieldListItem(state);
                        },
                        onEditAddresses: () => _editAddresses(state, bloc),
                      ),

                      details: SaleInvoiceDetailsCard(
                        prefixController: prefixController,
                        invoiceNoController: invoiceNoController,
                        pickedInvoiceDate: pickedInvoiceDate,
                        onTapInvoiceDate: () => _pickSaleInvoiceDate(
                          context,
                          context.read<SaleInvoiceBloc>(),
                        ),
                      ),
                    ),

                    SizedBox(height: Sizes.height * .03),
                    GlobalItemsTableSection(
                      ledgerType:
                          state.selectedCustomer?.ledgerType ?? 'Individual',
                      rows: state.rows,
                      catalogue: state.catalogue,
                      hsnList: state.hsnMaster,
                      onAddNextRow: () =>
                          bloc.add(SaleInvoiceAddRow()), // ✅ ADD THIS
                      onAddRow: () {
                        bloc.add(SaleInvoiceAddRow());
                      },
                      onRemoveRow: (id) => bloc.add(SaleInvoiceRemoveRow(id)),
                      onUpdateRow: (row) => bloc.add(SaleInvoiceUpdateRow(row)),

                      onSelectCatalog: (rowId, item) {
                        bloc.add(SaleInvoiceSelectCatalogForRow(rowId, item));

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
                          bloc.add(SaleInvoiceApplyHsnToRow(rowId, hsn)),

                      onToggleUnit: (rowId, value) =>
                          bloc.add(SaleInvoiceToggleUnitForRow(rowId, value)),

                      onSearchItem: (text) => repo.searchItems(text),
                    ),
                    SizedBox(height: Sizes.height * .02),

                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          flex: 10,
                          child: GlobalNotesSection(
                            initialNotes: selectedNotesList,
                            initialTerms: selectedTermsList,
                            onNotesChanged: (list) => selectedNotesList = list,
                            onTermsChanged: (list) => selectedTermsList = list,
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
                                    bloc.add(SaleInvoiceToggleRoundOff(v)),

                                additionalChargesSection:
                                    GlobalAdditionalChargesSection(
                                      charges: state.charges,
                                      onAddCharge: (c) =>
                                          bloc.add(SaleInvoiceAddCharge(c)),
                                      onRemoveCharge: (id) =>
                                          bloc.add(SaleInvoiceRemoveCharge(id)),
                                    ),

                                miscChargesSection: GlobalMiscChargesSection(
                                  miscCharges: state.miscCharges,
                                  miscList: miscList,
                                  onAddMisc: (m) =>
                                      bloc.add(SaleInvoiceAddMiscCharge(m)),
                                  onRemoveMisc: (id) =>
                                      bloc.add(SaleInvoiceRemoveMiscCharge(id)),
                                ),

                                discountSection: GlobalDiscountsSection(
                                  discounts: state.discounts,
                                  onAddDiscount: (d) =>
                                      bloc.add(SaleInvoiceAddDiscount(d)),
                                  onRemoveDiscount: (id) =>
                                      bloc.add(SaleInvoiceRemoveDiscount(id)),
                                ),
                              ),
                              if (widget.saleInvoiceData == null)
                                Column(
                                  children: [
                                    SizedBox(height: Sizes.height * .02),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.end,
                                      children: [
                                        Text(
                                          "Mark as fully paid",
                                          style: GoogleFonts.inter(
                                            fontSize: 15,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
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
                                          value: fullyPaid,
                                          onChanged: (v) {
                                            onToggleFPaid(v ?? true);
                                            setState(() {});
                                            payingAmtController.text = state
                                                .totalAmount
                                                .toString();
                                          },
                                        ),
                                      ],
                                    ),
                                    SizedBox(height: Sizes.height * .02),
                                    Row(
                                      children: [
                                        Text(
                                          "Amount Paid",
                                          style: GoogleFonts.inter(
                                            fontSize: 15,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                        Spacer(flex: 2),
                                        Expanded(
                                          flex: 3,
                                          child: Row(
                                            children: [
                                              Container(
                                                height: 45,
                                                width: 30,
                                                decoration: BoxDecoration(
                                                  color:
                                                      AppColor.backgroundColor,
                                                  border: Border.all(
                                                    color: AppColor.borderColor,
                                                  ),
                                                ),
                                                child: Icon(
                                                  Icons.currency_rupee_sharp,
                                                  color: Color(0xff565D6D),
                                                  size: 18,
                                                ),
                                              ),
                                              Expanded(
                                                child: Container(
                                                  height: 45,
                                                  decoration: BoxDecoration(
                                                    border: Border.all(
                                                      color:
                                                          AppColor.borderColor,
                                                    ),
                                                  ),
                                                  alignment: Alignment.center,
                                                  child: TextField(
                                                    controller:
                                                        payingAmtController,
                                                    readOnly: fullyPaid,
                                                    onChanged: (v) {
                                                      setState(() {
                                                        balanceAmt =
                                                            "${state.totalAmount - double.parse(v)}";
                                                      });
                                                    },
                                                    style: GoogleFonts.inter(
                                                      color: AppColor.text,
                                                      fontSize: 14,
                                                      fontWeight:
                                                          FontWeight.w500,
                                                    ),
                                                    decoration: InputDecoration(
                                                      hintText: "0",
                                                      contentPadding:
                                                          EdgeInsets.symmetric(
                                                            vertical: 4,
                                                            horizontal: 10,
                                                          ),
                                                      border:
                                                          OutlineInputBorder(
                                                            borderSide:
                                                                BorderSide.none,
                                                          ),
                                                    ),
                                                  ),
                                                ),
                                              ),
                                              Expanded(
                                                child: Container(
                                                  height: 45,
                                                  decoration: BoxDecoration(
                                                    border: Border.all(
                                                      color:
                                                          AppColor.borderColor,
                                                    ),
                                                  ),
                                                  alignment: Alignment.center,
                                                  child: DropdownButton<LedgerListModel>(
                                                    padding:
                                                        EdgeInsets.symmetric(
                                                          vertical: 4,
                                                          horizontal: 10,
                                                        ),
                                                    underline: const SizedBox(),
                                                    isExpanded: true,
                                                    icon: const Icon(
                                                      Icons.keyboard_arrow_down,
                                                    ),

                                                    value: selectedLedger,

                                                    hint: Text(
                                                      "Select Ledger",
                                                      style: GoogleFonts.inter(
                                                        fontSize: 14,
                                                        fontWeight:
                                                            FontWeight.w500,
                                                      ),
                                                    ),
                                                    items: ledgerList.map((
                                                      ledger,
                                                    ) {
                                                      return DropdownMenuItem<
                                                        LedgerListModel
                                                      >(
                                                        value: ledger,
                                                        child: Text(
                                                          ledger.ledgerName ??
                                                              "",
                                                          style:
                                                              GoogleFonts.inter(
                                                                fontSize: 14,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .w500,
                                                                color: AppColor
                                                                    .textColor,
                                                              ),
                                                        ),
                                                      );
                                                    }).toList(),

                                                    onChanged:
                                                        (LedgerListModel? v) {
                                                          setState(() {
                                                            selectedLedger = v;
                                                          });
                                                        },
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                    SizedBox(height: Sizes.height * .02),
                                    Row(
                                      children: [
                                        Text(
                                          "Voucher Number",
                                          style: GoogleFonts.inter(
                                            fontSize: 15,
                                            color: Color(0xff22C55E),
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                        Spacer(),
                                        Expanded(
                                          child: CommonTextField(
                                            hintText: "Voucher No",
                                            controller: voucherNoController,
                                          ),
                                        ),
                                      ],
                                    ),

                                    SizedBox(height: Sizes.height * .02),
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

  void _editAddresses(SaleInvoiceState state, SaleInvoiceBloc bloc) {
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

  Future getAutoVoucherApi() async {
    var response = await ApiService.fetchData(
      "get/autonumber",
      licenceNo: Preference.getint(PrefKeys.licenseNo),
    );

    if (response['status'] == true) {
      voucherNoController.text = response['nextno'].toString();
    }
  }
}
