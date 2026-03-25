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
    'Expense',
    'Income',
    'Fixed Asset',
    'Capital',
    'Loans (Liability)',
  ];

  TextEditingController ledgerNameController = TextEditingController();
  TextEditingController spIdController = TextEditingController();
  TextEditingController contactNoNameController = TextEditingController();
  TextEditingController whatsapppNoController = TextEditingController();
  TextEditingController emailIdController = TextEditingController();
  TextEditingController openingBalanceController = TextEditingController(
    text: "0",
  );
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

    if (widget.existing != null) {
      final l = widget.existing!;
      String fullName = l.ledgerName ?? "";

      if (fullName.contains('~')) {
        List<String> parts = fullName.split('~');

        ledgerNameController.text = parts[0]; // Customer Name
        spIdController.text = parts[1]; // Special ID
      } else {
        ledgerNameController.text = fullName; // Only Name
        spIdController.text = ''; // No Special ID
      }
      contactNoNameController.text = l.contactNo?.toString() ?? "";
      whatsapppNoController.text = l.whatsAppNo.toString() == "null"
          ? ""
          : l.whatsAppNo.toString();
      emailIdController.text = l.email ?? "";
      openingBalanceController.text = (l.openingBalance?.abs() ?? "0")
          .toString();
      _selectedLedgerGroup = l.ledgerGroup;
      _selectedBalance = l.openingType ?? "Dr";
      addressLine1Controller.text = l.address ?? "";
      permanentareaController.text = l.town ?? "";

      // ---------- STATE & CITY ----------
      if (l.state != null && l.state!.isNotEmpty) {
        selectedState = SearchFieldListItem<String>(l.state!, item: l.state!);
        citiesSuggestions = stateCities[l.state!] ?? [];
      }

      if (l.city != null && l.city!.isNotEmpty) {
        selectedCity = SearchFieldListItem<String>(l.city!, item: l.city!);
      }

      setState(() {});
    }
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
          widget.existing == null ? "Create New Ledger" : "Update Ledger",
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
              child: Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: CommonTextField(
                      controller: ledgerNameController,
                      hintText: "Ledger Name",
                    ),
                  ),
                  SizedBox(width: 16),
                  Expanded(
                    flex: 1,
                    child: CommonTextField(
                      controller: spIdController,
                      hintText: "Special ID",
                    ),
                  ),
                ],
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
              text: "${widget.existing == null ? "Create" : "Update"} Ledger",
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
    final Map<String, dynamic> payloadData = {
      'licence_no': Preference.getint(PrefKeys.licenseNo),
      'branch_id': Preference.getString(PrefKeys.locationId),
      'ledger_name':
          ledgerNameController.text.trim() +
          (spIdController.text.trim().isNotEmpty
              ? "~${spIdController.text.trim()}"
              : ""),
      'whatapp_no': whatsapppNoController.text.trim().toString(),
      'email': emailIdController.text.trim().toString(),
      'ledger_group': _selectedLedgerGroup,
      'opening_balance': openingBalanceController.text.trim().isEmpty
          ? "0"
          : _selectedBalance != "Cr"
          ? "${int.tryParse(openingBalanceController.text.trim())}"
          : "-${int.tryParse(openingBalanceController.text.trim())}",
      'address': addressLine1Controller.text.trim().toString(),
      'town': permanentareaController.text.trim().toString(),
      'opening_type': _selectedBalance,
      if (widget.existing == null) 'closing_balance': "0",
      'gst_no': "",
      'state': selectedState?.item ?? "",
      'city': selectedCity?.item ?? "",
    };

    final contactNoText = contactNoNameController.text.trim();
    if (contactNoText.isNotEmpty) {
      final contactNo = int.tryParse(contactNoText);
      if (contactNo != null) {
        payloadData['contact_no'] = contactNo;
      }
    }

    final response = widget.existing == null
        ? await ApiService.postData(
            'ledger',
            payloadData,
            licenceNo: Preference.getint(PrefKeys.licenseNo),
          )
        : await ApiService.putData(
            'ledger/${widget.existing?.id}',
            payloadData,
            licenceNo: Preference.getint(PrefKeys.licenseNo),
          );

    if (response["status"] == true) {
      showCustomSnackbarSuccess(context, response['message']);
      Navigator.pop(context, "data");
    } else {
      showCustomSnackbarError(context, response['message']);
    }
  }
}
