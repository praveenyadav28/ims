// top of file
import 'dart:io';
import 'package:excel/excel.dart' hide Border;
import 'package:path_provider/path_provider.dart';
import 'package:open_filex/open_filex.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:ims/model/payment_model.dart';
import 'package:ims/ui/sales/data/reuse_print.dart';
import 'package:ims/ui/voucher/payment/create.dart';
import 'package:ims/ui/voucher/pdf_print.dart';
import 'package:ims/utils/api.dart';
import 'package:ims/utils/button.dart';
import 'package:ims/utils/colors.dart';
import 'package:ims/utils/navigation.dart';
import 'package:ims/utils/prefence.dart';
import 'package:ims/utils/snackbar.dart';
import 'package:ims/utils/textfield.dart';
import 'package:intl/intl.dart';

class PaymentListTableScreen extends StatefulWidget {
  const PaymentListTableScreen({super.key});

  @override
  State<PaymentListTableScreen> createState() => _PaymentListTableScreenState();
}

class _PaymentListTableScreenState extends State<PaymentListTableScreen> {
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
    fetchPayments();
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

  Future<void> fetchPayments() async {
    setState(() => loading = true);

    final res = await ApiService.fetchData(
      'get/payment',
      licenceNo: Preference.getint(PrefKeys.licenseNo),
    );

    allList = (res['data'] as List)
        .map((e) => PaymentModel.fromJson(e))
        .toList();
    list = allList;
    setState(() => loading = false);
  }

  Future<void> deletePayment(String id) async {
    await ApiService.deleteData(
      'payment/$id',
      licenceNo: Preference.getint(PrefKeys.licenseNo),
    );
    fetchPayments();
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
          "Payments",
          style: GoogleFonts.plusJakartaSans(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: AppColor.blackText,
          ),
        ),
        actions: [
          Center(
            child: InkWell(
              onTap: exportPaymentExcel,
              child: Container(
                width: 50,
                height: 40,
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(5),
                  color: AppColor.white,
                  border: Border.all(width: 1, color: AppColor.borderColor),
                ),
                child: Image.asset("assets/images/excel.png"),
              ),
            ),
          ),
          const SizedBox(width: 10),

          Center(
            child: defaultButton(
              onTap: () async {
                var data = await pushTo(PaymentEntry());
                if (data != null) {
                  fetchPayments().then((onValue) {
                    setState(() {});
                  });
                }
              },
              buttonColor: AppColor.blue,
              text: "Create Payment",
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
                    "Payment",
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
          Expanded(flex: 2, child: Text("Payment Number")),
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
          Expanded(
            flex: 2,
            child: Row(
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

                      await VoucherPdfEngine.printPayment(
                        data: p,
                        company: company,
                      );
                    } catch (e) {
                      Navigator.pop(context);
                      showCustomSnackbarError(context, "Print failed");
                    }
                  },
                ),

                IconButton(
                  icon: const Icon(Icons.edit, color: Colors.blue),
                  onPressed: () async {
                    var data = await pushTo(PaymentEntry(data: p));
                    if (data != null) {
                      fetchPayments().then((onValue) {
                        setState(() {});
                      });
                    }
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: () => confirmDelete(p.id),
                ),
              ],
            ),
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
        title: const Text("Delete Payment"),
        content: const Text("Are you sure you want to delete this payment?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              Navigator.pop(context);
              await deletePayment(id);
            },
            child: const Text("Delete"),
          ),
        ],
      ),
    );
  }

  Future<void> exportPaymentExcel() async {
    if (list.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("No data to export")));
      return;
    }

    final excel = Excel.createExcel();
    final sheet = excel['Payments'];

    CellValue cv(dynamic v) {
      if (v == null) return TextCellValue('');
      if (v is num) return DoubleCellValue(v.toDouble());
      return TextCellValue(v.toString());
    }

    // 🔹 Header Info
    sheet.appendRow([
      cv('From Date'),
      cv('To Date'),
      cv(''),
      cv(''),
      cv(''),
      cv(''),
      cv(''),
    ]);

    sheet.appendRow([
      cv(fromDateCtrl.text),
      cv(toDateCtrl.text),
      cv(''),
      cv(''),
      cv(''),
      cv(''),
      cv(''),
    ]);

    // 🔹 Table Header
    sheet.appendRow([
      cv('Date'),
      cv('Payment No'),
      cv('Party Name'),
      cv('Amount'),
      cv('Type'),
      cv('Invoice No'),
    ]);

    // 🔹 Data Rows (filtered list only)
    for (final p in list) {
      sheet.appendRow([
        cv(DateFormat('yyyy-MM-dd').format(p.date)),
        cv("${p.prefix} ${p.voucherNo}"),
        cv(p.supplierName),
        cv(p.amount), // numeric cell
        cv(p.type),
        cv(p.invoiceNo.toString()),
      ]);
    }

    final dir = await getApplicationDocumentsDirectory();
    final file = File(
      "${dir.path}/Payments_${DateFormat('ddMMyyyy_HHmm').format(DateTime.now())}.xlsx",
    );

    final bytes = excel.encode();
    await file.writeAsBytes(bytes!);
    await OpenFilex.open(file.path);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Payments Excel exported successfully")),
    );
  }
}
