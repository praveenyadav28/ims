import 'package:google_fonts/google_fonts.dart';
import 'package:ims/model/ledger_model.dart';
import 'package:ims/model/payment_model.dart';
import 'package:ims/model/reminder_card_modeld.dart';
import 'package:flutter/material.dart';
import 'package:ims/utils/api.dart';
import 'package:ims/utils/colors.dart';
import 'package:ims/utils/prefence.dart';

class OutStandingReminder extends StatefulWidget {
  const OutStandingReminder({super.key});

  @override
  State<OutStandingReminder> createState() => _OutStandingReminderState();
}

class _OutStandingReminderState extends State<OutStandingReminder> {
  List<PaymentModel> allReceipts = [];
  List<LedgerListModel> ledgerList = [];
  List<ReminderCardModel> reminderList = [];
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
  }

  void buildOutstandingReminders() {
    final Map<String, PaymentModel> latestReceiptByName = {};

    // Step 1: Get latest receipt for each ledger
    for (final r in allReceipts) {
      final name = (r.supplierName).trim();
      if (name.isEmpty) continue;

      if (!latestReceiptByName.containsKey(name)) {
        latestReceiptByName[name] = r;
      } else {
        if (r.date.isAfter(latestReceiptByName[name]!.date)) {
          latestReceiptByName[name] = r;
        }
      }
    }

    reminderList.clear();

    // Step 2: Check only latest receipt
    latestReceiptByName.forEach((name, receipt) {
      if (receipt.reminderDate == null) {
        // ❌ Latest voucher has no reminder → skip
        return;
      }

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
          closingBalance: ledger?.closingBalance ?? 0,
          mobile: ledger?.contactNo ?? 0,
        ),
      );
    });

    // Sort by reminder date
    reminderList.sort((a, b) => a.reminderDate.compareTo(b.reminderDate));
  }

  @override
  void initState() {
    loadRemindersData().then((valye) {
      setState(() {});
    });
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColor.white,
      appBar: AppBar(title: Text("Outstanding Reminder")),
      body: outstandingReminderTable(reminderList),
    );
  }

  Widget outstandingReminderTable(List<ReminderCardModel> reminderList) {
    if (reminderList.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(16),
        child: Text(
          "No Pending Reminders",
          style: TextStyle(color: Colors.grey),
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(12),
      child: SizedBox(
        width: double.infinity,
        child: DataTable(
          border: TableBorder.all(color: AppColor.borderColor),
          headingRowColor: WidgetStateProperty.all(const Color(0xffF1F5F9)),
          headingTextStyle: GoogleFonts.inter(
            fontWeight: FontWeight.w600,
            color: Colors.black,
          ),
          columns: const [
            DataColumn(
              label: Text("Ledger Name"),
              headingRowAlignment: MainAxisAlignment.center,
            ),
            DataColumn(
              label: Text("Mobile"),
              headingRowAlignment: MainAxisAlignment.center,
            ),
            DataColumn(
              label: Text("Receipt No"),
              headingRowAlignment: MainAxisAlignment.center,
            ),
            DataColumn(
              label: Text("Reminder Date"),
              headingRowAlignment: MainAxisAlignment.center,
            ),
            DataColumn(
              label: Text("Outstanding"),
              numeric: true,
              headingRowAlignment: MainAxisAlignment.center,
            ),
            DataColumn(
              label: Text("Remark"),
              headingRowAlignment: MainAxisAlignment.center,
            ),
          ],
          rows: reminderList.take(5).map((r) {
            final isOverdue = r.reminderDate.isBefore(DateTime.now());
            final isCr = r.closingBalance < 0;

            return DataRow(
              cells: [
                DataCell(Center(child: Text(r.name))),

                DataCell(Center(child: Text(r.mobile.toString()))),

                DataCell(Center(child: Text("#${r.recieptNo}"))),

                DataCell(
                  Center(
                    child: Text(
                      "${r.reminderDate.day.toString().padLeft(2, '0')}-"
                      "${r.reminderDate.month.toString().padLeft(2, '0')}-"
                      "${r.reminderDate.year}",
                      style: TextStyle(
                        color: isOverdue ? Colors.red : Colors.black87,
                        fontWeight: isOverdue
                            ? FontWeight.w600
                            : FontWeight.normal,
                      ),
                    ),
                  ),
                ),

                DataCell(
                  Center(
                    child: Text(
                      "₹ ${r.closingBalance.abs()} ${isCr ? "Cr" : "Dr"}",
                      style: TextStyle(
                        color: isCr ? Colors.red : Colors.green,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),

                DataCell(Center(child: Text(r.remark))),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }
}
