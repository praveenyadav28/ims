import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:ims/model/payment_model.dart';
import 'package:ims/ui/sales/data/reuse_print.dart';
import 'package:ims/ui/voucher/pdf_print.dart';
import 'package:ims/ui/voucher/recipt/create.dart';
import 'package:ims/utils/api.dart';
import 'package:ims/utils/button.dart';
import 'package:ims/utils/colors.dart';
import 'package:ims/utils/navigation.dart';
import 'package:ims/utils/prefence.dart';
import 'package:ims/utils/snackbar.dart';
import 'package:ims/utils/textfield.dart';
import 'package:intl/intl.dart';

class RecieptListTableScreen extends StatefulWidget {
  const RecieptListTableScreen({super.key});

  @override
  State<RecieptListTableScreen> createState() => _RecieptListTableScreenState();
}

class _RecieptListTableScreenState extends State<RecieptListTableScreen> {
  bool loading = false;
  List<PaymentModel> list = [];
  List<PaymentModel> allList = [];

  final TextEditingController fromDateCtrl = TextEditingController();
  final TextEditingController toDateCtrl = TextEditingController();
  final TextEditingController ledgerCtrl = TextEditingController();
  final TextEditingController voucherCtrl = TextEditingController();

  DateTime? fromDate;
  DateTime? toDate;
  Future<void> _pickDate(TextEditingController ctrl, bool isFrom) async {
    final d = await showDatePicker(
      context: context,
      firstDate: DateTime(1990),
      lastDate: DateTime(2100),
      initialDate: DateTime.now(),
    );

    if (d != null) {
      ctrl.text = DateFormat('yyyy-MM-dd').format(d);
      if (isFrom) {
        fromDate = d;
      } else {
        toDate = d;
      }
      applyFilter();
    }
  }

  void applyFilter() {
    List<PaymentModel> temp = allList;

    if (fromDate != null) {
      temp = temp.where((e) => !e.date.isBefore(fromDate!)).toList();
    }

    if (toDate != null) {
      temp = temp.where((e) => !e.date.isAfter(toDate!)).toList();
    }

    if (ledgerCtrl.text.isNotEmpty) {
      final q = ledgerCtrl.text.toLowerCase();
      temp = temp.where((e) {
        return e.supplierName.toLowerCase().contains(q) ||
            e.ledgerName.toLowerCase().contains(q);
      }).toList();
    }

    if (voucherCtrl.text.isNotEmpty) {
      final q = voucherCtrl.text.toLowerCase();
      temp = temp.where((e) {
        return e.voucherNo.toString().contains(q) ||
            e.prefix.toLowerCase().contains(q);
      }).toList();
    }

    setState(() {
      list = temp;
    });
  }

  @override
  void initState() {
    super.initState();
    setFinancialYear();
    fetchReciepts();
  }

  void setFinancialYear() {
    final now = DateTime.now();

    if (now.month >= 4) {
      fromDate = DateTime(now.year, 4, 1);
      toDate = DateTime(now.year + 1, 3, 31);
    } else {
      fromDate = DateTime(now.year - 1, 4, 1);
      toDate = DateTime(now.year, 3, 31);
    }

    fromDateCtrl.text = DateFormat("yyyy-MM-dd").format(fromDate!);
    toDateCtrl.text = DateFormat("yyyy-MM-dd").format(toDate!);
  }

  Future<void> fetchReciepts() async {
    setState(() => loading = true);

    final res = await ApiService.fetchData(
      'get/reciept',
      licenceNo: Preference.getint(PrefKeys.licenseNo),
    );
    print(res);
    allList = (res['data'] as List)
        .map((e) => PaymentModel.fromJson(e))
        .toList();
    list = allList;
    setState(() => loading = false);
  }

  Future<void> deleteReciept(String id) async {
    await ApiService.deleteData(
      'reciept/$id',
      licenceNo: Preference.getint(PrefKeys.licenseNo),
    );
    fetchReciepts();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xffF6F7FB),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: AppColor.white,
        iconTheme: IconThemeData(color: AppColor.black),
        title: Text(
          "Reciepts",
          style: GoogleFonts.plusJakartaSans(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: AppColor.blackText,
          ),
        ),
        actions: [
          Center(
            child: defaultButton(
              onTap: () async {
                var data = await pushTo(RecieptEntry());
                if (data != null) {
                  fetchReciepts().then((onValue) {
                    setState(() {});
                  });
                }
              },
              buttonColor: AppColor.blue,
              text: "Create Reciept",
              height: 40,
              width: 150,
            ),
          ),
          SizedBox(width: 10),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // ---------- TOP BAR ----------
            Container(
              padding: EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColor.white,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Row(
                children: [
                  const Icon(Icons.currency_rupee, color: Colors.deepPurple),
                  const SizedBox(width: 6),
                  Text(
                    "Reciept",
                    style: GoogleFonts.inter(
                      fontWeight: FontWeight.w600,
                      color: Colors.deepPurple,
                    ),
                  ),
                  SizedBox(width: 20),
                  Expanded(
                    child: Row(
                      children: [
                        Expanded(
                          child: CommonTextField(
                            controller: fromDateCtrl,
                            readOnly: true,
                            onTap: () => _pickDate(fromDateCtrl, true),
                            hintText: "From Date",
                            suffixIcon: Icon(Icons.calendar_today, size: 18),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: CommonTextField(
                            controller: toDateCtrl,
                            readOnly: true,
                            onTap: () => _pickDate(toDateCtrl, false),
                            hintText: "To Date",
                            suffixIcon: Icon(Icons.calendar_today, size: 18),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          flex: 2,
                          child: CommonTextField(
                            controller: ledgerCtrl,
                            onChanged: (_) => applyFilter(),
                            hintText: "Ledger / Account",
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: CommonTextField(
                            controller: voucherCtrl,
                            onChanged: (_) => applyFilter(),
                            hintText: "Voucher No",
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.clear, color: Colors.red),
                          onPressed: () {
                            fromDateCtrl.clear();
                            toDateCtrl.clear();
                            ledgerCtrl.clear();
                            voucherCtrl.clear();
                            fromDate = null;
                            toDate = null;
                            setState(() => list = allList);
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // ---------- TABLE ----------
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: AppColor.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColor.borderColor),
                ),
                child: loading
                    ? Center(child: GlowLoader())
                    : list.isEmpty
                    ? const Center(
                        child: Text(
                          "No Transactions Matching the current filter",
                        ),
                      )
                    : Column(
                        children: [
                          _tableHeader(),
                          const Divider(height: 1),
                          Expanded(
                            child: ListView.separated(
                              itemCount: list.length,
                              separatorBuilder: (_, __) =>
                                  const Divider(height: 1),
                              itemBuilder: (context, i) {
                                final p = list[i];
                                return _tableRow(p);
                              },
                            ),
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

  // ---------- HEADER ----------
  Widget _tableHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
      color: Colors.deepPurple.withOpacity(.08),
      child: Row(
        children: const [
          Expanded(flex: 2, child: Text("Date")),
          Expanded(flex: 2, child: Text("Reciept Number")),
          Expanded(flex: 3, child: Text("Party Name")),
          Expanded(flex: 2, child: Text("Amount")),
          Expanded(flex: 2, child: Text("Type")),
          Expanded(flex: 2, child: Text("Invoice No.")),
          Expanded(flex: 2, child: Text("Action")),
        ],
      ),
    );
  }

  // ---------- ROW ----------
  Widget _tableRow(PaymentModel p) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(DateFormat('yyyy-MM-dd').format(p.date)),
          ),
          Expanded(flex: 2, child: Text("${p.prefix} ${p.voucherNo}")),
          Expanded(flex: 3, child: Text(p.supplierName)),
          Expanded(
            flex: 2,
            child: Text(
              "₹ ${p.amount}",
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          Expanded(flex: 2, child: Text(p.type)),
          Expanded(flex: 2, child: Text(p.invoiceNo.toString())),
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.print, color: Colors.deepPurple),
                onPressed: () async {
                  try {
                    showDialog(
                      context: context,
                      barrierDismissible: false,
                      builder: (_) =>
                          const Center(child: CircularProgressIndicator()),
                    );

                    final companyRes = await ApiService.fetchData(
                      "get/company",
                      licenceNo: Preference.getint(PrefKeys.licenseNo),
                    );

                    Navigator.pop(context);

                    if (companyRes == null || companyRes['status'] != true) {
                      showCustomSnackbarError(
                        context,
                        "Company profile not found",
                      );
                      return;
                    }

                    final data = companyRes['data'];

                    // 🔥 FIX HERE
                    final Map<String, dynamic> companyMap =
                        data is List && data.isNotEmpty
                        ? Map<String, dynamic>.from(data.first)
                        : Map<String, dynamic>.from(data);

                    final company = CompanyPrintProfile.fromApi(companyMap);

                    await VoucherPdfEngine.printReceipt(
                      data: p,
                      company: company,
                    );
                  } catch (e, s) {
                    Navigator.pop(context);
                    debugPrint("❌ Print error: $e\n$s");
                    showCustomSnackbarError(context, "Print failed");
                  }
                },
              ),

              IconButton(
                icon: const Icon(Icons.edit, color: Colors.blue),
                onPressed: () async {
                  var data = await pushTo(RecieptEntry(recieptModel: p));
                  if (data != null) {
                    fetchReciepts();
                  }
                },
              ),
              IconButton(
                icon: const Icon(Icons.delete, color: Colors.red),
                onPressed: () => confirmDelete(p.id),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ---------- DELETE DIALOG ----------
  void confirmDelete(String id) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Delete Reciept"),
        content: const Text("Are you sure you want to delete this reciept?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              Navigator.pop(context);
              await deleteReciept(id);
            },
            child: const Text("Delete"),
          ),
        ],
      ),
    );
  }
}
