// ignore_for_file: must_be_immutable

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:ims/model/ledger_model.dart';
import 'package:ims/utils/api.dart';
import 'package:ims/utils/button.dart';
import 'package:ims/utils/colors.dart';
import 'package:ims/utils/prefence.dart';
import 'package:ims/utils/sizes.dart';
import 'package:ims/utils/snackbar.dart';
import 'package:ims/utils/state_cities.dart';
import 'package:ims/utils/textfield.dart';
import 'package:searchfield/searchfield.dart';

class CreateLedger extends StatefulWidget {
  CreateLedger({super.key, this.existing});
  LedgerListModel? existing;

  @override
  State<CreateLedger> createState() => _CreateLedgerState();
}

class _CreateLedgerState extends State<CreateLedger> {
  String _selectedBalance = 'Cr';
  final List<String> _balanceType = ['Cr', 'Dr'];

  String? _selectedLedgerGroup;
  final List<String> _groupLedgerList = [
    'Bank Account',
    'Cash In Hand',
    'Sundry Debtor',
    'Sundry Creditor',
    'Expense',
    'Fixed Asset',
    'Capital',
    'Loans (Liability)',
    'Misc Charges',
  ];

  // // LedgerList? ledgerData;
  // @override
  // void didChangeDependencies() {
  //   super.didChangeDependencies();
  //   final args = ModalRoute.of(context)?.settings.arguments;
  //   if (args != null && ledgerData == null) {
  //     ledgerData = args as LedgerList;

  //     _selectedTitle = ledgerData?.title ?? "";
  //     _selectedsubTitle = ledgerData?.relationType ?? "";
  //     _selectedLedgerGroup = ledgerData?.ledgerGroup ?? "";
  //     _selectedClosingBalance = ledgerData?.openingType ?? "Dr";
  //     _selectedBalance = ledgerData?.openingType ?? "Dr";
  //     ledgerNameController.text = ledgerData?.ledgerName ?? "";
  //     fatherNameController.text = ledgerData?.name ?? "";
  //     _documentImageUrls = ledgerData?.uplodeFile?.cast<String>() ?? [];
  //     contactNoNameController.text = ledgerData?.contactNo ?? "";
  //     emailIdController.text = ledgerData?.email ?? "";
  //     whatsapppNoController.text = ledgerData?.whatsappNo ?? "";
  //     gstNoController.text = ledgerData?.gstNo ?? "";
  //     closingBalanceController.text = ledgerData?.closingBalance ?? "";
  //     openingBalanceController.text = ledgerData?.openingBalance ?? "";
  //     aadharNoController.text = ledgerData?.aadharNo ?? "";
  //     addressLine1Controller.text = ledgerData?.permanentAddress ?? "";
  //     permanentareaController.text = ledgerData?.cityTownVillage ?? "";
  //     permanentpinCodeController.text = ledgerData?.pinCode ?? "";
  //     temporaryAddressController.text = ledgerData?.temporaryAddress ?? "";
  //     temporaryareaController.text = ledgerData?.tcityTownVillage ?? "";
  //     temporarypinCodeController.text = ledgerData?.tpinCode ?? "";
  //     selectedState = SearchFieldListItem<String>(
  //       ledgerData?.state ?? "",
  //       item: ledgerData?.state ?? "",
  //     );
  //     selectedCity = SearchFieldListItem<String>(
  //       ledgerData?.city ?? "",
  //       item: ledgerData?.city ?? "",
  //     );
  //     stateController.text = selectedState?.searchKey ?? '';
  //     cityController.text = selectedCity?.searchKey ?? '';
  //     selectedStateTemp = SearchFieldListItem<String>(
  //       ledgerData?.tstate ?? "",
  //       item: ledgerData?.tstate ?? "",
  //     );
  //     selectedCityTemp = SearchFieldListItem<String>(
  //       ledgerData?.tcity ?? "",
  //       item: ledgerData?.tcity ?? "",
  //     );
  //     tempSateController.text = selectedStateTemp?.searchKey ?? '';
  //     tempCityController.text = selectedCityTemp?.searchKey ?? '';
  //     citiesSuggestions = stateCities[selectedState?.searchKey] ?? [];
  //     citiesSuggestionsTemp = stateCities[selectedStateTemp?.searchKey] ?? [];

  //   }
  // }

  // TextEditingController miscAddNameController = TextEditingController();
  TextEditingController ledgerNameController = TextEditingController();
  // TextEditingController fatherNameController = TextEditingController();
  TextEditingController contactNoNameController = TextEditingController();
  TextEditingController whatsapppNoController = TextEditingController();
  TextEditingController emailIdController = TextEditingController();
  // TextEditingController closingBalanceController = TextEditingController();
  TextEditingController openingBalanceController = TextEditingController(
    text: "0",
  );
  // TextEditingController gstNoController = TextEditingController();
  // TextEditingController aadharNoController = TextEditingController();
  TextEditingController addressLine1Controller = TextEditingController();
  TextEditingController permanentareaController = TextEditingController();

  late List<String> statesSuggestions;
  late List<String> citiesSuggestions;

  late SearchFieldListItem<String>? selectedState;
  late SearchFieldListItem<String>? selectedCity;
  @override
  void initState() {
    statesSuggestions = stateCities.keys.toList();
    citiesSuggestions = [];
    selectedState = null;
    selectedCity = null;
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColor.white,
      appBar: AppBar(
        backgroundColor: AppColor.white,
        // leading: IconButton(
        //   onPressed: () {
        //     Navigator.pop(context, "data");
        //   },
        //   icon: Icon(Icons.arrow_back, color: AppColor.black),
        // ),
        elevation: .4,
        shadowColor: AppColor.grey,
        iconTheme: IconThemeData(color: Colors.black),
        title: Text(
          "Create New Ledger",
          style: GoogleFonts.plusJakartaSans(
            fontSize: 20,
            height: 1,
            fontWeight: FontWeight.w700,
            color: AppColor.blackText,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.only(
          right: Sizes.width * .08,
          left: Sizes.width * .08,
          top: Sizes.height * .05,
          bottom: Sizes.height * .02,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            nameField(
              text: "Ledger Name",
              child: CommonTextField(
                controller: ledgerNameController,
                hintText: "Enter ledger Name",
              ),
            ),
            SizedBox(height: Sizes.height * .02),
            nameField(
              text: "Phone",
              child: Row(
                children: [
                  Expanded(
                    child: CommonTextField(
                      hintText: "Mobile",
                      controller: contactNoNameController,
                    ),
                  ),
                  SizedBox(width: 16),
                  Expanded(
                    child: CommonTextField(
                      hintText: "Whatsapp No. (Optional)",
                      controller: whatsapppNoController,
                    ),
                  ),
                ],
              ),
            ),

            SizedBox(height: Sizes.height * .02),
            nameField(
              text: "Email Address",
              child: CommonTextField(
                hintText: "Email",
                controller: emailIdController,
              ),
            ),

            SizedBox(height: Sizes.height * .02),
            nameField(
              text: "Ledger Group",
              child: CommonDropdownField<String>(
                hintText: "Enter ledger group",
                value: _selectedLedgerGroup,
                onChanged: (value) {
                  setState(() {
                    _selectedLedgerGroup = value;
                  });
                },
                items: _groupLedgerList.map((ledegrGroup) {
                  return DropdownMenuItem(
                    value: ledegrGroup,
                    child: Text(ledegrGroup),
                  );
                }).toList(),
              ),
            ),

            SizedBox(height: Sizes.height * .02),
            nameField(
              text: "Opeing Balance",
              child: Row(
                children: [
                  Expanded(
                    flex: 4,
                    child: CommonTextField(
                      controller: openingBalanceController,
                      hintText: 'Opening Balance',
                    ),
                  ),
                  SizedBox(width: 10),
                  Expanded(
                    child: CommonDropdownField<String>(
                      value: _selectedBalance,
                      onChanged: (String? newValue) {
                        setState(() {
                          _selectedBalance = newValue ?? 'Dr';
                        });
                      },
                      items: _balanceType.map<DropdownMenuItem<String>>((
                        String value,
                      ) {
                        return DropdownMenuItem<String>(
                          value: value,
                          child: Text(
                            value,
                            style: TextStyle(
                              fontWeight: FontWeight.w500,
                              color: AppColor.lightblack,
                              fontSize: 17,
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ],
              ),
            ),

            SizedBox(height: Sizes.height * .02),
            SizedBox(height: Sizes.height * .02),
            nameField(
              text: "Address 1",
              child: Row(
                children: [
                  Expanded(
                    child: CommonSearchableDropdownField<String>(
                      controller: TextEditingController(
                        text: selectedState?.item ?? "",
                      ),
                      hintText: "--Select State--",
                      suggestions: statesSuggestions
                          .map((x) => SearchFieldListItem<String>(x, item: x))
                          .toList(),
                      onSuggestionTap: (item) {
                        setState(() {
                          selectedState = item;
                          citiesSuggestions = stateCities[item.searchKey] ?? [];
                          selectedCity = null;
                        });
                      },
                    ),
                  ),
                  SizedBox(width: 55),
                  Expanded(
                    child: CommonSearchableDropdownField<String>(
                      controller: TextEditingController(
                        text: selectedCity?.item ?? "",
                      ),
                      hintText: "--Select City--",
                      suggestions: citiesSuggestions
                          .map((x) => SearchFieldListItem<String>(x, item: x))
                          .toList(),
                      onSuggestionTap: (item) {
                        setState(() => selectedCity = item);
                      },
                    ),
                  ),
                  SizedBox(width: 55),
                  Expanded(
                    child: CommonTextField(
                      controller: permanentareaController,
                      hintText: "Type City/District/Village",
                    ),
                  ),
                  SizedBox(width: 55),
                  Expanded(child: SizedBox()),
                ],
              ),
            ),
            SizedBox(height: Sizes.height * .02),
            nameField(
              text: "Address Line",
              child: CommonTextField(
                controller: addressLine1Controller,
                hintText: "Address",
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: Container(
        padding: EdgeInsets.only(top: 17, bottom: 24, left: 27, right: 27),
        decoration: BoxDecoration(
          border: Border(top: BorderSide(color: AppColor.grey, width: .5)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            defaultButton(
              buttonColor: Color(0xff8947E5),
              text: "Create Ledger",
              height: 40,
              width: 149,
              onTap: () => postLedger(),
            ),

            SizedBox(width: 18),
            defaultButton(
              buttonColor: Color(0xffE11414),
              text: "Cancel",
              height: 40,
              width: 93,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> postLedger() async {
    // 1. Initialize the base payload map.
    final Map<String, dynamic> payloadData = {
      'licence_no': Preference.getint(PrefKeys.licenseNo),
      'branch_id': Preference.getString(PrefKeys.locationId),
      'ledger_name': ledgerNameController.text.trim().toString(),
      'whatapp_no': whatsapppNoController.text.trim().toString(),
      'email': emailIdController.text.trim().toString(),
      'ledger_group': _selectedLedgerGroup,
      // Safely parse int, using null if empty.
      'opening_balance': openingBalanceController.text.trim().isEmpty
          ? "0"
          : _selectedBalance != "Cr"
          ? "${int.tryParse(openingBalanceController.text.trim())}"
          : "-${int.tryParse(openingBalanceController.text.trim())}",
      'address': addressLine1Controller.text.trim().toString(),
      'town': permanentareaController.text.trim().toString(),
      'opening_type': _selectedBalance,
      'closing_balance': "0",
      'gst_no': "",
      'state': selectedState?.item ?? "",
      'city': selectedCity?.item ?? "",
    };

    // 2. Conditionally add 'contact_no' to the payload.
    final contactNoText = contactNoNameController.text.trim();
    if (contactNoText.isNotEmpty) {
      final contactNo = int.tryParse(contactNoText);
      if (contactNo != null) {
        payloadData['contact_no'] = contactNo;
      }
      // Note: If you must send a value even if parsing fails, change the logic.
      // However, it's best practice to only send valid data types.
    }

    // 3. Post the data.
    final response = await ApiService.postData(
      'ledger',
      payloadData, // Pass the single, complete map
      licenceNo: Preference.getint(PrefKeys.licenseNo),
    );

    // 4. Handle the response.
    if (response["status"] == true) {
      // Use `await` for async snackbar/dialog if needed, but not strictly required here.
      showCustomSnackbarSuccess(context, response['message']);
      // If you uncomment the pop, ensure 'context' is valid.
      Navigator.pop(context, "data");
    } else {
      showCustomSnackbarError(context, response['message']);
    }
  }
  // Future updateLedger(List<XFile>? documents) async {
  //   final response = await ApiService.uploadFiles(
  //     endpoint: 'ledger/${ledgerData!.id}',
  //     multiFiles: documents != null && documents.isNotEmpty
  //         ? {"ledger_file[]": documents}
  //         : null,
  //     fields: {
  //       'licence_no': Preference.getint(PrefKeys.licenseNo),
  //       'branch_id': Preference.getint(PrefKeys.locationId).toString(),
  //       'title': _selectedTitle,
  //       'ledger_name': ledgerNameController.text.trim().toString(),
  //       'relation_type': _selectedsubTitle,
  //       // 'ledger_file': 'nullable|array',
  //       // 'ledger_file.*': 'file|max:2048',
  //       'name': fatherNameController.text.trim().toString(),
  //       'contact_no': contactNoNameController.text.trim().toString(),
  //       'whatsapp_no': whatsapppNoController.text.trim().toString(),
  //       'email': emailIdController.text.trim().toString(),
  //       'ledger_group': _selectedLedgerGroup ?? "Sundry Debitors",
  //       'opening_balance': openingBalanceController.text.trim().toString(),
  //       'opening_type': _selectedBalance,
  //       'closing_balance': closingBalanceController.text.trim().toString(),
  //       'closing_type': _selectedClosingBalance,
  //       'gst_no': gstNoController.text.trim().toString(),
  //       'aadhar_no': aadharNoController.text.trim().toString(),
  //       // 'l_docu_uplode': 'nullable|file|max:2048',
  //       'permanent_address': addressLine1Controller.text.trim().toString(),
  //       'state': stateController.text.trim().toString(),
  //       'city': cityController.text.trim().toString(),
  //       'city_town_village': permanentareaController.text.trim().toString(),
  //       'pin_code': permanentpinCodeController.text.trim().toString(),
  //       'temporary_address': temporaryAddressController.text.trim().toString(),
  //       't_state': tempSateController.text.trim().toString(),
  //       't_city': tempCityController.text.trim().toString(),
  //       't_city_town_village': temporaryareaController.text.trim().toString(),
  //       't_pin_code': temporarypinCodeController.text.trim().toString(),
  //       'other1': 'LGR',
  //       'other4': "",
  //       'other5': "",
  //       '_method': "PUT",
  //     },
  //   );

  //   if (response["status"] == true) {
  //     showCustomSnackbarSuccess(context, response['message']);
  //     return true;
  //   } else {
  //     showCustomSnackbarError(context, response['message']);
  //     return false;
  //   }
  // }
}
