import 'dart:io';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:ims/model/contra_model.dart';
import 'package:ims/ui/sales/models/global_models.dart';
import 'package:ims/utils/api.dart';
import 'package:ims/utils/button.dart';
import 'package:ims/utils/colors.dart';
import 'package:ims/utils/prefence.dart';
import 'package:ims/utils/sizes.dart';
import 'package:ims/utils/snackbar.dart';
import 'package:ims/utils/textfield.dart';
import 'package:intl/intl.dart';
import 'package:searchfield/searchfield.dart';

// ignore: must_be_immutable
class JournalEntry extends StatefulWidget {
  JournalEntry({super.key, this.contraModel});
  ContraModel? contraModel;
  @override
  State<JournalEntry> createState() => _JournalEntryState();
}

class _JournalEntryState extends State<JournalEntry> {
  /// ================= DATA =================
  List<LedgerModelDrop> ledgerList = [];

  LedgerModelDrop? selectedDebitLedger;
  LedgerModelDrop? selectedCreditLedger;

  /// ================= CONTROLLERS =================
  final TextEditingController debitController = TextEditingController();
  final TextEditingController creditController = TextEditingController();
  final TextEditingController amountController = TextEditingController();
  final TextEditingController noteController = TextEditingController();
  final TextEditingController prefixController = TextEditingController();
  final TextEditingController voucherNoController = TextEditingController();
  final TextEditingController dateController = TextEditingController(
    text:
        "${DateTime.now().year}-${DateTime.now().month.toString().padLeft(2, '0')}-${DateTime.now().day.toString().padLeft(2, '0')}",
  );

  String? existingDocuUrl;
  DateTime? selectedDate;
  File? contraImage;
  final ImagePicker _picker = ImagePicker();
  Future<void> pickcontraImage() async {
    final XFile? picked = await _picker.pickImage(source: ImageSource.gallery);

    if (picked == null) return;

    setState(() {
      contraImage = File(picked.path);
    });
  }

  /// ================= INIT =================
  @override
  void initState() {
    super.initState();
    fetchLedgers();
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

  /// ================= UI =================
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
          "${widget.contraModel != null ? "Update" : "Create"} Journal Voucher",
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
                onTap: saveJournal,
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
          horizontal: 14,
          vertical: Sizes.height * .02,
        ),
        child: Row(
          children: [
            Expanded(child: _leftCard()),
            const SizedBox(width: 16),
            Expanded(child: _rightCard()),
          ],
        ),
      ),
    );
  }

  /// ================= LEFT CARD =================
  Widget _leftCard() {
    return _card(
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _label("Debit Ledger"),
          const SizedBox(height: 8),
          ledgerDropdown(
            controller: debitController,
            hint: "Select Debit Ledger",
            selectedLedger: selectedDebitLedger,
            onSelect: (v) {
              selectedDebitLedger = v;
              debitController.text = v.name;
            },
          ),
          SizedBox(height: Sizes.height * .02),
          _label("Credit Ledger"),
          const SizedBox(height: 8),
          ledgerDropdown(
            controller: creditController,
            hint: "Select Credit Ledger",
            selectedLedger: selectedCreditLedger,
            onSelect: (v) {
              selectedCreditLedger = v;
              creditController.text = v.name;
            },
          ),
          SizedBox(height: Sizes.height * .02),
          TitleTextFeild(
            controller: amountController,
            titleText: "Amount",
            hintText: "0",
          ),
        ],
      ),
    );
  }

  /// ================= RIGHT CARD =================
  Widget _rightCard() {
    return _card(
      Column(
        children: [
          Row(
            children: [
              Expanded(
                child: TitleTextFeild(
                  controller: dateController,
                  titleText: "Journal Date",
                  readOnly: true,
                  onTap: pickDate,
                ),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: TitleTextFeild(
                  controller: prefixController,
                  titleText: "Prefix",
                ),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: TitleTextFeild(
                  controller: voucherNoController,
                  titleText: "Voucher No",
                ),
              ),
            ],
          ),
          SizedBox(height: Sizes.height * .03),
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
                      border: Border.all(color: AppColor.borderColor),
                    ),
                    child: contraImage != null
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(6),
                            child: Image.file(
                              contraImage!,
                              height: 105,
                              width: 150,
                              fit: BoxFit.cover,
                            ),
                          )
                        : existingDocuUrl != null && existingDocuUrl!.isNotEmpty
                        ? Image.network(existingDocuUrl!, fit: BoxFit.cover)
                        : Center(
                            child: Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
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
                                    style: GoogleFonts.inter(fontSize: 12),
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
    );
  }

  /// ================= SEARCHABLE LEDGER DROPDOWN =================
  Widget ledgerDropdown({
    required TextEditingController controller,
    required String hint,
    required LedgerModelDrop? selectedLedger,
    required Function(LedgerModelDrop) onSelect,
  }) {
    return CommonSearchableDropdownField<LedgerModelDrop>(
      controller: controller,
      hintText: hint,
      suffixIcon: SizedBox(
        width: 160,
        child: Align(
          alignment: Alignment.centerRight,
          child: balanceSuffix(selectedLedger),
        ),
      ),
      suggestions: ledgerList.map((e) {
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

  /// ================= COMMON CARD =================
  Widget _card(Widget child) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColor.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColor.borderColor),
        boxShadow: const [BoxShadow(color: Color(0xff171a1f14), blurRadius: 4)],
      ),
      child: child,
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

  /// ================= API =================
  Future<void> fetchLedgers() async {
    final res = await ApiService.fetchData(
      "get/ledger",
      licenceNo: Preference.getint(PrefKeys.licenseNo),
    );

    setState(() {
      ledgerList = (res['data'] as List)
          .map((e) => LedgerModelDrop.fromMap(e))
          .toList();
    });
    if (widget.contraModel != null) {
      final e = widget.contraModel!;

      selectedDebitLedger = ledgerList.firstWhere(
        (x) => x.name == e.fromAccount,
      );
      debitController.text = selectedDebitLedger!.name;

      selectedCreditLedger = ledgerList.firstWhere(
        (x) => x.name == e.toAccount,
      );
      creditController.text = selectedCreditLedger!.name;
    }
  }

  Future<void> getAutoVoucherApi() async {
    final res = await ApiService.fetchData(
      "get/autojournal",
      licenceNo: Preference.getint(PrefKeys.licenseNo),
    );
    if (res['status'] == true) {
      voucherNoController.text = res['NextNo'].toString();
    }
  }

  Future<void> pickDate() async {
    final d = await showDatePicker(
      context: context,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      initialDate: DateTime.now(),
    );
    if (d != null) {
      selectedDate = d;
      dateController.text =
          "${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}";
    }
  }

  /// ================= SAVE =================
  Future<void> saveJournal() async {
    if (selectedDebitLedger == null || selectedCreditLedger == null) return;

    final body = {
      "licence_no": Preference.getint(PrefKeys.licenseNo),
      "branch_id": Preference.getString(PrefKeys.locationId),

      "ledger_id": selectedDebitLedger!.id,
      "ledger_name": selectedDebitLedger!.name,

      "account_id": selectedCreditLedger!.id,
      "account_name": selectedCreditLedger!.name,

      "amount": double.parse(amountController.text),
      "date": dateController.text,
      "prefix": prefixController.text,
      "vouncher_no": voucherNoController.text,
      "note": noteController.text,
    };
    final isEdit = widget.contraModel != null;

    final res = await ApiService.uploadMultipart(
      endpoint: isEdit ? "journal/${widget.contraModel!.id}" : "journal",
      fields: body,
      updateStatus: isEdit, // 🔥 PUT if edit, POST if new
      file: contraImage != null ? XFile(contraImage!.path) : null,
      fileKey: "docu",
      licenceNo: Preference.getint(PrefKeys.licenseNo),
    );

    if (res['status'] == true) {
      showCustomSnackbarSuccess(context, res['message']);
      Navigator.pop(context, true);
    } else {
      showCustomSnackbarError(context, res['message']);
    }
  }
}
