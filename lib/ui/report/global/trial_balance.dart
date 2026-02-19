import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:ims/utils/api.dart';
import 'package:ims/utils/prefence.dart';
import 'package:ims/utils/colors.dart';

class TrialBalanceScreen extends StatefulWidget {
  const TrialBalanceScreen({super.key});

  @override
  State<TrialBalanceScreen> createState() => _TrialBalanceScreenState();
}

class _TrialBalanceScreenState extends State<TrialBalanceScreen> {
  final fromCtrl = TextEditingController(text: "2025-04-01");
  final toCtrl = TextEditingController(text: "2026-03-31");

  bool loading = false;

  List<_LedgerRow> rows = [];
  Map<String, _GroupSum> groupSums = {};

  double totalDr = 0;
  double totalCr = 0;

  @override
  void initState() {
    super.initState();
    fetchTB();
  }

  Future<void> pickDate(TextEditingController c) async {
    final d = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(1990),
      lastDate: DateTime(2100),
    );
    if (d != null) {
      c.text = DateFormat('yyyy-MM-dd').format(d);
      setState(() {});
    }
  }

  Future<void> fetchTB() async {
    setState(() => loading = true);

    final res = await ApiService.fetchData(
      "get/ledgers?from_date=${fromCtrl.text}&to_date=${toCtrl.text}",
      licenceNo: Preference.getint(PrefKeys.licenseNo),
    );

    final List list = res['data'] ?? [];

    rows.clear();
    groupSums.clear();
    totalDr = 0;
    totalCr = 0;

    for (final e in list) {
      final name = e['ledger_name'] ?? '';
      final group = e['ledger_group'] ?? '';
      final bal = double.tryParse("${e['closing_balance'] ?? 0}") ?? 0;

      double dr = 0, cr = 0;
      if (bal > 0) {
        dr = bal;
        totalDr += dr;
      }
      if (bal < 0) {
        cr = bal.abs();
        totalCr += cr;
      }

      rows.add(_LedgerRow(name: name, group: group, dr: dr, cr: cr));

      groupSums.putIfAbsent(group, () => _GroupSum());
      groupSums[group]!.dr += dr;
      groupSums[group]!.cr += cr;
    }

    setState(() => loading = false);
  }

  @override
  Widget build(BuildContext context) {
    final balanced = (totalDr - totalCr).abs() < 0.01;

    return Scaffold(
      backgroundColor: AppColor.backgroundColor,
      appBar: AppBar(
        backgroundColor: const Color(0xff1aa3b3),
        title: Text(
          "Trial Balance",
          style: GoogleFonts.inter(fontWeight: FontWeight.w700),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Filters
            Container(
              padding: const EdgeInsets.all(12),
              decoration: _cardDeco(),
              child: Row(
                children: [
                  _dateField("From Date", fromCtrl, () => pickDate(fromCtrl)),
                  const SizedBox(width: 12),
                  _dateField("To Date", toCtrl, () => pickDate(toCtrl)),
                  const SizedBox(width: 12),
                  ElevatedButton(
                    onPressed: fetchTB,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xff0b5ed7),
                    ),
                    child: const Text("Search"),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Category Summary Table
            _tableHeader(["Category", "Dr.", "Cr."]),
            ...groupSums.entries.map(
              (e) => _tableRow([e.key, _amt(e.value.dr), _amt(e.value.cr)]),
            ),
            _tableFooter("Total", totalDr, totalCr),

            const SizedBox(height: 24),

            // Account-wise Table
            _tableHeader(["Account", "Category", "Dr.", "Cr."]),
            ...rows.map(
              (r) => _tableRow([r.name, r.group, _amt(r.dr), _amt(r.cr)]),
            ),
            _tableFooter("Total", totalDr, totalCr),

            const SizedBox(height: 12),
            Row(
              children: [
                Icon(
                  balanced ? Icons.check_circle : Icons.error,
                  color: balanced ? Colors.green : Colors.red,
                ),
                const SizedBox(width: 8),
                Text(
                  balanced ? "Trial Balance Matched" : "Trial Balance Mismatch",
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.w700,
                    color: balanced ? Colors.green : Colors.red,
                  ),
                ),
              ],
            ),

            if (loading)
              const Padding(
                padding: EdgeInsets.only(top: 12),
                child: LinearProgressIndicator(),
              ),
          ],
        ),
      ),
    );
  }

  Widget _dateField(String label, TextEditingController c, VoidCallback onTap) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
          const SizedBox(height: 6),
          TextField(
            controller: c,
            readOnly: true,
            onTap: onTap,
            decoration: const InputDecoration(
              isDense: true,
              border: OutlineInputBorder(),
              suffixIcon: Icon(Icons.calendar_month),
            ),
          ),
        ],
      ),
    );
  }

  BoxDecoration _cardDeco() => BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(10),
    border: Border.all(color: AppColor.borderColor),
    boxShadow: const [BoxShadow(color: Color(0xff171a1f14), blurRadius: 4)],
  );

  Widget _tableHeader(List<String> cols) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
      color: const Color(0xff6c757d),
      child: Row(
        children: [
          Expanded(flex: 4, child: _h(cols[0])),
          if (cols.length == 4) Expanded(flex: 3, child: _h(cols[1])),
          Expanded(child: _h(cols[cols.length - 2], right: true)),
          Expanded(child: _h(cols.last, right: true)),
        ],
      ),
    );
  }

  Widget _tableRow(List<String> cols) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: AppColor.borderColor)),
      ),
      child: Row(
        children: [
          Expanded(flex: 4, child: Text(cols[0])),
          if (cols.length == 4) Expanded(flex: 3, child: Text(cols[1])),
          Expanded(
            child: Text(cols[cols.length - 2], textAlign: TextAlign.right),
          ),
          Expanded(child: Text(cols.last, textAlign: TextAlign.right)),
        ],
      ),
    );
  }

  Widget _tableFooter(String title, double dr, double cr) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(width: 2)),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 4,
            child: Text(
              title,
              style: GoogleFonts.inter(fontWeight: FontWeight.w700),
            ),
          ),
          Expanded(
            child: Text(
              _amt(dr),
              textAlign: TextAlign.right,
              style: GoogleFonts.inter(fontWeight: FontWeight.w700),
            ),
          ),
          Expanded(
            child: Text(
              _amt(cr),
              textAlign: TextAlign.right,
              style: GoogleFonts.inter(fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _h(String t, {bool right = false}) => Text(
    t,
    textAlign: right ? TextAlign.right : TextAlign.left,
    style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.w700),
  );

  String _amt(double v) => v == 0 ? "0" : v.toStringAsFixed(2);
}

class _LedgerRow {
  final String name;
  final String group;
  final double dr;
  final double cr;
  _LedgerRow({
    required this.name,
    required this.group,
    required this.dr,
    required this.cr,
  });
}

class _GroupSum {
  double dr = 0;
  double cr = 0;
}
