import 'dart:io';

import 'package:dotted_border/dotted_border.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:ims/ui/master/misc/misc_charge_model.dart';
import 'package:ims/ui/sales/estimate/data/estimate_repository.dart';
import 'package:ims/ui/sales/estimate/models/estimate_models.dart';
import 'package:ims/ui/sales/estimate/models/estimateget_model.dart';
import 'package:ims/ui/sales/estimate/state/estimate_bloc.dart';
import 'package:ims/ui/sales/estimate/widgets/bill_to_card.dart';
import 'package:ims/ui/sales/estimate/widgets/estimate_details_card.dart';
import 'package:ims/ui/sales/estimate/widgets/estimate_header.dart';
import 'package:ims/ui/sales/estimate/widgets/items_table.dart';
import 'package:ims/ui/sales/estimate/widgets/notes_section.dart';
import 'package:ims/ui/sales/estimate/widgets/ship_to_card.dart';
import 'package:ims/ui/sales/estimate/widgets/summary_card.dart';
import 'package:ims/utils/api.dart';
import 'package:ims/utils/button.dart';
import 'package:ims/utils/colors.dart';
import 'package:ims/utils/prefence.dart';
import 'package:ims/utils/sizes.dart';
import 'package:ims/utils/snackbar.dart';

class CreateEstimateFullScreen extends StatelessWidget {
  final EstimateRepository repo;
  final EstimateData? estimateData;

  CreateEstimateFullScreen({
    Key? key,
    EstimateRepository? repo,
    this.estimateData,
  }) : repo = repo ?? EstimateRepository(),
       super(key: key);

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => EstBloc(repo: repo)..add(EstLoadInit()),
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

  File? signatureImage;
  final ImagePicker picker = ImagePicker();

  List<String> selectedNotesList = [];
  List<String> selectedTermsList = [];
  List<MiscChargeModelList> miscList = [];

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
      bloc.add(EstCalculate());
      bloc.emit(
        bloc.state.copyWith(
          estimateDate: date,
          validityDate: pickedValidityDate,
        ),
      );
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

  String signatureUrl = "";

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
      bloc.add(EstCalculate());
      bloc.emit(
        bloc.state.copyWith(
          estimateDate: pickedEstimateDate,
          validityDate: pickedValidityDate,
        ),
      );
    }
  }

  @override
  void initState() {
    super.initState();
    fetchMiscCharges(); // <- YEHI CALL KARNA HAI
  }

  @override
  Widget build(BuildContext context) {
    final bloc = context.read<EstBloc>();

    return Scaffold(
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
          'Create Estimate',
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
          estimateNoController.text = state.estimateNo.toString();
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                EstimateHeaderCard(
                  billTo: BillToCard(
                    state: state,
                    bloc: bloc,
                    cusNameController: cusNameController,
                    cashMobileController: cashMobileController,
                    cashBillingController: cashBillingController,
                    cashShippingController: cashShippingController,
                    onCreateCustomer: () =>
                        _showCreateCustomerDialog(context.read<EstBloc>()),
                  ),
                  shipTo: ShipToCard(
                    state: state,
                    cashBillingController: cashBillingController,
                    cashShippingController: cashShippingController,
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
                      bloc.add(EstCalculate());
                    },
                  ),
                ),
                SizedBox(height: Sizes.height * .03),
                ItemsTableSection(state: state, bloc: bloc),
                SizedBox(height: Sizes.height * .02),

                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 10,
                      child: NotesSection(
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
                          SummaryCard(
                            state: state,
                            bloc: bloc,
                            miscList: miscList,
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
                                        signatureUrl.isEmpty)
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
                                        borderRadius: BorderRadius.circular(6),
                                        child: signatureImage != null
                                            ? Image.file(
                                                signatureImage!,
                                                fit: BoxFit.cover,
                                                width: double.infinity,
                                                height: 125,
                                              )
                                            : Image.network(
                                                signatureUrl,
                                                fit: BoxFit.cover,
                                                width: double.infinity,
                                                height: 125,
                                                errorBuilder: (_, __, ___) =>
                                                    Center(
                                                      child: Column(
                                                        mainAxisAlignment:
                                                            MainAxisAlignment
                                                                .center,
                                                        children: const [
                                                          Icon(
                                                            Icons.add,
                                                            size: 30,
                                                          ),
                                                          SizedBox(height: 12),
                                                          Text(
                                                            "+ Add Signature",
                                                          ),
                                                        ],
                                                      ),
                                                    ),
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
                bloc.add(EstLoadInit());
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

                final updatedList = List<CustomerModel>.from(state.customers);
                updatedList[index] = CustomerModel(
                  id: state.selectedCustomer!.id,
                  name: state.selectedCustomer!.name,
                  mobile: state.selectedCustomer!.mobile,
                  billingAddress: billing.text,
                  shippingAddress: shipping.text,
                );

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

  Future<void> fetchMiscCharges() async {
    final res = await ApiService.fetchData(
      "get/misccharge",
      licenceNo: Preference.getint(PrefKeys.licenseNo),
    );

    if (res["status"] == true) {
      miscList = (res["data"] as List)
          .map((e) => MiscChargeModelList.fromJson(e))
          .toList();
      setState(() {});
    }
  }
}
