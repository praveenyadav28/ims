import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:ims/model/ledger_model.dart';
import 'package:ims/ui/sales/models/global_models.dart';
import 'package:ims/utils/api.dart';
import 'package:ims/utils/button.dart';
import 'package:ims/utils/colors.dart';
import 'package:ims/utils/prefence.dart';
import 'package:ims/utils/sizes.dart';
import 'package:ims/utils/snackbar.dart';
import 'package:ims/utils/textfield.dart';
import 'package:searchfield/searchfield.dart';

class RecieptEntry extends StatefulWidget {
  const RecieptEntry({super.key});

  @override
  State<RecieptEntry> createState() => _RecieptEntryState();
}

class _RecieptEntryState extends State<RecieptEntry> {
  List<LedgerListModel> ledgerList = [];
  LedgerListModel? selectedLedger;
  List<CustomerModel> customerList = [];
  CustomerModel? selectedCustomer;

  TextEditingController partyController = TextEditingController();
  TextEditingController invoiceNoController = TextEditingController();
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
    getAutoVoucherApi();
    ledgerApi();
    customerApi();
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
          "Create Reciept Voucher",
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
                onTap: () {},
              ),
              const SizedBox(width: 18),
              defaultButton(
                onTap: saveRecieptVoucher,
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
                        Row(
                          children: [
                            Expanded(
                              flex: 3,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    "Party Name",
                                    style: GoogleFonts.inter(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                      color: AppColor.textColor,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  CommonSearchableDropdownField<CustomerModel>(
                                    controller: partyController,
                                    hintText: "Search party by name or number",
                                    suggestions: customerList.map((c) {
                                      return SearchFieldListItem<CustomerModel>(
                                        c.name,
                                        item: c,
                                        child: ListTile(
                                          dense: true,
                                          title: Text(
                                            c.name,
                                            style: GoogleFonts.inter(
                                              fontSize: 14,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                          subtitle: c.mobile.isNotEmpty
                                              ? Text(c.mobile)
                                              : null,
                                        ),
                                      );
                                    }).toList(),
                                    onSuggestionTap: (s) {
                                      final customer = s.item!;
                                      setState(() {
                                        selectedCustomer = customer;
                                      });
                                      partyController.text = customer.name;
                                    },
                                  ),
                                ],
                              ),
                            ),
                            SizedBox(width: 20),
                            Expanded(
                              flex: 2,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    "Invoice",
                                    style: GoogleFonts.inter(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                      color: AppColor.textColor,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  CommonSearchableDropdownField<String>(
                                    controller: invoiceNoController,
                                    hintText: "Enter Invoice Number",
                                    suggestions: [],
                                    onSuggestionTap: (item) {
                                      setState(() {});
                                    },
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: Sizes.height * .02),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Recieve Mode",
                              style: GoogleFonts.inter(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: AppColor.textColor,
                              ),
                            ),
                            const SizedBox(height: 8),
                            CommonDropdownField<LedgerListModel>(
                              hintText: "Select Recieve Mode",
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
                          titleText: "Enter Recieve Amount",
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
                                titleText: "Reciept Date",
                                hintText: "Reciept Date",
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
                                titleText: "Reciept Voucher No.",
                                hintText: "Voucher No.",
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

  Future<void> customerApi() async {
    final list = await fetchCustomer();
    setState(() {
      customerList = list;
    });
  }

  Future<List<CustomerModel>> fetchCustomer() async {
    final res = await ApiService.fetchData(
      'get/customer',
      licenceNo: Preference.getint(PrefKeys.licenseNo),
    );
    final data = (res?['data'] as List?) ?? [];
    return data
        .map((e) => CustomerModel.fromMap(Map<String, dynamic>.from(e)))
        .toList();
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

  Future<void> saveRecieptVoucher() async {
    if (selectedLedger == null || selectedCustomer == null) return;

    final body = {
      "licence_no": Preference.getint(PrefKeys.licenseNo),
      "branch_id": Preference.getString(PrefKeys.locationId),
      "ledger_id": selectedLedger!.id,
      "ledger_name": selectedLedger!.ledgerName,
      "customer_id": selectedCustomer!.id,
      "customer_name": selectedCustomer!.name,
      "amount": double.parse(amountController.text),
      "invoice_no": invoiceNoController.text,
      "date": dateController.text, // yyyy-MM-dd
      "prefix": prefixController.text,
      "vouncher_no": voucherNoController.text,
      "note": noteController.text,
    };

    var response = await ApiService.postData(
      "reciept",
      body,
      licenceNo: Preference.getint(PrefKeys.licenseNo),
    );
    print(response);
    if (response['status'] == true) {
      showCustomSnackbarSuccess(context, response['message']);
    } else {
      showCustomSnackbarError(context, response['message']);
    }
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
