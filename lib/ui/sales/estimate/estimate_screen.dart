// create_estimate_fullscreen.dart
import 'dart:io';

import 'package:dotted_border/dotted_border.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:ims/ui/master/misc/misc_charge_model.dart';
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
import 'package:ims/utils/snackbar.dart';

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
  final prefixController = TextEditingController(text: 'EST');
  final estimateNoController = TextEditingController();
  final cusNameController = TextEditingController();
  final cashMobileController = TextEditingController();
  final cashBillingController = TextEditingController();
  final cashShippingController = TextEditingController();
  final validForController = TextEditingController();
  DateTime pickedEstimateDate = DateTime.now();
  DateTime? pickedValidityDate;
  String signatureImageUrl = '';

  File? signatureImage;
  final ImagePicker picker = ImagePicker();

  List<String> selectedNotesList = [];
  List<String> selectedTermsList = [];
  List<MiscChargeModelList> miscList = [];
  @override
  void initState() {
    super.initState();

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

      // set estimate dates & validity
      pickedEstimateDate = e.estimateDate;
      pickedValidityDate = e.estimateDate.add(Duration(days: e.paymentTerms));

      selectedNotesList = e.notes;
      selectedTermsList = e.terms;
      signatureImageUrl = e.signature;

      // If the estimate is a cash sale, enable cash sale mode in BLoC.
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

    // fetch misc etc.
    fetchMiscCharges();
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
      firstDate: DateTime(2020),
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

  // ---------------- PICK IMAGE ----------------
  Future<void> pickImage(String target) async {
    final XFile? picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked == null) return;
    setState(() {
      final file = File(picked.path);
      if (target == 'signature') signatureImage = file;
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
    final bloc = context.read<EstBloc>();

    return BlocListener<EstBloc, EstState>(
      listenWhen: (previous, current) {
        // Only listen when selectedCustomer or cashSaleDefault or estimateNo changes
        return previous.selectedCustomer != current.selectedCustomer ||
            previous.cashSaleDefault != current.cashSaleDefault ||
            previous.estimateNo != current.estimateNo;
      },
      listener: (context, state) {
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

        // Sync estimate number if repo sets it after load
        estimateNoController.text = state.estimateNo.toString();

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
                  text: "Save Estimate",
                  height: 40,
                  width: 149,
                  onTap: () {
                    bloc.add(
                      EstSaveWithUIData(
                        customerName: cusNameController.text,
                        mobile: cashMobileController.text,
                        billingAddress: cashBillingController.text,
                        shippingAddress: cashShippingController.text,
                        notes: selectedNotesList,
                        terms: selectedTermsList,
                        signatureImage: signatureImage,
                        updateId: widget.estimateData?.id,
                      ),
                    );
                  },
                ),
                const SizedBox(width: 18),
              ],
            ),
          ],
        ),
        body: BlocBuilder<EstBloc, EstState>(
          builder: (context, state) {
            // keep estimate number in sync (repo may set it)
            estimateNoController.text = state.estimateNo.toString();

            return SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  GlobalHeaderCard(
                    billTo: GlobalBillToCard(
                      ispurchase: false,
                      isCashSale: state.cashSaleDefault,
                      customers: state.customers,
                      selectedCustomer: state.selectedCustomer,

                      cusNameController: cusNameController,
                      mobileController: cashMobileController,
                      billingController: cashBillingController,
                      shippingController: cashShippingController,

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
                        cashShippingController.text = customer.shippingAddress;
                      },

                      onCreateCustomer: () =>
                          _showCreateCustomerDialog(context.read<EstBloc>()),
                    ),

                    shipTo: GlobalShipToCard(
                      billingController: cashBillingController,
                      shippingController: cashShippingController,
                      onEditAddresses: () => _editAddresses(state, bloc),
                    ),

                    details: EstimateDetailsCard(
                      prefixController: prefixController,
                      estimateNoController: estimateNoController,
                      validForController: validForController,
                      pickedEstimateDate: pickedEstimateDate,
                      pickedValidityDate: pickedValidityDate,
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
                    catalogue: state.catalogue,
                    hsnList: state.hsnMaster,
                    onAddRow: () => bloc.add(EstAddRow()),
                    onRemoveRow: (id) => bloc.add(EstRemoveRow(id)),
                    onUpdateRow: (row) => bloc.add(EstUpdateRow(row)),
                    onSelectCatalog: (id, item) =>
                        bloc.add(EstSelectCatalogForRow(id, item)),
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
                                onAddMisc: (m) => bloc.add(EstAddMiscCharge(m)),
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
                                  child: (signatureImage == null)
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
                                      : ClipRRect(
                                          borderRadius: BorderRadius.circular(
                                            6,
                                          ),
                                          child: Image.file(
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

  void _showCreateCustomerDialog(EstBloc bloc) {
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
                  EstLoadInit(),
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
}
