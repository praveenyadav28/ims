// ignore_for_file: must_be_immutable

import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:ims/model/ledger_model.dart';
import 'package:ims/model/payment_model.dart';
import 'package:ims/ui/sales/models/credit_note_data.dart';
import 'package:ims/ui/sales/models/purcahseinvoice_data.dart';
import 'package:ims/ui/sales/models/purchase_return_data.dart';
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
  TextEditingController amountController = TextEditingController();
  TextEditingController dateController = TextEditingController(
    text:
        "${DateTime.now().year}-${DateTime.now().month.toString().padLeft(2, '0')}-${DateTime.now().day.toString().padLeft(2, '0')}",
  );
  TextEditingController prefixController = TextEditingController();
  TextEditingController voucherNoController = TextEditingController();
  TextEditingController noteController = TextEditingController();

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
    existingDocuUrl = d.docu;

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
                                        fetchInvoicePending(
                                          item.item!,
                                        ); // 🔥 ADD THIS
                                      },
                                      suffixIcon:
                                          selectedType != "Other" &&
                                              invoiceNoController
                                                  .text
                                                  .isNotEmpty
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
                                                          fontWeight:
                                                              FontWeight.w700,
                                                          color:
                                                              pendingAmount > 0
                                                              ? Colors.red
                                                              : Colors.green,
                                                        ),
                                                      ),

                                                if (advanceAmount > 0)
                                                  Text(
                                                    "Adv: ₹ ${advanceAmount.toStringAsFixed(2)}",
                                                    style: GoogleFonts.inter(
                                                      fontSize: 11,
                                                      fontWeight:
                                                          FontWeight.w600,
                                                      color: Colors.blue,
                                                    ),
                                                  ),
                                              ],
                                            )
                                          : const SizedBox.shrink(),
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
      if (invoiceNoController.text.isNotEmpty)
        "invoice_no": invoiceNoController.text,
      "date": dateController.text, // yyyy-MM-dd
      "prefix": prefixController.text,
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
      relatedPayments.clear();
      relatedPurchaseReturns.clear();
      relatedCreditNotes.clear();
      relatedRecieptOnReturn.clear();
      showTransactions = false;
      pendingAmount = 0;
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

  Future<void> fetchInvoicePending(String invoiceKey) async {
    try {
      setState(() => loadingPending = true);

      double saleInvoiceAmt = 0;
      double totalReceipt = 0;
      double totalSaleReturn = 0;
      double totalDebitNote = 0;
      double paymentAgainstReturn = 0;

      /// ================= SALE INVOICE =================
      final invRes = await ApiService.fetchData(
        "get/purchaseinvoice",
        licenceNo: Preference.getint(PrefKeys.licenseNo),
      );

      final saleInvoices = PurchaseInvoiceListResponse.fromJson(invRes).data;

      final invoice = saleInvoices.firstWhere(
        (e) => "${e.prefix}${e.no}" == invoiceKey,
        orElse: () => PurchaseInvoiceData(
          id: "",
          licenceNo: 0,
          branchId: "",
          supplierId: "",
          supplierName: "",
          address0: "",
          address1: "",
          placeOfSupply: "",
          mobile: "",
          prefix: "",
          purchaseorderName: "",
          purchaseorderId: 0,
          no: 0,
          purchaseInvoiceDate: DateTime.now(),
          caseSale: false,
          notes: [],
          terms: [],
          subTotal: 0,
          subGst: 0,
          autoRound: false,
          totalAmount: 0,
          additionalCharges: [],
          discountLines: [],
          miscCharges: [],
          itemDetails: [],
          signature: "",
        ),
      );

      saleInvoiceAmt = invoice.totalAmount;

      /// ================= RECEIPTS =================
      final recRes = await ApiService.fetchData(
        "get/payment", // ✅ spelling fixed
        licenceNo: Preference.getint(PrefKeys.licenseNo),
      );

      final receipts = (recRes['data'] as List? ?? [])
          .map((e) => PaymentModel.fromJson(e))
          .where((e) => "${e.prefix}${e.invoiceNo}" == invoiceKey)
          .toList();

      totalReceipt = receipts.fold(0.0, (p, e) => p + e.amount);

      /// ================= SALE RETURNS =================
      final srRes = await ApiService.fetchData(
        "get/purchasereturn",
        licenceNo: Preference.getint(PrefKeys.licenseNo),
      );

      final saleReturns = PurchaseReturnListResponse.fromJson(
        srRes,
      ).data.where((e) => "${e.transNo}" == invoiceKey).toList();

      totalSaleReturn = saleReturns.fold(0.0, (p, e) => p + e.totalAmount);

      /// ================= DEBIT NOTES =================
      final dnRes = await ApiService.fetchData(
        "get/purchasenote",
        licenceNo: Preference.getint(PrefKeys.licenseNo),
      );
      final debitNotes = CreditNoteListResponse.fromJson(dnRes).data.where((e) {
        return "${e.transNo}" == invoiceKey;
      }).toList();

      totalDebitNote = debitNotes.fold(0.0, (p, e) => p + e.totalAmount);

      /// ================= PAYMENTS AGAINST RETURN =================
      final payRes = await ApiService.fetchData(
        "get/reciept",
        licenceNo: Preference.getint(PrefKeys.licenseNo),
      );

      final payments = (payRes['data'] as List? ?? [])
          .map((e) => PaymentModel.fromJson(e))
          .toList();

      final relatedReturnNos = saleReturns.map((e) => e.no).toSet();

      final paymentsOnReturns = payments.where(
        (p) => relatedReturnNos.contains(p.invoiceNo),
      );

      paymentAgainstReturn = paymentsOnReturns.fold(
        0.0,
        (p, e) => p + e.amount,
      );

      /// ================= FINAL PENDING =================
      final rawPending =
          saleInvoiceAmt -
          totalReceipt -
          totalSaleReturn -
          totalDebitNote +
          paymentAgainstReturn;
      double pending = rawPending;
      double advance = 0;

      if (rawPending < 0) {
        advance = rawPending.abs(); // customer ne extra de diya
        pending = 0;
      }

      setState(() {
        relatedPayments = receipts;
        relatedPurchaseReturns = saleReturns;
        relatedCreditNotes = debitNotes;
        relatedRecieptOnReturn = paymentsOnReturns.toList();
        showTransactions = true;
        pendingAmount = pending;
        advanceAmount = advance;
        loadingPending = false;
      });
    } catch (e, s) {
      debugPrint("❌ fetchInvoicePending error: $e");
      debugPrint("$s");

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
}
