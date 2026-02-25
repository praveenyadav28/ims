import 'dart:typed_data';

import 'package:dotted_border/dotted_border.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:ims/ui/master/misc/misc_charge_model.dart';
import 'package:ims/ui/purchase/purchase_return/state/purchase_return_bloc.dart';
import 'package:ims/ui/purchase/purchase_return/widgets/purchase_return_details.dart';
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
import 'package:ims/ui/sales/models/purchase_return_data.dart';
import 'package:ims/utils/api.dart';
import 'package:ims/utils/button.dart';
import 'package:ims/utils/colors.dart';
import 'package:ims/utils/prefence.dart';
import 'package:ims/utils/sizes.dart';
import 'package:ims/utils/snackbar.dart';
import 'package:ims/utils/state_cities.dart';
import 'package:searchfield/searchfield.dart';

class CreatePurchaseReturnFullScreen extends StatelessWidget {
  final GLobalRepository repo;
  final PurchaseReturnData? purchaseReturnData;

  CreatePurchaseReturnFullScreen({
    Key? key,
    GLobalRepository? repo,
    this.purchaseReturnData,
  }) : repo = repo ?? GLobalRepository(),
       super(key: key);

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) =>
          PurchaseReturnBloc(repo: repo)
            ..add(PurchaseReturnLoadInit(existing: purchaseReturnData)),
      child: CreatePurchaseReturnView(purchaseReturnData: purchaseReturnData),
    );
  }
}

class CreatePurchaseReturnView extends StatefulWidget {
  final PurchaseReturnData? purchaseReturnData;

  const CreatePurchaseReturnView({Key? key, this.purchaseReturnData})
    : super(key: key);

  @override
  State<CreatePurchaseReturnView> createState() =>
      _CreatePurchaseReturnViewState();
}

class _CreatePurchaseReturnViewState extends State<CreatePurchaseReturnView> {
  final prefixController = TextEditingController(text: "");
  final purchaseReturnNoController = TextEditingController();
  final cusNameController = TextEditingController();
  final cashMobileController = TextEditingController();
  final cashBillingController = TextEditingController();
  final cashShippingController = TextEditingController();
  DateTime pickedPurchaseReturnDate = DateTime.now();
  final stateController = TextEditingController();
  SearchFieldListItem<String>? selectedState;
  late List<String> statesSuggestions;
  String signatureImageUrl = '';

  Uint8List? signatureImage;
  final ImagePicker picker = ImagePicker();

  List<String> selectedNotesList = [];
  List<String> selectedTermsList = [];
  List<MiscChargeModelList> miscList = [];

  bool printAfterSave = false;
  void onTogglePrint(bool value) {
    setState(() {
      printAfterSave = value;
    });
  }

  @override
  void initState() {
    super.initState();

    statesSuggestions = stateCities.keys.toList();
    if (widget.purchaseReturnData != null) {
      final e = widget.purchaseReturnData!;

      // Prefill names / mobile
      cusNameController.text = e.supplierName;
      cashMobileController.text = e.mobile;

      cashBillingController.text = e.address0;
      cashShippingController.text = e.address1;
      stateController.text = e.placeOfSupply;

      pickedPurchaseReturnDate = e.purchaseReturnDate;

      selectedNotesList = e.notes;
      selectedTermsList = e.terms;
      signatureImageUrl = e.signature;

      if (e.caseSale == true) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          context.read<PurchaseReturnBloc>().add(
            PurchaseReturnToggleCashSale(true),
          );
        });
      } else {
        // Ensure BLoC reflects non-cash mode for editing
        WidgetsBinding.instance.addPostFrameCallback((_) {
          context.read<PurchaseReturnBloc>().add(
            PurchaseReturnToggleCashSale(false),
          );
          if (e.supplierId != null && e.supplierId!.isNotEmpty) {
            // find customer from loaded list (may be empty until load completes)
            final cands = context.read<PurchaseReturnBloc>().state.customers;
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
            context.read<PurchaseReturnBloc>().add(
              PurchaseReturnSelectCustomer(found),
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
    purchaseReturnNoController.dispose();
    cusNameController.dispose();
    cashMobileController.dispose();
    cashBillingController.dispose();
    cashShippingController.dispose();
    super.dispose();
  }

  Future<void> _pickPurchaseReturnDate(
    BuildContext ctx,
    PurchaseReturnBloc bloc,
  ) async {
    final date = await showDatePicker(
      context: ctx,
      initialDate: pickedPurchaseReturnDate,
      firstDate: DateTime(1990),
      lastDate: DateTime(2100),
    );
    if (date != null) {
      pickedPurchaseReturnDate = date;

      bloc.emit(bloc.state.copyWith(purchaseReturnDate: date));
      bloc.add(PurchaseReturnCalculate());
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
    final bloc = context.read<PurchaseReturnBloc>();

    return BlocListener<PurchaseReturnBloc, PurchaseReturnState>(
      listenWhen: (previous, current) {
        // Only listen when selectedCustomer or cashSaleDefault or purchaseReturnNo changes
        return previous.selectedCustomer != current.selectedCustomer ||
            previous.cashSaleDefault != current.cashSaleDefault ||
            previous.purchaseReturnNo != current.purchaseReturnNo;
      },
      listener: (context, state) {
        // When customer selected via dropdown, autofill name/mobile/address fields
        bool isUpdateMode = widget.purchaseReturnData != null;

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
          stateController.text = state.transPlaceOfSupply!;
          return; // 🚨 customer logic SKIP
        }
        purchaseReturnNoController.text = state.purchaseReturnNo.toString();
      },
      child: Scaffold(
        key: purchaseReturnNavigatorKey,
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
            '${widget.purchaseReturnData == null ? "Create" : "Update"} Purchase Return',
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
                  text: "Save Purchase Return",
                  height: 40,
                  width: 189,
                  onTap: () {
                    bloc.add(
                      PurchaseReturnSaveWithUIData(
                        supplierName: cusNameController.text,
                        mobile: cashMobileController.text,
                        billingAddress: cashBillingController.text,
                        shippingAddress: cashShippingController.text,
                        notes: selectedNotesList,
                        terms: selectedTermsList,
                        signatureImage: signatureImage,
                        updateId: widget.purchaseReturnData?.id,
                        stateName: stateController.text,
                        printAfterSave: printAfterSave,
                      ),
                    );
                  },
                ),  const SizedBox(width: 10),
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
        body: BlocBuilder<PurchaseReturnBloc, PurchaseReturnState>(
          builder: (context, state) {
            purchaseReturnNoController.text = state.purchaseReturnNo.toString();

            return SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  GlobalHeaderCard(
                    billTo: GlobalBillToCard(
                      isCashSale: state.cashSaleDefault,
                      customers: state.customers,
                      selectedCustomer: state.selectedCustomer,

                      cusNameController: cusNameController,
                      mobileController: cashMobileController,
                      billingController: cashBillingController,
                      shippingController: cashShippingController,
                      stateController: stateController,

                      onToggleCashSale: () {
                        bloc.add(
                          PurchaseReturnToggleCashSale(!state.cashSaleDefault),
                        );

                        if (state.cashSaleDefault) {
                          cusNameController.clear();
                          cashMobileController.clear();
                          cashBillingController.clear();
                          cashShippingController.clear();
                        }
                      },

                      onCustomerSelected: (customer) {
                        bloc.add(PurchaseReturnSelectCustomer(customer));
                        cashMobileController.text = customer.mobile;
                        cashBillingController.text = customer.billingAddress;
                        cashShippingController.text = customer.shippingAddress;
                        stateController.text =
                            customer.state ??
                            Preference.getString(PrefKeys.state);
                      },

                      onCreateCustomer: () => _showCreateCustomerDialog(
                        context.read<PurchaseReturnBloc>(),
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

                    details: PurchaseReturnDetailsCard(
                      prefixController: prefixController,
                      purchaseReturnNoController: purchaseReturnNoController,
                      pickedPurchaseReturnDate: pickedPurchaseReturnDate,
                      onTapPurchaseReturnDate: () => _pickPurchaseReturnDate(
                        context,
                        context.read<PurchaseReturnBloc>(),
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
                    onAddRow: () => bloc.add(PurchaseReturnAddRow()),
                    onRemoveRow: (id) => bloc.add(PurchaseReturnRemoveRow(id)),
                    onUpdateRow: (row) =>
                        bloc.add(PurchaseReturnUpdateRow(row)),
                    onSelectCatalog: (id, item) =>
                        bloc.add(PurchaseReturnSelectCatalogForRow(id, item)),
                    onSelectHsn: (id, hsn) =>
                        bloc.add(PurchaseReturnApplyHsnToRow(id, hsn)),
                    onToggleUnit: (id, value) =>
                        bloc.add(PurchaseReturnToggleUnitForRow(id, value)),
                    isReturn: false,
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
                                  bloc.add(PurchaseReturnToggleRoundOff(v)),

                              additionalChargesSection:
                                  GlobalAdditionalChargesSection(
                                    charges: state.charges,
                                    onAddCharge: (c) =>
                                        bloc.add(PurchaseReturnAddCharge(c)),
                                    onRemoveCharge: (id) => bloc.add(
                                      PurchaseReturnRemoveCharge(id),
                                    ),
                                  ),

                              miscChargesSection: GlobalMiscChargesSection(
                                miscCharges: state.miscCharges,
                                miscList: miscList,
                                onAddMisc: (m) =>
                                    bloc.add(PurchaseReturnAddMiscCharge(m)),
                                onRemoveMisc: (id) => bloc.add(
                                  PurchaseReturnRemoveMiscCharge(id),
                                ),
                              ),

                              discountSection: GlobalDiscountsSection(
                                discounts: state.discounts,
                                onAddDiscount: (d) =>
                                    bloc.add(PurchaseReturnAddDiscount(d)),
                                onRemoveDiscount: (id) =>
                                    bloc.add(PurchaseReturnRemoveDiscount(id)),
                              ),
                            ),

                            SizedBox(height: Sizes.height * .02),
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

  void _showCreateCustomerDialog(PurchaseReturnBloc bloc) {
    final nameCtrl = TextEditingController();
    final mobileCtrl = TextEditingController();
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
              final res = await ApiService.postData('supplier', {
                "customer_type": "Individual",
                'company_name': nameCtrl.text.trim(),
                'mobile': mobileCtrl.text.trim(),
                'licence_no': Preference.getint(PrefKeys.licenseNo).toString(),
                'branch_id': Preference.getString(PrefKeys.locationId),
              }, licenceNo: Preference.getint(PrefKeys.licenseNo));
              if (res != null && res['status'] == true) {
                showCustomSnackbarSuccess(context, 'Supplier created');
                bloc.add(
                  PurchaseReturnLoadInit(),
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

  void _editAddresses(PurchaseReturnState state, PurchaseReturnBloc bloc) {
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
