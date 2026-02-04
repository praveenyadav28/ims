// ignore_for_file: must_be_immutable
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:ims/model/expanse_model.dart';
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
import 'dart:io';
import 'package:image_picker/image_picker.dart';

class ExpenseEntry extends StatefulWidget {
  ExpenseEntry({this.expenseModel, super.key});
  ExpanseModel? expenseModel;
  @override
  State<ExpenseEntry> createState() => _ExpenseEntryState();
}

class _ExpenseEntryState extends State<ExpenseEntry> {
  /// ================= DATA =================
  List<LedgerModelDrop> expenseList = [];
  List<LedgerModelDrop> paymentLedgerList = [];

  LedgerModelDrop? selectedExpense;
  LedgerModelDrop? selectedPaymentLedger;
  String? existingDocuUrl;

  /// ================= CONTROLLERS =================
  final TextEditingController expenseController = TextEditingController();
  final TextEditingController paymentController = TextEditingController();
  final TextEditingController amountController = TextEditingController();
  final TextEditingController noteController = TextEditingController();
  final TextEditingController prefixController = TextEditingController();
  final TextEditingController voucherNoController = TextEditingController();
  final TextEditingController dateController = TextEditingController(
    text:
        "${DateTime.now().year}-${DateTime.now().month.toString().padLeft(2, '0')}-${DateTime.now().day.toString().padLeft(2, '0')}",
  );

  DateTime? selectedDate;
  File? expenseImage;
  final ImagePicker _picker = ImagePicker();
  Future<void> pickExpenseImage() async {
    final XFile? picked = await _picker.pickImage(source: ImageSource.gallery);

    if (picked == null) return;

    setState(() {
      expenseImage = File(picked.path);
    });
  }

  /// ================= INIT =================
  @override
  void initState() {
    super.initState();
    fetchLedgers();

    if (widget.expenseModel != null) {
      final e = widget.expenseModel!;

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
          "${widget.expenseModel != null ? "Update" : "Create"} Expense Voucher",
          style: GoogleFonts.plusJakartaSans(
            fontSize: 20,
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
                onTap: saveExpense,
                buttonColor: const Color(0xff8947E5),
                text: widget.expenseModel != null ? "Update" : "Save",
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
          _label("Expense"),
          const SizedBox(height: 8),
          _ledgerDropdown(
            controller: expenseController,
            hint: "Select Expense",
            list: expenseList,
            onSelect: (v) {
              selectedExpense = v;
              expenseController.text = v.name;
            },
            selectedLedger: selectedExpense,
          ),
          SizedBox(height: Sizes.height * .02),
          _label("Payment Mode"),
          const SizedBox(height: 8),
          _ledgerDropdown(
            controller: paymentController,
            hint: "Select Payment Mode",
            list: paymentLedgerList,
            onSelect: (v) {
              selectedPaymentLedger = v;
              paymentController.text = v.name;
            },
            selectedLedger: selectedPaymentLedger,
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
                  titleText: "Expense Date",
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
                onTap: pickExpenseImage,
                child: SizedBox(
                  height: 105,
                  width: 150,
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: AppColor.borderColor),
                    ),
                    child: expenseImage != null
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(6),
                            child: Image.file(
                              expenseImage!,
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

    final list = (res['data'] as List)
        .map((e) => LedgerModelDrop.fromMap(e))
        .toList();

    setState(() {
      expenseList = list.where((e) => e.ledgerGroup == 'Expense').toList();
      paymentLedgerList = list
          .where(
            (e) =>
                e.ledgerGroup == 'Bank Account' ||
                e.ledgerGroup == 'Cash In Hand',
          )
          .toList();
    });
    if (widget.expenseModel != null) {
      final e = widget.expenseModel!;

      selectedExpense = expenseList.firstWhere((x) => x.name == e.supplierName);
      expenseController.text = selectedExpense!.name;

      selectedPaymentLedger = paymentLedgerList.firstWhere(
        (x) => x.name == e.ledgerName,
      );
      paymentController.text = selectedPaymentLedger!.name;
    }
  }

  Future<void> getAutoVoucherApi() async {
    final res = await ApiService.fetchData(
      "get/autoexpense",
      licenceNo: Preference.getint(PrefKeys.licenseNo),
    );
    if (res['status'] == true) {
      voucherNoController.text = res['NextNo'].toString();
    }
  }

  Future<void> pickDate() async {
    final d = await showDatePicker(
      context: context,
            firstDate: DateTime(1990),
            lastDate: DateTime(2100),
      initialDate: DateTime.now(),
    );
    if (d != null) {
      selectedDate = d;
      dateController.text =
          "${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}";
    }
  }

  Future<void> saveExpense() async {
    if (selectedExpense == null || selectedPaymentLedger == null) return;

    final fields = {
      "licence_no": Preference.getint(PrefKeys.licenseNo),
      "branch_id": Preference.getString(PrefKeys.locationId),
      "ledger_id": selectedPaymentLedger!.id,
      "ledger_name": selectedPaymentLedger!.name,
      "account_id": selectedExpense!.id,
      "account_name": selectedExpense!.name,
      "amount": amountController.text,
      "date": dateController.text,
      "prefix": prefixController.text,
      "vouncher_no": voucherNoController.text,
      "note": noteController.text,
    };

    try {
      final isEdit = widget.expenseModel != null;

      final res = await ApiService.uploadMultipart(
        endpoint: isEdit ? "expense/${widget.expenseModel!.id}" : "expense",
        fields: fields,
        updateStatus: isEdit, // 🔥 PUT if edit, POST if new
        file: expenseImage != null ? XFile(expenseImage!.path) : null,
        fileKey: "docu",
        licenceNo: Preference.getint(PrefKeys.licenseNo),
      );

      if (res['status'] == true) {
        showCustomSnackbarSuccess(context, res['message']);
        Navigator.pop(context, true);
      } else {
        showCustomSnackbarError(context, res['message']);
      }
    } catch (e) {
      showCustomSnackbarError(context, e.toString());
    }
  }
}
