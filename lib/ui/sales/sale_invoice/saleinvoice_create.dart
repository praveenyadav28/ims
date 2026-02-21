import 'dart:typed_data';
import 'package:dotted_border/dotted_border.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:ims/model/ledger_model.dart';
import 'package:ims/ui/master/misc/misc_charge_model.dart';
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
import 'package:ims/utils/snackbar.dart';
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
  final prefixController = TextEditingController();
  final invoiceNoController = TextEditingController();
  final cusNameController = TextEditingController();
  final cashMobileController = TextEditingController();
  final cashBillingController = TextEditingController();
  final payingAmtController = TextEditingController();
  final cashShippingController = TextEditingController();
  final voucherNoController = TextEditingController();
  DateTime pickedInvoiceDate = DateTime.now();
  final stateController = TextEditingController();
  SearchFieldListItem<String>? selectedState;
  late List<String> statesSuggestions;

  String signatureImageUrl = '';
  List<LedgerListModel> ledgerList = [];
  LedgerListModel? selectedLedger;

  Uint8List? signatureImage;
  final ImagePicker picker = ImagePicker();

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

  @override
  void initState() {
    super.initState();
    statesSuggestions = stateCities.keys.toList();

    getAutoVoucherApi();
    ledgerApi();
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
      signatureImageUrl = e.signature;

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

  Future<void> pickImage(String target) async {
    final XFile? picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked == null) return;

    final bytes = await picked.readAsBytes();
    setState(() {
      if (target == 'signature') signatureImage = bytes;
    });
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
        invoiceNoController.text = state.saleInvoiceNo.toString();
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
                  text: "Save Sale Invoice",
                  height: 40,
                  width: 179,
                  onTap: () {
                    bloc.add(
                      SaleInvoiceSaveWithUIData(
                        customerName: cusNameController.text,
                        mobile: cashMobileController.text,
                        billingAddress: cashBillingController.text,
                        shippingAddress: cashShippingController.text,
                        notes: selectedNotesList,
                        terms: selectedTermsList,
                        signatureImage: signatureImage,
                        updateId: widget.saleInvoiceData?.id,
                        stateName: stateController.text,
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
                const SizedBox(width: 18),
              ],
            ),
          ],
        ),
        body: BlocBuilder<SaleInvoiceBloc, SaleInvoiceState>(
          builder: (context, state) {
            invoiceNoController.text = state.saleInvoiceNo.toString();

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
                      customers: state.customers,
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
                          // clearing when disabling cash sale
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
                        cashShippingController.text = customer.shippingAddress;
                        stateController.text =
                            customer.state ??
                            Preference.getString(PrefKeys.state);
                      },

                      onCreateCustomer: () => _showCreateCustomerDialog(
                        context.read<SaleInvoiceBloc>(),
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
                    rows: state.rows, // list of GlobalItemRow
                    catalogue: state.catalogue, // list of ItemServiceModel
                    hsnList: state.hsnMaster, // list of HsnModel

                    onAddRow: () => bloc.add(SaleInvoiceAddRow()),

                    onRemoveRow: (id) => bloc.add(SaleInvoiceRemoveRow(id)),

                    onUpdateRow: (row) => bloc.add(SaleInvoiceUpdateRow(row)),

                    onSelectCatalog: (rowId, item) =>
                        bloc.add(SaleInvoiceSelectCatalogForRow(rowId, item)),

                    onSelectHsn: (rowId, hsn) =>
                        bloc.add(SaleInvoiceApplyHsnToRow(rowId, hsn)),

                    onToggleUnit: (rowId, value) =>
                        bloc.add(SaleInvoiceToggleUnitForRow(rowId, value)),
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
                                              BorderRadiusGeometry.circular(5),
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
                                                color: AppColor.backgroundColor,
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
                                                    color: AppColor.borderColor,
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
                                                    fontWeight: FontWeight.w500,
                                                  ),
                                                  decoration: InputDecoration(
                                                    hintText: "0",
                                                    contentPadding:
                                                        EdgeInsets.symmetric(
                                                          vertical: 4,
                                                          horizontal: 10,
                                                        ),
                                                    border: OutlineInputBorder(
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
                                                    color: AppColor.borderColor,
                                                  ),
                                                ),
                                                alignment: Alignment.center,
                                                child:
                                                    DropdownButton<
                                                      LedgerListModel
                                                    >(
                                                      padding:
                                                          EdgeInsets.symmetric(
                                                            vertical: 4,
                                                            horizontal: 10,
                                                          ),
                                                      underline:
                                                          const SizedBox(),
                                                      isExpanded: true,
                                                      icon: const Icon(
                                                        Icons
                                                            .keyboard_arrow_down,
                                                      ),

                                                      value: selectedLedger,

                                                      hint: Text(
                                                        "Select Ledger",
                                                        style:
                                                            GoogleFonts.inter(
                                                              fontSize: 14,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .w500,
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
                                                              selectedLedger =
                                                                  v;
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
                                  Row(
                                    children: [
                                      Text(
                                        "Balance",
                                        style: GoogleFonts.inter(
                                          fontSize: 15,
                                          color: Color(0xff22C55E),
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      Spacer(),
                                      Text(
                                        "₹ $balanceAmt",
                                        style: GoogleFonts.inter(
                                          fontSize: 15,
                                          color: Color(0xff22C55E),
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),

                            SizedBox(height: Sizes.height * .03),
                            Row(
                              children: [
                                Text(
                                  "Authorized signatory for ",
                                  style: GoogleFonts.roboto(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w400,
                                    color: AppColor.text,
                                  ),
                                ),
                                Text(
                                  "Business Name",
                                  style: GoogleFonts.roboto(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                    color: AppColor.text,
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: 10),
                            GestureDetector(
                              onTap: () => pickImage('signature'),
                              child: SizedBox(
                                width: double.infinity,
                                height: 110,
                                child: DottedBorder(
                                  options: RoundedRectDottedBorderOptions(
                                    strokeWidth: 1.6,
                                    radius: Radius.circular(6),
                                    dashPattern: [5, 3],
                                    color: AppColor.textLightBlack,
                                  ),
                                  child:
                                      (signatureImage == null &&
                                          signatureImageUrl.trim().isEmpty)
                                      ? Center(
                                          child: Column(
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            children: [
                                              Icon(
                                                Icons.add,
                                                size: 30,
                                                color: AppColor.primary,
                                              ),
                                              SizedBox(height: 12),
                                              Text(
                                                "Add Signature",
                                                style: GoogleFonts.roboto(
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.w500,
                                                  color: AppColor.primary,
                                                ),
                                              ),
                                            ],
                                          ),
                                        )
                                      : (signatureImage == null)
                                      ? ClipRRect(
                                          borderRadius: BorderRadius.circular(
                                            6,
                                          ),
                                          child: Image.network(
                                            signatureImageUrl,
                                            fit: BoxFit.cover,
                                            width: double.infinity,
                                            height: 125,
                                          ),
                                        )
                                      : ClipRRect(
                                          borderRadius: BorderRadius.circular(
                                            6,
                                          ),
                                          child: Image.memory(
                                            signatureImage!,
                                            fit: BoxFit.cover,
                                            width: double.infinity,
                                            height: 125,
                                          ),
                                        ),
                                ),
                              ),
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

  void _showCreateCustomerDialog(SaleInvoiceBloc bloc) {
    final nameCtrl = TextEditingController();
    final mobileCtrl = TextEditingController();
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
              controller: mobileCtrl,
              decoration: const InputDecoration(labelText: 'Mobile'),
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
                'mobile': mobileCtrl.text.trim(),
                'licence_no': Preference.getint(PrefKeys.licenseNo).toString(),
                'branch_id': Preference.getString(PrefKeys.locationId),
              }, licenceNo: Preference.getint(PrefKeys.licenseNo));
              if (res != null && res['status'] == true) {
                showCustomSnackbarSuccess(context, 'Customer created');
                bloc.add(
                  SaleInvoiceLoadInit(),
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
