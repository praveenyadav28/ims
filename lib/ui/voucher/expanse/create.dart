// ignore_for_file: must_be_immutable
import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:ims/model/expanse_model.dart';
import 'package:ims/model/ledger_model.dart';
import 'package:ims/ui/master/company/company_api.dart';
import 'package:ims/ui/master/ledger/ledger_master.dart';
import 'package:ims/ui/sales/data/reuse_print.dart';
import 'package:ims/ui/voucher/pdf_print.dart';
import 'package:ims/utils/api.dart';
import 'package:ims/utils/button.dart';
import 'package:ims/utils/colors.dart';
import 'package:ims/utils/navigation.dart';
import 'package:ims/utils/prefence.dart';
import 'package:ims/utils/sizes.dart';
import 'package:ims/utils/snackbar.dart';
import 'package:ims/utils/textfield.dart';
import 'package:intl/intl.dart';
import 'package:searchfield/searchfield.dart';
import 'package:image_picker/image_picker.dart';

class ExpenseEntry extends StatefulWidget {
  ExpenseEntry({this.expenseModel, super.key});
  ExpanseModel? expenseModel;
  @override
  State<ExpenseEntry> createState() => _ExpenseEntryState();
}

class _ExpenseEntryState extends State<ExpenseEntry> {
  /// ================= DATA =================
  List<LedgerListModel> expenseList = [];
  List<LedgerListModel> paymentLedgerList = [];

  List<LedgerListModel> initialExpanseList = [];
  List<LedgerListModel> initialBankList = [];
  LedgerListModel? selectedExpense;
  LedgerListModel? selectedPaymentLedger;
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
  Uint8List? expenseImage;
  final ImagePicker _picker = ImagePicker();
  Future<void> pickExpenseImage() async {
    final XFile? picked = await _picker.pickImage(source: ImageSource.gallery);

    if (picked == null) return;
    final bytes = await picked.readAsBytes();
    setState(() {
      expenseImage = bytes;
    });
  }

  bool printAfterSave = false;
  void onTogglePrint(bool value) {
    setState(() {
      printAfterSave = value;
    });
  }

  Timer? _debounce;

  /// ================= INIT =================
  @override
  void initState() {
    super.initState();
    searchLedger("").then((data) {
      initialExpanseList = data
          .where((e) => e.ledgerGroup == 'Expense')
          .toList();

      initialBankList = data
          .where(
            (e) =>
                e.ledgerGroup == "Bank Account" ||
                e.ledgerGroup == "Cash In Hand",
          )
          .toList();
    });

    if (widget.expenseModel != null) {
      final e = widget.expenseModel!;

      amountController.text = e.amount.toString();
      noteController.text = e.note;
      prefixController.text = e.prefix;
      voucherNoController.text = e.voucherNo.toString();
      dateController.text = DateFormat('yyyy-MM-dd').format(e.date);
      selectedDate = e.date;
      existingDocuUrl = e.docu;

      expenseController.text = e.supplierName;
      paymentController.text = e.ledgerName;

      searchLedger("").then((data) {
        setState(() {
          selectedExpense = data.firstWhere(
            (x) => x.ledgerName == e.supplierName,
            orElse: () => LedgerListModel(id: e.id, ledgerName: e.supplierName),
          );

          selectedPaymentLedger = data.firstWhere(
            (x) => x.ledgerName == e.ledgerName,
            orElse: () => LedgerListModel(id: e.id, ledgerName: e.ledgerName),
          );
        });
      });
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
          SearchField<LedgerListModel>(
            controller: expenseController,
            suggestions: initialExpanseList.map((e) {
              return SearchFieldListItem<LedgerListModel>(
                e.ledgerName ?? "",
                item: e,
                child: ledgerTile(e),
              );
            }).toList(),

            onSearchTextChanged: (text) async {
              if (_debounce?.isActive ?? false) _debounce!.cancel();

              await Future.delayed(const Duration(milliseconds: 200));

              final result = await searchLedger(text, groups: ["Expense"]);

              return result
                  .where(
                    (e) =>
                        e.ledgerGroup != "Bank Account" &&
                        e.ledgerGroup != "Cash In Hand",
                  )
                  .map((e) {
                    return SearchFieldListItem<LedgerListModel>(
                      e.ledgerName ?? "",
                      item: e,
                      child: ledgerTile(e),
                    );
                  })
                  .toList();
            },

            onSuggestionTap: (item) {
              final ledger = item.item!;
              setState(() {
                selectedExpense = ledger;
                expenseController.text = ledger.ledgerName ?? "";
              });
            },
            searchInputDecoration: SearchInputDecoration(
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 12,
              ),
              suffixIcon: InkWell(
                onTap: () async {
                  var data = await pushTo(CreateLedger());
                  if (data != null) {
                    searchLedger("").then((data) {
                      setState(() {
                        initialExpanseList = data
                            .where((e) => e.ledgerGroup == 'Expense')
                            .toList();
                      });
                    });
                  }
                },
                child: Container(
                  margin: EdgeInsets.all(5),
                  decoration: BoxDecoration(
                    color: AppColor.primary.withValues(alpha: .2),
                    borderRadius: BorderRadius.circular(5),
                  ),
                  child: Icon(Icons.add, color: AppColor.primarydark),
                ),
              ),

              labelText: "Search Expanse",
              labelStyle: GoogleFonts.inter(
                color: const Color(0xFF565D6D),
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(6),
                borderSide: BorderSide(color: Color(0xFFDEE1E6), width: 1),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(6),
                borderSide: BorderSide(color: Color(0xFFDEE1E6), width: 1),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(6),

                borderSide: BorderSide(color: Color(0xFFDEE1E6), width: 1),
              ),
            ),

            suggestionStyle: GoogleFonts.inter(
              color: const Color(0xFF565D6D),
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
            suggestionItemDecoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(4),
            ),
          ),

          SizedBox(height: Sizes.height * .02),
          _label("Payment Mode"),
          const SizedBox(height: 8),
          SearchField<LedgerListModel>(
            controller: paymentController,
            suggestions: initialBankList.map((e) {
              return SearchFieldListItem<LedgerListModel>(
                e.ledgerName ?? "",
                item: e,
                child: ledgerTile(e),
              );
            }).toList(),

            onSearchTextChanged: (text) async {
              if (_debounce?.isActive ?? false) _debounce!.cancel();

              await Future.delayed(const Duration(milliseconds: 200));

              final result = await searchLedger(
                text,
                groups: ["Bank Account", "Cash In Hand"],
              );

              return result.map((e) {
                return SearchFieldListItem<LedgerListModel>(
                  e.ledgerName ?? "",
                  item: e,
                  child: ledgerTile(e),
                );
              }).toList();
            },

            onSuggestionTap: (item) {
              setState(() {
                selectedPaymentLedger = item.item;
                paymentController.text = item.item?.ledgerName ?? "";
              });
            },
            searchInputDecoration: SearchInputDecoration(
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 12,
              ),
              labelText: "Search Bank Account",
              labelStyle: GoogleFonts.inter(
                color: const Color(0xFF565D6D),
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
              suffixIcon: InkWell(
                onTap: () async {
                  var data = await pushTo(CreateLedger());
                  if (data != null) {
                    searchLedger("").then((data) {
                      setState(() {
                        initialBankList = data
                            .where(
                              (e) =>
                                  e.ledgerGroup == "Bank Account" ||
                                  e.ledgerGroup == "Cash In Hand",
                            )
                            .toList();
                      });
                    });
                  }
                },
                child: Container(
                  margin: EdgeInsets.all(5),
                  decoration: BoxDecoration(
                    color: AppColor.primary.withValues(alpha: .2),
                    borderRadius: BorderRadius.circular(5),
                  ),
                  child: Icon(Icons.add, color: AppColor.primarydark),
                ),
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(6),
                borderSide: BorderSide(color: Color(0xFFDEE1E6), width: 1),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(6),
                borderSide: BorderSide(color: Color(0xFFDEE1E6), width: 1),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(6),

                borderSide: BorderSide(color: Color(0xFFDEE1E6), width: 1),
              ),
            ),

            suggestionStyle: GoogleFonts.inter(
              color: const Color(0xFF565D6D),
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
            suggestionItemDecoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(4),
            ),
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
                  onChanged: (value) async {
                    final currentText = value;

                    Future.delayed(const Duration(milliseconds: 300), () async {
                      if (prefixController.text.trim() != currentText.trim())
                        return;

                      final res = await ApiService.postData(
                        'get/transno',
                        {"trans_type": "Expense", "prefix": currentText.trim()},
                        licenceNo: Preference.getint(PrefKeys.licenseNo),
                      );

                      if (prefixController.text.trim() != currentText.trim())
                        return;

                      if (res != null && res['status'] == true) {
                        final newNo = res['next_no'].toString();

                        voucherNoController.value = TextEditingValue(
                          text: newNo,
                          selection: TextSelection.collapsed(
                            offset: newNo.length,
                          ),
                        );
                      } else {
                        voucherNoController.clear();
                      }
                    });
                  },
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
                            child: Image.memory(
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

  Widget balanceSuffix(LedgerListModel? ledger) {
    if (ledger == null) return const SizedBox.shrink();

    final bal = ledger.closingBalance ?? 0;
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
  Widget ledgerTile(LedgerListModel c) {
    final bal = c.closingBalance ?? 0;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          c.ledgerName ?? "",
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

  Future<void> getAutoVoucherApi() async {
    final res = await ApiService.fetchData(
      "get/autoexpense",
      licenceNo: Preference.getint(PrefKeys.licenseNo),
    );
    if (res['status'] == true) {
      voucherNoController.text = res['next_no'].toString();
      prefixController.text = res['prefix'].toString();
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

  Future<void> saveExpense() async {
    if (selectedExpense == null || selectedPaymentLedger == null) return;

    final fields = {
      "licence_no": Preference.getint(PrefKeys.licenseNo),
      "branch_id": Preference.getString(PrefKeys.locationId),
      "ledger_id": selectedPaymentLedger!.id,
      "ledger_name": selectedPaymentLedger!.ledgerName,
      "account_id": selectedExpense!.id,
      "account_name": selectedExpense!.ledgerName,
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
        file: expenseImage,
        fileKey: "docu",
        licenceNo: Preference.getint(PrefKeys.licenseNo),
      );

      if (res['status'] == true) {
        showCustomSnackbarSuccess(context, res['message']);
        if (printAfterSave) {
          final p = ExpanseModel.fromJson(res!['data']);

          final companyApi = await CompanyProfileAPi.getCompanyProfile();
          final company = CompanyPrintProfile.fromApi(companyApi["data"][0]);

          await VoucherPdfEngine.printExpense(data: p, company: company);
        }
        Navigator.pop(context, true);
      } else {
        showCustomSnackbarError(context, res['message']);
      }
    } catch (e) {
      showCustomSnackbarError(context, e.toString());
    }
  }
}
