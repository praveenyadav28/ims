import 'package:google_fonts/google_fonts.dart';
import 'package:ims/model/ledger_model.dart';
import 'package:ims/model/payment_model.dart';
import 'package:ims/model/reminder_card_modeld.dart';
import 'package:flutter/material.dart';
import 'package:ims/utils/api.dart';
import 'package:ims/utils/button.dart';
import 'package:ims/utils/colors.dart';
import 'package:ims/utils/prefence.dart';
import 'package:ims/utils/textfield.dart';

class OutStandingReminder extends StatefulWidget {
  const OutStandingReminder({super.key});

  @override
  State<OutStandingReminder> createState() => _OutStandingReminderState();
}

class _OutStandingReminderState extends State<OutStandingReminder> {
  List<PaymentModel> allReceipts = [];
  List<LedgerListModel> ledgerList = [];
  List<ReminderCardModel> reminderList = [];
  List<ReminderCardModel> filteredList = [];

  TextEditingController searchController = TextEditingController();

  DateTime? fromDate;
  DateTime? toDate;

  int currentPage = 0;
  int rowsPerPage = 100;

  @override
  void initState() {
    super.initState();
    loadRemindersData();
    searchController.addListener(applyFilters);
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  Future<void> loadRemindersData() async {
    final recRes = await ApiService.fetchData(
      'get/reciept',
      licenceNo: Preference.getint(PrefKeys.licenseNo),
    );

    allReceipts = (recRes['data'] as List)
        .map((e) => PaymentModel.fromJson(e))
        .toList();

    final ledRes = await ApiService.fetchData(
      "get/ledger",
      licenceNo: Preference.getint(PrefKeys.licenseNo),
    );

    ledgerList = (ledRes['data'] as List)
        .map((e) => LedgerListModel.fromJson(e))
        .toList();

    buildOutstandingReminders();

    setState(() {
      filteredList = List.from(reminderList);
    });
  }

  void buildOutstandingReminders() {
    final Map<String, PaymentModel> latestReceiptByName = {};

    for (final r in allReceipts) {
      final name = (r.supplierName).trim();
      if (name.isEmpty) continue;

      if (!latestReceiptByName.containsKey(name) ||
          r.date.isAfter(latestReceiptByName[name]!.date)) {
        latestReceiptByName[name] = r;
      }
    }

    reminderList.clear();

    latestReceiptByName.forEach((name, receipt) {
      if (receipt.reminderDate == null) return;

      LedgerListModel? ledger;
      try {
        ledger = ledgerList.firstWhere(
          (l) =>
              (l.ledgerName ?? "").trim().toLowerCase().replaceAll(" ", "") ==
              name.toLowerCase().replaceAll(" ", ""),
        );
      } catch (_) {
        ledger = null;
      }

      reminderList.add(
        ReminderCardModel(
          customerId: ledger?.id ?? "",
          name: ledger?.ledgerName ?? name,
          remark: receipt.note,
          reminderDate: receipt.reminderDate!,
          recieptNo: receipt.voucherNo,
          prefix: receipt.prefix,
          closingBalance: ledger?.closingBalance ?? 0,
          mobile: ledger?.contactNo ?? 0,
        ),
      );
    });

    reminderList.sort((a, b) => a.reminderDate.compareTo(b.reminderDate));
  }

  // ---------------- FILTER ----------------

  void applyFilters() {
    List<ReminderCardModel> temp = List.from(reminderList);

    final query = searchController.text.toLowerCase();

    if (query.isNotEmpty) {
      temp = temp.where((r) {
        return r.name.toLowerCase().contains(query) ||
            r.recieptNo.toString().contains(query) ||
            r.mobile.toString().contains(query);
      }).toList();
    }

    if (fromDate != null) {
      temp = temp
          .where(
            (r) =>
                r.reminderDate.isAfter(fromDate!) ||
                r.reminderDate.isAtSameMomentAs(fromDate!),
          )
          .toList();
    }

    if (toDate != null) {
      temp = temp
          .where(
            (r) =>
                r.reminderDate.isBefore(toDate!) ||
                r.reminderDate.isAtSameMomentAs(toDate!),
          )
          .toList();
    }

    setState(() {
      filteredList = temp;
      currentPage = 0;
    });
  }

  Future<void> pickDate(bool isFrom) async {
    DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );

    if (picked != null) {
      setState(() {
        if (isFrom) {
          fromDate = picked;
        } else {
          toDate = picked;
        }
      });
      applyFilters();
    }
  }

  void clearFilters() {
    setState(() {
      searchController.clear();
      fromDate = null;
      toDate = null;
      filteredList = List.from(reminderList);
      currentPage = 0;
    });
  }

  // ---------------- PAGINATION ----------------

  List<ReminderCardModel> get paginatedList {
    final start = currentPage * rowsPerPage;
    final end = start + rowsPerPage;
    return filteredList.sublist(
      start,
      end > filteredList.length ? filteredList.length : end,
    );
  }

  int get totalPages => (filteredList.length / rowsPerPage).ceil();

  // ---------------- UI ----------------

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColor.white,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: AppColor.primary,
        iconTheme: IconThemeData(color: AppColor.white),
        title: Text(
          "Outstanding Reminder",
          style: GoogleFonts.inter(fontWeight: FontWeight.w600),
        ),
      ),
      body: Column(
        children: [
          buildSummaryCards(),
          buildFilterCard(),
          SizedBox(width: double.infinity, child: buildTable()),
          buildPagination(),
        ],
      ),
    );
  }

  Widget buildSummaryCards() {
    final total = filteredList.length;
    final overdue = filteredList
        .where((e) => e.reminderDate.isBefore(DateTime.now()))
        .length;

    final totalOutstanding = filteredList.fold<double>(
      0,
      (sum, item) => sum + item.closingBalance.abs(),
    );

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          summaryCard("Total", total.toString(), Colors.blue),
          const SizedBox(width: 16),
          summaryCard("Overdue", overdue.toString(), Colors.red),
          const SizedBox(width: 16),
          summaryCard(
            "Outstanding",
            "₹ ${totalOutstanding.toStringAsFixed(0)}",
            Colors.green,
          ),
        ],
      ),
    );
  }

  Widget summaryCard(String title, String value, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: GoogleFonts.inter(
                fontSize: 14,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: GoogleFonts.inter(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget buildFilterCard() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: CommonTextField(
                controller: searchController,
                hintText: "Search Ledger / Receipt / Mobile",
                suffixIcon: Icon(Icons.search),
              ),
            ),
            const SizedBox(width: 20),
            defaultButton(
              onTap: () => pickDate(true),
              height: 40,
              width: 150,
              buttonColor: AppColor.blue,
              text: fromDate == null
                  ? "From Date"
                  : "${fromDate!.day}-${fromDate!.month}-${fromDate!.year}",
            ),
            const SizedBox(width: 15),
            defaultButton(
              onTap: () => pickDate(false),
              height: 40,
              width: 150,
              buttonColor: AppColor.blue,
              text: toDate == null
                  ? "To Date"
                  : "${toDate!.day}-${toDate!.month}-${toDate!.year}",
            ),

            const SizedBox(width: 30),
            defaultButton(
              onTap: clearFilters,
              height: 40,
              width: 100,
              buttonColor: AppColor.red,
              text: "Clear",
            ),
          ],
        ),
      ),
    );
  }

  Widget buildTable() {
    if (filteredList.isEmpty) {
      return const Center(
        child: Text("No Pending Reminders", style: TextStyle(height: 3)),
      );
    }

    return Padding(
      padding: const EdgeInsets.all(16),
      child: SingleChildScrollView(
        child: DataTable(
          headingRowColor: WidgetStateProperty.all(const Color(0xffF1F5F9)),
          columns: const [
            DataColumn(label: Text("Ledger")),
            DataColumn(label: Text("Mobile")),
            DataColumn(label: Text("Receipt")),
            DataColumn(label: Text("Reminder")),
            DataColumn(label: Text("Outstanding")),
            DataColumn(label: Text("Remark")),
          ],
          rows: paginatedList.map((r) {
            final isOverdue = r.reminderDate.isBefore(DateTime.now());
            final isCr = r.closingBalance < 0;

            return DataRow(
              cells: [
                DataCell(Text(r.name)),
                DataCell(Text(r.mobile.toString())),
                DataCell(
                  Text(
                    "${r.prefix}${r.prefix.isEmpty ? '' : '-'}${r.recieptNo}",
                  ),
                ),
                DataCell(
                  Text(
                    "${r.reminderDate.day}-${r.reminderDate.month}-${r.reminderDate.year}",
                    style: TextStyle(
                      color: isOverdue ? Colors.red : Colors.black87,
                    ),
                  ),
                ),
                DataCell(
                  Text(
                    "₹ ${r.closingBalance.abs()} ${isCr ? "Cr" : "Dr"}",
                    style: TextStyle(color: isCr ? Colors.red : Colors.green),
                  ),
                ),
                DataCell(Text(r.remark)),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget buildPagination() {
    if (filteredList.isEmpty) return const SizedBox();

    return Padding(
      padding: const EdgeInsets.all(8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Text("Page ${currentPage + 1} of $totalPages"),
          IconButton(
            onPressed: currentPage > 0
                ? () => setState(() => currentPage--)
                : null,
            icon: const Icon(Icons.arrow_back),
          ),
          IconButton(
            onPressed: currentPage < totalPages - 1
                ? () => setState(() => currentPage++)
                : null,
            icon: const Icon(Icons.arrow_forward),
          ),
        ],
      ),
    );
  }
}
