// ignore_for_file: must_be_immutable

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:ims/model/ledger_model.dart';
import 'package:ims/model/payment_model.dart';
import 'package:ims/utils/api.dart';
import 'package:ims/utils/button.dart';
import 'package:ims/utils/colors.dart';
import 'package:ims/utils/prefence.dart';
import 'package:ims/utils/sizes.dart';
import 'package:ims/utils/snackbar.dart';
import 'package:ims/utils/textfield.dart';
import 'package:searchfield/searchfield.dart';

class PaymentEntry extends StatefulWidget {
  PaymentEntry({super.key, this.data});
  PaymentModel? data;
  @override
  State<PaymentEntry> createState() => _PaymentEntryState();
}

class _PaymentEntryState extends State<PaymentEntry> {
  List<LedgerListModel> ledgerList = [];
  LedgerListModel? selectedLedger;
  List<LedgerListModel> supplierList = [];
  LedgerListModel? selectedSupplier;
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
  @override
  void initState() {
    super.initState();
    fetchLedgerData().then((onValue) {
      if (widget.data != null) {
        fillDataForEdit();
      } else {
        getAutoVoucherApi();
      }
    });
  }

  void fillDataForEdit() {
    final d = widget.data!;

    partyController.text = d.supplierName;
    selectedType = d.type.toString();
    amountController.text = d.amount.toString();
    invoiceNoController.text = d.invoiceNo.toString();
    dateController.text =
        "${d.date.year}-${d.date.month.toString().padLeft(2, '0')}-${d.date.day.toString().padLeft(2, '0')}";

    prefixController.text = d.prefix;
    voucherNoController.text = d.voucherNo.toString();
    noteController.text = d.note;

    // match selected ledger
    selectedLedger = ledgerList.firstWhere(
      (e) => e.ledgerName == d.ledgerName,
      orElse: () => ledgerList.first,
    );

    // match supplier
    selectedSupplier = supplierList.firstWhere(
      (e) => e.ledgerName == d.supplierName,
      orElse: () => supplierList.first,
    );

    setState(() {});
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
          "Create Payment Voucher",
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
                text: (widget.data != null) ? "Update" : "Save",
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
                                    suggestions: supplierList.map((c) {
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
                                      selectedSupplier = s.item;
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
                                    hintText: "Payment For",
                                    value: selectedType,
                                    items: [
                                      DropdownMenuItem(
                                        value: "Other",
                                        child: Text("Other"),
                                      ),
                                      DropdownMenuItem(
                                        value: "Purchase Invoice",
                                        child: Text("Purchase Invoice"),
                                      ),
                                      DropdownMenuItem(
                                        value: "Sale Return",
                                        child: Text("Sale Return"),
                                      ),
                                      DropdownMenuItem(
                                        value: "Credit Note",
                                        child: Text("Credit Note"),
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
                                titleText: "Enter Payment Amount",
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
                                titleText: "Payment Date",
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
                                titleText: "Payment Voucher No.",

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
      supplierList = allLedgers
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

  Future<void> savePaymentVoucher() async {
    if (selectedLedger == null || selectedSupplier == null) return;

    final body = {
      "licence_no": Preference.getint(PrefKeys.licenseNo),
      "branch_id": Preference.getString(PrefKeys.locationId),
      "ledger_id": selectedLedger!.id,
      "ledger_name": selectedLedger!.ledgerName,
      "supplier_id": selectedSupplier!.id,
      "supplier_name": selectedSupplier!.ledgerName,
      "amount": double.parse(amountController.text),
      "invoice_no": invoiceNoController.text,
      "date": dateController.text, // yyyy-MM-dd
      "prefix": prefixController.text,
      "vouncher_no": voucherNoController.text,
      "note": noteController.text,
      "type": selectedType,
    };

    var response = (widget.data != null)
        ? await ApiService.putData(
            "payment/${widget.data?.id}",
            body,
            licenceNo: Preference.getint(PrefKeys.licenseNo),
          )
        : await ApiService.postData(
            "payment",
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

  Future getAutoVoucherApi() async {
    var response = await ApiService.fetchData(
      "get/autono",
      licenceNo: Preference.getint(PrefKeys.licenseNo),
    );
    if (response['status'] == true) {
      voucherNoController.text = response['next_no'].toString();
    }
  }

  Future<void> loadInvoiceList() async {
    if (selectedSupplier == null || selectedType == "Other") {
      invoiceList.clear();
      invoiceNoController.clear();
      setState(() {});
      return;
    }

    if (selectedType == "Purchase Invoice") {
      final res = await ApiService.fetchData(
        "get/purchaseinvoice",
        licenceNo: Preference.getint(PrefKeys.licenseNo),
      );

      invoiceList = (res['data'] as List)
          .where((e) => e['supplier_id'] == selectedSupplier!.id)
          .map((e) => "${e['no']}")
          .toList();
    }

    if (selectedType == "Sale Return") {
      final res = await ApiService.fetchData(
        "get/returnsale",
        licenceNo: Preference.getint(PrefKeys.licenseNo),
      );

      invoiceList = (res['data'] as List)
          .where((e) => e['customer_id'] == selectedSupplier!.id)
          .map((e) => "${e['no']}")
          .toList();
    }

    if (selectedType == "Debit Note") {
      final res = await ApiService.fetchData(
        "get/debitnote",
        licenceNo: Preference.getint(PrefKeys.licenseNo),
      );

      invoiceList = (res['data'] as List)
          .where((e) => e['customer_id'] == selectedSupplier!.id)
          .map((e) => "${e['no']}")
          .toList();
    }

    setState(() {});
  }
}
