// ignore_for_file: must_be_immutable

import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:ims/model/contra_model.dart';
import 'package:ims/ui/sales/models/global_models.dart';
import 'package:ims/utils/api.dart';
import 'package:ims/utils/button.dart';
import 'package:ims/utils/colors.dart';
import 'package:ims/utils/prefence.dart';
import 'package:ims/utils/sizes.dart';
import 'package:ims/utils/snackbar.dart';
import 'package:ims/utils/textfield.dart';
import 'package:searchfield/searchfield.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';

class ContraEntry extends StatefulWidget {
  ContraEntry({super.key, this.contraModel});
  ContraModel? contraModel;
  @override
  State<ContraEntry> createState() => _ContraEntryState();
}

class _ContraEntryState extends State<ContraEntry> {
  List<LedgerModelDrop> ledgerList = [];

  LedgerModelDrop? selectedFromLedger; // Bank / Cash (From)
  LedgerModelDrop? selectedToLedger; // Bank / Cash (To)

  final TextEditingController fromController = TextEditingController();
  final TextEditingController toController = TextEditingController();
  TextEditingController amountController = TextEditingController();
  TextEditingController dateController = TextEditingController(
    text:
        "${DateTime.now().year}-${DateTime.now().month.toString().padLeft(2, '0')}-${DateTime.now().day.toString().padLeft(2, '0')}",
  );
  TextEditingController prefixController = TextEditingController();
  TextEditingController voucherNoController = TextEditingController();
  TextEditingController noteController = TextEditingController();

  String? existingDocuUrl;
  DateTime? selectedDate;
  Uint8List? contraImage;
  final ImagePicker _picker = ImagePicker();
  Future<void> pickcontraImage() async {
    final XFile? picked = await _picker.pickImage(source: ImageSource.gallery);
    if (picked == null) return;

    final bytes = await picked.readAsBytes();
    setState(() {
      contraImage = bytes; // ✅ bytes store karo
    });
  }

  @override
  void initState() {
    super.initState();
    ledgerApi();

    if (widget.contraModel != null) {
      final e = widget.contraModel!;

      // ---- BASIC FIELDS ----
      amountController.text = e.amount.toString();
      noteController.text = e.note;
      prefixController.text = e.prefix;
      voucherNoController.text = e.voucherNo.toString();
      dateController.text = DateFormat('yyyy-MM-dd').format(e.date);
      selectedDate = e.date;

      // ---- IMAGE URL ----
      existingDocuUrl = e.docu; // 👈 add variable (see below)
    } else {
      getAutoVoucherApi();
    }
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
          "${widget.contraModel != null ? "Update" : "Create"} Contra Voucher",
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
                text: widget.contraModel != null ? "Update" : "Save",
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
                              "From Acount",
                              style: GoogleFonts.inter(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: AppColor.textColor,
                              ),
                            ),
                            const SizedBox(height: 8),
                            const SizedBox(height: 8),
                            ledgerSearchDropdown(
                              controller: fromController,
                              hint: "Select Bank / Cash",
                              list: ledgerList,
                              selectedLedger: selectedFromLedger,
                              onSelect: (v) {
                                selectedFromLedger = v;
                              },
                            ),
                          ],
                        ),

                        SizedBox(height: Sizes.height * .02),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "To Account",
                              style: GoogleFonts.inter(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: AppColor.textColor,
                              ),
                            ),
                            const SizedBox(height: 8),
                            ledgerSearchDropdown(
                              controller: toController,
                              hint: "Select Bank / Cash",
                              list: ledgerList,
                              selectedLedger: selectedToLedger,
                              onSelect: (v) {
                                selectedToLedger = v;
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
                              onTap: pickcontraImage,
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
                                  child: contraImage != null
                                      ? ClipRRect(
                                          borderRadius: BorderRadius.circular(
                                            6,
                                          ),
                                          child: Image.memory(
                                            contraImage!,
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

  Future<void> ledgerApi() async {
    final res = await ApiService.fetchData(
      "get/ledger",
      licenceNo: Preference.getint(PrefKeys.licenseNo),
    );

    final list = (res['data'] as List)
        .map((e) => LedgerModelDrop.fromMap(e))
        .toList();

    setState(() {
      ledgerList = list
          .where(
            (e) =>
                e.ledgerGroup == 'Bank Account' ||
                e.ledgerGroup == 'Cash In Hand',
          )
          .toList();
    });
    if (widget.contraModel != null) {
      final e = widget.contraModel!;

      selectedFromLedger = ledgerList.firstWhere(
        (x) => x.name == e.fromAccount,
      );
      fromController.text = selectedFromLedger!.name;

      selectedToLedger = ledgerList.firstWhere((x) => x.name == e.toAccount);
      toController.text = selectedToLedger!.name;
    }
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
    if (selectedFromLedger == null || selectedToLedger == null) return;
    if (selectedFromLedger!.id == selectedToLedger!.id) {
      showCustomSnackbarError(context, "From and To ledger cannot be same");
      return;
    }

    final body = {
      "licence_no": Preference.getint(PrefKeys.licenseNo),
      "branch_id": Preference.getString(PrefKeys.locationId),
      "ledger_id": selectedFromLedger!.id,
      "ledger_name": selectedFromLedger!.name,
      "account_id": selectedToLedger!.id,
      "account_name": selectedToLedger!.name,
      "amount": double.parse(amountController.text),
      "date": dateController.text, // yyyy-MM-dd
      "prefix": prefixController.text,
      "vouncher_no": voucherNoController.text,
      "note": noteController.text,
    };
    final isEdit = widget.contraModel != null;

    final response = await ApiService.uploadMultipart(
      endpoint: isEdit ? "contra/${widget.contraModel!.id}" : "contra",
      fields: body,
      updateStatus: isEdit, // 🔥 PUT if edit, POST if new
      file: contraImage,
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

  Widget balanceSuffix(LedgerModelDrop? ledger) {
    if (ledger == null) return const SizedBox.shrink();

    final bal = double.tryParse(ledger.closingBalance ?? "0") ?? 0;

    return Text(
      "₹ ${bal.abs()} ${bal < 0 ? "Cr" : "Dr"}  ",
      style: GoogleFonts.inter(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: bal < 0 ? Colors.red : Colors.green,
      ),
    );
  }

  Widget ledgerSearchDropdown({
    required TextEditingController controller,
    required String hint,
    required List<LedgerModelDrop> list,
    required LedgerModelDrop? selectedLedger,
    required Function(LedgerModelDrop) onSelect,
  }) {
    return CommonSearchableDropdownField<LedgerModelDrop>(
      controller: controller,
      hintText: hint,

      suffixIcon: SizedBox(
        width: 130,
        child: Align(
          alignment: Alignment.centerRight,
          child: balanceSuffix(selectedLedger),
        ),
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
          controller.text = item.item!.name;
        });
      },
    );
  }
}
