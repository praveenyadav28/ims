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
import 'package:ims/utils/snackbar.dart';

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
  final prefixController = TextEditingController();
  final invoiceNoController = TextEditingController();
  final cusNameController = TextEditingController();
  final cashMobileController = TextEditingController();
  final cashBillingController = TextEditingController();
  final cashShippingController = TextEditingController();
  DateTime pickedInvoiceDate = DateTime.now();
  String signatureImageUrl = '';

  File? signatureImage;
  final ImagePicker picker = ImagePicker();

  List<String> selectedNotesList = [];
  List<String> selectedTermsList = [];
  List<MiscChargeModelList> miscList = [];
  @override
  void initState() {
    super.initState();

    if (widget.diliveryChallanData != null) {
      final e = widget.diliveryChallanData!;
      cusNameController.text = e.customerName;
      cashMobileController.text = e.mobile;
      cashBillingController.text = e.address0;
      cashShippingController.text = e.address1;
      pickedInvoiceDate = e.diliveryChallanDate;
      selectedNotesList = e.notes;
      selectedTermsList = e.terms;
      signatureImageUrl = e.signature;

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
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (date != null) {
      pickedInvoiceDate = date;
      bloc.add(DiliveryChallanCalculate());
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

        invoiceNoController.text = state.diliveryChallanNo.toString();
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
                  text: "Save Dilivery Challan",
                  height: 40,
                  width: 179,
                  onTap: () {
                    bloc.add(
                      DiliveryChallanSaveWithUIData(
                        customerName: cusNameController.text,
                        mobile: cashMobileController.text,
                        billingAddress: cashBillingController.text,
                        shippingAddress: cashShippingController.text,
                        notes: selectedNotesList,
                        terms: selectedTermsList,
                        signatureImage: signatureImage,
                        updateId: widget.diliveryChallanData?.id,
                      ),
                    );
                  },
                ),
                const SizedBox(width: 18),
              ],
            ),
          ],
        ),
        body: BlocBuilder<DiliveryChallanBloc, DiliveryChallanState>(
          builder: (context, state) {
            invoiceNoController.text = state.diliveryChallanNo.toString();

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

                      // --------- LOGIC CALLBACKS ---------
                      onToggleCashSale: () {
                        bloc.add(
                          DiliveryChallanToggleCashSale(!state.cashSaleDefault),
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
                        bloc.add(DiliveryChallanSelectCustomer(customer));

                        cashMobileController.text = customer.mobile;
                        cashBillingController.text = customer.billingAddress;
                        cashShippingController.text = customer.shippingAddress;
                      },

                      onCreateCustomer: () => _showCreateCustomerDialog(
                        context.read<DiliveryChallanBloc>(),
                      ),
                    ),
                    shipTo: GlobalShipToCard(
                      billingController: cashBillingController,
                      shippingController: cashShippingController,
                      onEditAddresses: () => _editAddresses(state, bloc),
                    ),
                    details: DiliveryChallanDetailsCard(
                      prefixController: prefixController,
                      invoiceNoController: invoiceNoController,
                      pickedInvoiceDate: pickedInvoiceDate,
                      onTapInvoiceDate: () => _pickChallanDate(
                        context,
                        context.read<DiliveryChallanBloc>(),
                      ),
                    ),
                  ),

                  SizedBox(height: Sizes.height * .03),
                  GlobalItemsTableSection(
                    rows: state.rows, // list of GlobalItemRow
                    catalogue: state.catalogue, // list of ItemServiceModel
                    hsnList: state.hsnMaster, // list of HsnModel

                    onAddRow: () => bloc.add(DiliveryChallanAddRow()),

                    onRemoveRow: (id) => bloc.add(DiliveryChallanRemoveRow(id)),

                    onUpdateRow: (row) =>
                        bloc.add(DiliveryChallanUpdateRow(row)),

                    onSelectCatalog: (rowId, item) => bloc.add(
                      DiliveryChallanSelectCatalogForRow(rowId, item),
                    ),

                    onSelectHsn: (rowId, hsn) =>
                        bloc.add(DiliveryChallanApplyHsnToRow(rowId, hsn)),

                    onToggleUnit: (rowId, value) =>
                        bloc.add(DiliveryChallanToggleUnitForRow(rowId, value)),
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
                                onRemoveDiscount: (id) =>
                                    bloc.add(DiliveryChallanRemoveDiscount(id)),
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

  void _showCreateCustomerDialog(DiliveryChallanBloc bloc) {
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
                  DiliveryChallanLoadInit(),
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
}
