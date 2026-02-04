import 'dart:io';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:ims/model/payment_model.dart';
import 'package:ims/ui/sales/models/global_models.dart';
import 'package:ims/utils/api.dart';
import 'package:ims/utils/button.dart';
import 'package:ims/utils/colors.dart';
import 'package:ims/utils/prefence.dart';
import 'package:ims/utils/sizes.dart';
import 'package:ims/utils/snackbar.dart';
import 'package:ims/utils/textfield.dart';
import 'package:searchfield/searchfield.dart';

// ignore: must_be_immutable
class RecieptEntry extends StatefulWidget {
  RecieptEntry({super.key, this.recieptModel});
  PaymentModel? recieptModel;
  @override
  State<RecieptEntry> createState() => _RecieptEntryState();
}

class _RecieptEntryState extends State<RecieptEntry> {
  List<LedgerModelDrop> ledgerList = [];
  LedgerModelDrop? selectedLedger;
  List<LedgerModelDrop> customerList = [];
  LedgerModelDrop? selectedCustomer;
  List<String> invoiceList = [];

  TextEditingController partyController = TextEditingController();
  TextEditingController ledgerController = TextEditingController();
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
  File? recieptImage;
  String? existingDocuUrl;
  final ImagePicker _picker = ImagePicker();
  Future<void> pickrecieptImage() async {
    final XFile? picked = await _picker.pickImage(source: ImageSource.gallery);

    if (picked == null) return;

    setState(() {
      recieptImage = File(picked.path);
    });
  }

  String selectedType = "Other";

  @override
  void initState() {
    super.initState();
    fetchLedgerData().then((onValue) {
      if (widget.recieptModel != null) {
        fillDataForEdit();
      } else {
        getAutoVoucherApi();
      }
    });
  }

  void fillDataForEdit() {
    final d = widget.recieptModel!;

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
      (e) => e.name == d.ledgerName,
      orElse: () => ledgerList.first,
    );

    // match supplier
    selectedCustomer = customerList.firstWhere(
      (e) => e.name == d.supplierName,
      orElse: () => customerList.first,
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
                                  _label("Party Name"),
                                  const SizedBox(height: 8),
                                  _ledgerDropdown(
                                    controller: partyController,
                                    hint: "Select Party",
                                    list: customerList,
                                    onSelect: (v) {
                                      selectedCustomer = v;
                                      partyController.text = v.name;
                                    },
                                    selectedLedger: selectedCustomer,
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
                                  _label("Type"),
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
                            _label("Recieve Mode"),
                            const SizedBox(height: 8),
                            _ledgerDropdown(
                              controller: ledgerController,

                              hint: "Select Recieve Mode",
                              list: ledgerList,
                              onSelect: (v) {
                                selectedLedger = v;
                                ledgerController.text = v.name;
                              },
                              selectedLedger: selectedLedger,
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
                              onTap: pickrecieptImage,
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
                                  child: recieptImage != null
                                      ? ClipRRect(
                                          borderRadius: BorderRadius.circular(
                                            6,
                                          ),
                                          child: Image.file(
                                            recieptImage!,
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

    final data = (response['data'] as List)
        .map((e) => LedgerModelDrop.fromMap(e))
        .toList();

    setState(() {
      /// Bank + Cash
      ledgerList = data
          .where(
            (e) =>
                e.ledgerGroup == 'Bank Account' ||
                e.ledgerGroup == 'Cash In Hand',
          )
          .toList();

      /// Customers (Exclude Bank & Cash)
      customerList = data
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
      "ledger_name": selectedLedger?.name ?? "",
      "customer_id": selectedCustomer?.id ?? "",
      "customer_name": selectedCustomer?.name ?? "",
      "amount": double.parse(amountController.text),
      if (invoiceNoController.text.isNotEmpty)
        "invoice_no": invoiceNoController.text,
      "date": dateController.text, // yyyy-MM-dd
      "prefix": prefixController.text,
      "vouncher_no": voucherNoController.text,
      "note": noteController.text,
      "type": selectedType,
      'other1': selectedCustomer?.ledgerGroup ?? "",
    };
    final isEdit = widget.recieptModel != null;

    final response = await ApiService.uploadMultipart(
      endpoint: isEdit ? "reciept/${widget.recieptModel!.id}" : "reciept",
      fields: body,
      updateStatus: isEdit, // 🔥 PUT if edit, POST if new
      file: recieptImage != null ? XFile(recieptImage!.path) : null,
      fileKey: "docu",
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

  /// ================= SEARCHABLE DROPDOWN =================
  Widget _ledgerDropdown({
    required TextEditingController controller,
    required String hint,
    required List<LedgerModelDrop> list,
    required LedgerModelDrop? selectedLedger,
    required Function(LedgerModelDrop) onSelect,
  }) {
    return CommonSearchableDropdownField<LedgerModelDrop>(
      controller: controller,
      hintText: hint,

      // 🔥 BALANCE IN SUFFIX
      suffixIcon: SizedBox(
        width: 150,
        child: Center(child: balanceSuffix(selectedLedger)),
      ),

      suggestions: list.map((e) {
        return SearchFieldListItem<LedgerModelDrop>(
          e.name,
          item: e,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            child: ledgerTile(e),
          ),
        );
      }).toList(),

      onSuggestionTap: (item) {
        setState(() {
          onSelect(item.item!);
        });
      },
    );
  }

  Widget balanceSuffix(LedgerModelDrop? ledger) {
    if (ledger == null) return const SizedBox.shrink();

    final bal = double.tryParse(ledger.closingBalance ?? "0") ?? 0;
    final isCr = bal < 0;

    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: Text(
        "₹ ${bal.abs()} ${isCr ? "Cr" : "Dr"}",
        style: GoogleFonts.inter(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: isCr ? Colors.red : Colors.green,
        ),
      ),
    );
  }

  /// ================= LEDGER TILE =================
  Widget ledgerTile(LedgerModelDrop c) {
    final bal = double.tryParse(c.closingBalance ?? "0") ?? 0;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          c.name,
          style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w500),
        ),
        Text(
          "₹ ${bal.abs()} ${bal < 0 ? "Cr" : "Dr"}",
          style: GoogleFonts.inter(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: bal < 0 ? Colors.red : Colors.green,
          ),
        ),
      ],
    );
  }

  Widget _label(String text) {
    return Text(
      text,
      style: GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        color: AppColor.textColor,
      ),
    );
  }
}
