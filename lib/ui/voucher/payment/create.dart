// ignore_for_file: must_be_immutable
import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:ims/model/ledger_model.dart';
import 'package:ims/model/payment_model.dart';
import 'package:ims/ui/master/company/company_api.dart';
import 'package:ims/ui/master/customer_supplier/create.dart';
import 'package:ims/ui/master/ledger/ledger_master.dart';
import 'package:ims/ui/sales/data/reuse_print.dart';
import 'package:ims/ui/sales/models/credit_note_data.dart';
import 'package:ims/ui/sales/models/purchase_return_data.dart';
import 'package:ims/ui/voucher/pdf_print.dart';
import 'package:ims/utils/api.dart';
import 'package:ims/utils/button.dart';
import 'package:ims/utils/colors.dart';
import 'package:ims/utils/navigation.dart';
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
  List<PaymentRowModel> paymentRows = [];
  List<LedgerListModel> ledgerList = [];
  List<LedgerListModel> supplierList = [];
  LedgerListModel? selectedSupplier;
  List<String> invoiceList = [];
  double pendingAmount = 0;
  double advanceAmount = 0;

  bool loadingPending = false;
  List<PaymentModel> relatedPayments = [];
  List<PurchaseReturnData> relatedPurchaseReturns = [];
  List<CreditNoteData> relatedCreditNotes = [];
  List<PaymentModel> relatedRecieptOnReturn = [];
  bool showTransactions = false;

  TextEditingController partyController = TextEditingController();
  TextEditingController invoiceNoController = TextEditingController();
  TextEditingController dateController = TextEditingController(
    text:
        "${DateTime.now().year}-${DateTime.now().month.toString().padLeft(2, '0')}-${DateTime.now().day.toString().padLeft(2, '0')}",
  );
  TextEditingController prefixController = TextEditingController();
  TextEditingController voucherNoController = TextEditingController();
  TextEditingController noteController = TextEditingController();
  List<LedgerListModel> initialPartyList = [];
  List<LedgerListModel> initialBankList = [];

  DateTime? selectedDate;
  Uint8List? paymentImage;
  String? existingDocuUrl;
  final ImagePicker _picker = ImagePicker();
  Future<void> pickpaymentImage() async {
    final XFile? picked = await _picker.pickImage(source: ImageSource.gallery);

    if (picked == null) return;
    final bytes = await picked.readAsBytes();
    setState(() {
      paymentImage = bytes;
    });
  }

  String selectedType = "Other";
  bool printAfterSave = false;
  void onTogglePrint(bool value) {
    setState(() {
      printAfterSave = value;
    });
  }

  @override
  void initState() {
    super.initState();

    if (paymentRows.isEmpty) {
      paymentRows.add(PaymentRowModel());
    }

    searchLedger("").then((data) {
      initialPartyList = data
          .where(
            (e) =>
                e.ledgerGroup != "Bank Account" &&
                e.ledgerGroup != "Cash In Hand",
          )
          .toList();

      initialBankList = data
          .where(
            (e) =>
                e.ledgerGroup == "Bank Account" ||
                e.ledgerGroup == "Cash In Hand",
          )
          .toList();
      supplierList = initialPartyList;
      ledgerList = initialBankList;
      setState(() {});
      if (widget.data != null) {
        fillDataForEdit();
      } else {
        getAutoVoucherApi();
      }
    });
  }

  @override
  void dispose() {
    for (var row in paymentRows) {
      row.amountController.dispose();
    }
    super.dispose();
  }

  void fillDataForEdit() {
    final d = widget.data!;

    partyController.text = d.supplierName;
    selectedType = d.type.toString();
    invoiceNoController.text = d.invoiceNo.toString();
    dateController.text =
        "${d.date.year}-${d.date.month.toString().padLeft(2, '0')}-${d.date.day.toString().padLeft(2, '0')}";

    prefixController.text = d.prefix;
    voucherNoController.text = d.voucherNo.toString();
    noteController.text = d.note;
    existingDocuUrl = d.docu;

    // match supplier
    selectedSupplier = supplierList.firstWhere(
      (e) => e.ledgerName == d.supplierName,
      orElse: () => supplierList.first,
    );
    paymentRows.clear();
    for (var e in widget.data!.ledgerDetails!) {
      final row = PaymentRowModel();

      row.ledger = ledgerList.firstWhere(
        (l) => l.id == e.ledgerId,
        // orElse: () => null,
      );

      row.amountController.text = e.amount.toString();

      paymentRows.add(row);
    }

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
          "${widget.data != null ? "Update" : "Create"} Payment Voucher",
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
              const SizedBox(width: 10),
              Checkbox(
                fillColor: WidgetStatePropertyAll(AppColor.primary),
                shape: ContinuousRectangleBorder(
                  borderRadius: BorderRadiusGeometry.circular(5),
                ),
                value: printAfterSave,
                onChanged: (v) {
                  onTogglePrint(v ?? true);
                  setState(() {});
                },
              ),
              Text(
                "Print   ",
                style: GoogleFonts.inter(
                  fontSize: 15,
                  color: AppColor.black,
                  fontWeight: FontWeight.w600,
                ),
              ),
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
                                  Row(
                                    children: [
                                      Text(
                                        "Party Name",
                                        style: GoogleFonts.inter(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w500,
                                          color: AppColor.textColor,
                                        ),
                                      ),
                                      Spacer(),
                                      TextButton(
                                        onPressed: () async {
                                          await pushTo(
                                            CreateCusSup(isCustomer: false),
                                          );
                                        },
                                        child: Text(
                                          "+ Create Supplier",
                                          style: TextStyle(
                                            color: AppColor.primary,
                                          ),
                                        ),
                                      ),
                                    ],
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
                        if (selectedType != "Other")
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              SizedBox(height: Sizes.height * .02),
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
                                    invoiceNoController.text = item.item ?? "";
                                  });
                                  fetchInvoicePending(
                                    item.item!,
                                  ); // 🔥 ADD THIS
                                },
                                suffixIcon:
                                    selectedType != "Other" &&
                                        invoiceNoController.text.isNotEmpty
                                    ? Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        crossAxisAlignment:
                                            CrossAxisAlignment.end,
                                        children: [
                                          loadingPending
                                              ? const SizedBox(
                                                  height: 10,
                                                  width: 10,
                                                  child: GlowLoader(),
                                                )
                                              : Text(
                                                  "₹ ${pendingAmount.toStringAsFixed(2)}",
                                                  style: GoogleFonts.inter(
                                                    fontWeight: FontWeight.w700,
                                                    color: pendingAmount > 0
                                                        ? Colors.red
                                                        : Colors.green,
                                                  ),
                                                ),

                                          if (advanceAmount > 0)
                                            Text(
                                              "Adv: ₹ ${advanceAmount.toStringAsFixed(2)}",
                                              style: GoogleFonts.inter(
                                                fontSize: 11,
                                                fontWeight: FontWeight.w600,
                                                color: Colors.blue,
                                              ),
                                            ),
                                        ],
                                      )
                                    : const SizedBox.shrink(),
                              ),
                            ],
                          ),

                        if (selectedType != "Other") SizedBox(width: 10),
                        SizedBox(height: Sizes.height * .02),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text("Payment Modes"),
                                Spacer(),
                                TextButton(
                                  onPressed: () async {
                                    await pushTo(CreateLedger());
                                  },
                                  child: Text(
                                    "+ Create Ledger",
                                    style: TextStyle(color: AppColor.primary),
                                  ),
                                ),
                              ],
                            ),

                            SizedBox(height: 8),

                            ListView.builder(
                              shrinkWrap: true,
                              physics: NeverScrollableScrollPhysics(),
                              itemCount: paymentRows.length,
                              itemBuilder: (context, index) {
                                final row = paymentRows[index];

                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 10),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.end,
                                    children: [
                                      /// Ledger Dropdown
                                      Expanded(
                                        flex: 3,
                                        child:
                                            CommonDropdownField<
                                              LedgerListModel
                                            >(
                                              hintText: "Select Mode",
                                              value:
                                                  ledgerList.contains(
                                                    row.ledger,
                                                  )
                                                  ? row.ledger
                                                  : null,
                                              items: ledgerList.map((ledger) {
                                                return DropdownMenuItem(
                                                  value: ledger,
                                                  child: Text(
                                                    ledger.ledgerName ?? "",
                                                  ),
                                                );
                                              }).toList(),
                                              onChanged: (v) {
                                                setState(() {
                                                  row.ledger = v;
                                                });
                                              },
                                            ),
                                      ),

                                      SizedBox(width: 10),

                                      /// Amount
                                      Expanded(
                                        flex: 2,
                                        child: CommonTextField(
                                          controller: row.amountController,
                                          hintText: "Amount",
                                        ),
                                      ),

                                      /// Delete Button
                                      index != paymentRows.length - 1
                                          ? IconButton(
                                              icon: Icon(
                                                Icons.delete,
                                                color: Colors.red,
                                              ),
                                              onPressed: () {
                                                setState(() {
                                                  paymentRows.removeAt(index);
                                                });
                                              },
                                            )
                                          : IconButton(
                                              onPressed: () {
                                                setState(() {
                                                  paymentRows.add(
                                                    PaymentRowModel(),
                                                  );
                                                });
                                              },
                                              icon: Icon(Icons.add),
                                            ),
                                    ],
                                  ),
                                );
                              },
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
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Expanded(
                              child: TitleTextFeild(
                                controller: noteController,
                                titleText: "Notes",
                                maxLines: 5,
                              ),
                            ),
                            SizedBox(width: 10),
                            GestureDetector(
                              onTap: pickpaymentImage,
                              child: SizedBox(
                                height: 105,
                                width: 150,
                                child: Container(
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(6),
                                    border: Border.all(
                                      color: AppColor.borderColor,
                                    ),
                                  ),
                                  child: paymentImage != null
                                      ? ClipRRect(
                                          borderRadius: BorderRadius.circular(
                                            6,
                                          ),
                                          child: Image.memory(
                                            paymentImage!,
                                            height: 105,
                                            width: 150,
                                            fit: BoxFit.cover,
                                          ),
                                        )
                                      : existingDocuUrl != null &&
                                            existingDocuUrl!.isNotEmpty
                                      ? Image.network(
                                          existingDocuUrl!,
                                          fit: BoxFit.cover,
                                        )
                                      : Center(
                                          child: Padding(
                                            padding: const EdgeInsets.all(8.0),
                                            child: Column(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.center,
                                              children: [
                                                Icon(
                                                  Icons.cloud_upload_outlined,
                                                  size: 32,
                                                  color: AppColor.primary,
                                                ),
                                                const SizedBox(height: 8),
                                                Text(
                                                  "Upload Image",
                                                  style: GoogleFonts.inter(
                                                    fontWeight: FontWeight.w500,
                                                  ),
                                                ),
                                                const SizedBox(height: 4),
                                                Text(
                                                  "PNG / JPG (max 5MB)",
                                                  style: GoogleFonts.inter(
                                                    fontSize: 12,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            if (showTransactions) ...[
              SizedBox(height: 20),

              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColor.white,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColor.borderColor),
                  boxShadow: [
                    BoxShadow(
                      color: Color(0xff171a1f14),
                      offset: Offset(0, .5),
                      blurRadius: 4,
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (relatedPayments.isNotEmpty)
                      _txSection(
                        "Payments (On Invoice)",
                        relatedPayments
                            .map(
                              (e) =>
                                  "₹ ${e.amount}  |  ${e.prefix}${e.invoiceNo}  |  ${e.date.toString().split(' ').first}",
                            )
                            .toList(),
                        Colors.green,
                      ),

                    if (relatedPurchaseReturns.isNotEmpty)
                      _txSection(
                        "Purchase Returns",
                        relatedPurchaseReturns
                            .map(
                              (e) =>
                                  "₹ ${e.totalAmount}  |  ${e.prefix}${e.no}  |  ${e.purchaseReturnDate.toString().split(' ').first}",
                            )
                            .toList(),
                        Colors.orange,
                      ),

                    if (relatedRecieptOnReturn.isNotEmpty)
                      _txSection(
                        "Reciepts on Purchase Return",
                        relatedRecieptOnReturn
                            .map(
                              (e) =>
                                  "₹ ${e.amount}  |  ${e.prefix}${e.invoiceNo}  |  ${e.date.toString().split(' ').first}",
                            )
                            .toList(),
                        Colors.blue,
                      ),

                    if (relatedCreditNotes.isNotEmpty)
                      _txSection(
                        "Debit Notes",
                        relatedCreditNotes
                            .map(
                              (e) =>
                                  "₹ ${e.totalAmount}  |  ${e.prefix}${e.no}  |  ${e.creditNoteDate.toString().split(' ').first}",
                            )
                            .toList(),
                        Colors.red,
                      ),

                    if (relatedPayments.isEmpty &&
                        relatedPurchaseReturns.isEmpty &&
                        relatedRecieptOnReturn.isEmpty &&
                        relatedCreditNotes.isEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Text(
                          "No related transactions found.",
                          style: GoogleFonts.inter(color: Colors.grey),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(1990),
      lastDate: DateTime(2100),
    );

    if (picked != null) {
      selectedDate = picked;
      dateController.text =
          "${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}";
      setState(() {});
    }
  }

  List<Map<String, dynamic>> get ledgerDetails => paymentRows.map((e) {
    return {
      "ledger_id": e.ledger?.id,
      "ledger_name": e.ledger?.ledgerName,
      "amount": e.amountController.text,
    };
  }).toList();
  double get totalAmount {
    return paymentRows.fold(
      0,
      (sum, e) => sum + (double.tryParse(e.amountController.text) ?? 0),
    );
  }

  Future<void> savePaymentVoucher() async {
    if (selectedSupplier == null) return;

    if (paymentRows.isEmpty) {
      showCustomSnackbarError(context, "Add at least one payment mode");
      return;
    }
    for (var row in paymentRows) {
      if (row.ledger == null) {
        showCustomSnackbarError(context, "Select all payment modes");
        return;
      }

      final amt = double.tryParse(row.amountController.text);

      if (amt == null || amt <= 0) {
        showCustomSnackbarError(context, "Amount must be greater than 0");
        return;
      }
    }
    final ids = paymentRows.map((e) => e.ledger?.id).toList();

    if (ids.toSet().length != ids.length) {
      showCustomSnackbarError(context, "Duplicate payment mode not allowed");
      return;
    }
    final body = {
      "licence_no": Preference.getint(PrefKeys.licenseNo),
      "branch_id": Preference.getString(PrefKeys.locationId),
      "supplier_id": selectedSupplier!.id,
      "supplier_name": selectedSupplier!.ledgerName,
      "ledger_details": jsonEncode(ledgerDetails),
      if (invoiceNoController.text.isNotEmpty)
        "invoice_no": invoiceNoController.text,
      "date": dateController.text, // yyyy-MM-dd
      "prefix": prefixController.text,
      "amount2": totalAmount.toString(),
      "vouncher_no": voucherNoController.text,
      "note": noteController.text,
      "type": selectedType,
    };
    final isEdit = widget.data != null;

    var response = await ApiService.uploadMultipart(
      endpoint: isEdit ? "payment/${widget.data!.id}" : "payment",
      fields: body,
      updateStatus: isEdit, // 🔥 PUT if edit, POST if new
      file: paymentImage,
      fileKey: "docu",
      licenceNo: Preference.getint(PrefKeys.licenseNo),
    );
    if (response['status'] == true) {
      showCustomSnackbarSuccess(context, response['message']);
      if (printAfterSave) {
        final p = PaymentModel.fromJson(response!['data']);

        final companyApi = await CompanyProfileAPi.getCompanyProfile();
        final company = CompanyPrintProfile.fromApi(companyApi["data"][0]);

        await VoucherPdfEngine.printPayment(data: p, company: company);
      }
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
      prefixController.text = response['prefix'].toString();
    }
  }

  Future<void> loadInvoiceList() async {
    if (selectedSupplier == null || selectedType == "Other") {
      invoiceList.clear();
      invoiceNoController.clear();
      relatedPayments.clear();
      relatedPurchaseReturns.clear();
      relatedCreditNotes.clear();
      relatedRecieptOnReturn.clear();
      showTransactions = false;
      pendingAmount = 0;
      setState(() {});
      return;
    }

    try {
      final res = await ApiService.fetchData(
        "get/ledgerreports/${selectedSupplier!.id}",
        licenceNo: Preference.getint(PrefKeys.licenseNo),
      );

      List<String> tempList = [];

      /// 🔥 PURCHASE INVOICE
      if (selectedType == "Purchase Invoice") {
        for (var e in res['Purchaseinvoice'] ?? []) {
          tempList.add("${e['prefix']}${e['no']}");
        }
      }

      /// 🔥 SALE RETURN
      if (selectedType == "Sale Return") {
        for (var e in res['Salereturn'] ?? []) {
          tempList.add("${e['prefix']}${e['no']}");
        }
      }

      /// 🔥 DEBIT NOTE
      if (selectedType == "Debit Note") {
        for (var e in res['Debitnote'] ?? []) {
          tempList.add("${e['prefix']}${e['no']}");
        }
      }

      invoiceList = tempList;

      setState(() {});
    } catch (e) {
      invoiceList = [];
      setState(() {});
    }
  }

  Future<void> fetchInvoicePending(String invoiceKey) async {
    try {
      setState(() => loadingPending = true);

      double purchaseInvoiceAmt = 0;
      double totalPayment = 0;
      double totalPurchaseReturn = 0;
      double totalCreditNote = 0;
      double receiptAgainstReturn = 0;

      final res = await ApiService.fetchData(
        "get/ledgerreports/${selectedSupplier!.id}",
        licenceNo: Preference.getint(PrefKeys.licenseNo),
      );

      /// ================= PURCHASE INVOICE =================
      for (var e in res['Purchaseinvoice'] ?? []) {
        print(e);
        if ("${e['prefix']}${e['no']}" == invoiceKey) {
          purchaseInvoiceAmt = (e['totle_amo'] as num?)?.toDouble() ?? 0;
          break;
        }
      }

      /// ================= PAYMENTS =================
      final payments = <PaymentModel>[];
      for (var e in res['Payment'] ?? []) {
        if ("${e['invoice_no']}" == invoiceKey) {
          final model = PaymentModel.fromJson(e);
          payments.add(model);
          totalPayment += model.amount;
        }
      }

      /// ================= PURCHASE RETURNS =================
      final purchaseReturns = <PurchaseReturnData>[];
      for (var e in res['Purchasereturn'] ?? []) {
        if ("${e['invoice_pre']}${e['invoice_no']}" == invoiceKey) {
          final model = PurchaseReturnData.fromJson(e);
          purchaseReturns.add(model);
          totalPurchaseReturn += model.totalAmount;
        }
      }

      /// ================= CREDIT NOTES =================
      final creditNotes = <CreditNoteData>[];
      for (var e in res['Creditnote'] ?? []) {
        if ("${e['invoice_pre']}${e['invoice_no']}" == invoiceKey) {
          final model = CreditNoteData.fromJson(e);
          creditNotes.add(model);
          totalCreditNote += model.totalAmount;
        }
      }

      /// ================= RECEIPTS AGAINST RETURN =================
      final receiptsOnReturns = <PaymentModel>[];

      final returnNos = purchaseReturns.map((e) => "${e.no}").toSet();

      for (var e in res['Recipt'] ?? []) {
        if (returnNos.contains("${e['invoice_no']}")) {
          final model = PaymentModel.fromJson(e);
          receiptsOnReturns.add(model);
          receiptAgainstReturn += model.amount;
        }
      }

      /// ================= FINAL CALCULATION =================
      final rawPending =
          purchaseInvoiceAmt -
          totalPayment -
          totalPurchaseReturn -
          totalCreditNote +
          receiptAgainstReturn;

      double pending = rawPending;
      double advance = 0;

      if (rawPending < 0) {
        advance = rawPending.abs();
        pending = 0;
      }

      setState(() {
        relatedPayments = payments;
        relatedPurchaseReturns = purchaseReturns;
        relatedCreditNotes = creditNotes;
        relatedRecieptOnReturn = receiptsOnReturns;

        pendingAmount = pending;
        advanceAmount = advance;
        showTransactions = true;
        loadingPending = false;
      });
    } catch (e) {
      setState(() {
        pendingAmount = 0;
        loadingPending = false;
      });
    }
  }

  Widget _txSection(String title, List<String> rows, Color color) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
            const SizedBox(height: 6),
            ...rows.map(
              (e) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Row(
                  children: [
                    Icon(Icons.circle, size: 6, color: color),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(e, style: GoogleFonts.inter(fontSize: 13)),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<List<LedgerListModel>> searchLedger(
    String text, {
    List<String>? groups,
  }) async {
    try {
      final res = await ApiService.fetchData(
        text.isEmpty ? "get/ledger/search" : "get/ledger/search?search=$text",
        licenceNo: Preference.getint(PrefKeys.licenseNo),
      );

      final data = (res?['data'] as List?) ?? [];

      final list = data.map((e) => LedgerListModel.fromJson(e)).toList();

      // 🔥 group filter (frontend)
      if (groups != null && groups.isNotEmpty) {
        return list.where((e) => groups.contains(e.ledgerGroup)).toList();
      }

      return list;
    } catch (e) {
      return [];
    }
  }
}

class PaymentRowModel {
  LedgerListModel? ledger;
  TextEditingController amountController = TextEditingController();
  TextEditingController ledgerController = TextEditingController();
}
