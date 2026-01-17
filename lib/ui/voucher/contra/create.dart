import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:ims/model/ledger_model.dart';
import 'package:ims/utils/api.dart';
import 'package:ims/utils/button.dart';
import 'package:ims/utils/colors.dart';
import 'package:ims/utils/prefence.dart';
import 'package:ims/utils/sizes.dart';
import 'package:ims/utils/snackbar.dart';
import 'package:ims/utils/textfield.dart';

class ContraEntry extends StatefulWidget {
  const ContraEntry({super.key});

  @override
  State<ContraEntry> createState() => _ContraEntryState();
}

class _ContraEntryState extends State<ContraEntry> {
  List<LedgerListModel> ledgerList = [];
  LedgerListModel? selectedLedger;
  LedgerListModel? selectedParty;

  TextEditingController partyController = TextEditingController();
  TextEditingController amountController = TextEditingController();
  TextEditingController dateController = TextEditingController(
    text:
        "${DateTime.now().year}-${DateTime.now().month.toString().padLeft(2, '0')}-${DateTime.now().day.toString().padLeft(2, '0')}",
  );
  TextEditingController prefixController = TextEditingController();
  TextEditingController voucherNoController = TextEditingController();
  TextEditingController noteController = TextEditingController();

  DateTime? selectedDate;

  @override
  void initState() {
    super.initState();
    ledgerApi();
    getAutoVoucherApi();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColor.backgroundColor,
      appBar: AppBar(
        backgroundColor: AppColor.white,
        leading: IconButton(
          onPressed: () {
            Navigator.pop(context);
          },
          icon: Icon(Icons.arrow_back, color: AppColor.black),
        ),
        elevation: 0,
        // shadowColor: AppColor.grey,
        title: Text(
          "Create Contra Voucher",
          style: GoogleFonts.plusJakartaSans(
            fontSize: 20,
            height: 1,
            fontWeight: FontWeight.w700,
            color: AppColor.blackText,
          ),
        ),

        actions: [
          Row(
            children: [
              defaultButton(
                buttonColor: const Color(0xffE11414),
                text: "Cancel",
                height: 40,
                width: 93,
                onTap: () {
                  Navigator.pop(context);
                },
              ),
              const SizedBox(width: 18),
              defaultButton(
                onTap: savePaymentVoucher,
                buttonColor: const Color(0xff8947E5),
                text: "Save",
                height: 40,
                width: 113,
              ),
              const SizedBox(width: 18),
            ],
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.symmetric(
          vertical: Sizes.height * .02,
          horizontal: 14,
        ),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: Container(
                    padding: EdgeInsets.symmetric(vertical: 20, horizontal: 19),
                    decoration: BoxDecoration(
                      color: AppColor.white,
                      boxShadow: [
                        BoxShadow(
                          color: Color(0xff171a1f14),
                          offset: Offset(0, .5),
                          blurRadius: 4,
                        ),
                      ],
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppColor.borderColor),
                    ),
                    child: Column(
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Bank Acount",
                              style: GoogleFonts.inter(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: AppColor.textColor,
                              ),
                            ),
                            const SizedBox(height: 8),
                            CommonDropdownField<LedgerListModel>(
                              hintText: "Select Bank Account",
                              value: selectedParty,
                              items: ledgerList.map((ledger) {
                                return DropdownMenuItem<LedgerListModel>(
                                  value: ledger,
                                  child: Text(
                                    ledger.ledgerName ?? "",
                                    style: GoogleFonts.inter(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                      color: AppColor.textColor,
                                    ),
                                  ),
                                );
                              }).toList(),

                              onChanged: (LedgerListModel? v) {
                                setState(() {
                                  selectedParty = v;
                                });
                              },
                            ),
                          ],
                        ),

                        SizedBox(height: Sizes.height * .02),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Payment Mode",
                              style: GoogleFonts.inter(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: AppColor.textColor,
                              ),
                            ),
                            const SizedBox(height: 8),
                            CommonDropdownField<LedgerListModel>(
                              hintText: "Select Payment Mode",
                              value: selectedLedger,
                              items: ledgerList.map((ledger) {
                                return DropdownMenuItem<LedgerListModel>(
                                  value: ledger,
                                  child: Text(
                                    ledger.ledgerName ?? "",
                                    style: GoogleFonts.inter(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                      color: AppColor.textColor,
                                    ),
                                  ),
                                );
                              }).toList(),

                              onChanged: (LedgerListModel? v) {
                                setState(() {
                                  selectedLedger = v;
                                });
                              },
                            ),
                          ],
                        ),

                        SizedBox(height: Sizes.height * .02),
                        TitleTextFeild(
                          controller: amountController,
                          titleText: "Enter Payment Amount",
                          hintText: "0",
                        ),
                      ],
                    ),
                  ),
                ),
                SizedBox(width: 18),
                Expanded(
                  child: Container(
                    padding: EdgeInsets.symmetric(vertical: 20, horizontal: 19),
                    decoration: BoxDecoration(
                      color: AppColor.white,
                      boxShadow: [
                        BoxShadow(
                          color: Color(0xff171a1f14),
                          offset: Offset(0, .5),
                          blurRadius: 4,
                        ),
                      ],
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppColor.borderColor),
                    ),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: TitleTextFeild(
                                controller: dateController,
                                titleText: "Contra Date",
                                hintText: "Enter Date",
                                readOnly: true,
                                onTap: pickDate,
                              ),
                            ),
                            SizedBox(width: 30),
                            Expanded(
                              child: TitleTextFeild(
                                controller: prefixController,
                                titleText: "Voucher Prifix",
                                hintText: "Prifix",
                              ),
                            ),
                            SizedBox(width: 30),
                            Expanded(
                              child: TitleTextFeild(
                                controller: voucherNoController,
                                titleText: "Contra Voucher No.",

                                hintText: "Voucher Number",
                              ),
                            ),
                            SizedBox(width: 30),
                          ],
                        ),
                        SizedBox(height: Sizes.height * .037),
                        TitleTextFeild(
                          controller: noteController,
                          titleText: "Notes",
                          maxLines: 5,
                          hintText: "Enter Notes",
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
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
      "get/autovouncher",
      licenceNo: Preference.getint(PrefKeys.licenseNo),
    );
    if (response['status'] == true) {
      voucherNoController.text = response['NextNo'].toString();
    }
  }

  Future<void> pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );

    if (picked != null) {
      selectedDate = picked;
      dateController.text =
          "${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}";
      setState(() {});
    }
  }

  Future<void> savePaymentVoucher() async {
    if (selectedLedger == null || selectedParty == null) return;

    final body = {
      "licence_no": Preference.getint(PrefKeys.licenseNo),
      "branch_id": Preference.getString(PrefKeys.locationId),
      "ledger_id": selectedLedger!.id,
      "ledger_name": selectedLedger!.ledgerName,
      "account_id": selectedParty!.id,
      "account_name": selectedParty!.ledgerName,
      "amount": double.parse(amountController.text),
      "date": dateController.text, // yyyy-MM-dd
      "prefix": prefixController.text,
      "vouncher_no": voucherNoController.text,
      "note": noteController.text,
    };

    var response = await ApiService.postData(
      "contra",
      body,
      licenceNo: Preference.getint(PrefKeys.licenseNo),
    );
    if (response['status'] == true) {
      showCustomSnackbarSuccess(context, response['message']);
      Navigator.pop(context, true);
    } else {
      showCustomSnackbarError(context, response['message']);
    }
  }
}
