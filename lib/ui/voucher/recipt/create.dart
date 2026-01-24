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
import 'package:searchfield/searchfield.dart';

class RecieptEntry extends StatefulWidget {
  const RecieptEntry({super.key});

  @override
  State<RecieptEntry> createState() => _RecieptEntryState();
}

class _RecieptEntryState extends State<RecieptEntry> {
  List<LedgerListModel> ledgerList = [];
  LedgerListModel? selectedLedger;
  List<LedgerListModel> customerList = [];
  LedgerListModel? selectedCustomer;
  List<String> invoiceList = [];

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

  String selectedType = "Other";

  @override
  void initState() {
    super.initState();
    getAutoVoucherApi();
    fetchLedgerData();
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
                onTap: () {
                  Navigator.pop(context);
                },
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
                                  CommonSearchableDropdownField<
                                    LedgerListModel
                                  >(
                                    controller: partyController,
                                    hintText: "Search party by name or number",
                                    suggestions: customerList.map((c) {
                                      return SearchFieldListItem<
                                        LedgerListModel
                                      >(
                                        c.ledgerName ?? "",
                                        item: c,
                                        child: ListTile(
                                          dense: true,
                                          title: Text(
                                            c.ledgerName ?? "",
                                            style: GoogleFonts.inter(
                                              fontSize: 14,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                          subtitle: Text(
                                            c.ledgerGroup.toString(),
                                            style: GoogleFonts.inter(
                                              fontSize: 13,
                                              fontWeight: FontWeight.w400,
                                            ),
                                          ),
                                        ),
                                      );
                                    }).toList(),
                                    onSuggestionTap: (s) {
                                      if (s.item == null) return;

                                      FocusScope.of(context).unfocus();
                                      selectedCustomer = s.item;
                                      partyController.text =
                                          s.item?.ledgerName ?? "";
                                      loadInvoiceList(); // ✅ PERFECT
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
                                    "Type",
                                    style: GoogleFonts.inter(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                      color: AppColor.textColor,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  CommonDropdownField<String>(
                                    hintText: "Reciept For",
                                    items: [
                                      DropdownMenuItem(
                                        value: "Other",
                                        child: Text("Other"),
                                      ),
                                      DropdownMenuItem(
                                        value: "Sale Invoice",
                                        child: Text("Sale Invoice"),
                                      ),
                                      DropdownMenuItem(
                                        value: "Purchase Return",
                                        child: Text("Purchase Return"),
                                      ),
                                      DropdownMenuItem(
                                        value: "Debit Note",
                                        child: Text("Debit Note"),
                                      ),
                                    ],
                                    onChanged: (v) {
                                      selectedType = v!;
                                      loadInvoiceList(); // ✅ ADD THIS
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
                        Row(
                          children: [
                            if (selectedType != "Other")
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      "Invoice No",
                                      style: GoogleFonts.inter(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w500,
                                        color: AppColor.textColor,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    CommonSearchableDropdownField<String>(
                                      hintText: "Select Invoice Number",
                                      controller: invoiceNoController,
                                      suggestions: invoiceList
                                          .map(
                                            (e) => SearchFieldListItem<String>(
                                              e,
                                              item: e,
                                            ),
                                          )
                                          .toList(),
                                      onSuggestionTap: (item) {
                                        setState(() {
                                          invoiceNoController.text =
                                              item.item ?? "";
                                        });
                                      },
                                    ),
                                  ],
                                ),
                              ),

                            if (selectedType != "Other") SizedBox(width: 10),
                            Expanded(
                              child: TitleTextFeild(
                                controller: amountController,
                                titleText: "Enter Recieve Amount",
                                hintText: "0",
                              ),
                            ),
                          ],
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

  Future<void> fetchLedgerData() async {
    final response = await ApiService.fetchData(
      "get/ledger",
      licenceNo: Preference.getint(PrefKeys.licenseNo),
    );

    final List data = response['data'] ?? [];

    final allLedgers = data.map((e) => LedgerListModel.fromJson(e)).toList();

    setState(() {
      /// Bank + Cash
      ledgerList = allLedgers
          .where(
            (e) =>
                e.ledgerGroup == 'Bank Account' ||
                e.ledgerGroup == 'Cash In Hand',
          )
          .toList();

      /// Customers (Exclude Bank & Cash)
      customerList = allLedgers
          .where(
            (e) =>
                e.ledgerGroup != 'Bank Account' &&
                e.ledgerGroup != 'Cash In Hand',
          )
          .toList();
    });
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
      "ledger_id": selectedLedger?.id ?? "",
      "ledger_name": selectedLedger?.ledgerName ?? "",
      "customer_id": selectedCustomer?.id ?? "",
      "customer_name": selectedCustomer?.ledgerName ?? "",
      "amount": double.parse(amountController.text),
      if (invoiceNoController.text.isNotEmpty)
        "invoice_no": invoiceNoController.text,
      "date": dateController.text, // yyyy-MM-dd
      "prefix": prefixController.text,
      "vouncher_no": voucherNoController.text,
      "note": noteController.text,
      "type": selectedType,
    };

    var response = await ApiService.postData(
      "reciept",
      body,
      licenceNo: Preference.getint(PrefKeys.licenseNo),
    );
    if (response['status'] == true) {
      Navigator.pop(context, "data");
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

  Future<void> loadInvoiceList() async {
    if (selectedCustomer == null || selectedType == "Other") {
      invoiceList.clear();
      invoiceNoController.clear();
      setState(() {});
      return;
    }

    if (selectedType == "Sale Invoice") {
      final res = await ApiService.fetchData(
        "get/invoice",
        licenceNo: Preference.getint(PrefKeys.licenseNo),
      );

      invoiceList = (res['data'] as List)
          .where((e) => e['customer_id'] == selectedCustomer!.id)
          .map((e) => "${e['prefix']}${e['no']}")
          .toList();
    }

    if (selectedType == "Purchase Return") {
      final res = await ApiService.fetchData(
        "get/purchasereturn",
        licenceNo: Preference.getint(PrefKeys.licenseNo),
      );

      invoiceList = (res['data'] as List)
          .where((e) => e['supplier_id'] == selectedCustomer!.id)
          .map((e) => "${e['prefix']}${e['no']}")
          .toList();
    }

    if (selectedType == "Debit Note") {
      final res = await ApiService.fetchData(
        "get/purchasenote",
        licenceNo: Preference.getint(PrefKeys.licenseNo),
      );

      invoiceList = (res['data'] as List)
          .where((e) => e['supplier_id'] == selectedCustomer!.id)
          .map((e) => "${e['prefix']}${e['no']}")
          .toList();
    }

    setState(() {});
  }
}
