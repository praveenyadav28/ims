import 'dart:io';

import 'package:dotted_border/dotted_border.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:ims/ui/master/misc/misc_charge_model.dart';
import 'package:ims/ui/purchase/purchase_order/state/purchase_order_bloc.dart';
import 'package:ims/ui/purchase/purchase_order/widgets/purchase_order_details.dart';
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
import 'package:ims/ui/sales/models/purchaseorder_model.dart';
import 'package:ims/utils/api.dart';
import 'package:ims/utils/button.dart';
import 'package:ims/utils/colors.dart';
import 'package:ims/utils/prefence.dart';
import 'package:ims/utils/sizes.dart';
import 'package:ims/utils/snackbar.dart';
import 'package:ims/utils/state_cities.dart';
import 'package:searchfield/searchfield.dart';

class CreatePurchaseOrderFullScreen extends StatelessWidget {
  final GLobalRepository repo;
  final PurchaseOrderData? purchaseOrderData;

  CreatePurchaseOrderFullScreen({
    Key? key,
    GLobalRepository? repo,
    this.purchaseOrderData,
  }) : repo = repo ?? GLobalRepository(),
       super(key: key);

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) =>
          PurchaseOrderBloc(repo: repo)
            ..add(PurchaseOrderLoadInit(existing: purchaseOrderData)),
      child: CreatePurchaseOrderView(purchaseOrderData: purchaseOrderData),
    );
  }
}

class CreatePurchaseOrderView extends StatefulWidget {
  final PurchaseOrderData? purchaseOrderData;

  const CreatePurchaseOrderView({Key? key, this.purchaseOrderData})
    : super(key: key);

  @override
  State<CreatePurchaseOrderView> createState() =>
      _CreatePurchaseOrderViewState();
}

class _CreatePurchaseOrderViewState extends State<CreatePurchaseOrderView> {
  final prefixController = TextEditingController(text: "");
  final purchaseOrderNoController = TextEditingController();
  final cusNameController = TextEditingController();
  final cashMobileController = TextEditingController();
  final cashBillingController = TextEditingController();
  final cashShippingController = TextEditingController();
  final validForController = TextEditingController();
  DateTime pickedPurchaseOrderDate = DateTime.now();
  final stateController = TextEditingController();
  SearchFieldListItem<String>? selectedState;
  late List<String> statesSuggestions;
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

    statesSuggestions = stateCities.keys.toList();
    if (widget.purchaseOrderData != null) {
      final e = widget.purchaseOrderData!;

      // always set payment terms field (so UI shows days)
      validForController.text = e.paymentTerms.toString();

      // Prefill names / mobile
      cusNameController.text = e.supplierName;
      cashMobileController.text = e.mobile;

      cashBillingController.text = e.address0;
      cashShippingController.text = e.address1;
      stateController.text = e.placeOfSupply.isNotEmpty
          ? e.placeOfSupply
          : Preference.getString(PrefKeys.state);

      pickedPurchaseOrderDate = e.purchaseOrderDate;
      pickedValidityDate = e.purchaseOrderDate.add(
        Duration(days: e.paymentTerms),
      );

      selectedNotesList = e.notes;
      selectedTermsList = e.terms;
      signatureImageUrl = e.signature;

      if (e.caseSale == true) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          context.read<PurchaseOrderBloc>().add(
            PurchaseOrderToggleCashSale(true),
          );
        });
      } else {
        // Ensure BLoC reflects non-cash mode for editing
        WidgetsBinding.instance.addPostFrameCallback((_) {
          context.read<PurchaseOrderBloc>().add(
            PurchaseOrderToggleCashSale(false),
          );
          if (e.supplierId != null && e.supplierId!.isNotEmpty) {
            // find customer from loaded list (may be empty until load completes)
            final cands = context.read<PurchaseOrderBloc>().state.customers;
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
            context.read<PurchaseOrderBloc>().add(
              PurchaseOrderSelectCustomer(found),
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
    purchaseOrderNoController.dispose();
    cusNameController.dispose();
    cashMobileController.dispose();
    cashBillingController.dispose();
    cashShippingController.dispose();
    validForController.dispose();
    super.dispose();
  }

  Future<void> _pickPurchaseOrderDate(
    BuildContext ctx,
    PurchaseOrderBloc bloc,
  ) async {
    final date = await showDatePicker(
      context: ctx,
      initialDate: pickedPurchaseOrderDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (date != null) {
      pickedPurchaseOrderDate = date;
      final days = int.tryParse(validForController.text) ?? 0;
      pickedValidityDate = days > 0
          ? date.add(Duration(days: days))
          : pickedValidityDate;
      bloc.emit(
        bloc.state.copyWith(
          purchaseOrderDate: date,
          validityDate: pickedValidityDate,
        ),
      );
      bloc.add(PurchaseOrderCalculate());
      setState(() {});
    }
  }

  Future<void> _pickValidityDate(
    BuildContext ctx,
    PurchaseOrderBloc bloc,
  ) async {
    final date = await showDatePicker(
      context: ctx,
      initialDate: pickedValidityDate ?? pickedPurchaseOrderDate,
      firstDate: pickedPurchaseOrderDate,
      lastDate: DateTime(2100),
    );
    if (date != null) {
      pickedValidityDate = date;
      validForController.text = date
          .difference(pickedPurchaseOrderDate)
          .inDays
          .toString();
      bloc.emit(
        bloc.state.copyWith(
          purchaseOrderDate: pickedPurchaseOrderDate,
          validityDate: pickedValidityDate,
        ),
      );
      bloc.add(PurchaseOrderCalculate());
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
    final bloc = context.read<PurchaseOrderBloc>();

    return BlocListener<PurchaseOrderBloc, PurchaseOrderState>(
      listenWhen: (previous, current) {
        // Only listen when selectedCustomer or cashSaleDefault or purchaseOrderNo changes
        return previous.selectedCustomer != current.selectedCustomer ||
            previous.cashSaleDefault != current.cashSaleDefault ||
            previous.purchaseOrderNo != current.purchaseOrderNo;
      },
      listener: (context, state) {
        // When customer selected via dropdown, autofill name/mobile/address fields
        bool isUpdateMode = widget.purchaseOrderData != null;

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

        purchaseOrderNoController.text = state.purchaseOrderNo.toString();

        // validity days sync (if BLoC has validForDays)
        validForController.text = state.validForDays.toString();
      },
      child: Scaffold(
        key: purchaseOrderNavigatorKey,
        backgroundColor: AppColor.white,
        appBar: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: BlocBuilder<PurchaseOrderBloc, PurchaseOrderState>(
            builder: (context, state) {
              return AppBar(
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
                  '${widget.purchaseOrderData == null ? "Create" : "Update"} Purchase Order',
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
                      if (state.catalogue.any((i) {
                        final stock = int.tryParse(i.stockQty ?? '0') ?? 0;
                        final reorder = int.tryParse(i.reOLevel) ?? 0;
                        return stock <= reorder;
                      }))
                        defaultButton(
                          buttonColor: const Color.fromARGB(255, 225, 157, 20),
                          text: "Fill Low Stock",
                          height: 40,
                          width: 163,
                          onTap: () {
                            context.read<PurchaseOrderBloc>().add(
                              PurchaseOrderAddLowStockItems(),
                            );
                          },
                        ),

                      const SizedBox(width: 18),
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
                        text: "Save Purchase Order",
                        height: 40,
                        width: 189,
                        onTap: () {
                          bloc.add(
                            PurchaseOrderSaveWithUIData(
                              supplierName: cusNameController.text,
                              mobile: cashMobileController.text,
                              billingAddress: cashBillingController.text,
                              shippingAddress: cashShippingController.text,
                              notes: selectedNotesList,
                              terms: selectedTermsList,
                              signatureImage: signatureImage,
                              updateId: widget.purchaseOrderData?.id,
                            ),
                          );
                        },
                      ),
                      const SizedBox(width: 18),
                    ],
                  ),
                ],
              );
            },
          ),
        ),
        body: BlocBuilder<PurchaseOrderBloc, PurchaseOrderState>(
          builder: (context, state) {
            purchaseOrderNoController.text = state.purchaseOrderNo.toString();

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
                      ispurchase: true,
                      onToggleCashSale: () {
                        bloc.add(
                          PurchaseOrderToggleCashSale(!state.cashSaleDefault),
                        );

                        if (state.cashSaleDefault) {
                          cusNameController.clear();
                          cashMobileController.clear();
                          cashBillingController.clear();
                          cashShippingController.clear();
                        }
                      },

                      onCustomerSelected: (customer) {
                        bloc.add(PurchaseOrderSelectCustomer(customer));
                        cashMobileController.text = customer.mobile;
                        cashBillingController.text = customer.billingAddress;
                        cashShippingController.text = customer.shippingAddress;
                        stateController.text =
                            customer.state ??
                            Preference.getString(PrefKeys.state);
                      },

                      onCreateCustomer: () => _showCreateCustomerDialog(
                        context.read<PurchaseOrderBloc>(),
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

                    details: PurchaseOrderDetailsCard(
                      prefixController: prefixController,
                      purchaseOrderNoController: purchaseOrderNoController,
                      validForController: validForController,
                      pickedPurchaseOrderDate: pickedPurchaseOrderDate,
                      pickedValidityDate: pickedValidityDate,
                      onTapPurchaseOrderDate: () => _pickPurchaseOrderDate(
                        context,
                        context.read<PurchaseOrderBloc>(),
                      ),
                      onTapValidityDate: () => _pickValidityDate(
                        context,
                        context.read<PurchaseOrderBloc>(),
                      ),
                      onValidForChanged: (value) {
                        final days = int.tryParse(value) ?? 0;
                        pickedValidityDate = pickedPurchaseOrderDate.add(
                          Duration(days: days),
                        );
                        // inform bloc about validForDays (keep state consistent)
                        bloc.emit(
                          state.copyWith(
                            validForDays: days,
                            validityDate: pickedValidityDate,
                          ),
                        );
                        bloc.add(PurchaseOrderCalculate());
                        setState(() {});
                      },
                    ),
                  ),

                  SizedBox(height: Sizes.height * .03),
                  GlobalItemsTableSection(
                    rows: state.rows,
                    catalogue: state.catalogue,
                    hsnList: state.hsnMaster,
                    onAddRow: () => bloc.add(PurchaseOrderAddRow()),
                    onRemoveRow: (id) => bloc.add(PurchaseOrderRemoveRow(id)),
                    onUpdateRow: (row) => bloc.add(PurchaseOrderUpdateRow(row)),
                    onSelectCatalog: (id, item) =>
                        bloc.add(PurchaseOrderSelectCatalogForRow(id, item)),
                    onSelectHsn: (id, hsn) =>
                        bloc.add(PurchaseOrderApplyHsnToRow(id, hsn)),
                    onToggleUnit: (id, value) =>
                        bloc.add(PurchaseOrderToggleUnitForRow(id, value)),
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
                                  bloc.add(PurchaseOrderToggleRoundOff(v)),

                              additionalChargesSection:
                                  GlobalAdditionalChargesSection(
                                    charges: state.charges,
                                    onAddCharge: (c) =>
                                        bloc.add(PurchaseOrderAddCharge(c)),
                                    onRemoveCharge: (id) =>
                                        bloc.add(PurchaseOrderRemoveCharge(id)),
                                  ),

                              miscChargesSection: GlobalMiscChargesSection(
                                miscCharges: state.miscCharges,
                                miscList: miscList,
                                onAddMisc: (m) =>
                                    bloc.add(PurchaseOrderAddMiscCharge(m)),
                                onRemoveMisc: (id) =>
                                    bloc.add(PurchaseOrderRemoveMiscCharge(id)),
                              ),

                              discountSection: GlobalDiscountsSection(
                                discounts: state.discounts,
                                onAddDiscount: (d) =>
                                    bloc.add(PurchaseOrderAddDiscount(d)),
                                onRemoveDiscount: (id) =>
                                    bloc.add(PurchaseOrderRemoveDiscount(id)),
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

  void _showCreateCustomerDialog(PurchaseOrderBloc bloc) {
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
                  PurchaseOrderLoadInit(),
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

  void _editAddresses(PurchaseOrderState state, PurchaseOrderBloc bloc) {
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
                  closingBalance: state.selectedCustomer!.closingBalance,
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
