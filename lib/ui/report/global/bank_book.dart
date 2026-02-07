import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:ims/model/ledger_model.dart';
import 'package:ims/utils/button.dart';
import 'package:ims/utils/colors.dart';
import 'package:ims/utils/textfield.dart';
import 'package:intl/intl.dart';
import 'package:searchfield/searchfield.dart';

import 'package:ims/utils/api.dart';
import 'package:ims/utils/prefence.dart';

class BankBookReportScreen extends StatefulWidget {
  const BankBookReportScreen({super.key});

  @override
  State<BankBookReportScreen> createState() => _BankBookReportScreenState();
}

class _BankBookReportScreenState extends State<BankBookReportScreen> {
  final df = DateFormat("dd-MM-yyyy");

  // ---------------- CONTROLLERS ----------------
  TextEditingController ledgerCtrl = TextEditingController();
  TextEditingController fromCtrl = TextEditingController();
  TextEditingController toCtrl = TextEditingController();

  // ---------------- DATA ----------------
  List<LedgerListModel> ledgerList = [];
  LedgerListModel? selectedLedger;

  DateTime fromDate = DateTime.now();
  DateTime toDate = DateTime.now();

  double openingBalance = 0;
  double debitTotal = 0;
  double creditTotal = 0;

  List<LedgerRow> rows = [];

  @override
  void initState() {
    super.initState();
    fromCtrl.text = df.format(fromDate);
    toCtrl.text = df.format(toDate);
    ledgerApi();
  }

  // ================= LEDGER LIST =================
  Future<void> ledgerApi() async {
    final res = await ApiService.fetchData(
      "get/ledger",
      licenceNo: Preference.getint(PrefKeys.licenseNo),
    );

    setState(() {
      ledgerList = (res['data'] as List)
          .map((e) => LedgerListModel.fromJson(e))
          .where((e) => e.ledgerGroup == 'Bank Account')
          .toList();
    });
  }

  Future<void> fetchLedgerReport() async {
    if (selectedLedger == null) return;

    rows.clear();
    debitTotal = 0;
    creditTotal = 0;

    final res = await ApiService.fetchData(
      "get/ledgerreports/${selectedLedger!.id}",
      licenceNo: Preference.getint(PrefKeys.licenseNo),
    );
    print(res);

    /// ================= OPENING =================
    double opening = (res['Ledger']['opening_balance'] ?? 0).toDouble();
    String openingType = res['Ledger']['opening_type'] ?? "DR";

    // DR = debit , CR = credit
    openingBalance = openingType == "DR" ? opening : -opening;

    /// ================= COMMON HANDLER =================
    void addRow({
      required DateTime date,
      required String type,
      required String party,
      required double debit,
      required double credit,
      required String no,
    }) {
      // before from date → opening
      if (date.isBefore(fromDate)) {
        openingBalance += (debit - credit);
        return;
      }

      if (date.isAfter(toDate)) return;

      rows.add(
        LedgerRow(
          date: date,
          voucherNo: no,
          type: type,
          party: party,
          debit: debit,
          credit: credit,
        ),
      );

      debitTotal += debit;
      creditTotal += credit;
    }

    // ================= RECEIPT =================
    for (var e in res['Recipt'] ?? []) {
      addRow(
        date: DateTime.parse(e['date']),
        type: "Receipt",
        party: e['customer_name'],
        debit: e['amount'].toDouble(),
        credit: 0,
        no: e['vouncher_no'].toString(),
      );
    }

    for (var e in res['Payment'] ?? []) {
      addRow(
        date: DateTime.parse(e['date']),
        type: "Payment",
        party: e['supplier_name'],
        debit: 0,
        credit: e['amount'].toDouble(),
        no: e['vouncher_no'].toString(),
      );
    }

    // ================= CONTRA =================
    for (var e in res['Contra'] ?? []) {
      addRow(
        date: DateTime.parse(e['date']),
        type: "Contra",
        party: e['account_name'] == selectedLedger!.ledgerName
            ? e['ledger_name']
            : e['account_name'],
        debit: e['account_name'] == selectedLedger!.ledgerName
            ? e['amount'].toDouble()
            : 0,
        credit: e['account_name'] == selectedLedger!.ledgerName
            ? 0
            : e['amount'].toDouble(),
        no: e['vouncher_no'].toString(),
      );
    }

    // ================= EXPENSE =================
    for (var e in res['Expense'] ?? []) {
      addRow(
        date: DateTime.parse(e['date']),
        type: "Expense",
        party: e['account_name'],
        debit: 0,
        credit: e['amount'].toDouble(),
        no: e['vouncher_no'].toString(),
      );
    }

    // ================= Journal =================
    for (var e in res['Journal'] ?? []) {
      addRow(
        date: DateTime.parse(e['date']),
        type: "Journal",
        party: e['account_name'] == selectedLedger!.ledgerName
            ? e['ledger_name']
            : e['account_name'],
        debit: e['account_name'] == selectedLedger!.ledgerName
            ? e['amount'].toDouble()
            : 0,
        credit: e['account_name'] == selectedLedger!.ledgerName
            ? 0
            : e['amount'].toDouble(),
        no: e['vouncher_no'].toString(),
      );
    }

    rows.sort((a, b) => a.date.compareTo(b.date));
    setState(() {});
  }

  // ================= UI =================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xffF3F4F6),
      appBar: AppBar(
        backgroundColor: AppColor.primary,
        title: const Text("Bank Book Report"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _filterBar(),
            const SizedBox(height: 10),
            _openingRow(),
            const SizedBox(height: 10),
            _ledgerTable(),
          ],
        ),
      ),
    );
  }

  // ================= FILTER =================
  Widget _filterBar() {
    return Row(
      children: [
        Expanded(
          child: CommonSearchableDropdownField<LedgerListModel>(
            controller: ledgerCtrl,
            hintText: "Select Bank",
            suggestions: ledgerList
                .map((e) => SearchFieldListItem(e.ledgerName ?? "", item: e))
                .toList(),
            onSuggestionTap: (v) {
              selectedLedger = v.item;
              ledgerCtrl.text = v.item!.ledgerName!;
            },
          ),
        ),
        const SizedBox(width: 10),
        _dateBox(fromCtrl, true),
        const SizedBox(width: 8),
        _dateBox(toCtrl, false),
        const SizedBox(width: 10),
        defaultButton(
          onTap: fetchLedgerReport,
          text: "View",
          height: 40,
          width: 150,
          buttonColor: AppColor.blue,
        ),
      ],
    );
  }

  Widget _dateBox(TextEditingController c, bool isFrom) {
    return InkWell(
      onTap: () async {
        final d = await showDatePicker(
          context: context,
          firstDate: DateTime(1990),
          lastDate: DateTime(2100),
          initialDate: isFrom ? fromDate : toDate,
        );
        if (d != null) {
          setState(() {
            if (isFrom) {
              fromDate = d;
              fromCtrl.text = df.format(d);
            } else {
              toDate = d;
              toCtrl.text = df.format(d);
            }
          });
        }
      },
      child: Container(
        width: 140,
        alignment: Alignment.center,
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          border: Border.all(color: AppColor.backgroundColor),
          borderRadius: BorderRadius.circular(5),
          color: Colors.white,
        ),
        child: Text(
          c.text,
          style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w500),
        ),
      ),
    );
  }

  // ================= OPENING =================
  Widget _openingRow() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [_box("Opening", openingBalance)],
    );
  }

  // ================= TABLE =================
  Widget _ledgerTable() {
    return Expanded(
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            _header(),
            Expanded(
              child: ListView.builder(
                itemCount: rows.length,
                itemBuilder: (_, i) {
                  final e = rows[i];
                  return Padding(
                    padding: const EdgeInsets.all(10),
                    child: Row(
                      children: [
                        _cell(df.format(e.date), 2),
                        _cell(e.voucherNo, 1),
                        _cell(e.type, 2),
                        _cell(e.party, 3),
                        _cell(e.debit.toStringAsFixed(2), 2),
                        _cell(e.credit.toStringAsFixed(2), 2),
                      ],
                    ),
                  );
                },
              ),
            ),
            _summary(),
          ],
        ),
      ),
    );
  }

  Widget _header() {
    return Container(
      height: 45,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: AppColor.primary,
        borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
      ),
      child: const Row(
        children: [
          _Head("Date", 2),
          _Head("No", 1),
          _Head("Type", 2),
          _Head("Party", 3),
          _Head("Debit", 2),
          _Head("Credit", 2),
        ],
      ),
    );
  }

  Widget _summary() {
    final balance = openingBalance + debitTotal - creditTotal;

    return Container(
      padding: const EdgeInsets.all(12),
      color: Colors.grey.shade100,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          _box("Debit", debitTotal),
          _box("Credit", -creditTotal),
          _box("Balance", balance),
        ],
      ),
    );
  }

  Widget _box(String title, double val) {
    return Container(
      margin: const EdgeInsets.only(left: 10),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        border: Border.all(),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Column(
        children: [
          Text(title),
          Text(
            val.abs().toStringAsFixed(2) + (val <= 0 ? " Cr" : " Dr"),
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _cell(String text, int flex) {
    return Expanded(
      flex: flex,
      child: Text(text, overflow: TextOverflow.ellipsis),
    );
  }
}

// ================= MODEL =================
class LedgerRow {
  final DateTime date;
  final String voucherNo;
  final String type;
  final String party;
  final double debit;
  final double credit;

  LedgerRow({
    required this.date,
    required this.voucherNo,
    required this.type,
    required this.party,
    required this.debit,
    required this.credit,
  });
}

class _Head extends StatelessWidget {
  final String text;
  final int flex;
  const _Head(this.text, this.flex);

  @override
  Widget build(BuildContext context) {
    return Expanded(
      flex: flex,
      child: Text(
        text,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
