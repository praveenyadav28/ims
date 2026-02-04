import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:ims/model/contra_model.dart';
import 'package:ims/ui/voucher/contra/create.dart';
import 'package:ims/utils/api.dart';
import 'package:ims/utils/button.dart';
import 'package:ims/utils/colors.dart';
import 'package:ims/utils/navigation.dart';
import 'package:ims/utils/prefence.dart';
import 'package:ims/utils/textfield.dart';
import 'package:intl/intl.dart';

class ContraListTableScreen extends StatefulWidget {
  const ContraListTableScreen({super.key});

  @override
  State<ContraListTableScreen> createState() => _ContraListTableScreenState();
}

class _ContraListTableScreenState extends State<ContraListTableScreen> {
  bool loading = false;
  List<ContraModel> list = [];
  List<ContraModel> allList = [];

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
    List<ContraModel> temp = allList;

    if (fromDate != null) {
      temp = temp.where((e) => !e.date.isBefore(fromDate!)).toList();
    }

    if (toDate != null) {
      temp = temp.where((e) => !e.date.isAfter(toDate!)).toList();
    }

    if (ledgerCtrl.text.isNotEmpty) {
      final q = ledgerCtrl.text.toLowerCase();
      temp = temp.where((e) {
        return e.fromAccount.toLowerCase().contains(q) ||
            e.toAccount.toLowerCase().contains(q);
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
      'get/contra',
      licenceNo: Preference.getint(PrefKeys.licenseNo),
    );

    allList = (res['data'] as List)
        .map((e) => ContraModel.fromJson(e))
        .toList();

    list = allList;

    setState(() => loading = false);
  }

  Future<void> deletePayment(String id) async {
    await ApiService.deleteData(
      'contra/$id',
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
          "Contra",
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
                var data = await pushTo(ContraEntry());
                if (data != null) {
                  fetchPayments();
                }
              },
              buttonColor: AppColor.blue,
              text: "Create Contra",
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
                    "Contra",
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
          Expanded(flex: 3, child: Text("Contra Number")),
          Expanded(flex: 3, child: Text("From Account")),
          Expanded(flex: 3, child: Text("To Account")),
          Expanded(flex: 2, child: Text("Amount")),
          Expanded(flex: 3, child: Text("Narration")),
          SizedBox(width: 70),
        ],
      ),
    );
  }

  // ---------- ROW ----------
  Widget _tableRow(ContraModel p) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(DateFormat('yyyy-MM-dd').format(p.date)),
          ),
          Expanded(flex: 3, child: Text("${p.prefix} ${p.voucherNo}")),
          Expanded(flex: 3, child: Text(p.fromAccount)),
          Expanded(flex: 3, child: Text(p.toAccount)),
          Expanded(
            flex: 2,
            child: Text(
              "₹ ${p.amount}",
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(p.note, maxLines: 1, overflow: TextOverflow.ellipsis),
          ),
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.edit, color: Colors.blue),
                onPressed: () async {
                  var data = await pushTo(ContraEntry(contraModel: p));
                  if (data != null) {
                    fetchPayments();
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
        title: const Text("Delete Contra"),
        content: const Text("Are you sure you want to delete this contra?"),
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
}
